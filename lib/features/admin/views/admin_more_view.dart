import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../ui/admin_ui.dart';
import '../../ads/views/admin_ads_moderation_view.dart';
import 'admin_announcements_view.dart';
import 'admin_map_view.dart';
import 'admin_verifications_view.dart';
import '../../events/views/admin_events_view.dart';

enum AdminMorePage { verification, map, broadcast, events, ads }

extension on AdminMorePage {
  (IconData, String) get tile {
    switch (this) {
      case AdminMorePage.verification:
        return (Icons.verified_user_outlined, 'Verification');
      case AdminMorePage.map:
        return (Icons.location_on_rounded, 'Map');
      case AdminMorePage.broadcast:
        return (Icons.campaign_rounded, 'Broadcast\n(Announcements)');
      case AdminMorePage.events:
        return (Icons.event_note_rounded, 'Events');
      case AdminMorePage.ads:
        return (Icons.sell_rounded, 'Ads');
    }
  }

  Widget build() {
    switch (this) {
      case AdminMorePage.verification:
        return const AdminVerificationsView();
      case AdminMorePage.map:
        return const AdminMapView();
      case AdminMorePage.broadcast:
        return const AdminAnnouncementsView();
      case AdminMorePage.events:
        return const AdminEventsView();
      case AdminMorePage.ads:
        return const AdminAdsView();
    }
  }
}

Route<void> adminMoreRoute(AdminMorePage page) =>
    MaterialPageRoute<void>(builder: (_) => page.build());

class AdminMoreView extends StatelessWidget {
  const AdminMoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return AdminPage(
      title: 'More',
      actions: [
        AdminHeaderIcon(
          tooltip: 'Settings',
          icon: Icons.settings_outlined,
          onPressed: () => navigatorKey.currentState?.pushNamed(
            AppConstants.routeSettings,
          ),
        ),
        const SizedBox(width: 4),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _AdminToolsBanner(onTap: () => _showAdminTools(context)),
          const SizedBox(height: 22),
          Text('Management Modules', style: AdminText.title(p, size: 18)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              for (final page in AdminMorePage.values)
                _ModuleTile(
                  icon: page.tile.$1,
                  label: page.tile.$2,
                  onTap: () => Navigator.of(context).push(adminMoreRoute(page)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _HelpCard(
            onTap: () => navigatorKey.currentState?.pushNamed(
              AppConstants.routeHelpSupport,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminTools(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) {
        final p = AdminPalette.of(ctx);
        final theme = ctx.watch<ThemeController>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Admin Tools', style: AdminText.title(p, size: 18)),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark mode'),
                value: theme.isDark && !theme.isSystem,
                onChanged: (v) =>
                    theme.setMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  navigatorKey.currentState?.pushNamed(
                    AppConstants.routeSettings,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Sign out',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await context.read<AuthController>().signOut();
                  navigatorKey.currentState?.pushNamedAndRemoveUntil(
                    AppConstants.routeLogin,
                    (_) => false,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _AdminToolsBanner extends StatelessWidget {
  const _AdminToolsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [p.heroStart, p.heroEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: p.amber, size: 38),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Tools', style: AdminText.header(size: 16)),
                      const SizedBox(height: 2),
                      Text(
                        'Manage all features from here',
                        style: AdminText.label(
                          Colors.white.withValues(alpha: 0.85),
                          size: 12,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: p.cardDecoration(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: p.primary, size: 34),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AdminText.title(p, size: 14).copyWith(
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

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: p.isDark ? p.card : p.softGreen,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.isDark ? p.cardBorder : p.softGreen),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Icon(
                  p.isDark
                      ? Icons.support_agent_rounded
                      : Icons.info_outline_rounded,
                  color: p.primary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Need help?', style: AdminText.title(p, size: 14)),
                      const SizedBox(height: 2),
                      Text(
                        'Contact support for assistance',
                        style: AdminText.body(p, size: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
