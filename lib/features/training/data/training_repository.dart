import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../ui/ui.dart';
import 'sqlite_training_repository.dart';
import 'training_models.dart';
import 'training_story.dart';

/// The Entraînement tab's data (ENT-01…09). Programs and coaches will come from the
/// `entrainement` API (backend/apps/entrainement); the player's progress stays on the phone.
abstract interface class TrainingRepository {
  Future<List<TrainingProgram>> programs();
  Future<List<MuCoach>> coaches();
  Future<TrainingProgress> progress();

  /// « S’inscrire au programme » (ENT-03).
  Future<TrainingProgress> enroll(String programId);

  /// « Marquer comme fait » on the last exercise (ENT-04 → ENT-05).
  Future<TrainingProgress> completeLesson(LessonResult result);

  /// « Comment c’était ? » (ENT-05).
  Future<TrainingProgress> rateLesson(String programId, int index, LessonFeeling feeling);

  /// « Plus tard » on the AI plan card (ENT-01).
  Future<TrainingProgress> hidePlanCard();
}

/// The story in memory, for widget tests.
class FakeTrainingRepository implements TrainingRepository {
  FakeTrainingRepository({this.latency = Duration.zero});

  final Duration latency;

  TrainingProgress _progress = TrainingProgress(
    enrolled: {'bandeja': TrainingStory.bandejaJoined},
    results: TrainingStory.doneSessions,
    streakBefore: TrainingStory.streakBefore,
    weeklyGoal: TrainingStory.weeklyGoal,
  );

  Future<T> _wait<T>(T value) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return value;
  }

  @override
  Future<List<TrainingProgram>> programs() => _wait(TrainingStory.programs);

  @override
  Future<List<MuCoach>> coaches() => _wait(TrainingStory.coaches);

  @override
  Future<TrainingProgress> progress() => _wait(_progress);

  @override
  Future<TrainingProgress> enroll(String programId) => _wait(
    _progress = _progress.copyWith(
      enrolled: {..._progress.enrolled, programId: DateTime.now()},
    ),
  );

  @override
  Future<TrainingProgress> completeLesson(LessonResult result) => _wait(
    _progress = _progress.copyWith(
      results: [
        for (final r in _progress.results)
          if (r.programId != result.programId || r.index != result.index) r,
        result,
      ],
    ),
  );

  @override
  Future<TrainingProgress> rateLesson(String programId, int index, LessonFeeling feeling) =>
      _wait(
        _progress = _progress.copyWith(
          results: [
            for (final r in _progress.results)
              r.programId == programId && r.index == index ? r.copyWith(feeling: feeling) : r,
          ],
        ),
      );

  @override
  Future<TrainingProgress> hidePlanCard() =>
      _wait(_progress = _progress.copyWith(planCardHidden: true));
}

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => SqliteTrainingRepository(ref.watch(appDatabaseProvider)),
);
