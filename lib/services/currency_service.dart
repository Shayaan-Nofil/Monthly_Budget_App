import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:currency_converter/currency.dart';
import 'package:currency_converter/currency_converter.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Converts amounts with Hive-backed rate cache for offline reuse.
class CurrencyService {
  CurrencyService();

  static const _boxName = 'fx_rate_cache';
  static const _cacheTtl = Duration(hours: 24);

  Box<String>? _box;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    _ready = true;
  }

  /// Returns converted amount, or `null` if conversion is unavailable.
  Future<double?> convertAmount({
    required String from,
    required String to,
    required double amount,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    await init();
    final fromCode = from.toUpperCase();
    final toCode = to.toUpperCase();
    if (fromCode == toCode) return amount;

    final cachedRate = _readCachedRate(fromCode, toCode);
    final online = await _hasNetwork();

    if (online) {
      try {
        final converted = await CurrencyConverter.convert(
          from: _currencyFromCode(fromCode),
          to: _currencyFromCode(toCode),
          amount: amount,
          withoutRounding: true,
        ).timeout(timeout);
        if (converted != null) {
          final rate = amount == 0 ? 0.0 : converted / amount;
          await _writeCachedRate(fromCode, toCode, rate);
          return converted;
        }
      } on TimeoutException {
        // fall through to cache
      } on SocketException {
        // fall through to cache
      } catch (_) {
        // fall through to cache
      }
    }

    if (cachedRate != null) {
      return amount * cachedRate;
    }
    return null;
  }

  Future<bool> _hasNetwork() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Currency _currencyFromCode(String code) {
    final lc = code.trim().toLowerCase();
    final aliases = {
      'try': 'turkisL',
      'rmb': 'cny',
    };
    final normalized = aliases[lc] ?? lc;
    for (final c in Currency.values) {
      if (c.name.toLowerCase() == normalized) return c;
    }
    throw ArgumentError('Unsupported currency code: $code');
  }

  double? _readCachedRate(String from, String to) {
    final box = _box;
    if (box == null) return null;
    final raw = box.get(_key(from, to));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final rate = (map['rate'] as num?)?.toDouble();
      final atMs = map['at'] as int?;
      if (rate == null || atMs == null) return null;
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(atMs),
      );
      // Prefer fresh rates when online path failed; still allow stale offline.
      if (age > _cacheTtl * 7) return rate; // keep usable offline for a week
      return rate;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedRate(String from, String to, double rate) async {
    final box = _box;
    if (box == null) return;
    await box.put(
      _key(from, to),
      jsonEncode({
        'rate': rate,
        'at': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    // Also cache inverse for convenience.
    if (rate != 0) {
      await box.put(
        _key(to, from),
        jsonEncode({
          'rate': 1 / rate,
          'at': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    }
  }

  String _key(String from, String to) => '${from}_$to';
}
