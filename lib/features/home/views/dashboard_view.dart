import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../posts/controllers/post_controller.dart';
import '../../posts/models/post_model.dart';
import '../../posts/views/post_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  PostModule? _module; // null = All
  Stream<List<PostModel>>? _postsStream;
  PostModule? _cachedModule;

  Stream<List<PostModel>> _getPostsStream() {
    if (_postsStream == null || _cachedModule != _module) {
      _cachedModule = _module;
      _postsStream = context.read<PostController>().watchPosts(module: _module);
    }
    return _postsStream!;
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
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () => navigatorKey.currentState?.pushNamed(
                  AppConstants.routeCreatePost,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                final posts = snap.data ?? [];
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to share!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => navigatorKey.currentState?.pushNamed(
                              AppConstants.routeCreatePost,
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create post'),
                          ),
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
