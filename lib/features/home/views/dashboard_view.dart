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
import '../../posts/widgets/post_filter_sheet.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  PostModule? _module;
  Stream<List<PostModel>>? _postsStream;
  PostModule? _cachedModule;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter;
  double? _radiusKm;
  double? _userLatitude;
  double? _userLongitude;
  String? _locationError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<PostModel>> _getPostsStream() {
    if (_postsStream == null || _cachedModule != _module) {
      _cachedModule = _module;
      _postsStream = context.read<PostController>().watchPosts(module: _module);
    }
    return _postsStream!;
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _categoryFilter != null || _radiusKm != null;

  Future<void> _ensureUserLocation() async {
    if (_userLatitude != null && _userLongitude != null) return;
    setState(() => _locationError = null);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationError = 'Location permission is required for nearby filter.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _userLatitude = pos.latitude;
        _userLongitude = pos.longitude;
        _locationError = null;
      });
    } catch (e) {
      setState(() => _locationError = 'Could not get your location.');
    }
  }

  Future<void> _openFilters(List<PostModel> allPosts) async {
    final result = await PostFilterSheet.show(
      context,
      categories: PostSearchFilter.categoriesFromPosts(allPosts),
      selectedCategory: _categoryFilter,
      selectedRadiusKm: _radiusKm,
    );
    if (result == null || !mounted) return;

    setState(() {
      _categoryFilter = result.category;
      _radiusKm = result.radiusKm;
      _locationError = null;
      if (result.radiusKm == null) {
        _userLatitude = null;
        _userLongitude = null;
      }
    });

    if (result.radiusKm != null) {
      await _ensureUserLocation();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _categoryFilter = null;
      _radiusKm = null;
      _userLatitude = null;
      _userLongitude = null;
      _locationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(
              AppConstants.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: _hasActiveFilters,
                  child: const Icon(Icons.tune_rounded),
                ),
                tooltip: 'Filters',
                onPressed: () async {
                  final snap = await _getPostsStream().first;
                  if (!mounted) return;
                  await _openFilters(snap);
                },
              ),
              const NotificationBellButton(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () => navigatorKey.currentState?.pushNamed(
                  AppConstants.routeCreatePost,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search posts…',
                leading: const Icon(Icons.search_rounded),
                trailing: _searchQuery.isEmpty
                    ? null
                    : [
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      ],
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          if (_hasActiveFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      InputChip(
                        label: Text('“$_searchQuery”'),
                        onDeleted: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    if (_radiusKm != null)
                      InputChip(
                        label: Text('Within ${_radiusKm!.toStringAsFixed(0)} km'),
                        onDeleted: () => setState(() {
                          _radiusKm = null;
                          _userLatitude = null;
                          _userLongitude = null;
                        }),
                      ),
                    if (_categoryFilter != null)
                      InputChip(
                        label: Text(_categoryFilter!),
                        onDeleted: () => setState(() => _categoryFilter = null),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear'),
                      onPressed: _clearFilters,
                    ),
                  ],
                ),
              ),
            ),
          if (_locationError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  _locationError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _module == null,
                        onSelected: (_) => setState(() => _module = null),
                      ),
                    ),
                    ...PostModule.values.map((m) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(m.label),
                            selected: _module == m,
                            onSelected: (_) => setState(() => _module = m),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: StreamBuilder<List<PostModel>>(
              stream: _getPostsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final allPosts = snap.data ?? [];
                final posts = PostSearchFilter.apply(
                  posts: allPosts,
                  keyword: _searchQuery,
                  category: _categoryFilter,
                  radiusKm: _radiusKm,
                  userLatitude: _userLatitude,
                  userLongitude: _userLongitude,
                );

                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasActiveFilters
                                ? Icons.search_off_rounded
                                : Icons.inbox_rounded,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasActiveFilters
                                ? 'No posts match your search'
                                : 'No posts yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _hasActiveFilters
                                ? 'Try different keywords or filters'
                                : 'Be the first to share!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _clearFilters,
                              child: const Text('Clear filters'),
                            ),
                          ] else ...[
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => navigatorKey.currentState?.pushNamed(
                                AppConstants.routeCreatePost,
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create post'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final post = posts[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(
                          key: ValueKey(post.id),
                          post: post,
                          onTap: () => navigatorKey.currentState?.pushNamed(
                            AppConstants.routePostDetail,
                            arguments: post,
                          ),
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
