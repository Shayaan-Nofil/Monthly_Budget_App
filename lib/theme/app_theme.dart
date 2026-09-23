import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// iOS-inspired theme. Surfaces are explicitly tinted from the seed color
/// (Material 3 `surface` alone is nearly white/black and looks unchanged).
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
    return _build(accent: accent, brightness: Brightness.light);
  }

  static ThemeData dark({Color? primary}) {
    final accent = primary ?? defaultPrimary;
    return _build(accent: accent, brightness: Brightness.dark);
  }

  static ThemeData _build({
    required Color accent,
    required Brightness brightness,
  }) {
    final isLight = brightness == Brightness.light;
    final seeded = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      error: overspend,
    );

    // Blend seed into neutrals so the page background visibly follows primary.
    final baseNeutral = isLight ? const Color(0xFFF7F7F7) : const Color(0xFF101010);
    final surface = _tint(baseNeutral, accent, isLight ? 0.07 : 0.11);
    final surfaceLow = _tint(
      isLight ? Colors.white : const Color(0xFF1A1A1A),
      accent,
      isLight ? 0.06 : 0.16,
    );
    final surfaceMid = _tint(
      isLight ? const Color(0xFFF0F0F0) : const Color(0xFF222222),
      accent,
      isLight ? 0.10 : 0.18,
    );
    final surfaceHigh = _tint(
      isLight ? const Color(0xFFE8E8E8) : const Color(0xFF2A2A2A),
      accent,
      isLight ? 0.12 : 0.20,
    );
    final surfaceHighest = _tint(
      isLight ? Colors.white : const Color(0xFF303030),
      accent,
      isLight ? 0.04 : 0.14,
    );

    final scheme = seeded.copyWith(
      surface: surface,
      surfaceDim: _tint(surface, accent, 0.04),
      surfaceBright: surfaceLow,
      surfaceContainerLowest: surfaceLow,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: surfaceMid,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      onSurface: seeded.onSurface,
      onSurfaceVariant: seeded.onSurfaceVariant,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: accent,
        brightness: brightness,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: isLight ? 0.18 : 0.55),
        color: surfaceLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 6,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
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
        backgroundColor: surfaceMid.withValues(alpha: 0.94),
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerColor: scheme.outlineVariant,
      dialogTheme: DialogThemeData(backgroundColor: surfaceHigh),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surfaceHigh),
    );
  }

  static Color _tint(Color base, Color seed, double amount) {
    return Color.alphaBlend(seed.withValues(alpha: amount.clamp(0.0, 1.0)), base);
  }
}
