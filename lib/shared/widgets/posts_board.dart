import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../features/posts/models/post_model.dart';

/// Status filter chips at the top of the board.
enum PostsBoardStatus { all, active, boosted, fulfilled }

/// Which section a post belongs to.
enum _Group { active, boosted, fulfilled }

_Group _groupOf(PostModel p) {
  if (p.isFulfilled) return _Group.fulfilled;
  if (p.isSponsored || p.isSponsorPaused) return _Group.boosted;
  return _Group.active;
}

/// One entry in a post's ⋮ menu.
class PostsBoardAction {
  const PostsBoardAction({
    required this.id,
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final String id;
  final IconData icon;
  final String label;
  final bool danger;
}

/// Shared "My Posts" / admin "Posts" layout: status chips, category chips,
/// then Active, Boosted and Fulfilled sections of compact post cards.
class PostsBoard extends StatefulWidget {
  const PostsBoard({
    super.key,
    required this.posts,
    required this.onView,
    required this.actionsFor,
    required this.onAction,
    this.header,
    this.emptyMessage = 'No posts yet',
    this.emptyAction,
    this.scrollController,
    this.footer,
  });

  final List<PostModel> posts;
  final ValueChanged<PostModel> onView;

  /// Menu entries for a post (empty list hides the ⋮ button).
  final List<PostsBoardAction> Function(PostModel) actionsFor;
  final void Function(PostModel post, String actionId) onAction;

  /// Shown above the chips (e.g. an admin search field).
  final Widget? header;
  final String emptyMessage;
  final Widget? emptyAction;
  final ScrollController? scrollController;

  /// Shown after the sections (e.g. completed exchanges).
  final Widget? footer;

  @override
  State<PostsBoard> createState() => _PostsBoardState();
}

class _PostsBoardState extends State<PostsBoard> {
  PostsBoardStatus _status = PostsBoardStatus.all;
  PostModule? _module;

  static const _modules = <PostModule>[
    PostModule.lost,
    PostModule.found,
    PostModule.lend,
    PostModule.borrow,
    PostModule.resources,
    PostModule.charity,
  ];

  @override
  Widget build(BuildContext context) {
    final b = _BoardColors.of(context);
    final filtered = widget.posts
        .where((p) => _module == null || p.module == _module)
        .toList();
    final groups = <_Group, List<PostModel>>{
      for (final g in _Group.values)
        g: filtered.where((p) => _groupOf(p) == g).toList(),
    };
    final visible = switch (_status) {
      PostsBoardStatus.all => _Group.values,
      PostsBoardStatus.active => const [_Group.active],
      PostsBoardStatus.boosted => const [_Group.boosted],
      PostsBoardStatus.fulfilled => const [_Group.fulfilled],
    };
    final shownCount = visible.fold<int>(0, (n, g) => n + groups[g]!.length);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: 12),
        ],
        // Status chips (one row, equal widths).
        Row(
          children: [
            for (final s in PostsBoardStatus.values) ...[
              if (s != PostsBoardStatus.all) const SizedBox(width: 8),
              Expanded(
                flex: s == PostsBoardStatus.boosted ? 13 : 10,
                child: _Chip(
                  label: switch (s) {
                    PostsBoardStatus.all => 'All',
                    PostsBoardStatus.active => 'Active',
                    PostsBoardStatus.boosted => 'Boosted',
                    PostsBoardStatus.fulfilled => 'Fulfilled',
                  },
                  icon: s == PostsBoardStatus.boosted
                      ? Icons.rocket_launch_rounded
                      : null,
                  iconColor: b.rocket,
                  selected: _status == s,
                  height: 48,
                  dense: true,
                  onTap: () => setState(() => _status = s),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Filter by Category',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: b.muted,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Chip(
              label: 'All',
              selected: _module == null,
              onTap: () => setState(() => _module = null),
            ),
            for (final m in _modules)
              _Chip(
                label: m.label,
                selected: _module == m,
                onTap: () => setState(() => _module = m),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (shownCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 52, color: b.muted),
                const SizedBox(height: 10),
                Text(
                  widget.posts.isEmpty ? widget.emptyMessage : 'No posts here',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: b.muted,
                      ),
                ),
                if (widget.posts.isEmpty && widget.emptyAction != null) ...[
                  const SizedBox(height: 14),
                  widget.emptyAction!,
                ],
              ],
            ),
          )
        else
          for (final g in visible)
            if (groups[g]!.isNotEmpty) ...[
              _SectionHeader(group: g, count: groups[g]!.length),
              const SizedBox(height: 10),
              for (final p in groups[g]!) ...[
                _BoardCard(
                  post: p,
                  group: g,
                  actions: widget.actionsFor(p),
                  onView: () => widget.onView(p),
                  onAction: (id) => widget.onAction(p, id),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 6),
            ],
        if (widget.footer != null) widget.footer!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Colours (from the mockup, with dark variants)
// ---------------------------------------------------------------------------

class _BoardColors {
  const _BoardColors({
    required this.green,
    required this.chipBg,
    required this.chipBorder,
    required this.chipText,
    required this.text,
    required this.muted,
    required this.card,
    required this.cardBorder,
    required this.activeBg,
    required this.activeFg,
    required this.blueBg,
    required this.blueFg,
    required this.boostPillBg,
    required this.boostPillFg,
    required this.rocket,
    required this.flagBg,
    required this.flagFg,
  });

  final Color green;
  final Color chipBg;
  final Color chipBorder;
  final Color chipText;
  final Color text;
  final Color muted;
  final Color card;
  final Color cardBorder;
  final Color activeBg;
  final Color activeFg;
  final Color blueBg;
  final Color blueFg;
  final Color boostPillBg;
  final Color boostPillFg;
  final Color rocket;
  final Color flagBg;
  final Color flagFg;

  static _BoardColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  static const _light = _BoardColors(
    green: Color(0xFF15803D),
    chipBg: Color(0xFFF0F1EF),
    chipBorder: Color(0xFFE2E4E0),
    chipText: Color(0xFF2B2F2C),
    text: Color(0xFF15181A),
    muted: Color(0xFF4B5563),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE8EAE6),
    activeBg: Color(0xFFDDF3E3),
    activeFg: Color(0xFF15803D),
    blueBg: Color(0xFFDDE8FB),
    blueFg: Color(0xFF1D4ED8),
    boostPillBg: Color(0xFFEDE4FB),
    boostPillFg: Color(0xFF4C1D95),
    rocket: Color(0xFF7C3AED),
    flagBg: Color(0xFFFDE2E2),
    flagFg: Color(0xFFC53030),
  );

  static const _dark = _BoardColors(
    green: Color(0xFF22A355),
    chipBg: Color(0xFF1C2738),
    chipBorder: Color(0xFF2E3A4D),
    chipText: Color(0xFFE8E4DC),
    text: Color(0xFFF1F3F5),
    muted: Color(0xFFB4BCC8),
    card: Color(0xFF1C2738),
    cardBorder: Color(0xFF2E3A4D),
    activeBg: Color(0xFF173B25),
    activeFg: Color(0xFF5FD38A),
    blueBg: Color(0xFF14294A),
    blueFg: Color(0xFF8AB4FF),
    boostPillBg: Color(0xFF2E1F4D),
    boostPillFg: Color(0xFFC4B5FD),
    rocket: Color(0xFFA78BFA),
    flagBg: Color(0xFF3A1818),
    flagFg: Color(0xFFF87171),
  );
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.height = 44,
    this.dense = false,
  });

  /// Tight padding and shrink-to-fit text, for the equal-width status row.
  final bool dense;

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final b = _BoardColors.of(context);
    return Material(
      color: selected ? b.green : b.chipBg,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? b.green : b.chipBorder),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 18),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: selected ? Colors.white : iconColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected ? Colors.white : b.chipText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.group, required this.count});

  final _Group group;
  final int count;

  @override
  Widget build(BuildContext context) {
    final b = _BoardColors.of(context);
    final (title, bg, fg, leading) = switch (group) {
      _Group.active => (
          'Active Posts',
          b.activeBg,
          b.text,
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: b.green, shape: BoxShape.circle),
          ) as Widget,
        ),
      _Group.boosted => (
          'Boosted Posts',
          b.blueBg,
          b.blueFg,
          Icon(Icons.rocket_launch_rounded, color: b.rocket, size: 24) as Widget,
        ),
      _Group.fulfilled => (
          'Fulfilled Posts',
          b.blueBg,
          b.blueFg,
          Icon(Icons.check_circle_rounded, color: b.blueFg, size: 24) as Widget,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            '$count ${count == 1 ? 'Post' : 'Posts'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: b.muted,
                ),
          ),
        ],
      ),
    );
  }
}

