import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../services/admin_service.dart';
import '../../posts/models/post_model.dart';
import '../../posts/views/post_card.dart';

class AdminPostsTimelineView extends StatefulWidget {
  const AdminPostsTimelineView({super.key});

  @override
  State<AdminPostsTimelineView> createState() => _AdminPostsTimelineViewState();
}

class _AdminPostsTimelineViewState extends State<AdminPostsTimelineView> {
  PostModule? _moduleFilter;
  final Set<String> _busyPostIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _moduleFilter == null,
                  onSelected: (_) => setState(() => _moduleFilter = null),
                ),
              ),
              ...PostModule.values.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(m.label),
                      selected: _moduleFilter == m,
                      onSelected: (_) => setState(() => _moduleFilter = m),
                    ),
                  )),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<PostModel>>(
            stream: context.read<AdminService>().watchPosts(module: _moduleFilter),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error loading posts: ${snap.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final posts = snap.data ?? [];
              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.feed_outlined,
                        size: 56,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text('No posts found', style: theme.textTheme.titleMedium),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final post = posts[i];
                  final flagged = post.isInappropriate;
                  final busy = _busyPostIds.contains(post.id);
                  return Stack(
                    children: [
                      PostCard(
                        key: ValueKey(post.id),
                        post: post,
                        onTap: () => navigatorKey.currentState?.pushNamed(
                          AppConstants.routePostDetail,
                          arguments: post,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: theme.colorScheme.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          child: PopupMenuButton<String>(
                            tooltip: 'Manage post',
                            onSelected: busy
                                ? null
                                : (value) async {
                                    if (value == 'view') {
                                      navigatorKey.currentState?.pushNamed(
                                        AppConstants.routePostDetail,
                                        arguments: post,
                                      );
                                      return;
                                    }
                                    if (value == 'flag') {
                                      await _markInappropriate(post, true);
                                      return;
                                    }
                                    if (value == 'unflag') {
                                      await _markInappropriate(post, false);
                                      return;
                                    }
                                    if (value == 'delete') {
                                      await _deletePost(post);
                                    }
                                  },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'view',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.visibility_outlined),
                                  title: Text('View'),
                                ),
                              ),
                              PopupMenuItem(
                                value: flagged ? 'unflag' : 'flag',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    flagged
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.report_gmailerrorred_rounded,
                                  ),
                                  title: Text(flagged ? 'Mark appropriate' : 'Mark inappropriate'),
                                ),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Delete'),
                                ),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert_rounded),
                          ),
                        ),
                      ),
                      if (flagged)
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Inappropriate',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (busy)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.66),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deletePost(PostModel post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post'),
        content: Text(
          'Are you sure you want to permanently delete "${post.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _busyPostIds.add(post.id));
    String message;
    var success = true;
    try {
      await context.read<AdminService>().deletePost(post.id);
      message = 'Post deleted.';
    } catch (e) {
      success = false;
      message = 'Failed to delete post: $e';
    }
    if (!mounted) return;
    setState(() => _busyPostIds.remove(post.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? null : Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }

  Future<void> _markInappropriate(PostModel post, bool inappropriate) async {
    String? reason;
    if (inappropriate) {
      reason = await _askReason('Mark inappropriate', 'Reason (optional)');
      if (!mounted) return;
      if (reason == null) return;
    }
    setState(() => _busyPostIds.add(post.id));
    var success = true;
    String message;
    try {
      await context.read<AdminService>().markPostInappropriate(
            post.id,
            inappropriate: inappropriate,
            reason: reason?.trim().isEmpty ?? true ? null : reason?.trim(),
          );
      message = inappropriate ? 'Post marked inappropriate.' : 'Post marked appropriate.';
    } catch (e) {
      success = false;
      message = 'Failed to update post: $e';
    }
    if (!mounted) return;
    setState(() => _busyPostIds.remove(post.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? null : Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }

  Future<String?> _askReason(String title, String hint) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

}
