import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const defaultCategoryNames = <String>[
    'Petrol',
    'Food',
    'Subscriptions',
    'Cigarette',
    'Miscellaneous',
  ];

  static const defaultCategoryColors = <String, Color>{
    'Petrol': Color(0xFF7C6CF0),
    'Food': Color(0xFFFF9F0A),
    'Subscriptions': Color(0xFFBF5AF2),
    'Cigarette': Color(0xFFFF453A),
    'Miscellaneous': Color(0xFF30D158),
  };

  static const fallbackCategoryColors = <Color>[
    Color(0xFF9B8AFB),
    Color(0xFFFF9F0A),
    Color(0xFFBF5AF2),
    Color(0xFFFF453A),
    Color(0xFF30D158),
    Color(0xFF64D2FF),
    Color(0xFFFFD60A),
    Color(0xFFFF375F),
  ];

  static String colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Color colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return Color(value);
  }

  static Color colorForCategory(String name, int index) {
    return defaultCategoryColors[name] ??
        fallbackCategoryColors[index % fallbackCategoryColors.length];
  }
}
