import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/shell_tab.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../../posts/controllers/post_controller.dart';
import '../../posts/models/post_model.dart';
import '../../posts/utils/post_search_filter.dart';
import '../../posts/views/post_card.dart';
import '../../posts/widgets/post_filter_sheet.dart';
import '../widgets/location_search_sheet.dart';

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
  String _locationLabel = 'Set location';
  bool _locationLoading = true;
  String? _locationError;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    ShellTab.reselected.addListener(_onTabReselected);
    _resolveCurrentLocation();
  }

  @override
  void dispose() {
    ShellTab.reselected.removeListener(_onTabReselected);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Home tab tapped while already on Home: scroll back to the top.
  void _onTabReselected() {
    if (ShellTab.reselected.tab != 0) return;
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    if (offset <= 0) return;

    // Far down the feed: jump close to the top first so the animation
    // stays short instead of scrolling through every post.
    final viewport = _scrollController.position.viewportDimension;
    if (offset > viewport * 3) {
      _scrollController.jumpTo(viewport);
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
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

  Future<void> _resolveCurrentLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationLoading = false;
          _locationLabel = 'Set location';
          _locationError = 'Location permission is required.';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final label = await labelForCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _userLatitude = pos.latitude;
        _userLongitude = pos.longitude;
        _locationLabel = label;
        _locationLoading = false;
        _locationError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationLabel = 'Set location';
        _locationError = 'Could not get your location.';
      });
    }
  }

  Future<void> _ensureUserLocation() async {
    if (_userLatitude != null && _userLongitude != null) return;
    await _resolveCurrentLocation();
  }

  Future<void> _openLocationSheet() async {
    final result = await LocationSearchSheet.show(
      context,
      initialQuery: _locationLabel == 'Set location' ? null : _locationLabel,
    );
    if (result == null || !mounted) return;
    setState(() {
      _userLatitude = result.latitude;
      _userLongitude = result.longitude;
      _locationLabel = result.address;
      _locationError = null;
      _locationLoading = false;
    });
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
      _locationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            toolbarHeight: 72,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConstants.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      InkWell(
                        onTap: _locationLoading ? null : _openLocationSheet,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 2),
                              if (_locationLoading)
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.secondary,
                                  ),
                                )
                              else
                                Flexible(
                                  child: Text(
                                    _locationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: const [NotificationBellButton(), SizedBox(width: 4)],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 148,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Image(
                        image: AssetImage('assets/home_banner.jpg'),
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stronger\nCommunity Together',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => navigatorKey.currentState
                                  ?.pushNamed(AppConstants.routeEvents),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Text('Learn More'),
                              label: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search posts...',
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                  IconButton(
                    tooltip: 'Filters',
                    icon: Badge(
                      isLabelVisible: _hasActiveFilters,
                      child: const Icon(Icons.tune_rounded),
                    ),
                    onPressed: () async {
                      final allForCategories = await context
                          .read<PostController>()
                          .watchPosts()
                          .first;
                      if (!mounted) return;
                      await _openFilters(allForCategories);
                    },
                  ),
                ],
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const filters =
                      <({PostModule? module, IconData icon, String label})>[
                        (module: null, icon: Icons.apps_rounded, label: 'All'),
                        (
                          module: PostModule.lost,
                          icon: Icons.pets_rounded,
                          label: 'Lost',
                        ),
                        (
                          module: PostModule.found,
                          icon: Icons.inventory_2_outlined,
                          label: 'Found',
                        ),
                        (
                          module: PostModule.charity,
                          icon: Icons.favorite_border_rounded,
                          label: 'Charity',
                        ),
                        (
                          module: PostModule.resources,
                          icon: Icons.shield_outlined,
                          label: 'Rescue',
                        ),
                        (
                          module: PostModule.lend,
                          icon: Icons.handshake_outlined,
                          label: 'Lend',
                        ),
                        (
                          module: PostModule.borrow,
                          icon: Icons.shopping_bag_outlined,
                          label: 'Borrow',
                        ),
                      ];
                  final itemWidth = constraints.maxWidth / 5;
                  return SizedBox(
                    height: 84,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      itemBuilder: (context, i) {
                        final item = filters[i];
                        return SizedBox(
                          width: itemWidth,
                          child: _HomeCat(
                            icon: item.icon,
                            label: item.label,
                            selected: _module == item.module,
                            onTap: () => setState(() => _module = item.module),
                          ),
                        );
                      },
                    ),
                  );
                },
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
                        label: Text(
                          'Within ${_radiusKm!.toStringAsFixed(0)} km',
                        ),
                        onDeleted: () => setState(() => _radiusKm = null),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Text('Latest Posts', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () => navigatorKey.currentState?.pushNamed(
                      AppConstants.routeCreatePost,
                    ),
                    child: const Text('Create'),
                  ),
                ],
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
                if (_locationLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final posts = PostSearchFilter.apply(
                  posts: allPosts,
                  keyword: _searchQuery,
                  category: _categoryFilter,
                  radiusKm: _radiusKm,
                  userLatitude: _userLatitude,
                  userLongitude: _userLongitude,
                  placeLabel: _userLatitude == null ? null : _locationLabel,
                );
                posts.sort((a, b) {
                  final sponsor = (b.isSponsored ? 1 : 0).compareTo(
                    a.isSponsored ? 1 : 0,
                  );
                  if (sponsor != 0) return sponsor;
                  final ad =
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bd =
                      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bd.compareTo(ad);
                });

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
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasActiveFilters
                                ? 'No posts match your search'
                                : _userLatitude != null
                                ? 'No posts in $_locationLabel'
                                : 'No posts yet',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _hasActiveFilters
                                ? 'Try different keywords or filters'
                                : _userLatitude != null
                                ? 'Posts from this place will show up here.'
                                : 'Be the first to share!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
                              onPressed: () => navigatorKey.currentState
                                  ?.pushNamed(AppConstants.routeCreatePost),
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
                  delegate: SliverChildBuilderDelegate((_, i) {
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
                  }, childCount: posts.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCat extends StatelessWidget {
  const _HomeCat({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
