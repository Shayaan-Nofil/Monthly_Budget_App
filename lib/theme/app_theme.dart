import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// iOS-inspired theme with a lavender accent.
class AppTheme {
  AppTheme._();

  static const _accent = Color(0xFF9B8AFB);
  static const _overspend = Color(0xFFFF453A);
  static const _success = Color(0xFF30D158);

  static Color get accent => _accent;
  static Color get overspend => _overspend;
  static Color get success => _success;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.light,
        primary: _accent,
        error: _overspend,
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: _accent,
        brightness: Brightness.light,
      ),
    );
    return _applyText(base);
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.dark,
        primary: _accent,
        error: _overspend,
      ),
      scaffoldBackgroundColor: const Color(0xFF000000),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: _accent,
        brightness: Brightness.dark,
      ),
    );
    return _applyText(base);
  }

  static ThemeData _applyText(ThemeData base) {
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
        elevation: 0,
        color: base.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: base.brightness == Brightness.light
            ? const Color(0xF0F9F9F9)
            : const Color(0xF01C1C1E),
        indicatorColor: _accent.withValues(alpha: 0.18),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerColor: base.brightness == Brightness.light
          ? const Color(0xFFC6C6C8)
          : const Color(0xFF38383A),
    );
  }
}
