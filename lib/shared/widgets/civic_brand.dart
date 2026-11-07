import 'package:civic_citizen/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// People-and-leaf mark used on splash and home.
class CivicLogo extends StatelessWidget {
  const CivicLogo({super.key, this.size = 72, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.leaf;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(c)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    // Leaf
    final leaf = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..quadraticBezierTo(w * 0.92, h * 0.28, w * 0.62, h * 0.55)
      ..quadraticBezierTo(w * 0.50, h * 0.42, w * 0.38, h * 0.55)
      ..quadraticBezierTo(w * 0.08, h * 0.28, w * 0.50, h * 0.08)
      ..close();
    canvas.drawPath(leaf, p);
    // Heads
    canvas.drawCircle(Offset(w * 0.32, h * 0.62), w * 0.11, p);
    canvas.drawCircle(Offset(w * 0.68, h * 0.62), w * 0.11, p);
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.10, p);
    // Shoulders
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.88),
        width: w * 0.72,
        height: h * 0.28,
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

class CivicCategoryTile extends StatelessWidget {
  const CivicCategoryTile({
    super.key,
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
    final theme = Theme.of(context);
    final bg = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.55);
    final fg = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: fg, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

IconData civicIconForLabel(String label) {
  switch (label.toLowerCase()) {
    case 'lost':
      return Icons.pets_rounded;
    case 'found':
      return Icons.inventory_2_outlined;
    case 'charity':
      return Icons.favorite_border_rounded;
    case 'rescue':
    case 'resources':
      return Icons.shield_outlined;
    default:
      return Icons.category_outlined;
  }
}
