import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../ui/ui.dart';
import 'training_models.dart';
import 'training_repository.dart';
import 'training_story.dart';

/// [TrainingRepository] on the phone's database (schema v3): programs joined in
/// `entrainement_inscriptions`, sessions done in `entrainement_seances`, the streak and the plan
/// card in `entrainement_profil`. The catalogue itself is the story's content until the
/// entrainement API serves it.
class SqliteTrainingRepository implements TrainingRepository {
  SqliteTrainingRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  static Map<String, Object?> _resultRow(LessonResult r) => {
    'programme': r.programId,
    'seance': r.index,
    'faite_le': r.doneAt.toIso8601String(),
    'minutes': r.minutes,
    'exercices_faits': r.drillsDone,
    'exercices_total': r.drillsTotal,
    'reussis': r.reps,
    'objectif': r.target,
    'ressenti': r.feeling?.name,
    'notes': r.notes,
  };

  static LessonResult _result(Map<String, Object?> r) => LessonResult(
    programId: r['programme']! as String,
    index: r['seance']! as int,
    doneAt: DateTime.parse(r['faite_le']! as String),
    minutes: r['minutes']! as int,
    drillsDone: r['exercices_faits']! as int,
    drillsTotal: r['exercices_total']! as int,
    reps: r['reussis'] as int?,
    target: r['objectif'] as int?,
    feeling: r['ressenti'] == null ? null : LessonFeeling.values.byName(r['ressenti']! as String),
    notes: r['notes'] as String?,
  );

  /// Bandeja joined on lun. 5 oct., sessions 1 to 4 done, 6 weeks in a row.
  static Future<void> seed(DatabaseExecutor db) async {
    await db.insert('entrainement_inscriptions', {
      'programme': 'bandeja',
      'inscrit_le': TrainingStory.bandejaJoined.toIso8601String(),
    });
    for (final r in TrainingStory.doneSessions) {
      await db.insert('entrainement_seances', _resultRow(r));
    }
    await db.insert('entrainement_profil', {
      'id': 1,
      'serie_semaines': TrainingStory.streakBefore,
      'objectif_semaine': TrainingStory.weeklyGoal,
      'plan_masque': 0,
    });
  }

  @override
  Future<List<TrainingProgram>> programs() async => TrainingStory.programs;

  @override
  Future<List<MuCoach>> coaches() async => TrainingStory.coaches;

  @override
  Future<TrainingProgress> progress() async {
    final db = await _db;
    final enrolled = await db.query('entrainement_inscriptions');
    final results = await db.query('entrainement_seances', orderBy: 'faite_le');
    final profile = (await db.query('entrainement_profil')).single;
    return TrainingProgress(
      enrolled: {
        for (final r in enrolled)
          r['programme']! as String: DateTime.parse(r['inscrit_le']! as String),
      },
      results: results.map(_result).toList(),
      streakBefore: profile['serie_semaines']! as int,
      weeklyGoal: profile['objectif_semaine']! as int,
      planCardHidden: profile['plan_masque'] == 1,
    );
  }

  @override
  Future<TrainingProgress> enroll(String programId) async {
    await (await _db).insert(
      'entrainement_inscriptions',
      {'programme': programId, 'inscrit_le': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return progress();
  }

  @override
  Future<TrainingProgress> completeLesson(LessonResult result) async {
    await (await _db).insert(
      'entrainement_seances',
      _resultRow(result),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return progress();
  }

  @override
  Future<TrainingProgress> rateLesson(String programId, int index, LessonFeeling feeling) async {
    await (await _db).update(
      'entrainement_seances',
      {'ressenti': feeling.name},
      where: 'programme = ? AND seance = ?',
      whereArgs: [programId, index],
    );
    return progress();
  }

  @override
  Future<TrainingProgress> hidePlanCard() async {
    await (await _db).update('entrainement_profil', {'plan_masque': 1});
    return progress();
  }
}
