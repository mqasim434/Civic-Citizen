import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Gold accent that marks sponsored content, so ads never look like
/// normal community posts.
class AdStyle {
  AdStyle._();

  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color border(BuildContext context) =>
      _dark(context) ? const Color(0xFF7A6126) : const Color(0xFFE2BE6A);

  /// Faint warm card background.
  static Color background(BuildContext context) =>
      _dark(context) ? const Color(0xFF221F1A) : const Color(0xFFFFFBF1);

  static Color labelBackground(BuildContext context) =>
      _dark(context) ? const Color(0xFF3A2F16) : const Color(0xFFFCEFCF);

  static Color labelForeground(BuildContext context) =>
      _dark(context) ? const Color(0xFFF2C96B) : const Color(0xFF8A5D0B);

  /// Card shape for sponsored items: same radius as other cards, gold edge.
  static ShapeBorder cardShape(BuildContext context) => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: border(context), width: 1.5),
      );
}

/// "Sponsored" pill with a megaphone icon.
class SponsoredLabel extends StatelessWidget {
  const SponsoredLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final fg = AdStyle.labelForeground(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdStyle.labelBackground(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_rounded, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            'Sponsored',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
