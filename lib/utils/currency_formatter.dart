import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _format = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  static String format(num? amount) {
    if (amount == null) return '—';
    return _format.format(amount.round());
  }

  static String formatUsedBudget(num used, num budget) {
    return '${format(used)} / ${format(budget)}';
  }

  static String percent(double value) {
    if (value.isNaN || value.isInfinite) return '0%';
    return '${(value * 100).round()}%';
  }
}
