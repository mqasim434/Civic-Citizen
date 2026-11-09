import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/shell_tab.dart';
import '../../../core/navigation/tab_reselect.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../lend_borrow/widgets/completed_exchanges_section.dart';
import '../../lost_found/widgets/completed_recoveries_section.dart';
import '../../ads/widgets/boost_post_sheet.dart';
import '../../mutual_confidence/models/public_trust_profile.dart';
import '../../mutual_confidence/services/trust_profile_service.dart';
import '../../points/services/points_service.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deleted')));
    }
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

/// Keeps white header text readable over the lighter photo tint.
const _headerTextShadow = [
  Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1)),
];

class _ProfileViewState extends State<ProfileView>
    with TabReselectListener {
  final _postsKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  int get shellTabIndex => ShellTab.profile;

  @override
  void onTabReselected() => scrollToTop(_scrollController);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPosts() {
    final target = _postsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('Please sign in', style: theme.textTheme.bodyLarge),
        ),
      );
    }
    final c = AppTheme.colors(context);
    return Scaffold(
      backgroundColor: c.isDark ? c.page : AppTheme.warmCream,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: Image(
                      image: AssetImage('assets/home_banner.jpg'),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                  // Light tint so the photo shows; a bit stronger at the
                  // bottom behind the name and email.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.burgundy.withValues(alpha: 0.30),
                            AppTheme.burgundy.withValues(alpha: 0.62),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 12, 28),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => navigatorKey.currentState
                                ?.pushNamed(AppConstants.routeSettings),
                            icon: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 84,
                          height: 84,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    user.photoUrl?.trim().isNotEmpty == true
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl?.trim().isNotEmpty == true
                                    ? null
                                    : Text(
                                        (user.displayName?.isNotEmpty == true
                                                ? user.displayName![0]
                                                : user.email?[0] ?? '?')
                                            .toUpperCase(),
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              color: AppTheme.burgundy,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 2,
                                  shadowColor: Colors.black26,
                                  shape: const CircleBorder(
                                    side: BorderSide(
                                      color: AppTheme.burgundy,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () =>
                                        navigatorKey.currentState?.pushNamed(
                                          AppConstants.routeEditProfile,
                                        ),
                                    child: const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size: 15,
                                        color: AppTheme.burgundy,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.displayName ?? 'User',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            shadows: _headerTextShadow,
                          ),
                        ),
                        if (user.email != null)
                          Text(
                            user.email!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              shadows: _headerTextShadow,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder<int>(
                    stream: context.read<PointsService>().watchBalance(
                      user.uid,
                    ),
                    builder: (context, snap) {
                      return Row(
                        children: [
                          _Stat(label: 'Points', value: '${snap.data ?? 0}'),
                          // Helps = completed lend/borrow exchanges +
                          // returned lost items.
                          StreamBuilder<PublicTrustProfile?>(
                            stream: context
                                .read<TrustProfileService>()
                                .watchProfile(user.uid),
                            builder: (context, trust) => _Stat(
                              label: 'Helps',
                              value:
                                  '${trust.data?.totalCompletedHandshakes ?? 0}',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _MenuTile(
                    icon: Icons.bookmark_border_rounded,
                    label: 'My Posts',
                    onTap: _scrollToPosts,
                  ),
                  _MenuTile(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favourites',
                    onTap: () => navigatorKey.currentState?.pushNamed(
                      AppConstants.routeFavourites,
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Daily Rewards',
                    onTap: () => ShellTab.go(3),
                  ),
                  _MenuTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () => navigatorKey.currentState?.pushNamed(
                      AppConstants.routeNotifications,
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.headset_mic_outlined,
                    label: 'Help & Support',
                    onTap: () => navigatorKey.currentState?.pushNamed(
                      AppConstants.routeHelpSupport,
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => navigatorKey.currentState?.pushNamed(
                      AppConstants.routeSettings,
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.event_outlined,
                    label: 'Community events',
                    onTap: () => navigatorKey.currentState?.pushNamed(
                      AppConstants.routeEvents,
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.campaign_outlined,
                    label: 'Run an ad',
                    onTap: () => navigatorKey.currentState?.pushNamed(
                      AppConstants.routeCreateAd,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.burgundyInk,
                      side: BorderSide(color: c.beige),
                      backgroundColor: c.isDark ? c.card : AppTheme.ivory,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'My posts',
                    key: _postsKey,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Active listings only — completed lend/borrow items move to Completed exchanges.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<PostModel>>(
                    stream: context.read<PostController>().watchMyPosts(
                      user.uid,
                    ),
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
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => navigatorKey.currentState
                                    ?.pushNamed(AppConstants.routeCreatePost),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Create your first post'),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: posts
                            .map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _MyPostCard(
                                  post: p,
                                  onView: () =>
                                      navigatorKey.currentState?.pushNamed(
                                        AppConstants.routePostDetail,
                                        arguments: p,
                                      ),
                                  onEdit: () =>
                                      navigatorKey.currentState?.pushNamed(
                                        AppConstants.routeEditPost,
                                        arguments: p,
                                      ),
                                  onDelete: () =>
                                      _showDeleteConfirm(context, p),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  CompletedExchangesSection(userId: user.uid),
                  CompletedRecoveriesSection(userId: user.uid),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.colors(context).inkMuted),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _MyPostCard extends StatelessWidget {
  static final _compact = ButtonStyle(
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    ),
    minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    textStyle: WidgetStatePropertyAll(
      GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );

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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              post.isStandaloneAd
                                  ? 'Sponsored'
                                  : post.module.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (post.isSponsorPaused) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Ad paused',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ] else if (post.isSponsored &&
                              !post.isStandaloneAd) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Sponsored',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onView,
                    style: _compact,
                    child: const Text('View'),
                  ),
                ),
                if (!post.isFulfilled &&
                    !post.isSponsored &&
                    !post.isSponsorPaused) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showBoostPostDialog(context, post),
                      style: _compact,
                      icon: const Icon(Icons.campaign_outlined, size: 16),
                      label: const Text('Boost'),
                    ),
                  ),
                ],
                if (post.hasAdHistory) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showPostInsights(context, post),
                      style: _compact,
                      icon: const Icon(Icons.insights_rounded, size: 16),
                      label: const Text('Insights'),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Edit',
                  onPressed: post.isFulfilled ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                const SizedBox(width: 4),
                IconButton.outlined(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  color: theme.colorScheme.error,
                  style: IconButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
