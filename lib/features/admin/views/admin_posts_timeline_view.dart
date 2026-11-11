import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/shell_tab.dart';
import '../../../core/navigation/tab_reselect.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/posts_board.dart';
import '../../posts/models/post_model.dart';
import '../services/admin_service.dart';
import '../ui/admin_ui.dart';
import 'admin_post_detail_view.dart';

enum _Sort { newest, oldest, mostLiked }

/// Admin posts: shared posts board (status + category chips, Active /
/// Boosted / Fulfilled sections) with search, sort and moderation actions.
class AdminPostsTimelineView extends StatefulWidget {
  const AdminPostsTimelineView({super.key, this.onBack});

  /// Back arrow in the header (returns to the dashboard).
  final VoidCallback? onBack;

  @override
  State<AdminPostsTimelineView> createState() => _AdminPostsTimelineViewState();
}

class _AdminPostsTimelineViewState extends State<AdminPostsTimelineView>
    with TabReselectListener {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  bool _searching = false;
  _Sort _sort = _Sort.newest;

  @override
  int get shellTabIndex => AdminShellTab.posts;

  @override
  TabReselectNotifier get reselectNotifier => AdminShellTab.reselected;

  @override
  void onTabReselected() => scrollToTop(_scroll);

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickSort() async {
    final picked = await adminPickOption<_Sort>(
      context,
      title: 'Sort posts',
      options: _Sort.values,
      selected: _sort,
      labelOf: (s) => switch (s) {
        _Sort.newest => 'Newest first',
        _Sort.oldest => 'Oldest first',
        _Sort.mostLiked => 'Most liked',
      },
    );
    if (picked != null) setState(() => _sort = picked);
  }

  List<PostModel> _prepare(List<PostModel> all) {
    final q = _search.text.trim().toLowerCase();
    final list = all.where((post) {
      if (q.isEmpty) return true;
      return post.title.toLowerCase().contains(q) ||
          post.description.toLowerCase().contains(q) ||
          post.authorName.toLowerCase().contains(q);
    }).toList();
    switch (_sort) {
      case _Sort.newest:
        break; // already newest first from the query
      case _Sort.oldest:
        list.sort((a, b) => (a.createdAt ?? DateTime(0))
            .compareTo(b.createdAt ?? DateTime(0)));
      case _Sort.mostLiked:
        list.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return AdminPage(
      title: 'Posts',
      leading: widget.onBack == null
          ? null
          : AdminBackButton(onPressed: widget.onBack),
      actions: [
        AdminHeaderIcon(
          tooltip: _searching ? 'Close search' : 'Search posts',
          icon: _searching ? Icons.close_rounded : Icons.search_rounded,
          onPressed: () => setState(() {
            _searching = !_searching;
            if (!_searching) _search.clear();
          }),
        ),
        Badge(
          isLabelVisible: _sort != _Sort.newest,
          smallSize: 8,
          backgroundColor: p.amber,
          offset: const Offset(-8, 8),
          child: AdminHeaderIcon(
            tooltip: 'Sort',
            icon: Icons.filter_list_rounded,
            onPressed: _pickSort,
          ),
        ),
        const SizedBox(width: 4),
      ],
      body: StreamBuilder<List<PostModel>>(
        stream: context.read<AdminService>().watchPosts(),
        builder: (context, snap) {
          if (snap.hasError) {
            return AdminEmpty(
              icon: Icons.error_outline_rounded,
              message: 'Could not load posts.\n${snap.error}',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return PostsBoard(
            scrollController: _scroll,
            posts: _prepare(snap.data!),
            emptyMessage: 'No posts found',
            header: _searching
                ? AdminSearchField(
                    controller: _search,
                    hint: 'Search title, description or author...',
                    onChanged: (_) => setState(() {}),
                  )
                : null,
            onView: _view,
            actionsFor: (post) => [
              const PostsBoardAction(
                id: 'view',
                icon: Icons.info_outline_rounded,
                label: 'View details',
              ),
              post.isInappropriate
                  ? const PostsBoardAction(
                      id: 'unflag',
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Mark appropriate',
                    )
                  : const PostsBoardAction(
                      id: 'flag',
                      icon: Icons.report_gmailerrorred_rounded,
                      label: 'Mark inappropriate',
                    ),
              const PostsBoardAction(
                id: 'delete',
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                danger: true,
              ),
            ],
            onAction: _onMenu,
          );
        },
      ),
    );
  }

  Future<void> _onMenu(PostModel post, String action) async {
    switch (action) {
      case 'view':
        _view(post);
      case 'flag':
        await _setFlagged(post, true);
      case 'unflag':
        await _setFlagged(post, false);
      case 'delete':
        await _delete(post);
    }
  }

  Future<void> _delete(PostModel post) async {
    final ok = await adminConfirm(
      context,
      title: 'Delete post',
      message: 'Permanently delete "${post.title}"?',
      confirm: 'Delete',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<AdminService>().deletePost(post.id);
      if (mounted) adminSnack(context, 'Post deleted.');
    } catch (e) {
      if (mounted) adminSnack(context, 'Failed to delete post: $e', error: true);
    }
  }

  Future<void> _setFlagged(PostModel post, bool flagged) async {
    String? reason;
    if (flagged) {
      reason = await adminAskReason(
        context,
        title: 'Mark inappropriate',
        confirm: 'Mark',
      );
      if (reason == null || !mounted) return;
    }
    try {
      await context.read<AdminService>().markPostInappropriate(
            post.id,
            inappropriate: flagged,
            reason: reason == null || reason.isEmpty ? null : reason,
          );
      if (mounted) {
        adminSnack(
          context,
          flagged ? 'Post marked inappropriate.' : 'Post marked appropriate.',
        );
      }
    } catch (e) {
      if (mounted) adminSnack(context, 'Failed to update post: $e', error: true);
    }
  }
}

/// Opens the admin details page (author, contracts / claims, both parties).
void _view(PostModel post) {
  navigatorKey.currentState?.push(
    MaterialPageRoute<void>(builder: (_) => AdminPostDetailView(post: post)),
  );
}
