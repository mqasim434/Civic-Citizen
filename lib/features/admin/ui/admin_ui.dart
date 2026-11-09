import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/controllers/auth_controller.dart';

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------

/// Colours for the admin panel. Get with `AdminPalette.of(context)`.
class AdminPalette {
  const AdminPalette({
    required this.isDark,
    required this.page,
    required this.card,
    required this.cardBorder,
    required this.text,
    required this.muted,
    required this.primary,
    required this.buttonStart,
    required this.buttonEnd,
    required this.headerTop,
    required this.headerBottom,
    required this.wave,
    required this.heroStart,
    required this.heroEnd,
    required this.softGreen,
    required this.softGreenText,
    required this.softRed,
    required this.softRedText,
    required this.softBlue,
    required this.softBlueText,
    required this.softAmber,
    required this.softAmberText,
    required this.amber,
    required this.tileWarm,
    required this.tileAmber,
    required this.navBg,
    required this.navActive,
    required this.navBorder,
    required this.chipBg,
    required this.chipBorder,
    required this.shadow,
  });

  final bool isDark;
  final Color page;
  final Color card;
  final Color cardBorder;
  final Color text;
  final Color muted;

  /// Green for text, icons and selected states.
  final Color primary;

  /// Gradient of filled green buttons.
  final Color buttonStart;
  final Color buttonEnd;

  /// Wavy header gradient.
  final Color headerTop;
  final Color headerBottom;
  final Color wave;

  /// "Total Users" card gradient.
  final Color heroStart;
  final Color heroEnd;

  final Color softGreen;
  final Color softGreenText;
  final Color softRed;
  final Color softRedText;
  final Color softBlue;
  final Color softBlueText;
  final Color softAmber;
  final Color softAmberText;
  final Color amber;

  /// Dashboard tile tints (cards in dark mode).
  final Color tileWarm;
  final Color tileAmber;

  final Color navBg;
  final Color navActive;
  final Color navBorder;
  final Color chipBg;
  final Color chipBorder;
  final Color shadow;

  static AdminPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const light = AdminPalette(
    isDark: false,
    page: Color(0xFFF4F2EB),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFEDE9E0),
    text: Color(0xFF1C2A21),
    muted: Color(0xFF6F7A72),
    primary: Color(0xFF1F7A45),
    buttonStart: Color(0xFF2B9653),
    buttonEnd: Color(0xFF1A6B3A),
    headerTop: Color(0xFF14522F),
    headerBottom: Color(0xFF2D8A52),
    wave: Color(0x26FFFFFF),
    heroStart: Color(0xFF1C7240),
    heroEnd: Color(0xFF2E9A58),
    softGreen: Color(0xFFDDF0E1),
    softGreenText: Color(0xFF2E7D46),
    softRed: Color(0xFFFDE2E2),
    softRedText: Color(0xFFD64545),
    softBlue: Color(0xFFDCEAFF),
    softBlueText: Color(0xFF2F6FDB),
    softAmber: Color(0xFFFFEFD2),
    softAmberText: Color(0xFFB7791F),
    amber: Color(0xFFF2A93B),
    tileWarm: Color(0xFFFFF9EF),
    tileAmber: Color(0xFFFFF2DA),
    navBg: Color(0xFFFFFFFF),
    navActive: Color(0xFFE2F2E6),
    navBorder: Color(0xFFEDE9E0),
    chipBg: Color(0xFFFFFFFF),
    chipBorder: Color(0xFFE5E0D5),
    shadow: Color(0x12000000),
  );

  static const dark = AdminPalette(
    isDark: true,
    page: Color(0xFF0A0E0C),
    card: Color(0xFF131A16),
    cardBorder: Color(0xFF1F2A24),
    text: Color(0xFFF1F5F2),
    muted: Color(0xFF9AA69F),
    primary: Color(0xFF2CCB68),
    buttonStart: Color(0xFF2CCB68),
    buttonEnd: Color(0xFF169A48),
    headerTop: Color(0xFF0F3A22),
    headerBottom: Color(0xFF060C09),
    wave: Color(0x1F2CCB68),
    heroStart: Color(0xFF1DA552),
    heroEnd: Color(0xFF0E5F2F),
    softGreen: Color(0xFF173B25),
    softGreenText: Color(0xFF4ADE80),
    softRed: Color(0xFF3A1818),
    softRedText: Color(0xFFF87171),
    softBlue: Color(0xFF14294A),
    softBlueText: Color(0xFF60A5FA),
    softAmber: Color(0xFF3A2C12),
    softAmberText: Color(0xFFFBBF24),
    amber: Color(0xFFFBBF24),
    tileWarm: Color(0xFF131A16),
    tileAmber: Color(0xFF131A16),
    navBg: Color(0xFF0D1310),
    navActive: Color(0xFF153823),
    navBorder: Color(0xFF1C5A35),
    chipBg: Color(0xFF131A16),
    chipBorder: Color(0xFF25302A),
    shadow: Color(0x40000000),
  );

  BoxDecoration cardDecoration({double radius = 18, Color? color}) =>
      BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: shadow,
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      );

  LinearGradient get buttonGradient => LinearGradient(
        colors: [buttonStart, buttonEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Text styles used across the admin panel.
class AdminText {
  AdminText._();

  static TextStyle title(AdminPalette p, {double size = 16}) =>
      GoogleFonts.figtree(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: p.text,
        height: 1.2,
      );

  static TextStyle body(AdminPalette p, {double size = 13}) =>
      GoogleFonts.figtree(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: p.muted,
        height: 1.35,
      );

  static TextStyle label(Color color, {double size = 12}) =>
      GoogleFonts.figtree(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle header({double size = 20}) => GoogleFonts.figtree(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "2 min ago", "3h ago", "Yesterday", "Nov 9".
String adminTimeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays == 1) return 'Yesterday';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return adminDate(t);
}

/// "Nov 10, 2026".
String adminDate(DateTime t) => '${_months[t.month - 1]} ${t.day}, ${t.year}';

/// "10:00 AM".
String adminTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// "12,450".
String adminNumber(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Growth of a total over the last 30 days, as a whole percent.
/// Null when there is nothing to compare against.
int? adminGrowthPercent(Iterable<DateTime?> createdAt) {
  final cutoff = DateTime.now().subtract(const Duration(days: 30));
  var before = 0;
  var recent = 0;
  for (final t in createdAt) {
    if (t == null) continue;
    if (t.isAfter(cutoff)) {
      recent++;
    } else {
      before++;
    }
  }
  if (before == 0) return null;
  return (recent * 100 / before).round();
}

void adminSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// Green gradient with soft waves and a curved bottom edge.
class AdminHeaderPainter extends CustomPainter {
  const AdminHeaderPainter(this.p);

  final AdminPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shape = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - 26)
      ..cubicTo(w * 0.72, h + 4, w * 0.36, h - 34, 0, h - 6)
      ..close();

    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.headerTop, p.headerBottom],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    canvas.clipPath(shape);
    final wave = Paint()..color = p.wave;

    // Large soft wave across the lower half.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.62)
        ..cubicTo(w * 0.28, h * 0.38, w * 0.55, h * 0.95, w, h * 0.48)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      wave,
    );

    // Thinner highlight band near the top right.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, 0)
        ..cubicTo(w * 0.55, h * 0.32, w * 0.8, h * 0.08, w, h * 0.3)
        ..lineTo(w, 0)
        ..close(),
      Paint()..color = p.wave.withValues(alpha: p.wave.a * 0.7),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AdminHeaderPainter old) => old.p != p;
}

