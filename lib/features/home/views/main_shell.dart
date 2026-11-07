import 'package:flutter/material.dart';

import '../../../core/navigation/shell_tab.dart';
import '../../../core/theme/app_theme.dart';
import '../../fun_activity/views/rewards_view.dart';
import '../../profile/views/profile_view.dart';
import '../../profile/widgets/ban_guard.dart';
import 'dashboard_view.dart';
import 'map_placeholder_view.dart';
import 'nearby_posts_view.dart';

/// Main shell with bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    _TabItem(
      icon: Icons.home_outlined,
      selected: Icons.home_rounded,
      label: 'Home',
    ),
    _TabItem(
      icon: Icons.location_on_outlined,
      selected: Icons.location_on_rounded,
      label: 'Nearby',
    ),
    _TabItem(
      icon: Icons.map_outlined,
      selected: Icons.map_rounded,
      label: 'Map',
    ),
    _TabItem(
      icon: Icons.card_giftcard_outlined,
      selected: Icons.card_giftcard_rounded,
      label: 'Rewards',
    ),
    _TabItem(
      icon: Icons.person_outline_rounded,
      selected: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _index = ShellTab.index.value;
    ShellTab.index.addListener(_onExternalTab);
  }

  @override
  void dispose() {
    ShellTab.index.removeListener(_onExternalTab);
    super.dispose();
  }

  void _onExternalTab() {
    if (!mounted) return;
    final next = ShellTab.index.value;
    if (next != _index) setState(() => _index = next);
  }

  void _select(int i) {
    setState(() => _index = i);
    if (ShellTab.index.value != i) ShellTab.index.value = i;
  }

  @override
  Widget build(BuildContext context) {
    return BanGuard(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  DashboardView(),
                  NearbyPostsView(),
                  MapPostsView(),
                  RewardsView(embedded: true),
                  ProfileView(),
                ],
              ),
            ),
            _CivicNavBar(
              index: _index,
              tabs: _tabs,
              onSelected: _select,
            ),
          ],
        ),
      ),
    );
  }
}

class _CivicNavBar extends StatelessWidget {
  const _CivicNavBar({
    required this.index,
    required this.tabs,
    required this.onSelected,
  });

  final int index;
  final List<_TabItem> tabs;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const _TopCornerBorderPainter(),
        child: Material(
        color: AppTheme.paperRaised,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onSelected(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            i == index ? tabs[i].selected : tabs[i].icon,
                            size: 22,
                            color: i == index
                                ? AppTheme.olive
                                : AppTheme.inkMuted,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tabs[i].label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == index
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == index
                                  ? AppTheme.olive
                                  : AppTheme.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: i == index ? 18 : 0,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppTheme.olive,
                              borderRadius: BorderRadius.circular(2),
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
      ),
    );
  }
}

/// Stroke along the top edge and the two top corners only.
class _TopCornerBorderPainter extends CustomPainter {
  const _TopCornerBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 24.0;
    const stroke = 1.5;
    final inset = stroke / 2;
    final r = radius - inset;
    final path = Path()
      ..moveTo(inset, r + inset)
      ..arcToPoint(
        Offset(r + inset, inset),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(size.width - r - inset, inset)
      ..arcToPoint(
        Offset(size.width - inset, r + inset),
        radius: Radius.circular(r),
        clockwise: true,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.olive
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _TabItem {
  const _TabItem({
    required this.icon,
    required this.selected,
    required this.label,
  });

  final IconData icon;
  final IconData selected;
  final String label;
}
