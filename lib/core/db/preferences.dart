import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Small values kept in the `preferences` table (key → text): the signed-in account, the theme,
/// the language, the notification pause… Replaces shared_preferences.
class Preferences {
  const Preferences(this._database);

  final AppDatabase _database;

  Future<String?> get(String key) async {
    final rows = await (await _database.db)
        .query('preferences', columns: ['valeur'], where: 'cle = ?', whereArgs: [key]);
    return rows.firstOrNull?['valeur'] as String?;
  }

  /// Stores [value] under [key]; null removes it.
  Future<void> set(String key, String? value) async {
    final db = await _database.db;
    if (value == null) {
      await db.delete('preferences', where: 'cle = ?', whereArgs: [key]);
    } else {
      await db.insert('preferences', {'cle': key, 'valeur': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