/// White icon button for the green header.
class AdminHeaderIcon extends StatelessWidget {
  const AdminHeaderIcon({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

/// Notification bell for the green header, with a red count badge.
class AdminBell extends StatelessWidget {
  const AdminBell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: context.read<NotificationService>().watchUnreadCount(user.uid),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => navigatorKey.currentState?.pushNamed(
            AppConstants.routeNotifications,
          ),
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: const Color(0xFFE53935),
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        );
      },
    );
  }
}

/// Standard admin screen: wavy green header with a title, then [body] on
/// the cream (light) or near-black (dark) page.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions = const [],
    this.floating,
  });

  final String title;
  final Widget body;

  /// Usually [AdminBackButton]. Null shows nothing.
  final Widget? leading;
  final List<Widget> actions;
  final Widget? floating;

  static const toolbarHeight = 56.0;
  static const waveDepth = 26.0;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: p.page,
      floatingActionButton: floating,
      body: Column(
        children: [
          SizedBox(
            height: top + toolbarHeight + waveDepth,
            child: CustomPaint(
              painter: AdminHeaderPainter(p),
              child: Padding(
                padding: EdgeInsets.only(top: top, left: 4, right: 4),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: toolbarHeight,
                    child: Row(
                      children: [
                        if (leading != null) leading! else const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: leading == null ? 4 : 0,
                            ),
                            child: Text(
                              title,
                              style: AdminText.header(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        ...actions,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Back arrow for [AdminPage]. Pops the nearest navigator unless
/// [onPressed] is given.
class AdminBackButton extends StatelessWidget {
  const AdminBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AdminHeaderIcon(
      tooltip: 'Back',
      icon: Icons.arrow_back_rounded,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

/// Small rounded status label, e.g. "Active", "Found", "Upcoming".
class AdminPill extends StatelessWidget {
  const AdminPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.fontSize = 11,
  });

  factory AdminPill.green(BuildContext context, String label) {
    final p = AdminPalette.of(context);
    return AdminPill(
      label: label,
      background: p.softGreen,
      foreground: p.softGreenText,
    );
  }

  factory AdminPill.red(BuildContext context, String label) {
    final p = AdminPalette.of(context);
    return AdminPill(
      label: label,
      background: p.softRed,
      foreground: p.softRedText,
    );
  }

  factory AdminPill.blue(BuildContext context, String label) {
    final p = AdminPalette.of(context);
    return AdminPill(
      label: label,
      background: p.softBlue,
      foreground: p.softBlueText,
    );
  }

  factory AdminPill.amber(BuildContext context, String label) {
    final p = AdminPalette.of(context);
    return AdminPill(
      label: label,
      background: p.softAmber,
      foreground: p.softAmberText,
    );
  }

  factory AdminPill.grey(BuildContext context, String label) {
    final p = AdminPalette.of(context);
    return AdminPill(
      label: label,
      background: p.chipBorder,
      foreground: p.muted,
    );
  }

  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AdminText.label(foreground, size: fontSize)),
    );
  }
}

/// Horizontal row of rounded filter chips (All, Lost, Found...).
class AdminChipBar<T> extends StatelessWidget {
  const AdminChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelOf,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 12),
    this.expand = false,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelOf;
  final EdgeInsets padding;

  /// Stretch chips to fill the width (used by tab-like rows).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    Widget chip(T o) {
      final on = o == selected;
      return GestureDetector(
        onTap: () => onSelected(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: on ? p.buttonGradient : null,
            color: on ? null : p.chipBg,
            borderRadius: BorderRadius.circular(20),
            border: on ? null : Border.all(color: p.chipBorder),
          ),
          child: Text(
            labelOf(o),
            maxLines: 1,
            style: AdminText.label(on ? Colors.white : p.text, size: 13),
          ),
        ),
      );
    }

    if (expand) {
      return Padding(
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: chip(options[i])),
            ],
          ],
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chip(options[i]),
          ],
        ],
      ),
    );
  }
}

