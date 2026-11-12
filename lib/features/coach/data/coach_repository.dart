import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import 'coach_models.dart';
import 'coach_story.dart';

/// The coach space's data (COA-04…12). Students, earnings and stats are the story's until the
/// backend serves them; what the coach does — the draft program, todos handled, feedback sent —
/// is kept on the phone and synced (coach_brouillons, coach_actions, coach_retours).
abstract interface class CoachRepository {
  Future<List<CoachStudent>> students();

  /// Ids of the « À traiter » items already handled (plus `ai-suggestion` when dismissed).
  Future<Set<String>> handled();
  Future<void> handle(String id);

  /// The program being written (null once deleted).
  Future<ProgramDraft?> draft();
  Future<void> saveDraft(ProgramDraft draft);
  Future<void> deleteDraft();

  /// The feedback sent on a student's video (null: not yet).
  Future<CoachFeedback?> feedback(String studentId);
  Future<void> sendFeedback(CoachFeedback feedback);
}

/// The story in memory, for widget tests.
class FakeCoachRepository implements CoachRepository {
  final Set<String> _handled = {};
  ProgramDraft? _draft = CoachStory.draft;
  final Map<String, CoachFeedback> _feedback = {};

  @override
  Future<List<CoachStudent>> students() async => CoachStory.students;

  @override
  Future<Set<String>> handled() async => {..._handled};

  @override
  Future<void> handle(String id) async => _handled.add(id);

  @override
  Future<ProgramDraft?> draft() async => _draft;

  @override
  Future<void> saveDraft(ProgramDraft draft) async => _draft = draft;

  @override
  Future<void> deleteDraft() async => _draft = null;

  @override
  Future<CoachFeedback?> feedback(String studentId) async => _feedback[studentId];

  @override
  Future<void> sendFeedback(CoachFeedback feedback) async =>
      _feedback[feedback.studentId] = feedback;
}

/// [CoachRepository] on the phone's database (schema v5).
class SqliteCoachRepository implements CoachRepository {
  SqliteCoachRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  /// The draft « Jeu au filet en 4 semaines » as it stands on ven. 16 oct.
  static Future<void> seed(DatabaseExecutor db) => db.insert('coach_brouillons', {
    'id': CoachStory.draft.id,
    'contenu': jsonEncode(CoachStory.draft.toJson()),
    'modifie_le': CoachStory.draft.updatedAt.toIso8601String(),
    'supprime': 0,
  });

  @override
  Future<List<CoachStudent>> students() async => CoachStory.students;

  @override
  Future<Set<String>> handled() async => {
    for (final r in await (await _db).query('coach_actions')) r['cle']! as String,
  };

  @override
  Future<void> handle(String id) async => (await _db).insert('coach_actions', {
    'cle': id,
    'faite_le': DateTime.now().toIso8601String(),
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  @override
  Future<ProgramDraft?> draft() async {
    final rows = await (await _db).query(
      'coach_brouillons',
      where: 'supprime = 0',
      orderBy: 'modifie_le DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProgramDraft.fromJson(
      (jsonDecode(rows.single['contenu']! as String) as Map).cast<String, Object?>(),
    );
  }

  @override
  Future<void> saveDraft(ProgramDraft draft) async => (await _db).insert('coach_brouillons', {
    'id': draft.id,
    'contenu': jsonEncode(draft.toJson()),
    'modifie_le': draft.updatedAt.toIso8601String(),
    'supprime': 0,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> deleteDraft() async =>
      (await _db).update('coach_brouillons', {'supprime': 1}, where: 'supprime = 0');

  @override
  Future<CoachFeedback?> feedback(String studentId) async {
    final rows = await (await _db).query(
      'coach_retours',
      where: 'eleve = ?',
      whereArgs: [studentId],
    );
    if (rows.isEmpty) return null;
    final r = rows.single;
    return CoachFeedback(
      studentId: studentId,
      comments: [
        for (final c in jsonDecode(r['commentaires']! as String) as List)
          VideoComment.fromJson((c as Map).cast()),
      ],
      message: r['message']! as String,
      askNewVideo: r['nouvelle_video'] == 1,
      sentAt: DateTime.parse(r['envoye_le']! as String),
    );
  }

  @override
  Future<void> sendFeedback(CoachFeedback feedback) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('coach_retours', {
        'eleve': feedback.studentId,
        'commentaires': jsonEncode([for (final c in feedback.comments) c.toJson()]),
        'message': feedback.message,
        'nouvelle_video': feedback.askNewVideo ? 1 : 0,
        'envoye_le': (feedback.sentAt ?? DateTime.now()).toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('coach_actions', {
        'cle': 'video-${feedback.studentId}',
        'faite_le': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
  }
}

final coachRepositoryProvider = Provider<CoachRepository>(
  (ref) => SqliteCoachRepository(ref.watch(appDatabaseProvider)),
);
