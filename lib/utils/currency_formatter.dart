import 'package:intl/intl.dart';

import 'supported_currencies.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String _code = SupportedCurrencies.defaultCode;
  static String _symbol = SupportedCurrencies.symbolFor(_code);
  static int _decimalDigits = SupportedCurrencies.decimalDigitsFor(_code);

  static String get code => _code;
  static String get symbol => _symbol;

  static void configure({
    required String code,
    required String symbol,
    int? decimalDigits,
  }) {
    _code = code.toUpperCase();
    _symbol = symbol;
    _decimalDigits =
        decimalDigits ?? SupportedCurrencies.decimalDigitsFor(_code);
  }

  static NumberFormat get _format => NumberFormat.currency(
        locale: 'en',
        symbol: '$_symbol ',
        decimalDigits: _decimalDigits,
      );

  static String format(num? amount) {
    if (amount == null) return '—';
    if (_decimalDigits == 0) {
      return _format.format(amount.round());
    }
    return _format.format(amount);
  }

  static String formatIn(String currencyCode, num? amount) {
    if (amount == null) return '—';
    final code = currencyCode.toUpperCase();
    final digits = SupportedCurrencies.decimalDigitsFor(code);
    final f = NumberFormat.currency(
      locale: 'en',
      symbol: '${SupportedCurrencies.symbolFor(code)} ',
      decimalDigits: digits,
    );
    if (digits == 0) return f.format(amount.round());
    return f.format(amount);
  }

  static String formatUsedBudget(num used, num budget) {
    return '${format(used)} / ${format(budget)}';
  }

  static String percent(double value) {
    if (value.isNaN || value.isInfinite) return '0%';
    return '${(value * 100).round()}%';
  }
}
