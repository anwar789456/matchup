import 'package:sqflite/sqflite.dart';

import '../../../core/connectivity.dart';
import '../../../core/db/app_database.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import 'games_repository.dart';

/// [GamesRepository] on the phone's database: open and published games in `parties` (with
/// `places_liberees` for the places freed since), their players in `partie_joueurs`, and the
/// player's place or waitlist spot in `participations`. Line-ups, chat and the AI's reasons come
/// from [FakeGamesRepository.detailsOf].
class SqliteGamesRepository implements GamesRepository {
  SqliteGamesRepository(this._database, {bool Function()? offline})
      : _offline = offline ?? (() => false);

  final AppDatabase _database;
  final bool Function() _offline;

  Future<Database> get _db async {
    if (_offline()) throw const OfflineException();
    return _database.db;
  }

  static Map<String, Object?> _row(MuGame g, int position, {int? recommended, bool published = false}) => {
        'id': g.id,
        'etablissement_id': g.venueId,
        'sport': g.sport.name,
        'etablissement': g.venue,
        'terrain': g.court,
        'lieu': g.place,
        'distance_km': g.distanceKm,
        'debut': g.start.toIso8601String(),
        'places_total': g.spotsTotal,
        'places_restantes': g.spotsLeft,
        'prix_joueur': g.pricePerPlayer,
        'type_partie': g.gameType,
        'niveau_min': g.levelMin,
        'niveau_max': g.levelMax,
        'date_libelle': g.dateLabel,
        'organisateur': g.organiser,
        'fiabilite_organisateur': g.organiserReliability,
        'compatibilite': g.matchFit,
        'raison_compatibilite': g.matchFitReason,
        'statut': g.status.name,
        'remboursement': g.refund,
        'recommandee': recommended,
        'publiee': published ? 1 : 0,
        'position': position,
      };

  static Future<void> _insert(
    DatabaseExecutor db,
    MuGame g,
    int position, {
    int? recommended,
    bool published = false,
  }) async {
    await db.insert('parties', _row(g, position, recommended: recommended, published: published));
    for (final (i, p) in g.players.indexed) {
      await db.insert('partie_joueurs', {'partie_id': g.id, 'position': i, 'nom': p.name});
    }
  }

  /// The story's open games; G1 and G2 are « Parties pour toi ».
  static Future<void> seed(DatabaseExecutor db) async {
    for (final (i, g) in Story.openGames.indexed) {
      final rank = g.id == Story.g1.id ? 1 : (g.id == Story.g2.id ? 2 : null);
      await _insert(db, g, i, recommended: rank);
    }
  }

