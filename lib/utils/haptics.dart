import 'package:flutter/services.dart';

/// Centralized haptic feedback for taps and important actions.
class AppHaptics {
  AppHaptics._();

  /// Standard button / list / card tap.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Destructive or heavier actions (delete, sign out).
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Segmented controls, tabs, toggles, color chips.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Successful save / create.
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// Failed action or validation error.
  static Future<void> error() => HapticFeedback.heavyImpact();
}
