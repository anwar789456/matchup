import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
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
}

final trainingProgressProvider =
    AsyncNotifierProvider<TrainingProgressController, TrainingProgress>(
      TrainingProgressController.new,
    );