/// Green gradient button. [compact] for in-card actions like "View".
class AdminButton extends StatelessWidget {
  const AdminButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.busy = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;
  final bool busy;

  /// Soft red style (e.g. Reject).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final enabled = onPressed != null && !busy;
    final fg = danger ? p.softRedText : Colors.white;
    final height = compact ? 34.0 : 52.0;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: danger ? null : p.buttonGradient,
            color: danger ? p.softRed : null,
            borderRadius: BorderRadius.circular(compact ? 18 : 26),
            boxShadow: danger || p.isDark
                ? null
                : [
                    BoxShadow(
                      color: p.buttonEnd.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(compact ? 18 : 26),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, color: fg, size: compact ? 16 : 22),
                  if (busy || icon != null) const SizedBox(width: 8),
                  Text(
                    label,
                    style: AdminText.label(fg, size: compact ? 13 : 15),
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

/// Rounded search box used on Users and Map.
class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.cardBorder),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: AdminText.title(p, size: 14).copyWith(
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AdminText.body(p, size: 14),
          prefixIcon: Icon(Icons.search_rounded, color: p.muted),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

/// Square card button with a soft background, used for filter / more.
class AdminSquareIconButton extends StatelessWidget {
  const AdminSquareIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.cardBorder),
          ),
          child: Icon(icon, color: p.text, size: 22),
        ),
      ),
    );
  }
}

/// "Recent Activities          View All ->".
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Row(
      children: [
        Expanded(child: Text(title, style: AdminText.title(p, size: 17))),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!, style: AdminText.label(p.primary, size: 13)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: p.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Centered icon + message for empty and error states.
class AdminEmpty extends StatelessWidget {
  const AdminEmpty({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: p.muted.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AdminText.body(p, size: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular "more" button (three dots). White disc when [onImage].
class AdminMoreButton<T> extends StatelessWidget {
  const AdminMoreButton({
    super.key,
    required this.itemBuilder,
    required this.onSelected,
    this.onImage = false,
    this.tooltip = 'More',
  });

  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;
  final bool onImage;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final button = PopupMenuButton<T>(
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_vert_rounded,
        color: onImage ? const Color(0xFF1C2A21) : p.text,
        size: 22,
      ),
    );
    if (!onImage) return button;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
      ),
      child: Center(child: button),
    );
  }
}

/// Menu row with an icon, for [AdminMoreButton] items.
PopupMenuItem<T> adminMenuItem<T>(
  T value,
  IconData icon,
  String label, {
  bool danger = false,
}) {
  return PopupMenuItem<T>(
    value: value,
    child: Builder(
      builder: (context) {
        final color = danger ? Theme.of(context).colorScheme.error : null;
        return Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color)),
          ],
        );
      },
    ),
  );
}

/// Asks for an optional reason. Returns null on cancel.
Future<String?> adminAskReason(
  BuildContext context, {
  required String title,
  String hint = 'Reason (optional)',
  String confirm = 'Confirm',
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: Text(confirm),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// Yes/no confirmation. Returns true on confirm.
Future<bool> adminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Confirm',
  bool danger = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Picks one option from a bottom sheet list. Returns null on dismiss.
Future<T?> adminPickOption<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T) labelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final p = AdminPalette.of(ctx);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title, style: AdminText.title(p, size: 18)),
            ),
            for (final o in options)
              ListTile(
                title: Text(labelOf(o)),
                trailing: o == selected
                    ? Icon(Icons.check_rounded, color: p.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(o),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
