import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Per-user primary color, stored only on device (Hive), not Firebase.
class ThemePreferencesProvider extends ChangeNotifier {
  ThemePreferencesProvider();

  static const _boxName = 'theme_prefs';

  Box<String>? _box;
  String? _userId;
  Color _primary = AppTheme.defaultPrimary;
  bool _ready = false;

  Color get primary => _primary;
  bool get isReady => _ready;
  String? get userId => _userId;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    _ready = true;
    _loadForCurrentUser();
  }

  /// Call when auth uid changes. Signed-out users get the icon default.
  void bindUser(String? uid) {
    if (_userId == uid) return;
    _userId = uid;
    _loadForCurrentUser();
  }

  void _loadForCurrentUser() {
    final uid = _userId;
    if (uid == null || _box == null) {
      _primary = AppTheme.defaultPrimary;
      notifyListeners();
      return;
    }
    final hex = _box!.get(_key(uid));
    _primary = hex == null || hex.isEmpty
        ? AppTheme.defaultPrimary
        : AppConstants.colorFromHex(hex);
    notifyListeners();
  }

  Future<void> setPrimary(Color color) async {
    _primary = color;
    notifyListeners();
    final uid = _userId;
    final box = _box;
    if (uid == null || box == null) return;
    await box.put(_key(uid), AppConstants.colorToHex(color));
  }

  Future<void> resetPrimary() async {
    await setPrimary(AppTheme.defaultPrimary);
  }

  String _key(String uid) => 'primary_$uid';
}
