import '../../common/data/draft_store.dart';
import 'onboarding_state.dart';

/// Where the onboarding progress is kept between launches.
abstract interface class OnboardingStore {
  Future<PlayerOnboardingState?> load();

  Future<void> save(PlayerOnboardingState state);

  Future<void> clear();
}

/// Keeps the progress as JSON in the `brouillons` table, through [DraftStore].
class DraftOnboardingStore implements OnboardingStore {
  const DraftOnboardingStore(this._drafts);

  final DraftStore _drafts;
  static const _key = 'player_onboarding.v1';

  @override
  Future<PlayerOnboardingState?> load() async {
    final json = await _drafts.load(_key);
    if (json == null) return null;
    try {
      return PlayerOnboardingState.fromJson(json);
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> save(PlayerOnboardingState state) => _drafts.save(_key, state.toJson());

  @override
  Future<void> clear() => _drafts.clear(_key);
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
