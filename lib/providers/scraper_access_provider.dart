import 'package:flutter/foundation.dart';

import '../services/scraper_remote_config.dart';

/// Exposes whether the signed-in account may use Gemini receipt import.
class ScraperAccessProvider extends ChangeNotifier {
  ScraperAccessProvider({ScraperRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? ScraperRemoteConfig();

  final ScraperRemoteConfig _remoteConfig;
  String? _email;
  bool _ready = false;

  bool get isReady => _ready;

  /// True when Remote Config allows the Gemini scraper for the current user.
  bool get isScraperAllowed => _remoteConfig.isScraperAllowedFor(_email);

  Future<void> initialize() async {
    await _remoteConfig.initialize();
    _ready = true;
    notifyListeners();
  }

  void bindEmail(String? email) {
    final next = email?.trim();
    if (next == _email) return;
    _email = next;
    notifyListeners();
  }

  /// Re-fetch Remote Config (respects minimum fetch interval in release).
  Future<void> refresh() async {
    await _remoteConfig.fetch();
    notifyListeners();
  }
}
