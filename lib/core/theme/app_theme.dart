import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Home, Nearby, and Map use the original forest green with sage and ivory.
/// Profile: Burgundy #713F43, Muted Beige #C6AA91, Warm Cream #F4EFE6.
class AppTheme {
  AppTheme._();

  // Home, Nearby & Map. Forest green replaces the client's olive swatch.
  static const Color olive = Color(0xFF1F6B45);
  static const Color sage = Color(0xFFD8DDCB);
  static const Color ivory = Color(0xFFF3F0E7);

  // Profile
  static const Color burgundy = Color(0xFF713F43);
  static const Color beige = Color(0xFFC6AA91);
  static const Color warmCream = Color(0xFFF4EFE6);

  // Aliases used across the app. [leaf] is the forest green.
  static const Color ink = Color(0xFF243028);
  static const Color leaf = olive;
  static const Color leafSoft = sage;
  static const Color paper = ivory;
  static const Color paperRaised = warmCream;
  static const Color stone = beige;
  static const Color inkMuted = Color(0xFF4E5849);
  static const Color errorLight = Color(0xFFB42318);

  // Dark
  static const Color inkDark = Color(0xFF0E1624);
  static const Color paperDark = Color(0xFF151D2B);
  static const Color raisedDark = Color(0xFF1C2738);
  static const Color leafDark = Color(0xFF6FBF94);
  static const Color textDark = Color(0xFFE8E4DC);
  static const Color mutedDark = Color(0xFFB4BCC8);

  /// Header (app bar) colours, a step apart from the page background.
  static const Color headerLight = Color(0xFFE9E3D4);
  static const Color headerDark = raisedDark;

  static const double _radius = 18;

  /// Shared card system for Home, Nearby and Rewards: corner radius, gap
  /// between cards and screen side padding.
  static const double cardRadius = _radius;
  static const double cardGap = 12;
  static const double pagePadding = 16;

