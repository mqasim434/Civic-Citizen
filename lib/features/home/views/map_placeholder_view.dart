import 'dart:async';

import 'package:flutter/material.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../posts/controllers/post_controller.dart';
import '../../posts/models/post_model.dart';

class MapPostsView extends StatefulWidget {
  const MapPostsView({super.key});

  @override
  State<MapPostsView> createState() => _MapPostsViewState();
}

class _MapPostsViewState extends State<MapPostsView> {
  static const LatLng _defaultCenter = LatLng(31.5204, 74.3587);
  static const CameraPosition _defaultCamera = CameraPosition(
    target: _defaultCenter,
    zoom: 11.5,
  );

  final Completer<GoogleMapController> _mapController = Completer();
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  final Map<String, LatLng> _resolvedByLocation = {};
  final Map<String, Future<LatLng?>> _pendingLocationLookups = {};

  PostModule? _moduleFilter;
  String? _categoryFilter;
  bool _didCenterOnUser = false;

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsStream = context.read<PostController>().watchPosts(
      module: _moduleFilter,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: StreamBuilder<List<PostModel>>(
        stream: postsStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allPosts = snap.data ?? const <PostModel>[];
          final availableCategories = _extractCategories(allPosts);
          _normalizeCategoryFilter(availableCategories);
          final visiblePosts = _applyCategoryFilter(allPosts);

          return FutureBuilder<Map<String, LatLng>>(
            future: _buildMarkerCoordinates(visiblePosts),
            builder: (context, coordSnap) {
              final markerCoords = coordSnap.data ?? const <String, LatLng>{};
              final markerPosts = visiblePosts
                  .where((p) => markerCoords.containsKey(p.id))
                  .toList();
              final markers = _buildMarkers(markerPosts, markerCoords);
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _defaultCamera,
                    markers: markers,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    onTap: (_) => _customInfoWindowController.hideInfoWindow!(),
                    onCameraMove: (_) => _customInfoWindowController.onCameraMove!(),
                    onMapCreated: (controller) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(controller);
                      }
                      _customInfoWindowController.googleMapController = controller;
                      _centerOnCurrentLocation();
                    },
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _MapFilters(
                      moduleFilter: _moduleFilter,
                      categoryFilter: _categoryFilter,
                      categories: availableCategories,
                      onModuleSelected: (module) => setState(() {
                        _moduleFilter = module;
                        _customInfoWindowController.hideInfoWindow!();
                      }),
                      onCategorySelected: (category) => setState(() {
                        _categoryFilter = category;
                        _customInfoWindowController.hideInfoWindow!();
                      }),
                    ),
                  ),
                  if (allPosts.isEmpty)
                    const _MapStatusBanner(
                      icon: Icons.inbox_rounded,
                      message: 'No posts available to show on the map.',
                    )
                  else if (visiblePosts.isNotEmpty &&
                      markerPosts.isEmpty &&
                      coordSnap.connectionState != ConnectionState.waiting)
                    const _MapStatusBanner(
                      icon: Icons.location_off_rounded,
                      message: 'No mappable locations found for selected tags.',
                    ),
                  if (coordSnap.connectionState == ConnectionState.waiting)
                    const _MapStatusBanner(
                      icon: Icons.sync_rounded,
                      message: 'Resolving post locations...',
                    ),
                  CustomInfoWindow(
                    controller: _customInfoWindowController,
                    height: 116,
                    width: 300,
                    offset: 42,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Set<Marker> _buildMarkers(List<PostModel> posts, Map<String, LatLng> coords) {
    return posts.map((post) {
      final location = coords[post.id]!;
      return Marker(
        markerId: MarkerId(post.id),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(post.module)),
        infoWindow: InfoWindow.noText,
        onTap: () {
          _customInfoWindowController.addInfoWindow!(
            _buildCustomInfoWindow(context, post),
            location,
          );
          _moveTo(location);
        },
      );
    }).toSet();
  }

  Future<void> _moveTo(LatLng location) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newLatLng(location));
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_didCenterOnUser) return;
    _didCenterOnUser = true;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      await _moveTo(LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      // Keep default camera target if current location can't be resolved.
    }
  }

  Future<Map<String, LatLng>> _buildMarkerCoordinates(
    List<PostModel> posts,
  ) async {
    final coords = <String, LatLng>{};
    for (final post in posts) {
      final rawLocation = post.location?.trim();
      if (rawLocation == null || rawLocation.isEmpty) continue;
      final latLng = await _resolveLocation(rawLocation);
      if (latLng != null) {
        coords[post.id] = latLng;
      }
    }
    return coords;
  }

  Future<LatLng?> _resolveLocation(String location) {
    final cached = _resolvedByLocation[location];
    if (cached != null) return Future.value(cached);

    final parsed = _tryParseLatLng(location);
    if (parsed != null) {
      _resolvedByLocation[location] = parsed;
      return Future.value(parsed);
    }

    final pending = _pendingLocationLookups[location];
    if (pending != null) return pending;

    final lookup = locationFromAddress(location)
        .then((results) {
          if (results.isEmpty) return null;
          final latLng = LatLng(
            results.first.latitude,
            results.first.longitude,
          );
          _resolvedByLocation[location] = latLng;
          return latLng;
        })
        .catchError((_) {
          return null;
        })
        .whenComplete(() {
          _pendingLocationLookups.remove(location);
        });

    _pendingLocationLookups[location] = lookup;
    return lookup;
  }

  LatLng? _tryParseLatLng(String value) {
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(value);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  List<String> _extractCategories(List<PostModel> posts) {
    final set = <String>{};
    for (final post in posts) {
      final label = post.categoryDisplayLabel?.trim();
      if (label != null && label.isNotEmpty) {
        set.add(label);
      }
    }
    final sorted = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  void _normalizeCategoryFilter(List<String> availableCategories) {
    if (_categoryFilter == null) return;
    if (!availableCategories.contains(_categoryFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _categoryFilter = null);
      });
    }
  }

  List<PostModel> _applyCategoryFilter(List<PostModel> posts) {
    final selected = _categoryFilter;
    if (selected == null) return posts;
    return posts.where((p) => p.categoryDisplayLabel == selected).toList();
  }

  double _markerHue(PostModule module) {
    switch (module) {
      case PostModule.lost:
        return BitmapDescriptor.hueRed;
      case PostModule.found:
        return BitmapDescriptor.hueGreen;
      case PostModule.charity:
        return BitmapDescriptor.hueViolet;
      case PostModule.resources:
        return BitmapDescriptor.hueAzure;
      case PostModule.lend:
        return BitmapDescriptor.hueOrange;
      case PostModule.borrow:
        return BitmapDescriptor.hueYellow;
    }
  }

  Widget _buildCustomInfoWindow(BuildContext context, PostModel post) {
    final theme = Theme.of(context);
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => navigatorKey.currentState?.pushNamed(
          AppConstants.routePostDetail,
          arguments: post,
        ),
        child: Container(
          width: 300,
          height: 116,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 96,
                  child: imageUrl == null
                      ? Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_outlined),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${post.module.label} • ${post.categoryDisplayLabel ?? 'General'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    if ((post.location?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(height: 2),
                      Text(
                        post.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFilters extends StatelessWidget {
  const _MapFilters({
    required this.moduleFilter,
    required this.categoryFilter,
    required this.categories,
    required this.onModuleSelected,
    required this.onCategorySelected,
  });

  final PostModule? moduleFilter;
  final String? categoryFilter;
  final List<String> categories;
  final ValueChanged<PostModule?> onModuleSelected;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All modules'),
                      selected: moduleFilter == null,
                      onSelected: (_) => onModuleSelected(null),
                    ),
                  ),
                  ...PostModule.values.map(
                    (module) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(module.label),
                        selected: moduleFilter == module,
                        onSelected: (_) => onModuleSelected(module),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All tags'),
                        selected: categoryFilter == null,
                        onSelected: (_) => onCategorySelected(null),
                      ),
                    ),
                    ...categories.map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag),
                          selected: categoryFilter == tag,
                          onSelected: (_) => onCategorySelected(tag),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapStatusBanner extends StatelessWidget {
  const _MapStatusBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