String _ago(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) {
    return '${d.inMinutes} ${d.inMinutes == 1 ? 'minute' : 'minutes'} ago';
  }
  if (d.inHours < 24) {
    return '${d.inHours} ${d.inHours == 1 ? 'hour' : 'hours'} ago';
  }
  if (d.inDays < 30) {
    return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'} ago';
  }
  return '${t.day}/${t.month}/${t.year}';
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.post,
    required this.group,
    required this.actions,
    required this.onView,
    required this.onAction,
  });

  final PostModel post;
  final _Group group;
  final List<PostsBoardAction> actions;
  final VoidCallback onView;
  final ValueChanged<String> onAction;

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
    final b = _BoardColors.of(context);
    final theme = Theme.of(context);
    final image = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final placeholder = ColoredBox(
      color: b.activeBg,
      child: Icon(Icons.image_outlined, color: b.activeFg, size: 36),
    );

    final Widget pill = post.isInappropriate
        ? _Pill(
            bg: b.flagBg,
            fg: b.flagFg,
            label: 'Flagged',
            leading: Icon(Icons.report_rounded, size: 16, color: b.flagFg),
          )
        : switch (group) {
            _Group.active => _Pill(
                bg: b.activeBg,
                fg: b.activeFg,
                label: 'Active',
                leading: Container(
                  width: 11,
                  height: 11,
                  decoration:
                      BoxDecoration(color: b.activeFg, shape: BoxShape.circle),
                ),
              ),
            _Group.boosted => _Pill(
                bg: b.boostPillBg,
                fg: b.boostPillFg,
                label: post.isSponsorPaused ? 'Boost paused' : 'Boosted',
                leading: Icon(
                  Icons.rocket_launch_rounded,
                  size: 16,
                  color: b.rocket,
                ),
              ),
            _Group.fulfilled => _Pill(
                bg: b.blueBg,
                fg: b.blueFg,
                label: 'Fulfilled',
                leading:
                    Icon(Icons.check_circle_rounded, size: 16, color: b.blueFg),
              ),
          };

    final dateLabel = group == _Group.fulfilled
        ? 'Completed: ${_ago(post.fulfilledAt ?? post.updatedAt ?? post.createdAt)}'
        : 'Posted: ${_ago(post.createdAt)}';

    final viewButton = group == _Group.active
        ? FilledButton(
            onPressed: onView,
            style: FilledButton.styleFrom(
              backgroundColor: b.green,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              minimumSize: const Size(112, 44),
            ),
            child: const Text('View'),
          )
        : OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              foregroundColor: b.green,
              side: BorderSide(color: b.green, width: 1.4),
              shape: const StadiumBorder(),
              minimumSize: const Size(112, 44),
            ),
            child: Text(group == _Group.fulfilled ? 'View Details' : 'View'),
          );

    Widget meta(IconData icon, String label, String value) => Row(
          children: [
            Icon(icon, size: 18, color: b.text),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: label,
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: b.text,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: b.muted),
              ),
            ),
          ],
        );

    return Material(
      color: b.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: b.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 150,
                      height: 118,
                      child: image == null
                          ? placeholder
                          : Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => placeholder,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: b.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        pill,
                        const SizedBox(height: 8),
                        meta(Icons.sell_outlined, 'Category: ',
                            post.module.label),
                        const SizedBox(height: 6),
                        meta(Icons.calendar_today_outlined, '', dateLabel),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      icon: Icon(Icons.more_vert_rounded, color: b.text),
                      onSelected: onAction,
                      itemBuilder: (_) => [
                        for (final a in actions)
                          PopupMenuItem<String>(
                            value: a.id,
                            child: Row(
                              children: [
                                Icon(
                                  a.icon,
                                  size: 20,
                                  color: a.danger ? theme.colorScheme.error : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  a.label,
                                  style: TextStyle(
                                    color:
                                        a.danger ? theme.colorScheme.error : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Count(icon: Icons.favorite_border_rounded, value: post.likeCount),
                  const SizedBox(width: 22),
                  _Count(
                    icon: Icons.chat_bubble_outline_rounded,
                    value: post.commentCount,
                  ),
                  const SizedBox(width: 18),
                  IconButton(
                    tooltip: 'Share',
                    visualDensity: VisualDensity.compact,
                    onPressed: _share,
                    icon: Icon(Icons.share_outlined, color: b.text),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: viewButton,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.bg,
    required this.fg,
    required this.label,
    required this.leading,
  });

  final Color bg;
  final Color fg;
  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
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
    final b = _BoardColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: b.text),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: b.text),
        ),
      ],
    );
  }
}