  /// Brand colours for the current theme. Use this in widgets instead of
  /// the light-only constants above so screens follow dark mode.
  static CivicColors colors(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? CivicColors.dark
          : CivicColors.light;

  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: olive,
      onPrimary: Colors.white,
      primaryContainer: sage,
      onPrimaryContainer: olive,
      secondary: olive,
      onSecondary: Colors.white,
      secondaryContainer: sage,
      onSecondaryContainer: olive,
      tertiary: burgundy,
      onTertiary: Colors.white,
      tertiaryContainer: beige,
      onTertiaryContainer: burgundy,
      surface: ivory,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      surfaceContainerLowest: warmCream,
      surfaceContainerLow: ivory,
      surfaceContainer: sage,
      surfaceContainerHigh: beige,
      surfaceContainerHighest: beige,
      outline: beige,
      outlineVariant: sage,
      error: errorLight,
      onError: Colors.white,
    );
    return _build(scheme, Brightness.light);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.dark(
      primary: leafDark,
      onPrimary: inkDark,
      primaryContainer: const Color(0xFF244536),
      onPrimaryContainer: sage,
      secondary: leafDark,
      onSecondary: inkDark,
      secondaryContainer: const Color(0xFF244536),
      onSecondaryContainer: sage,
      tertiary: const Color(0xFFC49296),
      onTertiary: inkDark,
      surface: paperDark,
      onSurface: textDark,
      onSurfaceVariant: mutedDark,
      surfaceContainerLowest: inkDark,
      surfaceContainerLow: raisedDark,
      surfaceContainer: const Color(0xFF222E40),
      surfaceContainerHigh: const Color(0xFF2A374B),
      surfaceContainerHighest: const Color(0xFF344257),
      outline: const Color(0xFF4A566A),
      outlineVariant: const Color(0xFF2E3A4D),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
    );
    return _build(scheme, Brightness.dark);
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final text = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      switchTheme: isDark
          ? null
          : SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return AppTheme.beige;
                }
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.ivory;
                }
                return AppTheme.olive;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.olive;
                }
                return AppTheme.sage;
              }),
              trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // A shade apart from the page so headers stand out.
        backgroundColor: isDark ? headerDark : headerLight,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.15,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        disabledColor: scheme.surfaceContainer,
        labelStyle: GoogleFonts.figtree(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: GoogleFonts.figtree(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        height: 72,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.figtree(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        elevation: 1,
        focusElevation: 2,
        hoverElevation: 2,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        extendedTextStyle: GoogleFonts.figtree(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.figtree(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.figtree(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          disabledBackgroundColor: scheme.surfaceContainerHigh,
          disabledForegroundColor: scheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: GoogleFonts.figtree(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: GoogleFonts.figtree(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: GoogleFonts.figtree(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.secondary,
          textStyle: GoogleFonts.figtree(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.primary,
        contentTextStyle: GoogleFonts.figtree(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.secondary,
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.figtree(
          fontSize: 13,
          color: scheme.onSurfaceVariant,
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
        elevation: const WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        ),
        hintStyle: WidgetStatePropertyAll(
          GoogleFonts.figtree(color: scheme.onSurfaceVariant),
        ),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.figtree(color: scheme.onSurface, fontWeight: FontWeight.w500),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.secondary,
        linearTrackColor: scheme.secondaryContainer,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return TextTheme(
      displayLarge: GoogleFonts.nunito(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: base,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: base,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      displaySmall: GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: base,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: base,
      ),
      headlineSmall: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: base,
      ),
      titleLarge: GoogleFonts.figtree(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: base,
      ),
      titleMedium: GoogleFonts.figtree(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: base,
      ),
      titleSmall: GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: base,
      ),
      bodyLarge: GoogleFonts.figtree(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: base,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: base,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.figtree(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      labelLarge: GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: base,
      ),
      labelMedium: GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: base,
      ),
      labelSmall: GoogleFonts.figtree(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: muted,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Brand palette that follows the active theme. Get it with
/// `AppTheme.colors(context)`.
class CivicColors {
  const CivicColors({
    required this.isDark,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.olive,
    required this.sage,
    required this.page,
    required this.raised,
    required this.card,
    required this.subtle,
    required this.subtleBorder,
    required this.beige,
    required this.burgundy,
    required this.burgundyInk,
    required this.burgundySoft,
    required this.onBurgundyMuted,
    required this.shadow,
  });

  final bool isDark;

  /// Main text and icons.
  final Color ink;

  /// Secondary text and icons.
  final Color inkMuted;

  /// Disabled or past items.
  final Color inkFaint;

  /// Forest green accent (text, icons, filled buttons).
  final Color olive;

  /// Soft green background behind green icons and chips.
  final Color sage;

  /// Screen background (ivory in light).
  final Color page;

  /// Raised surfaces like the nav bar (warm cream in light).
  final Color raised;

  /// Cards and tiles (white in light).
  final Color card;

  /// Inset boxes inside cards.
  final Color subtle;
  final Color subtleBorder;

  /// Muted beige for borders and stones.
  final Color beige;

  /// Burgundy for filled banners and buttons (white text on top).
  final Color burgundy;

  /// Burgundy for text and icons on a normal surface.
  final Color burgundyInk;

  /// Light burgundy tint behind burgundy icons.
  final Color burgundySoft;

  /// Secondary text on a burgundy fill.
  final Color onBurgundyMuted;

  final Color shadow;

  static const light = CivicColors(
    isDark: false,
    ink: AppTheme.ink,
    inkMuted: AppTheme.inkMuted,
    inkFaint: Color(0xFFB7AFA4),
    olive: AppTheme.olive,
    sage: AppTheme.sage,
    page: AppTheme.ivory,
    raised: AppTheme.warmCream,
    card: Colors.white,
    subtle: Color(0xFFF7F2EA),
    subtleBorder: Color(0xFFE4DDD2),
    beige: AppTheme.beige,
    burgundy: AppTheme.burgundy,
    burgundyInk: AppTheme.burgundy,
    burgundySoft: Color(0xFFF3E6EA),
    onBurgundyMuted: Color(0xFFF3D5DC),
    shadow: Color(0x14000000),
  );

  static const dark = CivicColors(
    isDark: true,
    ink: AppTheme.textDark,
    inkMuted: AppTheme.mutedDark,
    inkFaint: Color(0xFF6E7888),
    olive: AppTheme.leafDark,
    sage: Color(0xFF244536),
    page: AppTheme.paperDark,
    raised: AppTheme.raisedDark,
    card: AppTheme.raisedDark,
    subtle: Color(0xFF222E40),
    subtleBorder: Color(0xFF2E3A4D),
    beige: Color(0xFF4A566A),
    burgundy: Color(0xFF7A454A),
    burgundyInk: Color(0xFFD9A3A8),
    burgundySoft: Color(0xFF3A2A31),
    onBurgundyMuted: Color(0xFFEBCAD0),
    shadow: Color(0x40000000),
  );
}
