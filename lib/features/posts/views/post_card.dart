import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/network_status.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../ads/widgets/ad_style.dart';
import '../../ads/widgets/boost_post_sheet.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/post_comments_section.dart';
import '../widgets/post_engagement_bar.dart';

/// Feed card: photo with type pill and like heart, then title, location,
/// time, author, comments and share.
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.distanceLabel,
  });

  final PostModel post;
  final VoidCallback? onTap;
  final String? distanceLabel;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  static const _radius = 22.0;
  static const _imageHeight = 180.0;

  /// Optimistic like state until the server catches up.
  bool? _liked;
  bool _savingLike = false;
  int _extraComments = 0;
  int? _seenCommentCount;

  PostModel get post => widget.post;

  Future<void> _toggleLike(bool serverLiked) async {
    if (_savingLike) return;
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;
    if (!await NetworkStatus.isOnline) {
      _toast(NetworkStatus.offlineMessage);
      return;
    }
    if (!mounted) return;
    final shown = _liked ?? serverLiked;
    setState(() {
      _savingLike = true;
      _liked = !shown;
    });
    try {
      await context
          .read<PostService>()
          .toggleLike(postId: post.id, uid: uid);
    } catch (e) {
      if (!mounted) return;
      setState(() => _liked = shown);
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
    await SharePlus.instance.share(
      ShareParams(
        text: '${post.title}\n\n${post.description}\n\n'
            '${AppConstants.sharePostUrl(post.id)}',
        subject: post.title,
      ),
    );
  }

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
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
                postId: post.id,
                onOptimisticAdd: () {
                  if (mounted) setState(() => _extraComments++);
                },
                onOptimisticRevert: () {
                  if (mounted && _extraComments > 0) {
                    setState(() => _extraComments--);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppTheme.colors(context);
    final uid = context.watch<AuthController>().user?.uid;
    final mine = uid != null && uid == post.authorId;
    final sponsored = post.isSponsored;

    // Server count caught up with our optimistic comment: drop the extra.
    if (_seenCommentCount != post.commentCount) {
      _seenCommentCount = post.commentCount;
      _extraComments = 0;
    }
    final comments = post.commentCount + _extraComments;

    final location = [
      if (post.location?.trim().isNotEmpty == true) post.location!.trim(),
      if (widget.distanceLabel != null) widget.distanceLabel!,
    ].join(' · ');

    return Material(
      color: sponsored ? AdStyle.background(context) : c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(
          color: sponsored
              ? AdStyle.border(context)
              : theme.colorScheme.outlineVariant,
          width: sponsored ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sponsored) SponsoredImpression(post: post),
            _Photo(
              post: post,
              height: _imageHeight,
              heart: uid == null
                  ? null
                  : StreamBuilder<bool>(
                      stream: context
                          .read<PostService>()
                          .watchLiked(postId: post.id, uid: uid),
                      builder: (context, snap) {
                        final serverLiked = snap.data ?? false;
                        final liked = _liked ?? serverLiked;
                        // Server agrees with the optimistic value.
                        if (_liked != null &&
                            snap.hasData &&
                            _liked == serverLiked &&
                            !_savingLike) {
                          _liked = null;
                        }
                        return _Heart(
                          liked: liked,
                          onTap: () => _toggleLike(serverLiked),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: c.inkMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location.isEmpty ? 'Location not set' : location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: c.inkMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: c.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      UserAvatar(
                        userId: post.authorId,
                        name: post.authorName,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          post.authorName.isEmpty
                              ? 'Community member'
                              : post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (mine && post.hasAdHistory)
                        _IconAction(
                          icon: Icons.insights_rounded,
                          tooltip: 'Ad insights',
                          onTap: () => showPostInsights(context, post),
                        ),
                      _IconAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        tooltip: 'Comments',
                        label: '$comments',
                        onTap: _openComments,
                      ),
                      _IconAction(
                        icon: Icons.share_outlined,
                        tooltip: 'Share',
                        onTap: _share,
                      ),
                    ],
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

/// Photo with the type pill (and Sponsored label) on the left and the like
/// heart on the right.
class _Photo extends StatelessWidget {
  const _Photo({required this.post, required this.height, this.heart});

  final PostModel post;
  final double height;
  final Widget? heart;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final image = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final placeholder = ColoredBox(
      color: c.sage,
      child: Icon(Icons.image_outlined, size: 48, color: c.olive),
    );

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          else
            placeholder,
          Positioned(
            left: 14,
            top: 14,
            right: 64,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (!post.isStandaloneAd) _TypePill(label: post.module.label),
                if (post.isSponsored) const SponsoredLabel(),
              ],
            ),
          ),
          if (heart != null) Positioned(right: 10, top: 8, child: heart!),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        // Swapped: dark green pill with light green text.
        color: dark ? const Color(0xFF8FE0AE) : const Color(0xFF1E5E33),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: dark ? const Color(0xFF173B25) : const Color(0xFFE3F1E3),
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _Heart extends StatelessWidget {
  const _Heart({required this.liked, required this.onTap});

  final bool liked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: liked ? 'Unlike' : 'Like',
      onPressed: onTap,
      icon: Icon(
        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 32,
        color: liked ? const Color(0xFFE5484D) : Colors.white,
        shadows: const [
          Shadow(color: Color(0x66000000), blurRadius: 6),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.colors(context).ink;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
