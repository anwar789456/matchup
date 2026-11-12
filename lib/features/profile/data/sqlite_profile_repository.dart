import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../theme/theme.dart';
import '../../common/data/story_data.dart';
import 'profile_repository.dart';
import 'sqlite_me_repository.dart';

/// [PlayerProfileRepository] on the phone's database: what the player edits (PRF-04) in the
/// `profil_joueur` row, the players they follow in `joueurs_suivis`, their level adjustments and
/// disputes in `niveaux_ajustes`. Stats, badges and reviews are the story's.
class SqlitePlayerProfileRepository implements PlayerProfileRepository {
  SqlitePlayerProfileRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  static Map<String, Object?> rowOf(PlayerProfile p) => _row(p);

  static Map<String, Object?> _row(PlayerProfile p) => {
        'id': 1,
        'pseudo': p.handle,
        'bio': p.bio,
        'sports': jsonEncode([for (final s in p.sports) s.name]),
        'postes': jsonEncode({for (final e in p.positions.entries) e.key.name: e.value}),
        'zones': jsonEncode(p.zones),
        'visibilite': p.visibility.name,
        'montrer_niveau': p.showLevel ? 1 : 0,
        'montrer_fiabilite': p.showReliability ? 1 : 0,
        'suggerer_partenaire': p.suggestPartner ? 1 : 0,
      };

  static Future<void> seed(DatabaseExecutor db) =>
      db.insert('profil_joueur', _row(FakePlayerProfileRepository.yassine));

  @override
  Future<PlayerProfile> me() async {
    final db = await _db;
    final r = (await db.query('profil_joueur')).single;
    final identity = await accountIdentity(db);
    return FakePlayerProfileRepository.yassine.copyWith(
      name: identity?.displayName,
      handle: r['pseudo']! as String,
      bio: r['bio']! as String,
      sports: [
        for (final s in jsonDecode(r['sports']! as String) as List) MuSport.values.byName(s as String),
      ],
      positions: {
        for (final e in (jsonDecode(r['postes']! as String) as Map).entries)
          MuSport.values.byName(e.key as String): e.value as String,
      },
      zones: [for (final z in jsonDecode(r['zones']! as String) as List) z as String],
      visibility: ProfileVisibility.values.byName(r['visibilite']! as String),
      showLevel: r['montrer_niveau'] == 1,
      showReliability: r['montrer_fiabilite'] == 1,
      suggestPartner: r['suggerer_partenaire'] == 1,
    );
  }

  @override
  Future<PlayerProfile> player(String name) async {
    if (name == Story.myName) return me();
    final followed = await (await _db)
        .query('joueurs_suivis', where: 'nom = ?', whereArgs: [name]);
    return FakePlayerProfileRepository.skander.copyWith(followed: followed.isNotEmpty);
  }

  @override
  Future<void> save(PlayerProfile profile) async {
    await (await _db).insert('profil_joueur', _row(profile),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> follow(String name, {required bool follow}) async {
    final db = await _db;
    if (follow) {
      await db.insert('joueurs_suivis', {'nom': name, 'suivi_le': DateTime.now().toIso8601String()},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('joueurs_suivis', where: 'nom = ?', whereArgs: [name]);
    }
  }

  @override
  Future<LevelExplanation> explain(MuSport sport) async =>
      FakePlayerProfileRepository.storyExplanation;

  Future<void> _level(MuSport sport, Map<String, Object?> values) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final updated = await txn.update('niveaux_ajustes', {...values, 'le': now},
          where: 'sport = ?', whereArgs: [sport.name]);
      if (updated == 0) {
        await txn.insert('niveaux_ajustes', {'sport': sport.name, ...values, 'le': now});
      }
    });
  }

  /// A self-assessment, confirmed by the next 3 matches.
  @override
  Future<void> adjustLevel(MuSport sport, double level) => _level(sport, {'niveau': level});

  @override
  Future<void> contestLevel(MuSport sport) => _level(sport, {'conteste': 1});
}
