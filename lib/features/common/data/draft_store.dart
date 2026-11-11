import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';

/// Where the pro onboarding drafts (owner, coach, organiser) are kept between sessions, as JSON
/// maps under a key. The wizard saves after every change.
abstract interface class DraftStore {
  Future<Map<String, Object?>?> load(String key);

  Future<void> save(String key, Map<String, Object?> json);

  Future<void> clear(String key);
}

/// Keeps the drafts in the `brouillons` table (key, JSON content, last change).
class SqliteDraftStore implements DraftStore {
  const SqliteDraftStore(this._database);

  final AppDatabase _database;

  @override
  Future<Map<String, Object?>?> load(String key) async {
    final rows = await (await _database.db)
        .query('brouillons', columns: ['contenu'], where: 'cle = ?', whereArgs: [key]);
    final raw = rows.firstOrNull?['contenu'] as String?;
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
    await (await _database.db).insert(
      'brouillons',
      {'cle': key, 'contenu': jsonEncode(json), 'maj_le': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear(String key) async {
    await (await _database.db).delete('brouillons', where: 'cle = ?', whereArgs: [key]);
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
