import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../posts/models/post_model.dart';
import '../services/admin_service.dart';
import '../ui/admin_ui.dart';

enum _StatusFilter { all, active, flagged, fulfilled }

extension on _StatusFilter {
  String get label {
    switch (this) {
      case _StatusFilter.all:
        return 'All statuses';
      case _StatusFilter.active:
        return 'Active';
      case _StatusFilter.flagged:
        return 'Flagged as inappropriate';
      case _StatusFilter.fulfilled:
        return 'Fulfilled';
    }
  }

  bool matches(PostModel p) {
    switch (this) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.active:
        return !p.isFulfilled && !p.isInappropriate;
      case _StatusFilter.flagged:
        return p.isInappropriate;
      case _StatusFilter.fulfilled:
        return p.isFulfilled;
    }
  }
}

/// Admin posts timeline with type chips, search and status filter.
class AdminPostsTimelineView extends StatefulWidget {
  const AdminPostsTimelineView({super.key, this.onBack});

  /// Back arrow in the header (returns to the dashboard).
  final VoidCallback? onBack;

  @override
  State<AdminPostsTimelineView> createState() => _AdminPostsTimelineViewState();
}

class _AdminPostsTimelineViewState extends State<AdminPostsTimelineView> {
  PostModule? _module;
  _StatusFilter _status = _StatusFilter.all;
  bool _searching = false;
  final _search = TextEditingController();
  final Set<String> _busy = <String>{};

  /// Chips shown in the mockup order; Lend/Borrow follow.
  static const _modules = <PostModule?>[
    null,
    PostModule.lost,
    PostModule.found,
    PostModule.charity,
    PostModule.resources,
    PostModule.lend,
    PostModule.borrow,
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickStatus() async {
    final picked = await adminPickOption<_StatusFilter>(
      context,
      title: 'Filter posts',
      options: _StatusFilter.values,
      selected: _status,
      labelOf: (s) => s.label,
    );
    if (picked != null) setState(() => _status = picked);
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
          isLabelVisible: _status != _StatusFilter.all,
          smallSize: 8,
          backgroundColor: p.amber,
          offset: const Offset(-8, 8),
          child: AdminHeaderIcon(
            tooltip: 'Filter',
            icon: Icons.filter_list_rounded,
            onPressed: _pickStatus,
          ),
        ),
        const SizedBox(width: 4),
      ],
      body: Column(
        children: [
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AdminSearchField(
                controller: _search,
                hint: 'Search title, description or author...',
                onChanged: (_) => setState(() {}),
              ),
            ),
          AdminChipBar<PostModule?>(
            options: _modules,
            selected: _module,
            labelOf: (m) => m?.label ?? 'All',
            onSelected: (m) => setState(() => _module = m),
          ),
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: context.read<AdminService>().watchPosts(module: _module),
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
                final q = _search.text.trim().toLowerCase();
                final posts = snap.data!.where((post) {
                  if (!_status.matches(post)) return false;
                  if (q.isEmpty) return true;
                  return post.title.toLowerCase().contains(q) ||
                      post.description.toLowerCase().contains(q) ||
                      post.authorName.toLowerCase().contains(q);
                }).toList();
                if (posts.isEmpty) {
                  return const AdminEmpty(
                    icon: Icons.feed_outlined,
                    message: 'No posts found',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _AdminPostCard(
                    key: ValueKey(posts[i].id),
                    post: posts[i],
                    busy: _busy.contains(posts[i].id),
                    onMenu: (action) => _onMenu(posts[i], action),
                  ),
                );
              },
            ),
          ),
        ],
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
    setState(() => _busy.add(post.id));
    try {
      await context.read<AdminService>().deletePost(post.id);
      if (mounted) adminSnack(context, 'Post deleted.');
    } catch (e) {
      if (mounted) adminSnack(context, 'Failed to delete post: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(post.id));
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
    setState(() => _busy.add(post.id));
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
    } finally {
      if (mounted) setState(() => _busy.remove(post.id));
    }
  }
}

void _view(PostModel post) {
  navigatorKey.currentState?.pushNamed(
    AppConstants.routePostDetail,
    arguments: post,
  );
}

