import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../posts/controllers/post_controller.dart';
import '../../posts/models/post_model.dart';

Future<void> _showDeleteConfirm(BuildContext context, PostModel post) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete post?'),
      content: Text('Delete "${post.title}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<PostController>().deletePost(post.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    }
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please sign in',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => navigatorKey.currentState?.pushNamed(
              AppConstants.routeSettings,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Text(
                (user.displayName?.isNotEmpty == true
                        ? user.displayName![0]
                        : user.email?[0] ?? '?')
                    .toUpperCase(),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? 'User',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (user.email != null) ...[
              const SizedBox(height: 4),
              Text(
                user.email!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'My posts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<PostModel>>(
              stream: context.read<PostController>().watchMyPosts(user.uid),
              builder: (context, snap) {
                final posts = snap.data ?? [];
                if (posts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          'No posts yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => navigatorKey.currentState?.pushNamed(
                            AppConstants.routeCreatePost,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create your first post'),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: posts
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MyPostCard(
                              post: p,
                              onView: () => navigatorKey.currentState?.pushNamed(
                                AppConstants.routePostDetail,
                                arguments: p,
                              ),
                              onEdit: () => navigatorKey.currentState?.pushNamed(
                                AppConstants.routeEditPost,
                                arguments: p,
                              ),
                              onDelete: () => _showDeleteConfirm(context, p),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  navigatorKey.currentState?.pushNamedAndRemoveUntil(
                    AppConstants.routeLogin,
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPostCard extends StatelessWidget {
  const _MyPostCard({
    required this.post,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final PostModel post;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onView,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.imageUrls.isNotEmpty)
                  Image.network(
                    post.imageUrls.first,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              post.module.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                FilledButton.tonal(
                  onPressed: onView,
                  child: const Text('View'),
                ),
                OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
