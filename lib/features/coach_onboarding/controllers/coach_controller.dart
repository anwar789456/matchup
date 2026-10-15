import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../data/coach_draft.dart';

final coachRepositoryProvider = Provider<CoachRepository>(
  (ref) => FakeCoachRepository(now: ref.read(clockProvider)),
);

/// The coach wizard draft: loaded from the device (or started from the account), saved after
/// every change.
class CoachController extends AsyncNotifier<CoachDraft> {
  static const storeKey = 'coach_onboarding.v1';

  @override
  Future<CoachDraft> build() async {
    final json = await ref.read(draftStoreProvider).load(storeKey);
    if (json != null) {
      try {
        return CoachDraft.fromJson(json);
      } on Object {
        // An older or damaged draft: start again from the account.
      }
    }
    return ref.read(coachRepositoryProvider).start();
  }

  CoachDraft get current => state.requireValue;

  Future<void> edit(CoachDraft Function(CoachDraft d) change) async {
    final next = change(current).copyWith(savedAt: ref.read(clockProvider)());
    state = AsyncData(next);
    await ref.read(draftStoreProvider).save(storeKey, next.toJson());
  }

  Future<void> complete(int step) =>
      edit((d) => d.copyWith(reached: math.max(d.reached, step + 1)));
}

final coachProvider = AsyncNotifierProvider<CoachController, CoachDraft>(CoachController.new);

/// The three steps of the coach onboarding; the third is the dashboard (COA-03).
abstract final class CoachSteps {
  static const all = ['Profil', 'Certification', 'Premier programme'];

  static List<MuWizardStep> of(CoachDraft d, int current) => [
    for (final (i, label) in all.indexed)
      MuWizardStep(label, summary: i < current && i < d.reached ? summary(d, i) : null),
  ];

  static String? summary(CoachDraft d, int step) => switch (step) {
    0 => [if (d.sports.isNotEmpty) CoachCatalog.sportName(d.sports.first), d.city].join(' · '),
    1 => d.diploma == null ? null : 'Diplôme envoyé',
    _ => null,
  };
}
