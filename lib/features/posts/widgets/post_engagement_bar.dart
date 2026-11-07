import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/network_status.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import 'post_comments_section.dart';

class PostEngagementBar extends StatefulWidget {
  const PostEngagementBar({
    super.key,
    required this.post,
    this.showInsights = false,
    this.onInsights,
  });

  final PostModel post;
  final bool showInsights;
  final VoidCallback? onInsights;

  @override
  State<PostEngagementBar> createState() => _PostEngagementBarState();
}

class _PostEngagementBarState extends State<PostEngagementBar> {
  bool? _liked;
  int? _count;
  int _extraComments = 0;
  int? _seenCommentCount;
  bool _savingLike = false;

  Future<void> _like(int serverCount, bool serverLiked) async {
    if (_savingLike) return;
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;
    if (!await NetworkStatus.isOnline) {
      _toast(NetworkStatus.offlineMessage);
      return;
    }
    if (!mounted) return;

    final shownLiked = _liked ?? serverLiked;
    final shownCount = _count ?? serverCount;
    final next = !shownLiked;
    setState(() {
      _savingLike = true;
      _liked = next;
      _count = (shownCount + (next ? 1 : -1)).clamp(0, 1 << 30);
    });

    try {
      await context.read<PostService>().toggleLike(
            postId: widget.post.id,
            uid: uid,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = shownLiked;
        _count = shownCount;
      });
      _toast(
        NetworkStatus.isOfflineError(e)
            ? NetworkStatus.offlineMessage
            : '$e'.replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _savingLike = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _share() async {
    final link = AppConstants.sharePostUrl(widget.post.id);
    await SharePlus.instance.share(
      ShareParams(
        text: '${widget.post.title}\n\n${widget.post.description}\n\n$link',
        subject: widget.post.title,
      ),
    );
  }

  void _comments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (_, scroll) => ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                PostCommentsSection(
                  postId: widget.post.id,
                  onOptimisticAdd: () {
                    if (mounted) setState(() => _extraComments++);
                  },
                  onOptimisticRevert: () {
                    if (!mounted) return;
                    setState(() {
                      if (_extraComments > 0) _extraComments--;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = context.watch<AuthController>().user?.uid;
    final muted = theme.colorScheme.onSurfaceVariant;

    return StreamBuilder<PostModel?>(
      stream: context.read<PostService>().watchPost(widget.post.id),
      builder: (context, snap) {
        final live = snap.data ?? widget.post;
        return StreamBuilder<bool>(
          stream: uid == null
              ? const Stream<bool>.empty()
              : context.read<PostService>().watchLiked(
                    postId: widget.post.id,
                    uid: uid,
                  ),
          builder: (context, likedSnap) {
            final serverLiked = likedSnap.data ?? false;
            final caughtUp = _liked != null &&
                likedSnap.hasData &&
                likedSnap.data == _liked &&
                live.likeCount == _count;
            if (caughtUp) {
              _liked = null;
              _count = null;
            }
            if (_seenCommentCount != null &&
                live.commentCount > _seenCommentCount! &&
                _extraComments > 0) {
              final gained = live.commentCount - _seenCommentCount!;
              _extraComments = (_extraComments - gained).clamp(0, 1 << 20);
            }
            _seenCommentCount = live.commentCount;
            final liked = caughtUp ? serverLiked : (_liked ?? serverLiked);
            final count = caughtUp ? live.likeCount : (_count ?? live.likeCount);
            final commentCount = live.commentCount + _extraComments;
            final likeColor = liked ? theme.colorScheme.primary : muted;
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Row(
                children: [
                  _Action(
                    icon: liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '$count',
                    color: likeColor,
                    onTap: () => _like(live.likeCount, serverLiked),
                  ),
                  _Action(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '$commentCount',
                    color: muted,
                    onTap: () => _comments(context),
                  ),
                  _Action(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: muted,
                    onTap: _share,
                  ),
                  if (widget.showInsights) ...[
                    const Spacer(),
                    IconButton(
                      tooltip: 'Ad insights',
                      onPressed: widget.onInsights,
                      icon: Icon(
                        Icons.insights_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Records one unique view when a sponsored post is shown to someone else.
class SponsoredImpression extends StatefulWidget {
  const SponsoredImpression({super.key, required this.post});

  final PostModel post;

  @override
  State<SponsoredImpression> createState() => _SponsoredImpressionState();
}

class _SponsoredImpressionState extends State<SponsoredImpression> {
  static final _recorded = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  Future<void> _record() async {
    final post = widget.post;
    if (!post.isSponsored || !mounted) return;
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null || uid == post.authorId) return;
    if (!_recorded.add('${post.id}:$uid')) return;
    try {
      await context.read<PostService>().recordUniqueView(
            postId: post.id,
            uid: uid,
          );
    } catch (_) {
      _recorded.remove('${post.id}:$uid');
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
