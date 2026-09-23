import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/currency_preferences_provider.dart';
import '../providers/theme_preferences_provider.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import '../utils/supported_currencies.dart';
import '../widgets/primary_color_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themePrefs = context.watch<ThemePreferencesProvider>();
    final currencyPrefs = context.watch<CurrencyPreferencesProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Currency',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: theme.cardTheme.color,
            elevation: 4,
            shadowColor: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.5 : 0.14,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Home currency',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New expenses convert into this currency. Changing it does not rewrite existing amounts.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(currencyPrefs.homeCurrencyCode),
                    initialValue: currencyPrefs.homeCurrencyCode,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                    ),
                    items: [
                      for (final code in SupportedCurrencies.codes)
                        DropdownMenuItem(
                          value: code,
                          child: Text(
                            '$code (${SupportedCurrencies.symbolFor(code)})',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      AppHaptics.selection();
                      currencyPrefs.setHomeCurrency(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Appearance',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: theme.cardTheme.color,
            elevation: 4,
            shadowColor: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.5 : 0.14,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Primary color',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saved on this device for your account only.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryColorPicker(
                    color: themePrefs.primary,
                    onChanged: (color) {
                      themePrefs.setPrimary(color);
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        AppHaptics.light();
                        themePrefs.resetPrimary();
                      },
                      child: const Text('Reset to icon green'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: theme.cardTheme.color,
            elevation: 4,
            shadowColor: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.5 : 0.14,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.defaultPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Default is the green from the app icon.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
