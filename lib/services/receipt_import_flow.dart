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
import '../widgets/receipt_import_progress.dart';

/// Scan → OCR → Gemini (best-effort) → open [AddEditItemScreen].
class ReceiptImportFlow {
  ReceiptImportFlow._();

  static Future<void> start({
    required BuildContext context,
    required Month month,
  }) async {
    AppHaptics.light();

    final scanner = ReceiptScanService();
    List<String> paths;
    try {
      paths = await scanner.scanReceipts(maxPages: 1);
    } catch (e) {
      if (context.mounted) {
        AppHaptics.error();
        _toast(context, 'Could not open scanner: $e');
      }
      return;
    }
    if (!context.mounted) return;
    if (paths.isEmpty) return;

    final imagePath = paths.first;
    final home = context.read<CurrencyPreferencesProvider>().homeCurrencyCode;
    final categoryId = _resolveCategoryId(month, null);
    if (categoryId == null) {
      AppHaptics.error();
      _toast(context, 'Add a category to this month first.');
      return;
    }

    final progress = await ReceiptImportProgressDialog.show(context);
    progress.setImagePath(imagePath);
    progress.setStep(ReceiptImportStep.reading);

    void closeProgress() {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    ParsedReceipt parsed = const ParsedReceipt();
    var geminiFailed = false;

    try {
      final ocrText = await OcrService().extractLineByLine(imagePath);
      if (!context.mounted) return;

      if (ApiKeys.hasGeminiKey && ocrText.trim().isNotEmpty) {
        progress.setStep(ReceiptImportStep.understanding);
        try {
          parsed = await ReceiptParseService().parse(
            ocrText: ocrText,
            categoryNames: month.categories.map((c) => c.name).toList(),
            homeCurrencyCode: home,
          );
        } catch (_) {
          // Timeout / overload / parse errors — continue with a blank draft.
          geminiFailed = true;
          parsed = const ParsedReceipt();
        }
      } else if (!ApiKeys.hasGeminiKey) {
        geminiFailed = true;
      }

      if (!context.mounted) return;
      progress.setStep(ReceiptImportStep.finishing);
      closeProgress();

      final resolvedCategoryId =
          _resolveCategoryId(month, parsed.category) ?? categoryId;

      final currency = (parsed.currencyCode != null &&
              SupportedCurrencies.isSupported(parsed.currencyCode!))
          ? parsed.currencyCode!
          : home;

      if (geminiFailed) {
        AppHaptics.medium();
        _toast(
          context,
          parsed.hasAnyField
              ? 'Opened with partial details — please review.'
              : 'Couldn’t auto-fill from AI — enter the details yourself.',
        );
      } else {
        AppHaptics.success();
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddEditItemScreen(
            monthId: month.id,
            categoryId: resolvedCategoryId,
            draftName: parsed.name,
            draftAmount: parsed.total,
            draftCurrency: currency,
            draftDate: parsed.date ?? DateTime.now(),
            initialLocalReceiptPath: imagePath,
          ),
        ),
      );
    } catch (e) {
      // OCR or unexpected failure — still open Add item with the photo.
      if (!context.mounted) return;
      closeProgress();
      AppHaptics.medium();
      _toast(
        context,
        'Opened Add item with your receipt — fill in the details.',
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddEditItemScreen(
            monthId: month.id,
            categoryId: categoryId,
            draftCurrency: home,
            draftDate: DateTime.now(),
            initialLocalReceiptPath: imagePath,
          ),
        ),
      );
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
