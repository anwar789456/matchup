import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_state.dart';

/// Where the onboarding progress is kept between launches.
abstract interface class OnboardingStore {
  Future<PlayerOnboardingState?> load();

  Future<void> save(PlayerOnboardingState state);

  Future<void> clear();
}

/// Keeps the progress on the device (shared_preferences), as JSON.
class LocalOnboardingStore implements OnboardingStore {
  static const _key = 'player_onboarding.v1';

  @override
  Future<PlayerOnboardingState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return PlayerOnboardingState.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> save(PlayerOnboardingState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// For tests.
class MemoryOnboardingStore implements OnboardingStore {
  MemoryOnboardingStore([this.state]);

  PlayerOnboardingState? state;

  @override
  Future<PlayerOnboardingState?> load() async => state;

  @override
  Future<void> save(PlayerOnboardingState state) async => this.state = state;

  @override
  Future<void> clear() async => state = null;
}
