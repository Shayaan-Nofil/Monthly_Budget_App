import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// iOS-inspired theme. Default primary matches the app icon green.
class AppTheme {
  AppTheme._();

  /// Dominant green from `assets/images/budget_icon.png`.
  static const Color defaultPrimary = Color(0xFF24905C);
  static const Color overspend = Color(0xFFFF453A);
  static const Color success = Color(0xFF30D158);

  /// Alias kept for call sites that mean "brand default", not the live theme.
  static Color get accent => defaultPrimary;

  static ThemeData light({Color? primary}) {
    final accent = primary ?? defaultPrimary;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        error: overspend,
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: accent,
        brightness: Brightness.light,
      ),
    );
    return _applyText(base, accent);
  }

  static ThemeData dark({Color? primary}) {
    final accent = primary ?? defaultPrimary;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        primary: accent,
        error: overspend,
      ),
      scaffoldBackgroundColor: const Color(0xFF000000),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: accent,
        brightness: Brightness.dark,
      ),
    );
    return _applyText(base, accent);
  }

  static ThemeData _applyText(ThemeData base, Color accent) {
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: base.colorScheme.onSurface,
      displayColor: base.colorScheme.onSurface,
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: base.colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(
          alpha: base.brightness == Brightness.light ? 0.18 : 0.55,
        ),
        color: base.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: base.brightness == Brightness.light
            ? const Color(0xF0F9F9F9)
            : const Color(0xF01C1C1E),
        indicatorColor: accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerColor: base.brightness == Brightness.light
          ? const Color(0xFFC6C6C8)
          : const Color(0xFF38383A),
    );
  }
}
