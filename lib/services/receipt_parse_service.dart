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
}

/// Gemini Flash-Lite parse of OCR text → expense draft fields.
class ReceiptParseService {
  ReceiptParseService({GenerativeModel? model}) : _model = model;

  GenerativeModel? _model;

  static const _modelId = 'gemini-2.5-flash-lite';

  GenerativeModel _requireModel() {
    if (!ApiKeys.hasGeminiKey) {
      throw StateError(
        'Missing Gemini API key. Paste it in lib/config/api_keys.dart '
        'or run with --dart-define=GEMINI_API_KEY=...',
      );
    }
    return _model ??= GenerativeModel(
      model: _modelId,
      apiKey: ApiKeys.gemini,
      generationConfig: GenerationConfig(
        temperature: 0,
        maxOutputTokens: 120,
        responseMimeType: 'application/json',
      ),
    );
  }

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
    final currencyList = SupportedCurrencies.codes.join('|');

    final prompt =
        'Extract expense fields from receipt OCR. Return ONLY JSON:\n'
        '{"name":string|null,"total":number|null,"category":string|null,'
        '"date":"YYYY-MM-DD"|null,"currencyCode":string|null}\n'
        'Rules: total=amount paid; name=merchant; category must be one of '
        '[$categoryList] or null; currencyCode one of [$currencyList] or null '
        '(default would be $homeCurrencyCode); date null if unknown.\n'
        'OCR:\n$trimmed';

    final response = await _requireModel().generateContent([
      Content.text(prompt),
    ]);
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

  /// Keep head + tail so merchant (top) and totals (bottom) survive.
  String _truncateOcr(String text, {int maxChars = 1600}) {
    final t = text.trim();
    if (t.length <= maxChars) return t;
    const head = 800;
    const tail = 800;
    return '${t.substring(0, head)}\n...\n${t.substring(t.length - tail)}';
  }
}
