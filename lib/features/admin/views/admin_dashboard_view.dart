import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/shell_tab.dart';
import '../ui/admin_ui.dart';
import 'admin_home_view.dart';
import 'admin_more_view.dart';
import 'admin_posts_timeline_view.dart';
import 'admin_user_management_view.dart';

/// Admin shell: Dashboard, Posts, Users and More in the bottom bar.
/// More has its own navigator so its pages keep the bottom bar.
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  static const _dashboard = 0;
  static const _posts = 1;
  static const _more = 3;

  int _index = _dashboard;
  final _moreNav = GlobalKey<NavigatorState>();

  void _select(int i) {
    if (i == _index) {
      // Same tab again: on a More page go back to the menu, otherwise
      // scroll the current screen to the top.
      final nav = _moreNav.currentState;
      if (i == _more && nav != null && nav.canPop()) {
        nav.popUntil((r) => r.isFirst);
      } else {
        AdminShellTab.reselected.fire(i);
      }
      return;
    }
    setState(() => _index = i);
  }

  /// Opens one of the More pages (used by dashboard tiles).
  void _openMorePage(AdminMorePage page) {
    setState(() => _index = _more);
    final nav = _moreNav.currentState;
    if (nav == null) return;
    nav.popUntil((r) => r.isFirst);
    nav.push(adminMoreRoute(page));
  }

  void _handleBack() {
    final nav = _moreNav.currentState;
    if (_index == _more && nav != null && nav.canPop()) {
      nav.pop();
      return;
    }
    if (_index != _dashboard) {
      setState(() => _index = _dashboard);
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: p.page,
        body: IndexedStack(
          index: _index,
          children: [
            AdminHomeView(
              onOpenPosts: () => setState(() => _index = _posts),
              onOpenUsers: () => setState(() => _index = 2),
              onOpenMorePage: _openMorePage,
            ),
            AdminPostsTimelineView(
              onBack: () => setState(() => _index = _dashboard),
            ),
            const AdminUserManagementView(),
            Navigator(
              key: _moreNav,
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const AdminMoreView(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AdminBottomNav(
          index: _index,
          onSelected: _select,
        ),
      ),
    );
  }
}

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Dashboard'),
    (Icons.description_outlined, Icons.description_rounded, 'Posts'),
    (Icons.people_alt_outlined, Icons.people_alt_rounded, 'Users'),
    (Icons.notes_rounded, Icons.grid_view_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.navBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        // Green top border in both themes.
        border: Border(top: BorderSide(color: p.navBorder, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: p.isDark
                ? p.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: i == index ? _items[i].$2 : _items[i].$1,
                    label: _items[i].$3,
                    selected: i == index,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final color = selected ? p.primary : p.muted;
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? p.navActive : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                style: AdminText.label(color, size: 11).copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
