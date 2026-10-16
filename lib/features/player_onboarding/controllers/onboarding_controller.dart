import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/session.dart';
import '../data/api_profile_repository.dart';
import '../data/level_estimator.dart';
import '../data/location_services.dart';
import '../data/onboarding_state.dart';
import '../data/onboarding_store.dart';
import '../data/profile_repository.dart';

// Backends of the player onboarding. Swap the fakes for the API implementations here.
final onboardingStoreProvider = Provider<OnboardingStore>((ref) => LocalOnboardingStore());
final levelEstimatorProvider = Provider<LevelEstimator>((ref) => const FakeLevelEstimator());
final devicePermissionsProvider =
    Provider<DevicePermissions>((ref) => const SystemPermissions());
final zoneDirectoryProvider = Provider<ZoneDirectory>((ref) => const FakeZoneDirectory());
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ApiProfileRepository(ref.read(apiClientProvider), userId: () => ref.read(sessionProvider)),
);

/// The onboarding answers, loaded from the device and saved after every change.
class OnboardingController extends AsyncNotifier<PlayerOnboardingState> {
  OnboardingStore get _store => ref.read(onboardingStoreProvider);

  @override
  Future<PlayerOnboardingState> build() async =>
      await _store.load() ?? const PlayerOnboardingState();

  PlayerOnboardingState get current => state.value ?? const PlayerOnboardingState();

  Future<void> _update(PlayerOnboardingState Function(PlayerOnboardingState s) change) async {
    final next = change(current);
    state = AsyncData(next);
    await _store.save(next);
  }

  /// Remembers the screen to resume on.
  Future<void> visit(String route) async {
    if (current.lastRoute == route) return;
    await _update((s) => s.copyWith(lastRoute: route));
  }

  Future<void> toggleSport(MuSport sport) => _update((s) {
        final sports = [...s.sports];
        if (!sports.remove(sport)) sports.add(sport);
        return s.copyWith(sports: sports);
      });

  Future<void> answer(MuSport sport, String question, String value) => _update((s) {
        final answers = {...s.answers};
        answers[sport] = {...?answers[sport], question: value};
        return s.copyWith(answers: answers);
      });

  /// Stores the estimate; the confirmed level starts on it.
  Future<void> saveEstimate(MuSport sport, LevelEstimate estimate) => _update((s) => s.copyWith(
        estimates: {...s.estimates, sport: estimate},
        levels: {...s.levels, sport: estimate.level},
      ));

  Future<void> setLevel(MuSport sport, double level) =>
      _update((s) => s.copyWith(levels: {...s.levels, sport: level}));

  Future<void> setPosition(MuSport sport, String position) =>
      _update((s) => s.copyWith(positions: {...s.positions, sport: position}));

  Future<void> toggleSlot(String slot) => _update((s) {
        final slots = {...s.availability};
        if (!slots.remove(slot)) slots.add(slot);
        return s.copyWith(availability: slots);
      });

  /// After the location prompt: granted adds the current district to the zones.
  Future<void> setLocation({required bool granted, String? area}) => _update((s) => s.copyWith(
        locationGranted: granted,
        area: area,
        zones: granted && area != null && !s.zones.contains(area) ? [area, ...s.zones] : null,
      ));

  Future<void> addZone(String zone) => _update(
      (s) => s.zones.contains(zone) ? s : s.copyWith(zones: [...s.zones, zone]));

  Future<void> removeZone(String zone) =>
      _update((s) => s.copyWith(zones: s.zones.where((z) => z != zone).toList()));

  Future<void> toggleZone(String zone) =>
      current.zones.contains(zone) ? removeZone(zone) : addZone(zone);

  Future<void> setRadius(int km) => _update((s) => s.copyWith(radiusKm: km));

  Future<void> setNotifications({required bool granted}) =>
      _update((s) => s.copyWith(notificationsGranted: granted));

  Future<void> setProfile({String? pseudo, String? fullName}) =>
      _update((s) => s.copyWith(pseudo: pseudo, fullName: fullName));

  Future<void> complete() => _update((s) => s.copyWith(completed: true));

  Future<void> markTourSeen() => _update((s) => s.copyWith(tourSeen: true));

  Future<void> reset() async {
    state = const AsyncData(PlayerOnboardingState());
    await _store.clear();
  }
}

final onboardingProvider =
    AsyncNotifierProvider<OnboardingController, PlayerOnboardingState>(OnboardingController.new);

/// The current answers, or the empty state while loading.
extension OnboardingWatch on WidgetRef {
  PlayerOnboardingState watchOnboarding() =>
      watch(onboardingProvider).value ?? const PlayerOnboardingState();

  OnboardingController get onboarding => read(onboardingProvider.notifier);
}

/// The picked profile photo. Kept in memory until the profile is uploaded (no backend yet).
class ProfilePhotoController extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;

  void set(Uint8List? bytes) => state = bytes;
}

final profilePhotoProvider =
    NotifierProvider<ProfilePhotoController, Uint8List?>(ProfilePhotoController.new);
