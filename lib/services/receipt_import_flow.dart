import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_keys.dart';
import '../models/month.dart';
import '../providers/currency_preferences_provider.dart';
import '../screens/add_edit_item_screen.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parse_service.dart';
import '../services/receipt_scan_service.dart';
import '../utils/haptics.dart';
import '../utils/supported_currencies.dart';

/// Scan → OCR → Gemini → open [AddEditItemScreen] prefilled.
class ReceiptImportFlow {
  ReceiptImportFlow._();

  static Future<void> start({
    required BuildContext context,
    required Month month,
  }) async {
    if (!ApiKeys.hasGeminiKey) {
      AppHaptics.error();
      _toast(
        context,
        'Add your Gemini API key in lib/config/api_keys.dart '
        '(or --dart-define=GEMINI_API_KEY=...)',
      );
      return;
    }

    AppHaptics.light();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator.adaptive(),
                  SizedBox(height: 16),
                  Text('Scanning receipt…'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    void closeProgress() {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      final scanner = ReceiptScanService();
      final paths = await scanner.scanReceipts(maxPages: 1);
      if (!context.mounted) return;
      if (paths.isEmpty) {
        closeProgress();
        return;
      }

      final imagePath = paths.first;

      // Update progress label via rebuilding is awkward; keep simple spinner.
      final ocrText = await OcrService().extractLineByLine(imagePath);
      if (!context.mounted) return;

      final home =
          context.read<CurrencyPreferencesProvider>().homeCurrencyCode;
      final categories = month.categories.map((c) => c.name).toList();

      final parsed = await ReceiptParseService().parse(
        ocrText: ocrText,
        categoryNames: categories,
        homeCurrencyCode: home,
      );
      if (!context.mounted) return;
      closeProgress();

      final categoryId = _resolveCategoryId(month, parsed.category);
      if (categoryId == null) {
        AppHaptics.error();
        _toast(context, 'Add a category to this month first.');
        return;
      }

      final currency = (parsed.currencyCode != null &&
              SupportedCurrencies.isSupported(parsed.currencyCode!))
          ? parsed.currencyCode!
          : home;

      AppHaptics.success();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddEditItemScreen(
            monthId: month.id,
            categoryId: categoryId,
            draftName: parsed.name,
            draftAmount: parsed.total,
            draftCurrency: currency,
            draftDate: parsed.date ?? DateTime.now(),
            initialLocalReceiptPath: imagePath,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        closeProgress();
        AppHaptics.error();
        _toast(context, 'Could not import receipt: $e');
      }
    }
  }

  static String? _resolveCategoryId(Month month, String? parsedName) {
    if (month.categories.isEmpty) return null;
    if (parsedName != null) {
      for (final c in month.categories) {
        if (c.name.toLowerCase() == parsedName.toLowerCase()) return c.id;
      }
    }
    for (final c in month.categories) {
      if (c.name.toLowerCase() == 'miscellaneous') return c.id;
    }
    return month.categories.first.id;
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
