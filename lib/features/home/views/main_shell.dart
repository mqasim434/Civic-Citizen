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
    if (i == _index) {
      ShellTab.reselected.fire(i);
      return;
    }
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
            _CivicNavBar(index: _index, tabs: _tabs, onSelected: _select),
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

  static const _center = 2;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.raised,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : AppTheme.ink.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  foregroundPainter: _TopCornerBorderPainter(c.olive),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: i == _center
                        ? _CenterLabel(
                            label: tabs[i].label,
                            onTap: () => onSelected(i),
                          )
                        : _SideItem(
                            item: tabs[i],
                            selected: i == index,
                            onTap: () => onSelected(i),
                          ),
                  ),
              ],
            ),
            Positioned(
              top: -22,
              left: 0,
              right: 0,
              child: Center(
                child: _CenterButton(onTap: () => onSelected(_center)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _TabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final color = selected ? c.olive : c.inkMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.selected : item.icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 18 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: c.olive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.colors(context).isDark
                  ? AppTheme.leafDark
                  : AppTheme.olive,
            ),
          ),
        ),
      ),
    );
  }
}

/// Red map pin standing on a small street map.
class _MapPinIcon extends StatelessWidget {
  const _MapPinIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _MapPinPainter(),
    );
  }
}

class _MapPinPainter extends CustomPainter {
  const _MapPinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final frame = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.06, h * 0.50, w * 0.94, h * 0.96),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(frame, Paint()..color = const Color(0xFFD6E9F8));

    final inner = frame.deflate(w * 0.055);
    canvas.save();
    canvas.clipRRect(inner);
    canvas.drawRect(inner.outerRect, Paint()..color = const Color(0xFF43A047));
    final land = inner.outerRect;
    canvas.drawPath(
      Path()
        ..moveTo(land.left, land.bottom)
        ..lineTo(land.left, land.bottom - land.height * 0.42)
        ..lineTo(land.left + land.width * 0.46, land.bottom)
        ..close(),
      Paint()..color = const Color(0xFF1E88E5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(land.right, land.bottom)
        ..lineTo(land.right, land.bottom - land.height * 0.38)
        ..lineTo(land.right - land.width * 0.34, land.bottom)
        ..close(),
      Paint()..color = const Color(0xFF1E88E5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(land.left, land.top + land.height * 0.42)
        ..lineTo(
          land.left + land.width * 0.55,
          land.center.dy + land.height * 0.08,
        )
        ..lineTo(land.right - land.width * 0.08, land.top + land.height * 0.18),
      Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    final cx = w * 0.50;
    final cy = h * 0.30;
    final r = w * 0.24;
    final tip = h * 0.66;
    final pin = Path()
      ..moveTo(cx, tip)
      ..cubicTo(
        cx - r * 0.2,
        cy + r * 0.9,
        cx - r * 1.25,
        cy + r * 0.35,
        cx - r,
        cy,
      )
      ..arcToPoint(
        Offset(cx + r, cy),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..cubicTo(
        cx + r * 1.25,
        cy + r * 0.35,
        cx + r * 0.2,
        cy + r * 0.9,
        cx,
        tip,
      )
      ..close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, cx, h));
    canvas.drawPath(pin, Paint()..color = const Color(0xFFFF4D2E));
    canvas.restore();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cx, 0, w - cx, h));
    canvas.drawPath(pin, Paint()..color = const Color(0xFFE10600));
    canvas.restore();
    canvas.drawCircle(
      Offset(cx, cy - r * 0.06),
      r * 0.36,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPinPainter oldDelegate) => false;
}

/// Faded emerald wave, the same glow as the reference, softened so the
/// pin stays readable.
class _EmeraldWavePainter extends CustomPainter {
  const _EmeraldWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06140E), Color(0xFF0C3A22), Color(0xFF04110C)],
        ).createShader(rect),
    );

    final wave = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.18,
        size.width * 0.62,
        size.height * 0.46,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.66,
        size.width * 1.05,
        size.height * 0.34,
      );

    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.55
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0E6A38), Color(0xFF3DFF8A), Color(0xFF14924A)],
        ).createShader(rect),
    );
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.10
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xCCE8FFE8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  @override
  bool shouldRepaint(covariant _EmeraldWavePainter oldDelegate) => false;
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppTheme.olive.withValues(alpha: 0.55),
              blurRadius: 28,
              spreadRadius: 6,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _EmeraldWavePainter()),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x59000000), Color(0x33000000)],
                  ),
                ),
              ),
              const Center(child: _MapPinIcon(size: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stroke along the top edge and the two top corners only.
class _TopCornerBorderPainter extends CustomPainter {
  const _TopCornerBorderPainter(this.color);

  final Color color;

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
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TopCornerBorderPainter oldDelegate) =>
      oldDelegate.color != color;
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
