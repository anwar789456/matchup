import 'package:sqflite/sqflite.dart';

import '../../../core/connectivity.dart';
import '../../../core/db/app_database.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../booking/data/teammates_repository.dart';
import '../../common/data/story_data.dart';
import 'search_repository.dart';
import 'tournaments_repository.dart';

/// [TournamentsRepository] on the phone's database (`tournois`), soonest first.
class SqliteTournamentsRepository implements TournamentsRepository {
  SqliteTournamentsRepository(this._database, {bool Function()? offline})
      : _offline = offline ?? (() => false);

  final AppDatabase _database;
  final bool Function() _offline;

  static Future<void> seed(DatabaseExecutor db) async {
    final t = Story.padelMasters;
    await db.insert('tournois', {
      'id': t.id,
      'sport': t.sport.name,
      'nom': t.name,
      'debut': t.start.toIso8601String(),
      'fin': t.end.toIso8601String(),
      'etablissement': t.venue,
      'lieu': t.place,
      'frais_equipe': t.feePerTeam,
      'dotation': t.prize,
      'equipes_total': t.teamsTotal,
      'equipes_inscrites': t.teamsRegistered,
      'niveau_min': t.levelMin,
      'niveau_max': t.levelMax,
    });
  }

  @override
  Future<List<MuTournament>> nearby() async {
    if (_offline()) throw const OfflineException();
    return [
      // The app's own tournaments (Tournois module) count their validated teams and hide while
      // drafted or cancelled; the story's demo rows keep their numbers.
      for (final r in await (await _database.db).rawQuery('''
        SELECT t.*, CASE WHEN t.organisateur_id IS NULL THEN t.equipes_inscrites ELSE (
          SELECT COUNT(*) FROM tournoi_equipes e JOIN tournoi_decisions d ON d.equipe_id = e.id
          WHERE e.tournoi_id = t.id AND e.annulee = 0 AND d.statut = 'confirmee') END AS inscrites
        FROM tournois t
        WHERE t.statut NOT IN ('brouillon', 'annule')
        ORDER BY t.debut'''))
        MuTournament(
          id: r['id']! as String,
          sport: MuSport.values.byName(r['sport']! as String),
          name: r['nom']! as String,
          start: DateTime.parse(r['debut']! as String),
          end: DateTime.parse(r['fin']! as String),
          venue: r['etablissement']! as String,
          place: r['lieu']! as String,
          feePerTeam: r['frais_equipe']! as num,
          prize: r['dotation'] as num?,
          teamsTotal: r['equipes_total']! as int,
          teamsRegistered: r['inscrites']! as int,
          levelMin: (r['niveau_min'] as num?)?.toDouble(),
          levelMax: (r['niveau_max'] as num?)?.toDouble(),
        ),
    ];
  }
}

/// [SearchRepository] on the phone's database: districts (`zones`, with their venues in
/// `zone_etablissements`; `autour` = everything around the player's zone) and players
/// (`joueurs_recherche`).
class SqliteSearchRepository implements SearchRepository {
  const SqliteSearchRepository(this._database);

  final AppDatabase _database;

  static Future<void> seed(DatabaseExecutor db) async {
    for (final (i, (name, ids)) in Story.zones.indexed) {
      await db.insert('zones', {'nom': name, 'position': i, 'autour': ids == null ? 1 : 0});
      for (final id in ids ?? const <String>[]) {
        await db.insert('zone_etablissements', {'zone': name, 'etablissement_id': id});
      }
    }
    for (final (i, p) in Story.players.indexed) {
      await db.insert('joueurs_recherche',
          {'nom': p.name, 'niveau': p.level, 'lieu': p.place, 'position': i});
    }
  }

  @override
  Future<List<ZoneHit>> zones() async {
    final db = await _database.db;
    final venues = <String, List<String>>{};
    for (final r in await db.query('zone_etablissements')) {
      (venues[r['zone']! as String] ??= []).add(r['etablissement_id']! as String);
    }
    return [
      for (final r in await db.query('zones', orderBy: 'position'))
        ZoneHit(
          name: r['nom']! as String,
          venueIds: r['autour'] == 1 ? null : venues[r['nom']] ?? const [],
        ),
    ];
  }

  @override
  Future<List<PlayerHit>> players() async => [
        for (final r in await (await _database.db).query('joueurs_recherche', orderBy: 'position'))
          PlayerHit(
            name: r['nom']! as String,
            level: (r['niveau']! as num).toDouble(),
            place: r['lieu']! as String,
          ),
      ];
}

/// [TeammatesRepository] on the phone's database (`coequipiers`), most games together first.
class SqliteTeammatesRepository implements TeammatesRepository {
  const SqliteTeammatesRepository(this._database);

  final AppDatabase _database;

  static Future<void> seed(DatabaseExecutor db) async {
    for (final (i, t) in Story.teammates.indexed) {
      await db.insert('coequipiers', {
        'nom': t.name,
        'niveau': t.level,
        'poste': t.position,
        'matchs_ensemble': t.together,
        'position': i,
      });
    }
  }

  @override
  Future<List<Teammate>> suggested(String venueId) async => [
        for (final r in await (await _database.db)
            .query('coequipiers', orderBy: 'matchs_ensemble DESC, position'))
          Teammate(
            name: r['nom']! as String,
            level: (r['niveau']! as num).toDouble(),
            position: r['poste']! as String,
            gamesTogether: r['matchs_ensemble']! as int,
          ),
      ];
}
