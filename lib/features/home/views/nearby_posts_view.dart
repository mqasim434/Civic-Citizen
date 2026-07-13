import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../../posts/controllers/post_controller.dart';
import '../../posts/models/post_model.dart';
import '../../posts/utils/post_search_filter.dart';
import '../../posts/views/post_card.dart';

/// Posts near the user's current location, sorted by distance.
class NearbyPostsView extends StatefulWidget {
  const NearbyPostsView({super.key});

  @override
  State<NearbyPostsView> createState() => _NearbyPostsViewState();
}

class _NearbyPostsViewState extends State<NearbyPostsView>
    with AutomaticKeepAliveClientMixin {
  PostModule? _module;
  double _radiusKm = PostSearchFilter.defaultNearbyRadiusKm;
  double? _userLatitude;
  double? _userLongitude;
  bool _loadingLocation = true;
  String? _locationError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permission is required to show nearby posts.';
          _loadingLocation = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _userLatitude = pos.latitude;
        _userLongitude = pos.longitude;
        _loadingLocation = false;
      });
    } catch (_) {
      setState(() {
        _locationError = 'Could not get your location. Pull to retry.';
        _loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadLocation,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Nearby'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.my_location_rounded),
                  tooltip: 'Refresh location',
                  onPressed: _loadingLocation ? null : _loadLocation,
                ),
                const NotificationBellButton(),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Posts within ${_radiusKm.toStringAsFixed(_radiusKm == _radiusKm.roundToDouble() ? 0 : 1)} km of you, nearest first.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PostSearchFilter.radiusOptionsKm
                      .where((km) => km <= 10)
                      .map(
                        (km) => ChoiceChip(
                          label: Text('${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} km'),
                          selected: _radiusKm == km,
                          onSelected: (_) => setState(() => _radiusKm = km),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _module == null,
                        onSelected: (_) => setState(() => _module = null),
                      ),
                      const SizedBox(width: 8),
                      ...PostModule.values.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(m.label),
                            selected: _module == m,
                            onSelected: (_) => setState(() => _module = m),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_loadingLocation)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_locationError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_rounded,
                          size: 56,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _locationError!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadLocation,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              StreamBuilder<List<PostModel>>(
                stream: context.read<PostController>().watchPosts(module: _module),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final nearby = PostSearchFilter.nearbyPosts(
                    posts: snap.data ?? [],
                    userLatitude: _userLatitude!,
                    userLongitude: _userLongitude!,
                    radiusKm: _radiusKm,
                    module: _module,
                  );

                  if (nearby.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.near_me_disabled_rounded,
                                size: 56,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts nearby',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try a larger radius or check back later. '
                                'Only posts with map coordinates appear here.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final item = nearby[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PostCard(
                              key: ValueKey(item.post.id),
                              post: item.post,
                              distanceLabel: PostSearchFilter.formatDistanceKm(
                                item.distanceKm,
                              ),
                              onTap: () => navigatorKey.currentState?.pushNamed(
                                AppConstants.routePostDetail,
                                arguments: item.post,
                              ),
                            ),
                          );
                        },
                        childCount: nearby.length,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