/// Module badge colours from the mockup (Found green, Lost red...).
AdminPill _modulePill(BuildContext context, PostModule m) {
  switch (m) {
    case PostModule.lost:
      return AdminPill.red(context, m.label);
    case PostModule.found:
      return AdminPill.green(context, m.label);
    case PostModule.charity:
      return AdminPill.blue(context, m.label);
    case PostModule.resources:
      return AdminPill.amber(context, m.label);
    case PostModule.lend:
    case PostModule.borrow:
      return AdminPill.green(context, m.label);
  }
}

IconData _moduleIcon(PostModule m) {
  switch (m) {
    case PostModule.lost:
      return Icons.search_off_rounded;
    case PostModule.found:
      return Icons.travel_explore_rounded;
    case PostModule.charity:
      return Icons.volunteer_activism_rounded;
    case PostModule.resources:
      return Icons.inventory_2_rounded;
    case PostModule.lend:
    case PostModule.borrow:
      return Icons.handshake_rounded;
  }
}

class _AdminPostCard extends StatelessWidget {
  const _AdminPostCard({
    super.key,
    required this.post,
    required this.busy,
    required this.onMenu,
  });

  final PostModel post;
  final bool busy;
  final ValueChanged<String> onMenu;

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${post.title}\n\n${post.description}\n\n'
            '${AppConstants.sharePostUrl(post.id)}',
        subject: post.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final image = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final by = [
      'By ${post.authorName.isEmpty ? 'Unknown' : post.authorName}',
      if (post.createdAt != null) adminTimeAgo(post.createdAt),
    ].join(' • ');

    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: p.cardDecoration(),
            child: InkWell(
              onTap: () => _view(post),
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: SizedBox(
                      height: 150,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (image != null)
                            Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _ImagePlaceholder(module: post.module),
                            )
                          else
                            _ImagePlaceholder(module: post.module),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Wrap(
                              spacing: 6,
                              children: [
                                _modulePill(context, post.module),
                                if (post.isInappropriate)
                                  AdminPill.red(context, 'Inappropriate'),
                                if (post.isFulfilled)
                                  AdminPill.blue(context, 'Fulfilled'),
                                if (post.isSponsored)
                                  AdminPill.amber(context, 'Sponsored'),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: AdminMoreButton<String>(
                              onImage: true,
                              tooltip: 'Manage post',
                              onSelected: onMenu,
                              itemBuilder: (_) => [
                                adminMenuItem(
                                  'view',
                                  Icons.visibility_outlined,
                                  'View',
                                ),
                                post.isInappropriate
                                    ? adminMenuItem(
                                        'unflag',
                                        Icons.check_circle_outline_rounded,
                                        'Mark appropriate',
                                      )
                                    : adminMenuItem(
                                        'flag',
                                        Icons.report_gmailerrorred_rounded,
                                        'Mark inappropriate',
                                      ),
                                const PopupMenuDivider(),
                                adminMenuItem(
                                  'delete',
                                  Icons.delete_outline_rounded,
                                  'Delete',
                                  danger: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminText.title(p, size: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminText.body(p, size: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          by,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminText.body(p, size: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _Count(
                              icon: Icons.favorite_border_rounded,
                              value: post.likeCount,
                            ),
                            const SizedBox(width: 18),
                            _Count(
                              icon: Icons.chat_bubble_outline_rounded,
                              value: post.commentCount,
                            ),
                            const SizedBox(width: 14),
                            InkResponse(
                              onTap: _share,
                              radius: 20,
                              child: Icon(
                                Icons.share_outlined,
                                size: 20,
                                color: p.text,
                              ),
                            ),
                            const Spacer(),
                            AdminButton(
                              label: 'View',
                              compact: true,
                              onPressed: () => _view(post),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (busy)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.page.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.module});

  final PostModule module;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return ColoredBox(
      color: p.softGreen,
      child: Center(
        child: Icon(_moduleIcon(module), size: 48, color: p.softGreenText),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: p.text),
        const SizedBox(width: 5),
        Text('$value', style: AdminText.title(p, size: 13)),
      ],
    );
  }
}
