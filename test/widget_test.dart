import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_budget_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App themes build without error', (tester) async {
    expect(AppTheme.light(), isA<ThemeData>());
    expect(AppTheme.dark(), isA<ThemeData>());
  });
}
