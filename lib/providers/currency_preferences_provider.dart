import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/currency_formatter.dart';
import '../utils/supported_currencies.dart';

/// Home currency for a signed-in account (Hive cache + Firestore).
///
/// Changing home currency does **not** rewrite existing item prices.
class CurrencyPreferencesProvider extends ChangeNotifier {
  CurrencyPreferencesProvider({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _boxName = 'currency_prefs';

  final FirebaseFirestore _firestore;
  Box<String>? _box;
  String? _userId;
  String _homeCurrencyCode = SupportedCurrencies.defaultCode;
  bool _ready = false;

  String get homeCurrencyCode => _homeCurrencyCode;
  String get homeCurrencySymbol =>
      SupportedCurrencies.symbolFor(_homeCurrencyCode);
  bool get isReady => _ready;
  String? get userId => _userId;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    _ready = true;
    _applyFormatter();
    notifyListeners();
  }

  void bindUser(String? uid) {
    if (_userId == uid) return;
    _userId = uid;
    _loadLocal();
    if (uid != null) {
      // Fire-and-forget remote sync.
      _pullRemote(uid);
    }
  }

  void _loadLocal() {
    final uid = _userId;
    if (uid == null || _box == null) {
      _homeCurrencyCode = SupportedCurrencies.defaultCode;
      _applyFormatter();
      notifyListeners();
      return;
    }
    final code = _box!.get(_key(uid));
    _homeCurrencyCode = (code != null && SupportedCurrencies.isSupported(code))
        ? code.toUpperCase()
        : SupportedCurrencies.defaultCode;
    _applyFormatter();
    notifyListeners();
  }

  Future<void> _pullRemote(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('prefs')
          .get();
      final code = snap.data()?['homeCurrencyCode'] as String?;
      if (code != null &&
          SupportedCurrencies.isSupported(code) &&
          code.toUpperCase() != _homeCurrencyCode) {
        _homeCurrencyCode = code.toUpperCase();
        await _box?.put(_key(uid), _homeCurrencyCode);
        _applyFormatter();
        notifyListeners();
      } else if (code == null) {
        // Seed remote from local/default once.
        await _pushRemote(uid, _homeCurrencyCode);
      }
    } catch (_) {
      // Offline: keep local.
    }
  }

  Future<void> setHomeCurrency(String code) async {
    final normalized = code.toUpperCase();
    if (!SupportedCurrencies.isSupported(normalized)) return;
    _homeCurrencyCode = normalized;
    _applyFormatter();
    notifyListeners();

    final uid = _userId;
    if (uid != null) {
      await _box?.put(_key(uid), normalized);
      await _pushRemote(uid, normalized);
    }
  }

  Future<void> _pushRemote(String uid, String code) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('prefs')
          .set(
        {
          'homeCurrencyCode': code,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Offline: Hive already updated.
    }
  }

  void _applyFormatter() {
    CurrencyFormatter.configure(
      code: _homeCurrencyCode,
      symbol: SupportedCurrencies.symbolFor(_homeCurrencyCode),
      decimalDigits: SupportedCurrencies.decimalDigitsFor(_homeCurrencyCode),
    );
  }

  String _key(String uid) => 'home_$uid';
}
