import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../ads/widgets/ad_style.dart';
import '../../ads/widgets/boost_post_sheet.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../lend_borrow/models/contract_status.dart';
import '../../lend_borrow/models/lend_borrow_contract.dart';
import '../../lend_borrow/services/lend_borrow_contract_service.dart';
import '../../lost_found/models/claim_status.dart';
import '../../lost_found/models/lost_found_claim.dart';
import '../../lost_found/services/lost_found_claim_service.dart';
import '../../mutual_confidence/models/contact_request_status.dart';
import '../../mutual_confidence/models/public_trust_profile.dart';
import '../../mutual_confidence/services/contact_request_service.dart';
import '../../mutual_confidence/services/trust_profile_service.dart';
import '../../mutual_confidence/widgets/trust_card_widget.dart';
import '../models/post_comment.dart';
import '../models/post_model.dart';
import '../services/comment_service.dart';
import '../services/post_service.dart';
import '../widgets/post_comments_section.dart';
import '../widgets/post_engagement_bar.dart';
import '../widgets/post_image_gallery.dart';
import 'package:civic_citizen/shared/widgets/wave_header.dart';

/// Post details: role banner, item summary, the other person, contact
/// request, the user's next step (agreement / claim) and comments.
class PostDetailView extends StatelessWidget {
  const PostDetailView({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PostModel?>(
      stream: context.read<PostService>().watchPost(post.id),
      builder: (context, snap) => _PostDetailBody(post: snap.data ?? post),
    );
  }
}

// ---------------------------------------------------------------------------
// Who the viewer is in this post's exchange
// ---------------------------------------------------------------------------

enum _Role { lender, borrower, finder, owner }

/// The viewer's side of the active agreement / claim, if any.
class _Deal {
  const _Deal({
    this.role,
    this.otherId,
    this.otherName,
    this.otherRole,
    this.contract,
    this.claim,
  });

  final _Role? role;
  final String? otherId;
  final String? otherName;
  final _Role? otherRole;
  final LendBorrowContract? contract;
  final LostFoundClaim? claim;

  static String roleName(_Role r) => switch (r) {
        _Role.lender => 'Lender',
        _Role.borrower => 'Borrower',
        _Role.finder => 'Finder',
        _Role.owner => 'Owner',
      };

  /// Role from the post alone, before any agreement exists (post authors).
  static _Role? authorRole(PostModule m) => switch (m) {
        PostModule.lend => _Role.lender,
        PostModule.borrow => _Role.borrower,
        PostModule.found => _Role.finder,
        PostModule.lost => _Role.owner,
        _ => null,
      };

  factory _Deal.fromContract(LendBorrowContract c, String uid) {
    final lender = c.lenderId == uid;
    return _Deal(
      role: lender ? _Role.lender : _Role.borrower,
      otherId: lender ? c.borrowerId : c.lenderId,
      otherName: lender ? c.borrowerName : c.lenderName,
      otherRole: lender ? _Role.borrower : _Role.lender,
      contract: c,
    );
  }

