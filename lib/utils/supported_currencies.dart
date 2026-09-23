/// Supported fiat currencies for home currency + item entry.
class SupportedCurrencies {
  SupportedCurrencies._();

  static const defaultCode = 'PKR';

  /// ISO code → display symbol
  static const Map<String, String> symbols = {
    'PKR': 'Rs.',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'SAR': '﷼',
    'INR': '₹',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'CHF': 'CHF',
    'JPY': '¥',
    'CNY': '¥',
    'TRY': '₺',
    'SGD': 'S\$',
  };

  static List<String> get codes => symbols.keys.toList(growable: false);

  static String symbolFor(String code) =>
      symbols[code.toUpperCase()] ?? code.toUpperCase();

  static bool isSupported(String code) =>
      symbols.containsKey(code.toUpperCase());

  static int decimalDigitsFor(String code) {
    switch (code.toUpperCase()) {
      case 'PKR':
      case 'JPY':
        return 0;
      default:
        return 2;
    }
  }
}
