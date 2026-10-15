import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Where the pro onboarding drafts (owner, coach, organiser) are kept between sessions, as JSON
/// maps under a key. The wizard saves after every change.
abstract interface class DraftStore {
  Future<Map<String, Object?>?> load(String key);

  Future<void> save(String key, Map<String, Object?> json);

  Future<void> clear(String key);
}

/// Keeps the drafts on the device (shared_preferences; localStorage on the web).
class LocalDraftStore implements DraftStore {
  const LocalDraftStore();

  @override
  Future<Map<String, Object?>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, Object?>;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> save(String key, Map<String, Object?> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(json));
  }

  @override
  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

/// For tests.
class MemoryDraftStore implements DraftStore {
  final Map<String, Map<String, Object?>> drafts = {};

  @override
  Future<Map<String, Object?>?> load(String key) async => drafts[key];

  @override
  Future<void> save(String key, Map<String, Object?> json) async =>
      drafts[key] = jsonDecode(jsonEncode(json)) as Map<String, Object?>;

  @override
  Future<void> clear(String key) async => drafts.remove(key);
}
