import 'package:flutter/material.dart';

/// Green gradient header with soft waves and a curved bottom edge.
/// Same look as the admin panel header, sized for a normal app bar.
///
/// Use as `AppBar(flexibleSpace: const WaveHeaderBackground())`. The app bar
/// theme makes the bar itself transparent so the curve shows the page.
class WaveHeaderBackground extends StatelessWidget {
  const WaveHeaderBackground({super.key});

  // Light: same greens as the admin header.
  static const _lightTop = Color(0xFF14522F);
  static const _lightBottom = Color(0xFF2D8A52);
  static const _lightWave = Color(0x26FFFFFF);

  // Dark: deep green into the app's dark navy.
  static const _darkTop = Color(0xFF0F3A22);
  static const _darkBottom = Color(0xFF13202A);
  static const _darkWave = Color(0x1F2CCB68);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: WaveHeaderPainter(
        top: dark ? _darkTop : _lightTop,
        bottom: dark ? _darkBottom : _lightBottom,
        wave: dark ? _darkWave : _lightWave,
      ),
    );
  }
}

class WaveHeaderPainter extends CustomPainter {
  const WaveHeaderPainter({
    required this.top,
    required this.bottom,
    required this.wave,
    this.curveDepth = 12,
  });

  final Color top;
  final Color bottom;
  final Color wave;

  /// How far the curved bottom edge dips into the header.
  final double curveDepth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final d = curveDepth;

    final shape = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - d)
      ..cubicTo(w * 0.72, h + d * 0.15, w * 0.36, h - d * 1.3, 0, h - d * 0.2)
      ..close();

    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    canvas.clipPath(shape);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.62)
        ..cubicTo(w * 0.28, h * 0.38, w * 0.55, h * 0.95, w, h * 0.48)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = wave,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, 0)
        ..cubicTo(w * 0.55, h * 0.32, w * 0.8, h * 0.08, w, h * 0.3)
        ..lineTo(w, 0)
        ..close(),
      Paint()..color = wave.withValues(alpha: wave.a * 0.7),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WaveHeaderPainter old) =>
      old.top != top ||
      old.bottom != bottom ||
      old.wave != wave ||
      old.curveDepth != curveDepth;
}