  /// The stored games of [rows], as the story wrote them (before the player's changes).
  static Future<List<(MuGame, int)>> _read(DatabaseExecutor db, List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r['id']! as String];
    final players = <String, List<MuPerson>>{};
    for (final p in await db.query(
      'partie_joueurs',
      where: 'partie_id IN (${List.filled(ids.length, '?').join(', ')})',
      whereArgs: ids,
      orderBy: 'position',
    )) {
      (players[p['partie_id']! as String] ??= []).add(MuPerson(p['nom']! as String));
    }
    return [
      for (final r in rows)
        (
          MuGame(
            id: r['id']! as String,
            venueId: r['etablissement_id'] as String?,
            sport: MuSport.values.byName(r['sport']! as String),
            venue: r['etablissement']! as String,
            court: r['terrain'] as String?,
            place: r['lieu']! as String,
            distanceKm: (r['distance_km'] as num?)?.toDouble(),
            start: DateTime.parse(r['debut']! as String),
            spotsTotal: r['places_total']! as int,
            spotsLeft: r['places_restantes']! as int,
            pricePerPlayer: r['prix_joueur']! as num,
            gameType: r['type_partie']! as String,
            levelMin: (r['niveau_min'] as num?)?.toDouble(),
            levelMax: (r['niveau_max'] as num?)?.toDouble(),
            dateLabel: r['date_libelle'] as String?,
            players: players[r['id']] ?? const [],
            organiser: r['organisateur'] as String?,
            organiserReliability: r['fiabilite_organisateur'] as int?,
            matchFit: r['compatibilite'] as int?,
            matchFitReason: r['raison_compatibilite'] as String?,
            status: MuGameStatus.values.byName(r['statut']! as String),
            refund: r['remboursement'] as num?,
          ),
          r['places_liberees']! as int,
        ),
    ];
  }

  Future<Map<String, Map<String, Object?>>> _participations(DatabaseExecutor db) async => {
        for (final p in await db.query('participations')) p['partie_id']! as String: p,
      };

  /// [rows] as the player sees them now.
  Future<List<MuGame>> _current(DatabaseExecutor db, List<Map<String, Object?>> rows) async {
    final mine = await _participations(db);
    return [
      for (final (g, freed) in await _read(db, rows))
        FakeGamesRepository.current(
          g,
          joined: mine[g.id]?['statut'] == 'inscrit',
          freed: freed,
        ),
    ];
  }

  @override
  Future<List<MuGame>> openGames() async {
    final db = await _db;
    return _current(db, await db.query('parties', orderBy: 'position'));
  }

  @override
  Future<List<MuGame>> recommended() async {
    final db = await _db;
    return _current(
      db,
      await db.query('parties', where: 'recommandee IS NOT NULL', orderBy: 'recommandee'),
    );
  }

  @override
  Future<void> publish(MuGame game) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      final last = Sqflite.firstIntValue(await txn.rawQuery('SELECT MAX(position) FROM parties'));
      await _insert(txn, game, (last ?? -1) + 1, published: true);
    });
  }

  @override
  Future<List<MuGame>> joined() async {
    final db = await _database.db;
    return _current(
      db,
      await db.rawQuery(
        "SELECT p.* FROM parties p JOIN participations m ON m.partie_id = p.id "
        "WHERE m.statut = 'inscrit' ORDER BY p.position",
      ),
    );
  }

  @override
  Future<GameDetails> details(String id) async {
    final db = await _db;
    final rows = await db.query('parties', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw StateError('Partie introuvable : $id');
    final (base, freed) = (await _read(db, rows)).single;
    final m = (await _participations(db))[id];
    final team = m?['equipe'] as int?;
    final place = m?['place'] as int?;
    return FakeGamesRepository.detailsOf(
      base,
      membership: switch (m?['statut']) {
        'inscrit' => GameMembership.joined,
        'attente' => GameMembership.waitlisted,
        _ => GameMembership.none,
      },
      freed: freed,
      slot: team == null || place == null ? null : (team, place),
      waitlistPosition: m?['position_attente'] as int?,
    );
  }

  Future<void> _participate(String id, Map<String, Object?> values) async {
    await (await _database.db).insert(
      'participations',
      {'partie_id': id, ...values, 'le': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _withdraw(String id) async =>
      (await _database.db).delete('participations', where: 'partie_id = ?', whereArgs: [id]);

  @override
  Future<void> join(String id, {required int team, required int slot}) =>
      _participate(id, {'statut': 'inscrit', 'equipe': team, 'place': slot});

  @override
  Future<void> leave(String id) => _withdraw(id);

  @override
  Future<void> joinWaitlist(String id) => _participate(
        id,
        {'statut': 'attente', 'position_attente': FakeGamesRepository.waitlistStart},
      );

  @override
  Future<void> leaveWaitlist(String id) => _withdraw(id);

  Future<void> _freed(String id, int delta) async => (await _database.db).rawUpdate(
        'UPDATE parties SET places_liberees = places_liberees + ? WHERE id = ?',
        [delta, id],
      );

  @override
  Future<void> freeSpot(String id) => _freed(id, 1);

  @override
  Future<void> playerJoined(String id) => _freed(id, -1);
}
