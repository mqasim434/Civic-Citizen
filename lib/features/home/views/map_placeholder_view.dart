import 'dart:async';

import 'package:flutter/material.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/shell_tab.dart';
import '../../../core/theme/map_styles.dart';
import '../../../core/navigation/tab_reselect.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/utils/device_location.dart';
import '../../posts/controllers/post_controller.dart';
import '../../posts/models/post_model.dart';
import '../../posts/utils/post_search_filter.dart';
import '../widgets/location_search_sheet.dart';

class MapPostsView extends StatefulWidget {
  const MapPostsView({super.key});

  @override
  State<MapPostsView> createState() => _MapPostsViewState();
}

class _MapPostsViewState extends State<MapPostsView>
    with TabReselectListener {
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
  final TextEditingController _locationController = TextEditingController();

  PostModule? _moduleFilter;
  String? _categoryFilter;
  double? _radiusKm;
  double? _userLatitude;
  double? _userLongitude;
  bool _didCenterOnUser = false;
  bool _locationLoading = false;
  Stream<List<PostModel>>? _postsStream;
  PostModule? _cachedModule;

  @override
  int get shellTabIndex => ShellTab.map;

  /// Map has no list to scroll, so close any open popup and re-centre
  /// on the user's location (or the default city).
  @override
  void onTabReselected() {
    _customInfoWindowController.hideInfoWindow?.call();
    final target = _userLatitude != null && _userLongitude != null
        ? LatLng(_userLatitude!, _userLongitude!)
        : _defaultCenter;
    _moveTo(target);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _customInfoWindowController.dispose();
    super.dispose();
  }

  Stream<List<PostModel>> _getPostsStream() {
    if (_postsStream == null || _cachedModule != _moduleFilter) {
      _cachedModule = _moduleFilter;
      _postsStream =
          context.read<PostController>().watchPosts(module: _moduleFilter);
    }
    return _postsStream!;
  }

  Future<void> _ensureUserLocation({bool force = false}) async {
    if (!force && _userLatitude != null && _userLongitude != null) return;
    await _useCurrentLocation(moveCamera: false);
  }

  Future<void> _openLocationSearch() async {
    final result = await LocationSearchSheet.show(
      context,
      initialQuery: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _userLatitude = result.latitude;
      _userLongitude = result.longitude;
      _locationController.text = result.address;
      _locationLoading = false;
    });
    _customInfoWindowController.hideInfoWindow!();
    await _moveTo(LatLng(result.latitude, result.longitude));
  }

  Future<void> _useCurrentLocation({bool moveCamera = true}) async {
    setState(() => _locationLoading = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locationLoading = false);
        return;
      }
      final pos = await DeviceLocation.current();
      if (pos == null) {
        if (!mounted) return;
        setState(() => _locationLoading = false);
        return;
      }
      final label = await labelForCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _userLatitude = pos.latitude;
        _userLongitude = pos.longitude;
        _locationController.text = label;
        _locationLoading = false;
      });
      if (moveCamera) {
        await _moveTo(LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby & Map')),
      body: StreamBuilder<List<PostModel>>(
        stream: _getPostsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final allPosts = snap.data ?? const <PostModel>[];
          final availableCategories = _extractCategories(allPosts);
          _normalizeCategoryFilter(availableCategories);
          final visiblePosts = _applyCategoryFilter(
            allPosts
                .where((p) => p.isPubliclyListed && !p.isInappropriate)
                .toList(),
          );

          return FutureBuilder<Map<String, LatLng>>(
            future: _buildMarkerCoordinates(visiblePosts),
            builder: (context, coordSnap) {
              final markerCoords = coordSnap.data ?? const <String, LatLng>{};
              var markerPosts = visiblePosts
                  .where((p) => markerCoords.containsKey(p.id))
                  .toList();
              if (_radiusKm != null &&
                  _userLatitude != null &&
                  _userLongitude != null) {
                markerPosts = markerPosts.where((post) {
                  final coords = markerCoords[post.id]!;
                  return PostSearchFilter.distanceKm(
                        _userLatitude!,
                        _userLongitude!,
                        coords.latitude,
                        coords.longitude,
                      ) <=
                      _radiusKm!;
                }).toList();
              }
              final markers = _buildMarkers(markerPosts, markerCoords);
              final theme = Theme.of(context);
              final circles = _radiusKm != null &&
                      _userLatitude != null &&
                      _userLongitude != null
                  ? {
                      Circle(
                        circleId: const CircleId('nearby_radius'),
                        center: LatLng(_userLatitude!, _userLongitude!),
                        radius: _radiusKm! * 1000,
                        fillColor: theme.colorScheme.primary
                            .withValues(alpha: 0.12),
                        strokeColor: theme.colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    }
                  : const <Circle>{};
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _defaultCamera,
                    style: MapStyles.forContext(context),
                    markers: markers,
                    circles: circles,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    onTap: (_) => _customInfoWindowController.hideInfoWindow!(),
                    onCameraMove: (_) =>
                        _customInfoWindowController.onCameraMove!(),
                    onMapCreated: (controller) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(controller);
                      }
                      _customInfoWindowController.googleMapController =
                          controller;
                      _centerOnCurrentLocation();
                    },
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MapLocationField(
                          controller: _locationController,
                          loading: _locationLoading,
                          onOpenSearch: _openLocationSearch,
                          onUseCurrent: () {
                            _useCurrentLocation();
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapFilters(
                          moduleFilter: _moduleFilter,
                          categoryFilter: _categoryFilter,
                          radiusKm: _radiusKm,
                          categories: availableCategories,
                          onModuleSelected: (module) => setState(() {
                            _moduleFilter = module;
                            _categoryFilter = null;
                            _customInfoWindowController.hideInfoWindow!();
                          }),
                          onCategorySelected: (category) => setState(() {
                            _categoryFilter = category;
                            _customInfoWindowController.hideInfoWindow!();
                          }),
                          onRadiusSelected: (radius) async {
                            setState(() {
                              _radiusKm = radius;
                              _customInfoWindowController.hideInfoWindow!();
                            });
                            if (radius != null) {
                              await _ensureUserLocation();
                            }
                          },
                        ),
                      ],
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
                    )
                  else if (_radiusKm != null &&
                      (_userLatitude == null || _userLongitude == null))
                    const _MapStatusBanner(
                      icon: Icons.my_location_rounded,
                      message: 'Getting your location for the radius filter…',
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
    await _useCurrentLocation(moveCamera: true);
  }

  Future<Map<String, LatLng>> _buildMarkerCoordinates(
    List<PostModel> posts,
  ) async {
    final coords = <String, LatLng>{};
    for (final post in posts) {
      if (post.latitude != null && post.longitude != null) {
        coords[post.id] = LatLng(post.latitude!, post.longitude!);
        continue;
      }
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
    final needle = selected.trim().toLowerCase();
    return posts.where((p) {
      final label = p.categoryDisplayLabel?.trim().toLowerCase();
      final raw = p.category?.trim().toLowerCase();
      return label == needle || raw == needle;
    }).toList();
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

class _MapLocationField extends StatelessWidget {
  const _MapLocationField({
    required this.controller,
    required this.loading,
    required this.onOpenSearch,
    required this.onUseCurrent,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onOpenSearch;
  final VoidCallback onUseCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(12),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: loading ? null : onOpenSearch,
        decoration: InputDecoration(
          hintText: 'Search location…',
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
          prefixIcon: Icon(
            Icons.location_on_rounded,
            color: theme.colorScheme.secondary,
          ),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Use current location',
                  onPressed: onUseCurrent,
                  icon: Icon(
                    Icons.my_location_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                ),
        ),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MapFilters extends StatelessWidget {
  const _MapFilters({
    required this.moduleFilter,
    required this.categoryFilter,
    required this.radiusKm,
    required this.categories,
    required this.onModuleSelected,
    required this.onCategorySelected,
    required this.onRadiusSelected,
  });

  final PostModule? moduleFilter;
  final String? categoryFilter;
  final double? radiusKm;
  final List<String> categories;
  final ValueChanged<PostModule?> onModuleSelected;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<double?> onRadiusSelected;

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
                    child: ChoiceChip(
                      label: const Text('All modules'),
                      selected: moduleFilter == null,
                      onSelected: (_) => onModuleSelected(null),
                    ),
                  ),
                  ...PostModule.values.map(
                    (module) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
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
                      child: ChoiceChip(
                        label: const Text('All tags'),
                        selected: categoryFilter == null,
                        onSelected: (_) => onCategorySelected(null),
                      ),
                    ),
                    ...categories.map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
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
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Any distance'),
                      selected: radiusKm == null,
                      onSelected: (_) => onRadiusSelected(null),
                    ),
                  ),
                  ...PostSearchFilter.radiusOptionsKm.map(
                    (km) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} km'),
                        selected: radiusKm == km,
                        onSelected: (_) => onRadiusSelected(km),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