  factory _Deal.fromClaim(LostFoundClaim c, String uid) {
    final finder = c.finderId == uid;
    return _Deal(
      role: finder ? _Role.finder : _Role.owner,
      otherId: finder ? c.ownerId : c.finderId,
      otherName: finder ? c.ownerName : c.finderName,
      otherRole: finder ? _Role.owner : _Role.finder,
      claim: c,
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  const _PostDetailBody({required this.post});

  final PostModel post;

  bool get _isExchange =>
      post.module == PostModule.lend || post.module == PostModule.borrow;
  bool get _isRecovery =>
      post.module == PostModule.lost || post.module == PostModule.found;

  Future<void> _share() async {
    final link = AppConstants.sharePostUrl(post.id);
    await SharePlus.instance.share(
      ShareParams(
        text: '${post.title}\n\n${post.description}\n\n$link',
        subject: post.title,
      ),
    );
  }

  Stream<_Deal> _deal(BuildContext context, String uid) {
    if (_isExchange) {
      return context
          .read<LendBorrowContractService>()
          .watchActiveContractForPost(postId: post.id, userId: uid)
          .map((c) => c == null ? const _Deal() : _Deal.fromContract(c, uid));
    }
    if (_isRecovery) {
      return context
          .read<LostFoundClaimService>()
          .watchActiveClaimForPost(postId: post.id, userId: uid)
          .map((c) => c == null ? const _Deal() : _Deal.fromClaim(c, uid));
    }
    return Stream.value(const _Deal());
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthController>().user?.uid;
    final mine = uid != null && uid == post.authorId;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const WaveHeaderBackground(),
        bottom: const WaveHeaderSpacer(),
        centerTitle: true,
        title: const Text('Post Details'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: _share,
          ),
        ],
      ),
      body: StreamBuilder<_Deal>(
        stream: uid == null ? Stream.value(const _Deal()) : _deal(context, uid),
        builder: (context, snap) {
          final deal = snap.data ?? const _Deal();
          final role = deal.role ?? (mine ? _Deal.authorRole(post.module) : null);
          // The person card shows the other side of the deal, or the author.
          final personId = deal.otherId ?? post.authorId;
          final personName = deal.otherName ?? post.authorName;
          final personRole = deal.otherRole;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              4,
              AppTheme.pagePadding,
              28,
            ),
            children: [
              if (post.isSponsored) SponsoredImpression(post: post),
              if (role != null) ...[
                _RoleBanner(role: role),
                const SizedBox(height: AppTheme.cardGap),
              ],
              _SummaryCard(post: post),
              const SizedBox(height: AppTheme.cardGap),
              if (!(mine && deal.otherId == null)) ...[
                _PersonCard(
                  userId: personId,
                  name: personName,
                  role: personRole,
                ),
                const SizedBox(height: AppTheme.cardGap),
              ],
              _ContactCard(post: post),
              const SizedBox(height: AppTheme.cardGap),
              if (_isExchange || _isRecovery) ...[
                _NextStepCard(post: post, deal: deal, mine: mine),
                const SizedBox(height: AppTheme.cardGap),
              ],
              _AboutCard(post: post, mine: mine),
              const SizedBox(height: AppTheme.cardGap),
              _CommentsCard(postId: post.id),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

String _timeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${t.day}/${t.month}/${t.year}';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Soft tinted colours used by the banners and step card.
class _Tints {
  const _Tints(this.bg, this.fg, [this.border]);

  final Color bg;
  final Color fg;
  final Color? border;

  static _Tints blue(bool dark) => dark
      ? const _Tints(Color(0xFF14294A), Color(0xFF8AB4FF))
      : const _Tints(Color(0xFFCDE5FF), Color(0xFF12358F));

  static _Tints green(bool dark) => dark
      ? const _Tints(Color(0xFF173B25), Color(0xFF5FD38A))
      : const _Tints(Color(0xFFD6F3E1), Color(0xFF0E5C2F));

  static _Tints amber(bool dark) => dark
      ? const _Tints(Color(0xFF2E2716), Color(0xFFF2C96B), Color(0xFF4A3D1C))
      : const _Tints(Color(0xFFFEEFCE), Color(0xFF8A5D0B), Color(0xFFF8E2A8));

  static _Tints waiting(bool dark) => dark
      ? const _Tints(Color(0xFF1F2A3A), Color(0xFFC7CFDC))
      : const _Tints(Color(0xFFDFE1ED), Color(0xFF111827));
}

class _CardBox extends StatelessWidget {
  const _CardBox({
    required this.child,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppTheme.cardRadius);
    return Material(
      color: color ?? scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Round tinted icon used at the start of the contact and step cards.
class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.bg,
    required this.fg,
    this.size = 52,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: size * 0.5),
      );
}

// ---------------------------------------------------------------------------
// Role banner
// ---------------------------------------------------------------------------

class _RoleBanner extends StatelessWidget {
  const _RoleBanner({required this.role});

  final _Role role;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (label, icon, tint) = switch (role) {
      _Role.borrower => (
          'You are borrowing this item',
          Icons.person_rounded,
          _Tints.blue(dark),
        ),
      _Role.lender => (
          'You are lending this item',
          Icons.verified_user_rounded,
          _Tints.green(dark),
        ),
      _Role.finder => (
          'You found this item',
          Icons.verified_user_rounded,
          _Tints.green(dark),
        ),
      _Role.owner => (
          'You are claiming this item',
          Icons.person_rounded,
          _Tints.blue(dark),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tint.bg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: dark
                ? tint.fg
                : (tint.bg == _Tints.blue(false).bg
                    ? const Color(0xFF1D4FB8)
                    : const Color(0xFF17883F)),
            size: 26,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tint.fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item summary
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppTheme.colors(context);
    final images = post.imageUrls;
    final dark = theme.brightness == Brightness.dark;

    final Widget statusPill;
    if (post.isInappropriate) {
      statusPill = _StatusPill(
        label: 'Flagged',
        icon: Icons.report_rounded,
        tint: dark
            ? const _Tints(Color(0xFF3A1818), Color(0xFFF87171))
            : const _Tints(Color(0xFFFDE2E2), Color(0xFFC53030)),
      );
    } else if (post.isFulfilled) {
      statusPill = _StatusPill(
        label: 'Completed',
        icon: Icons.task_alt_rounded,
        tint: _Tints.blue(dark),
      );
    } else {
      statusPill = _StatusPill(
        label: 'Active',
        icon: Icons.check_circle_rounded,
        tint: dark
            ? _Tints.green(true)
            : const _Tints(Color(0xFFE6F6EB), Color(0xFF06693B)),
      );
    }

    return _CardBox(
      color: post.isSponsored ? AdStyle.background(context) : null,
      borderColor: post.isSponsored ? AdStyle.border(context) : null,
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => openPostImageViewer(context, images),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 126,
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (images.isNotEmpty)
                      Image.network(
                        images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _NoImage(module: post.module),
                      )
                    else
                      _NoImage(module: post.module),
                    if (images.length > 1)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_library_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${images.length}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      statusPill,
                    ],
                  ),
                  if (post.isSponsored) ...[
                    const SizedBox(height: 6),
                    const SponsoredLabel(),
                  ],
                  if (post.location?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: c.inkMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            post.location!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: c.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoImage extends StatelessWidget {
  const _NoImage({required this.module});

  final PostModule module;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    return ColoredBox(
      color: c.sage,
      child: Icon(Icons.image_outlined, color: c.olive, size: 36),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.tint,
  });

  final String label;
  final IconData icon;
  final _Tints tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tint.fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tint.fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The other person
// ---------------------------------------------------------------------------

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.userId,
    required this.name,
    required this.role,
  });

  final String userId;
  final String name;

  /// Their role in the deal; null shows "Member since".
  final _Role? role;

  void _showTrust(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: TrustCardWidget(userId: userId, displayNameFallback: name),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppTheme.colors(context);
    return StreamBuilder<PublicTrustProfile?>(
      stream: context.read<TrustProfileService>().watchProfile(userId),
      builder: (context, snap) {
        final profile = snap.data;
        final since = profile?.memberSince;
        final label = role == null ? 'Member' : _Deal.roleName(role!);
        final subtitle = since == null
            ? (role == null ? 'Community member' : label)
            : '$label since ${_months[since.month - 1]} ${since.year}';
        final displayName =
            (profile?.displayName.trim().isNotEmpty ?? false)
                ? profile!.displayName
                : (name.trim().isEmpty ? 'Community member' : name);

        return _CardBox(
          onTap: () => _showTrust(context),
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              UserAvatar(
                userId: userId,
                name: displayName,
                radius: 30,
                photoUrl: profile?.photoUrl ?? '',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (profile?.isVerified == true) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified_rounded,
                            size: 20,
                            color: c.olive,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: c.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.ink, size: 28),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Contact request
// ---------------------------------------------------------------------------

class _ContactCard extends StatefulWidget {
  const _ContactCard({required this.post});

  final PostModel post;

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  bool _requesting = false;

  Future<void> _request(String uid, String name) async {
    setState(() => _requesting = true);
    try {
      final id = await context.read<ContactRequestService>().createRequest(
            post: widget.post,
            requesterId: uid,
            requesterName: name,
          );
      if (!mounted) return;
      navigatorKey.currentState?.pushNamed(
        AppConstants.routeContactRequest,
        arguments: id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _openRequest(String id) => navigatorKey.currentState?.pushNamed(
        AppConstants.routeContactRequest,
        arguments: id,
      );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Card, icon bubble, icon and button colours from the mockup.
    final cardBg = dark ? const Color(0xFF15301F) : const Color(0xFFEBF8EE);
    final bubbleBg = dark ? const Color(0xFF1C4A2E) : const Color(0xFFDAF5E2);
    final iconColor = dark ? const Color(0xFF5FD38A) : const Color(0xFF0B8A40);
    final tint = dark
        ? _Tints.green(true)
        : const _Tints(Color(0xFFDAF5E2), Color(0xFF1B6446));
    final isAuthor = widget.post.authorId == user.uid;

    Widget card({
      required String subtitle,
      Widget? action,
      Widget? extra,
    }) {
      final theme = Theme.of(context);
      return _CardBox(
        color: cardBg,
        borderColor: cardBg,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _IconBubble(
                  icon: Icons.phone_rounded,
                  bg: bubbleBg,
                  fg: iconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Request',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.colors(context).inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (action != null) ...[const SizedBox(width: 8), action],
              ],
            ),
            if (extra != null) ...[const SizedBox(height: 10), extra],
          ],
        ),
      );
    }

    Widget pillButton(String label, VoidCallback? onTap, {bool busy = false}) {
      return OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: tint.fg,
          side: BorderSide(color: tint.fg, width: 1.4),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          minimumSize: const Size(0, 42),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: tint.fg),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    if (isAuthor) {
      return card(
        subtitle: 'Your number ${widget.post.contactNumber} is shown only '
            'after you approve a request.',
      );
    }

    return StreamBuilder(
      stream: context.read<ContactRequestService>().watchActiveRequestForPost(
            postId: widget.post.id,
            userId: user.uid,
          ),
      builder: (context, snap) {
        final request = snap.data;

        if (request != null && request.status.revealsContact) {
          final number =
              request.revealedContactNumber ?? widget.post.contactNumber;
          return card(
            subtitle: 'Approved. Use the number responsibly.',
            action: pillButton('Details', () => _openRequest(request.id)),
            extra: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    number,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: tint.fg,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy number',
                  icon: Icon(Icons.copy_rounded, color: tint.fg),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: number));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone number copied')),
                    );
                  },
                ),
              ],
            ),
          );
        }

        if (request != null && request.status.isActive) {
          return card(
            subtitle: 'A contact request has been sent.',
            action: pillButton('View Status', () => _openRequest(request.id)),
          );
        }

        return card(
          subtitle: "Request the owner's contact number after approval.",
          action: pillButton(
            'Request',
            widget.post.isFulfilled
                ? null
                : () => _request(
                      user.uid,
                      user.displayName ?? user.email ?? 'User',
                    ),
            busy: _requesting,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Your next step (agreement / claim)
// ---------------------------------------------------------------------------

class _NextStepCard extends StatefulWidget {
  const _NextStepCard({
    required this.post,
    required this.deal,
    required this.mine,
  });

  final PostModel post;
  final _Deal deal;
  final bool mine;

  @override
  State<_NextStepCard> createState() => _NextStepCardState();
}

class _NextStepCardState extends State<_NextStepCard> {
  bool _starting = false;

  bool get _isExchange =>
      widget.post.module == PostModule.lend ||
      widget.post.module == PostModule.borrow;

  Future<void> _start() async {
    final user = context.read<AuthController>().user;
    if (user == null) return;
    setState(() => _starting = true);
    try {
      final name = user.displayName ?? user.email ?? 'User';
      final String id;
      final String route;
      if (_isExchange) {
        id = await context.read<LendBorrowContractService>().createContract(
              post: widget.post,
              initiatorId: user.uid,
              initiatorName: name,
            );
        route = AppConstants.routeLendBorrowContract;
      } else {
        id = await context.read<LostFoundClaimService>().createClaim(
              post: widget.post,
              initiatorId: user.uid,
              initiatorName: name,
            );
        route = AppConstants.routeLostFoundClaim;
      }
      if (!mounted) return;
      navigatorKey.currentState?.pushNamed(route, arguments: id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _open(String route, String id) =>
      navigatorKey.currentState?.pushNamed(route, arguments: id);

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final deal = widget.deal;
    final contract = deal.contract;
    final claim = deal.claim;

    // Completed: link to the record.
    if (post.isFulfilled) {
      final recordId = post.completedContractId;
      return _StepBox(
        icon: Icons.task_alt_rounded,
        title: _isExchange ? 'Exchange completed' : 'Recovery confirmed',
        message: 'This listing is no longer on the public feed or map. '
            'Find it under Profile → '
            '${_isExchange ? 'Completed exchanges' : 'Completed recoveries'}.',
        action: recordId == null || recordId.isEmpty
            ? null
            : _StepButton(
                icon: Icons.description_outlined,
                label: _isExchange ? 'View Agreement' : 'View Record',
                onTap: () => _open(
                  _isExchange
                      ? AppConstants.routeLendBorrowContract
                      : AppConstants.routeLostFoundClaim,
                  recordId,
                ),
              ),
      );
    }

    // Lend / borrow agreement
    if (_isExchange) {
      if (contract == null) {
        return widget.mine
            ? const _StepBox(
                icon: Icons.schedule_rounded,
                title: 'Your Next Step',
                message: 'Wait for someone to start the agreement.',
                waiting: (
                  'Waiting for a request',
                  "You'll be notified when someone starts an agreement.",
                ),
              )
            : _StepBox(
                icon: Icons.edit_note_rounded,
                title: 'Your Next Step',
                message: 'Start the digital agreement for this item.',
                action: _StepButton(
                  icon: Icons.handshake_rounded,
                  label: 'Start Agreement',
                  busy: _starting,
                  onTap: _start,
                ),
              );
      }
      final open = () =>
          _open(AppConstants.routeLendBorrowContract, contract.id);
      final iAmLender = deal.role == _Role.lender;
      switch (contract.status) {
        case ContractStatus.pendingLenderSignature:
        case ContractStatus.pendingBorrowerSignature:
          final lenderTurn =
              contract.status == ContractStatus.pendingLenderSignature;
          final myTurn = lenderTurn == iAmLender;
          final verb = iAmLender ? 'lending' : 'borrowing';
          final other = lenderTurn ? 'lender' : 'borrower';
          return myTurn
              ? _StepBox(
                  icon: Icons.edit_square,
                  title: 'Your Next Step',
                  message: 'Please sign the $verb agreement.',
                  action: _StepButton(
                    icon: Icons.draw_rounded,
                    label: 'Sign Agreement',
                    onTap: open,
                  ),
                )
              : _StepBox(
                  icon: Icons.schedule_rounded,
                  title: 'Your Next Step',
                  message: 'Waiting for $other to sign the agreement.',
                  waiting: (
                    'Waiting for Signature',
                    "You'll be notified once they sign.",
                  ),
                  onTap: open,
                );
        case ContractStatus.readyForHandshake:
          return _StepBox(
            icon: Icons.qr_code_2_rounded,
            title: 'Your Next Step',
            message: 'Meet up and confirm the exchange with the QR handshake.',
            action: _StepButton(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Open QR Handshake',
              onTap: open,
            ),
          );
        case ContractStatus.completed:
        case ContractStatus.cancelled:
          return _StepBox(
            icon: Icons.description_outlined,
            title: contract.status.label,
            message: 'Open the agreement to see the details.',
            action: _StepButton(
              icon: Icons.open_in_new_rounded,
              label: 'View Agreement',
              onTap: open,
            ),
          );
      }
    }

    // Lost / found claim
    final isLostPost = post.module == PostModule.lost;
    if (claim == null) {
      return widget.mine
          ? const _StepBox(
              icon: Icons.schedule_rounded,
              title: 'Your Next Step',
              message: 'Wait for someone to start a recovery claim.',
              waiting: (
                'Waiting for a claim',
                "You'll be notified when someone responds.",
              ),
            )
          : _StepBox(
              icon: Icons.edit_note_rounded,
              title: 'Your Next Step',
              message: isLostPost
                  ? 'Found this item? Start the recovery.'
                  : 'Is this yours? Start a claim.',
              action: _StepButton(
                icon: Icons.play_arrow_rounded,
                label: isLostPost ? 'I Found This Item' : 'Claim This Item',
                busy: _starting,
                onTap: _start,
              ),
            );
    }
    final open = () => _open(AppConstants.routeLostFoundClaim, claim.id);
    final iAmAuthor = widget.mine;
    switch (claim.status) {
      case ClaimStatus.pendingConfirm:
        return iAmAuthor
            ? _StepBox(
                icon: Icons.fact_check_rounded,
                title: 'Your Next Step',
                message: 'Review and confirm the claim.',
                action: _StepButton(
                  icon: Icons.check_rounded,
                  label: 'Review Claim',
                  onTap: open,
                ),
              )
            : _StepBox(
                icon: Icons.schedule_rounded,
                title: 'Your Next Step',
                message: 'Waiting for the post author to confirm your claim.',
                waiting: (
                  'Waiting for Confirmation',
                  "You'll be notified once they confirm.",
                ),
                onTap: open,
              );
      case ClaimStatus.readyForHandshake:
        return _StepBox(
          icon: Icons.qr_code_2_rounded,
          title: 'Your Next Step',
          message: 'Meet up and confirm the handover with a QR scan.',
          action: _StepButton(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Open QR Confirmation',
            onTap: open,
          ),
        );
      case ClaimStatus.completed:
      case ClaimStatus.cancelled:
        return _StepBox(
          icon: Icons.description_outlined,
          title: claim.status.label,
          message: 'Open the claim to see the details.',
          action: _StepButton(
            icon: Icons.open_in_new_rounded,
            label: 'View Claim',
            onTap: open,
          ),
        );
    }
  }
}

/// Amber "Your Next Step" card with either a button or a waiting box.
class _StepBox extends StatelessWidget {
  const _StepBox({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.waiting,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  /// (title, subtitle) of the grey waiting box.
  final (String, String)? waiting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final tint = _Tints.amber(dark);
    final waitTint = _Tints.waiting(dark);
    final c = AppTheme.colors(context);

    return _CardBox(
      color: tint.bg,
      borderColor: tint.border,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconBubble(
                icon: icon,
                bg: dark
                    ? const Color(0xFF4A3D1C)
                    : const Color(0xFFFFE7AB),
                fg: c.ink,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(message, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
          if (waiting != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: waitTint.bg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty_rounded,
                      color: waitTint.fg, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          waiting!.$1,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: waitTint.fg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          waiting!.$2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: waitTint.fg.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Big green pill button inside the step card.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: dark ? const Color(0xFF1F9D55) : const Color(0xFF018D44),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 24),
        label: Text(label),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// About (description, tags, likes, owner tools)
// ---------------------------------------------------------------------------

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.post, required this.mine});

  final PostModel post;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppTheme.colors(context);
    final tags = <String>[
      post.module.label,
      if (post.categoryDisplayLabel != null) post.categoryDisplayLabel!,
      if (post.itemCondition?.trim().isNotEmpty == true)
        'Condition: ${post.itemCondition}',
    ];

    return _CardBox(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this item',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in tags)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.sage,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: c.olive,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (post.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(post.description, style: theme.textTheme.bodyLarge),
          ],
          if (mine &&
              !post.isFulfilled &&
              !post.isSponsored &&
              !post.isSponsorPaused) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => showBoostPostDialog(context, post),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Boost post'),
            ),
          ],
          PostEngagementBar(
            post: post,
            showInsights: mine && post.hasAdHistory,
            onInsights: () => showPostInsights(context, post),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

class _CommentsCard extends StatelessWidget {
  const _CommentsCard({required this.postId});

  final String postId;

  void _openAll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _CommentsPage(postId: postId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppTheme.colors(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = dark ? const Color(0xFF8AB4FF) : const Color(0xFF1A2A8C);
    final viewAll = dark ? c.olive : const Color(0xFF0B6B35);

    return StreamBuilder<List<PostComment>>(
      stream: context.read<CommentService>().watchComments(postId),
      builder: (context, snap) {
        final comments = snap.data ?? const <PostComment>[];
        final latest = comments.isEmpty ? null : comments.last;
        return _CardBox(
          onTap: () => _openAll(context),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Comments (${comments.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    comments.isEmpty ? 'Add' : 'View All',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: viewAll,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: viewAll),
                ],
              ),
              const SizedBox(height: 12),
              if (latest == null)
                Text(
                  'No comments yet. Start the discussion.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: c.inkMuted,
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      userId: latest.authorId,
                      name: latest.authorName,
                      radius: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  latest.authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                _timeAgo(latest.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            latest.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: c.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// All comments with the input box.
class _CommentsPage extends StatelessWidget {
  const _CommentsPage({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const WaveHeaderBackground(),
        bottom: const WaveHeaderSpacer(),
        title: const Text('Comments'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: PostCommentsSection(postId: postId),
        ),
      ),
    );
  }
}
