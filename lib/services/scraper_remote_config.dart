import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Gates the Gemini receipt-scraper via Remote Config.
///
/// Parameters (Firebase console):
/// - [scraper_enabled] bool — master switch
/// - [scraper_allowlist] JSON string, e.g. `{"email_list":["a@x.com","b@y.com"]}`
///
/// Rules:
/// - enabled == false → nobody
/// - enabled == true + empty allowlist → everybody
/// - enabled == true + non-empty allowlist → only listed emails
class ScraperRemoteConfig {
  ScraperRemoteConfig({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const enabledKey = 'scraper_enabled';
  static const allowlistKey = 'scraper_allowlist';

  final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );
    // Fail closed until a successful fetch says otherwise.
    await _remoteConfig.setDefaults(const {
      enabledKey: false,
      allowlistKey: '{"email_list":[]}',
    });
    await fetch();
    _initialized = true;
  }

  Future<void> fetch() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e, st) {
      debugPrint('Remote Config fetch failed: $e\n$st');
    }
  }

  bool get scraperEnabled => _remoteConfig.getBool(enabledKey);

  /// Parsed allowlist emails (lowercase). Empty ⇒ no restriction when enabled.
  Set<String> get allowlistEmails =>
      _parseAllowlist(_remoteConfig.getString(allowlistKey));

  /// Whether [email] may use the Gemini receipt scraper.
  bool isScraperAllowedFor(String? email) {
    if (!scraperEnabled) return false;
    final allowlist = allowlistEmails;
    if (allowlist.isEmpty) return true;
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return allowlist.contains(normalized);
  }

  /// Expects `{"email_list":["a@x.com","b@y.com"]}`.
  static Set<String> _parseAllowlist(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return {};

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return {};
      final listValue = decoded['email_list'];
      if (listValue is! List) return {};
      return listValue
          .map((e) => e.toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('Invalid scraper_allowlist JSON: $e');
      return {};
    }
  }
}
