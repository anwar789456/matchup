import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../ui/ui.dart';
import '../../player_onboarding/controllers/onboarding_controller.dart';
import '../data/training_models.dart';
import '../data/training_repository.dart';

/// The catalogue (ENT-02) and every program page (ENT-03).
final programsProvider = FutureProvider<List<TrainingProgram>>(
  (ref) => ref.watch(trainingRepositoryProvider).programs(),
);

final coachesProvider = FutureProvider<List<MuCoach>>(
  (ref) => ref.watch(trainingRepositoryProvider).coaches(),
);

/// One program by id (null until the catalogue is loaded).
final programProvider = Provider.family<TrainingProgram?, String>(
  (ref, id) => ref.watch(programsProvider).value?.where((p) => p.id == id).firstOrNull,
);

/// Programs joined, sessions done and the weekly streak, shared by ENT-01…05.
class TrainingProgressController extends AsyncNotifier<TrainingProgress> {
  TrainingRepository get _repo => ref.read(trainingRepositoryProvider);

  @override
  Future<TrainingProgress> build() => ref.watch(trainingRepositoryProvider).progress();

  Future<void> _run(Future<TrainingProgress> Function() change) async {
    state = AsyncData(await change());
  }

  Future<void> enroll(String programId) => _run(() => _repo.enroll(programId));

  Future<void> completeLesson(LessonResult result) => _run(() => _repo.completeLesson(result));

  Future<void> rateLesson(String programId, int index, LessonFeeling feeling) =>
      _run(() => _repo.rateLesson(programId, index, feeling));

  Future<void> hidePlanCard() => _run(_repo.hidePlanCard);

  Future<void> acceptPlan(TrainingPlan plan) => _run(() => _repo.acceptPlan(plan));

  Future<void> toggleSaved(String programId) => _run(() => _repo.toggleSaved(programId));

  Future<void> rateProgram(String programId, int stars, String? text) =>
      _run(() => _repo.rateProgram(programId, stars, text));
}

final trainingProgressProvider =
    AsyncNotifierProvider<TrainingProgressController, TrainingProgress>(
      TrainingProgressController.new,
    );

/// ENT-06's answers, kept while the player goes back and forth with ENT-07 (« Modifier »).
/// The days and moment start from the profile's availability (PLY-05: « lun-soir »…).
class PlanRequestController extends Notifier<PlanRequest> {
  static const _dayKeys = ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'];

  @override
  PlanRequest build() {
    final slots = ref.read(onboardingProvider).value?.availability ?? const <String>{};
    if (slots.isEmpty) return PlanRequest.story;
    final evening = slots.where((s) => s.endsWith('-soir')).length;
    final morning = slots.where((s) => s.endsWith('-matin')).length;
    final noon = slots.where((s) => s.endsWith('-aprem')).length;
    final moment = evening >= morning && evening >= noon
        ? DayMoment.evening
        : morning >= noon
        ? DayMoment.morning
        : DayMoment.noon;
    final days = {
      for (final s in slots)
        if (_dayKeys.contains(s.split('-').first)) _dayKeys.indexOf(s.split('-').first) + 1,
    };
    return PlanRequest.story.copyWith(days: days.isEmpty ? null : days, moment: moment);
  }

  void set(PlanRequest r) => state = r;

  void toggleGoal(PlanGoal g) {
    final goals = {...state.goals};
    if (!goals.remove(g)) {
      if (goals.length >= PlanRequest.maxGoals) return;
      goals.add(g);
    }
    state = state.copyWith(goals: goals);
  }

  void toggleDay(int weekday) {
    final days = {...state.days};
    if (!days.remove(weekday)) days.add(weekday);
    state = state.copyWith(days: days);
  }
}

final planRequestProvider = NotifierProvider<PlanRequestController, PlanRequest>(
  PlanRequestController.new,
);

/// The plan on screen (ENT-07): generated from [planRequestProvider], regenerated on demand.
class PlanController extends AsyncNotifier<TrainingPlan> {
  @override
  Future<TrainingPlan> build() => ref
      .read(trainingRepositoryProvider)
      .generatePlan(ref.read(planRequestProvider), ref.read(clockProvider)());

  Future<void> regenerate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> accept() async {
    final plan = state.value;
    if (plan == null) return;
    await ref.read(trainingProgressProvider.notifier).acceptPlan(plan);
  }
}

final planProvider = AsyncNotifierProvider.autoDispose<PlanController, TrainingPlan>(
  PlanController.new,
);
