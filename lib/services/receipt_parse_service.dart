import 'dart:async';
import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/api_keys.dart';
import '../utils/constants.dart';
import '../utils/supported_currencies.dart';

class ParsedReceipt {
  const ParsedReceipt({
    this.name,
    this.total,
    this.category,
    this.date,
    this.currencyCode,
  });

  final String? name;
  final double? total;
  final String? category;
  final DateTime? date;
  final String? currencyCode;

  bool get hasAnyField =>
      (name != null && name!.isNotEmpty) ||
      total != null ||
      category != null ||
      date != null ||
      currencyCode != null;
}

/// Gemini Flash-Lite parse of OCR text → expense draft fields.
class ReceiptParseService {
  ReceiptParseService({GenerativeModel? model}) : _model = model;

  GenerativeModel? _model;

  /// Alias tracks the current lite tier; 2.5-flash-lite is retired for new keys.
  static const _modelId = 'gemini-3.5-flash-lite';

  /// Don't block the user for a minute when the API is queued / overloaded.
  static const _timeout = Duration(seconds: 60);

  GenerativeModel _requireModel() {
    if (!ApiKeys.hasGeminiKey) {
      throw StateError('Missing Gemini API key');
    }
    return _model ??= GenerativeModel(
      model: _modelId,
      apiKey: ApiKeys.gemini,
      generationConfig: GenerationConfig(
        temperature: 0,
        maxOutputTokens: 100,
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Returns a [ParsedReceipt], or throws on hard failures.
  /// Callers should catch and continue with a blank draft.
  Future<ParsedReceipt> parse({
    required String ocrText,
    required List<String> categoryNames,
    required String homeCurrencyCode,
  }) async {
    final trimmed = _truncateOcr(ocrText);
    if (trimmed.isEmpty) {
      return const ParsedReceipt();
    }

    final categories = categoryNames.isEmpty
        ? AppConstants.defaultCategoryNames
        : categoryNames;
    final categoryList = categories.join('|');

    // Keep the prompt tiny — output is only ~50 tokens.
    final prompt =
        'OCR→JSON only. Keys: name,total,category,date,currencyCode. '
        'category∈[$categoryList]|null. date=YYYY-MM-DD|null. '
        'currency=ISO3|null (home=$homeCurrencyCode). total=number paid.\n'
        '$trimmed';

    final response = await _requireModel()
        .generateContent([Content.text(prompt)])
        .timeout(_timeout);

    final raw = response.text?.trim() ?? '';
    if (raw.isEmpty) return const ParsedReceipt();

    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final data = jsonDecode(cleaned) as Map<String, dynamic>;

    DateTime? date;
    final dateRaw = data['date']?.toString();
    if (dateRaw != null && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw);
    }

    String? currency = data['currencyCode']?.toString().toUpperCase();
    if (currency != null && !SupportedCurrencies.isSupported(currency)) {
      currency = null;
    }

    String? category = data['category']?.toString();
    if (category != null) {
      category = _matchCategory(category, categories);
    }

    return ParsedReceipt(
      name: data['name']?.toString().trim(),
      total: (data['total'] as num?)?.toDouble(),
      category: category,
      date: date,
      currencyCode: currency,
    );
  }

  String? _matchCategory(String raw, List<String> categories) {
    final needle = raw.trim().toLowerCase();
    for (final c in categories) {
      if (c.toLowerCase() == needle) return c;
    }
    for (final c in categories) {
      final lower = c.toLowerCase();
      if (lower.contains(needle) || needle.contains(lower)) return c;
    }
    return null;
  }

  /// Merchant is usually at the top, totals at the bottom.
  String _truncateOcr(String text, {int maxChars = 900}) {
    final t = text.trim();
    if (t.length <= maxChars) return t;
    const head = 450;
    const tail = 450;
    return '${t.substring(0, head)}\n...\n${t.substring(t.length - tail)}';
  }
}
