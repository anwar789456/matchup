import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import 'clients_repository.dart';
import 'owner_drafts.dart';
import 'owner_repository.dart';
import 'reviews_repository.dart';
import 'tariffs_repository.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
String? _iso(DateTime? d) => d?.toIso8601String();

/// [OwnerRepository] on the phone's database: courts (`proprio_terrains`), bookings
/// (`proprio_reservations`) with who arrived, is expected or did not come (`proprio_presences`),
/// and closed slots (`proprio_blocages`).
class SqliteOwnerRepository implements OwnerRepository {
  SqliteOwnerRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  static Map<String, Object?> _courtRow(OwnerCourt c) => {
        'id': c.id,
        'numero': c.number,
        'interieur': c.indoor ? 1 : 0,
        'visible': c.visible ? 1 : 0,
        'maintenance': c.maintenance ? 1 : 0,
      };

  static OwnerCourt _court(Map<String, Object?> r) => OwnerCourt(
        id: r['id']! as String,
        number: r['numero']! as int,
        indoor: r['interieur'] == 1,
        visible: r['visible'] == 1,
        maintenance: r['maintenance'] == 1,
      );

  static Future<void> _insertBooking(DatabaseExecutor db, OwnerBooking b) async {
    await db.insert('proprio_reservations', {
      'ref': b.ref,
      'terrain': b.court,
      'debut': _iso(b.start),
      'heures': b.hours,
      'organisateur': b.organiser,
      'type': b.kind.name,
      'joueurs': b.players,
      'capacite': b.capacity,
      'prix': b.price,
      'paye': b.paid,
      'statut': b.status.name,
      'moi': b.mine ? 1 : 0,
      'type_partie': b.gameType,
      'niveau_min': b.levelMin,
      'niveau_max': b.levelMax,
      'fiabilite': b.reliability,
      'honores': b.honoured,
      'matchs': b.matches,
      'note': b.note,
    });
    await _writePresences(db, b);
  }

  static Future<void> _writePresences(DatabaseExecutor db, OwnerBooking b) async {
    await db.delete('proprio_presences', where: 'ref = ?', whereArgs: [b.ref]);
    for (final (etat, names) in [('arrive', b.arrived), ('attendu', b.expected), ('absent', b.noShows)]) {
      for (final (i, name) in names.indexed) {
        await db.insert('proprio_presences', {'ref': b.ref, 'etat': etat, 'position': i, 'nom': name});
      }
    }
  }

  static Map<String, Object?> _blockRow(OwnerBlock b) => {
        'id': b.id,
        'terrain': b.court,
        'debut': _iso(b.start),
        'fin': _iso(b.end),
        'motif': b.reason.name,
        'note': b.note,
        'hebdo': b.weekly ? 1 : 0,
      };

  static OwnerBlock _block(Map<String, Object?> r) => OwnerBlock(
        id: r['id']! as String,
        court: r['terrain']! as int,
        start: _date(r['debut'])!,
        end: _date(r['fin'])!,
        reason: BlockReason.values.byName(r['motif']! as String),
        note: r['note'] as String?,
        weekly: r['hebdo'] == 1,
      );

  static Future<void> seed(DatabaseExecutor db) async {
    for (final c in FakeOwnerRepository.storyCourts) {
      await db.insert('proprio_terrains', _courtRow(c));
    }
    for (final b in FakeOwnerRepository.storyBookings()) {
      await _insertBooking(db, b);
    }
    for (final b in FakeOwnerRepository.storyBlocks) {
      await db.insert('proprio_blocages', _blockRow(b));
    }
  }

  /// The bookings of [rows] with their presences.
  Future<List<OwnerBooking>> _bookings(DatabaseExecutor db, List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return const [];
    final refs = [for (final r in rows) r['ref']! as String];
    final presences = <(String, String), List<String>>{};
    for (final p in await db.query(
      'proprio_presences',
      where: 'ref IN (${List.filled(refs.length, '?').join(', ')})',
      whereArgs: refs,
      orderBy: 'ref, etat, position',
    )) {
      (presences[(p['ref']! as String, p['etat']! as String)] ??= []).add(p['nom']! as String);
    }
    return [
      for (final r in rows)
        OwnerBooking(
          ref: r['ref']! as String,
          court: r['terrain']! as int,
          start: _date(r['debut'])!,
          hours: r['heures']! as int,
          organiser: r['organisateur']! as String,
          kind: OwnerBookingKind.values.byName(r['type']! as String),
          players: r['joueurs']! as int,
          capacity: r['capacite']! as int,
          price: r['prix']! as num,
          paid: r['paye']! as num,
          status: OwnerBookingStatus.values.byName(r['statut']! as String),
          mine: r['moi'] == 1,
          gameType: r['type_partie']! as String,
          levelMin: (r['niveau_min'] as num?)?.toDouble(),
          levelMax: (r['niveau_max'] as num?)?.toDouble(),
          reliability: r['fiabilite']! as int,
          honoured: r['honores']! as int,
          matches: r['matchs']! as int,
          note: r['note'] as String?,
          arrived: presences[(r['ref'], 'arrive')] ?? const [],
          expected: presences[(r['ref'], 'attendu')] ?? const [],
          noShows: presences[(r['ref'], 'absent')] ?? const [],
        ),
    ];
  }

  static (String, String) _dayRange(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return (_iso(start)!, _iso(start.add(const Duration(days: 1)))!);
  }

  @override
  Future<List<OwnerCourt>> courts() async =>
      [for (final r in await (await _db).query('proprio_terrains', orderBy: 'numero')) _court(r)];

  @override
  Future<OwnerCourt> updateCourt(OwnerCourt court) async {
    await (await _db).update('proprio_terrains', _courtRow(court), where: 'id = ?', whereArgs: [court.id]);
    return court;
  }

  @override
  Future<List<OwnerBooking>> bookingsOn(DateTime day) async {
    final db = await _db;
    final (from, to) = _dayRange(day);
    return _bookings(
      db,
      await db.query(
        'proprio_reservations',
        where: 'debut >= ? AND debut < ? AND statut != ?',
        whereArgs: [from, to, OwnerBookingStatus.cancelled.name],
        orderBy: 'debut, terrain',
      ),
    );
  }

  @override
  Future<List<OwnerBooking>> upcoming(DateTime from) async {
    final db = await _db;
    return _bookings(
      db,
      await db.query(
        'proprio_reservations',
        where: 'debut >= ?',
        whereArgs: [_dayRange(from).$1],
        orderBy: 'debut, terrain',
      ),
    );
  }

  @override
  Future<OwnerBooking?> booking(String ref) async {
    final db = await _db;
    return (await _bookings(
      db,
      await db.query('proprio_reservations', where: 'ref = ?', whereArgs: [ref]),
    ))
        .firstOrNull;
  }

  @override
  Future<List<OwnerBlock>> blocksOn(DateTime day) async {
    final (from, to) = _dayRange(day);
    return [
      for (final r in await (await _db).query('proprio_blocages', orderBy: 'debut'))
        if (_block(r) case final b
            when (_iso(b.start)!.compareTo(from) >= 0 && _iso(b.start)!.compareTo(to) < 0) ||
                (b.weekly && b.start.weekday == day.weekday && !day.isBefore(b.start)))
          b,
    ];
  }

  @override
  Future<OwnerBlock> block({
    required List<int> courts,
    required DateTime start,
    required DateTime end,
    required BlockReason reason,
    String? note,
    bool weekly = false,
  }) async {
    final db = await _db;
    return db.transaction((txn) async {
      final last = Sqflite.firstIntValue(await txn.rawQuery(
        'SELECT MAX(CAST(SUBSTR(id, 2) AS INTEGER)) FROM proprio_blocages',
      ));
      var next = last ?? 0;
      late OwnerBlock created;
      for (final c in courts) {
        created = OwnerBlock(
          id: 'b${++next}',
          court: c,
          start: start,
          end: end,
          reason: reason,
          note: note,
          weekly: weekly,
        );
        await txn.insert('proprio_blocages', _blockRow(created));
      }
      return created;
    });
  }

  @override
  Future<void> unblock(String id) async {
    await (await _db).delete('proprio_blocages', where: 'id = ?', whereArgs: [id]);
  }

  /// Stores a closed slot as Supabase has it (the cache of SupabaseOwnerRepository).
  Future<void> keepBlock(OwnerBlock b) async {
    await (await _db).insert('proprio_blocages', _blockRow(b), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<OwnerBooking> markNoShow(String ref, List<String> players) async {
    final db = await _db;
    return db.transaction((txn) async {
      final b = (await _bookings(
        txn,
        await txn.query('proprio_reservations', where: 'ref = ?', whereArgs: [ref]),
      ))
          .single;
      final next = b.copyWith(
        expected: [
          for (final p in b.expected)
            if (!players.contains(p)) p,
        ],
        noShows: [...b.noShows, ...players],
      );
      await _writePresences(txn, next);
      return next;
    });
  }

  @override
  Future<OwnerBooking> cancel(String ref) async {
    final db = await _db;
    await db.update('proprio_reservations', {'statut': OwnerBookingStatus.cancelled.name},
        where: 'ref = ?', whereArgs: [ref]);
    return (await booking(ref))!;
  }

  @override
  Future<CheckInResult> checkIn(String code, DateTime at) async {
    final c = code.trim().toUpperCase();
    return FakeOwnerRepository.checkInOf(c, at, await booking(c));
  }
}

/// [TariffsRepository] on the phone's database: peak hours in the `tarifs` row, price groups in
/// `tarif_groupes` (their courts in `tarif_groupe_terrains`), `dates_speciales` and `promos`.
class SqliteTariffsRepository implements TariffsRepository {
  SqliteTariffsRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  static Future<void> _write(DatabaseExecutor db, Tariffs t) async {
    await db.insert(
      'tarifs',
      {'id': 1, 'pointe_de': t.peakFrom, 'pointe_a': t.peakTo, 'weekend_pointe': t.weekendPeak ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.delete('tarif_groupes'); // cascades to tarif_groupe_terrains
    for (final (i, p) in t.prices.indexed) {
      await db.insert('tarif_groupes', {
        'id': p.id,
        'interieur': p.indoor ? 1 : 0,
        'prix_creuse': p.offPeak,
        'prix_pointe': p.peak,
        'position': i,
      });
      for (final c in p.courts) {
        await db.insert('tarif_groupe_terrains', {'groupe_id': p.id, 'terrain': c});
      }
    }
    await db.delete('dates_speciales');
    for (final d in t.specialDates) {
      await db.insert('dates_speciales', {
        'id': d.id,
        'jour': _iso(d.day),
        'nom': d.name,
        'pointe_journee': d.allDayPeak ? 1 : 0,
        'de': d.fromHour,
        'a': d.toHour,
        'a_confirmer': d.tentative ? 1 : 0,
      });
    }
    await db.delete('promos');
    for (final p in t.promos) {
      await _insertPromo(db, p);
    }
  }

  static Future<void> _insertPromo(DatabaseExecutor db, OwnerPromo p) => db.insert('promos', {
        'jour_semaine': p.draft.weekday,
        'de': p.draft.fromHour,
        'a': p.draft.toHour,
        'pourcentage': p.draft.percent,
        'prix_avant': p.draft.priceBefore,
        'premier_jour': _iso(p.firstDay),
        'hebdo': p.weekly ? 1 : 0,
      });

  static Future<void> seed(DatabaseExecutor db) => _write(db, FakeTariffsRepository.storyTariffs);

  @override
  Future<Tariffs> load() async {
    final db = await _db;
    final row = (await db.query('tarifs')).single;
    final courts = <String, List<int>>{};
    for (final r in await db.query('tarif_groupe_terrains', orderBy: 'terrain')) {
      (courts[r['groupe_id']! as String] ??= []).add(r['terrain']! as int);
    }
    return Tariffs(
      peakFrom: row['pointe_de']! as int,
      peakTo: row['pointe_a']! as int,
      weekendPeak: row['weekend_pointe'] == 1,
      prices: [
        for (final r in await db.query('tarif_groupes', orderBy: 'position'))
          CourtPrice(
            id: r['id']! as String,
            courts: courts[r['id']] ?? const [],
            indoor: r['interieur'] == 1,
            offPeak: r['prix_creuse']! as num,
            peak: r['prix_pointe']! as num,
          ),
      ],
      specialDates: [
        for (final r in await db.query('dates_speciales', orderBy: 'jour'))
          SpecialDate(
            id: r['id']! as String,
            day: _date(r['jour'])!,
            name: r['nom']! as String,
            allDayPeak: r['pointe_journee'] == 1,
            fromHour: r['de'] as int?,
            toHour: r['a'] as int?,
            tentative: r['a_confirmer'] == 1,
          ),
      ],
      promos: [
        for (final r in await db.query('promos', orderBy: 'id'))
          OwnerPromo(
            draft: PromoDraft(
              weekday: r['jour_semaine']! as int,
              fromHour: r['de']! as int,
              toHour: r['a']! as int,
              percent: r['pourcentage']! as int,
              priceBefore: r['prix_avant']! as num,
            ),
            firstDay: _date(r['premier_jour'])!,
            weekly: r['hebdo'] == 1,
          ),
      ],
    );
  }

  @override
  Future<Tariffs> save(Tariffs tariffs) async {
    await (await _db).transaction((txn) => _write(txn, tariffs));
    return load();
  }

  @override
  Future<Tariffs> publishPromo(OwnerPromo promo) async {
    await _insertPromo(await _db, promo);
    return load();
  }
}

/// [ReviewsRepository] on the phone's database: the latest reviews and the venue's replies in
/// `avis_etablissement`, the stars breakdown in `avis_repartition`.
class SqliteReviewsRepository implements ReviewsRepository {
  SqliteReviewsRepository(this._database, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;

  Future<Database> get _db => _database.db;

  static VenueReview _review(Map<String, Object?> r) => VenueReview(
        id: r['id']! as String,
        author: r['auteur']! as String,
        rating: r['note']! as int,
        date: _date(r['date'])!,
        court: r['terrain']! as int,
        text: r['texte']! as String,
        reply: r['reponse'] as String?,
        replyDate: _date(r['reponse_le']),
        draft: r['brouillon'] as String?,
      );

  static Future<void> seed(DatabaseExecutor db) async {
    final s = FakeReviewsRepository.storySummary;
    for (final e in s.byStars.entries) {
      await db.insert('avis_repartition', {'etoiles': e.key, 'nombre': e.value});
    }
    for (final r in s.latest) {
      await db.insert('avis_etablissement', {
        'id': r.id,
        'auteur': r.author,
        'note': r.rating,
        'date': _iso(r.date),
        'terrain': r.court,
        'texte': r.text,
        'reponse': r.reply,
        'reponse_le': _iso(r.replyDate),
        'brouillon': r.draft,
      });
    }
  }

  @override
  Future<ReviewsSummary> reviews() async {
    final db = await _db;
    final byStars = {
      for (final r in await db.query('avis_repartition', orderBy: 'etoiles DESC'))
        r['etoiles']! as int: r['nombre']! as int,
    };
    final total = byStars.values.fold(0, (a, b) => a + b);
    final sum = byStars.entries.fold(0, (a, e) => a + e.key * e.value);
    return ReviewsSummary(
      average: total == 0 ? 0 : (sum / total * 10).round() / 10,
      total: total,
      byStars: byStars,
      latest: [
        for (final r in await db.query('avis_etablissement', orderBy: 'date DESC')) _review(r),
      ],
    );
  }

  @override
  Future<VenueReview> reply(String id, String text) async {
    final db = await _db;
    await db.update(
      'avis_etablissement',
      {'reponse': text, 'reponse_le': _iso(_clock()), 'brouillon': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    return _review((await db.query('avis_etablissement', where: 'id = ?', whereArgs: [id])).single);
  }
}

/// [ClientsRepository] on the phone's database: the totals in the `proprio_clientele` row, the
/// most frequent clients in `proprio_clients` and their booking references in
/// `client_reservations`.
class SqliteClientsRepository implements ClientsRepository {
  SqliteClientsRepository(this._database);

  final AppDatabase _database;

  static Future<void> seed(DatabaseExecutor db) async {
    final s = FakeClientsRepository.storySummary();
    await db.insert('proprio_clientele', {
      'id': 1,
      'total': s.total,
      'habitues': s.regulars,
      'nouveaux': s.newcomers,
      'avec_absence': s.withNoShow,
      'depuis': _iso(s.since),
    });
    for (final (i, c) in s.top.indexed) {
      await db.insert('proprio_clients', {
        'nom': c.name,
        'telephone': c.phone,
        'visites': c.visits,
        'depense': c.spent,
        'absences': c.noShows,
        'fiabilite': c.reliability,
        'derniere_visite': _iso(c.lastVisit),
        'prochaine_visite': _iso(c.nextVisit),
        'premiere_visite': _iso(c.firstVisit),
        'favori': c.favourite,
        'habitue': c.regular ? 1 : 0,
        'nouveau': c.newcomer ? 1 : 0,
        'position': i,
      });
      for (final (j, ref) in c.refs.indexed) {
        await db.insert('client_reservations', {'client': c.name, 'position': j, 'ref': ref});
      }
    }
  }

  @override
  Future<ClientsSummary> clients() async {
    final db = await _database.db;
    final s = (await db.query('proprio_clientele')).single;
    final refs = <String, List<String>>{};
    for (final r in await db.query('client_reservations', orderBy: 'client, position')) {
      (refs[r['client']! as String] ??= []).add(r['ref']! as String);
    }
    return ClientsSummary(
      total: s['total']! as int,
      regulars: s['habitues']! as int,
      newcomers: s['nouveaux']! as int,
      withNoShow: s['avec_absence']! as int,
      since: _date(s['depuis'])!,
      top: [
        for (final c in await db.query('proprio_clients', orderBy: 'position'))
          OwnerClient(
            name: c['nom']! as String,
            phone: c['telephone']! as String,
            visits: c['visites']! as int,
            spent: c['depense']! as num,
            noShows: c['absences']! as int,
            reliability: c['fiabilite']! as int,
            lastVisit: _date(c['derniere_visite'])!,
            nextVisit: _date(c['prochaine_visite']),
            firstVisit: _date(c['premiere_visite'])!,
            favourite: c['favori']! as String,
            regular: c['habitue'] == 1,
            newcomer: c['nouveau'] == 1,
            refs: refs[c['nom']] ?? const [],
          ),
      ],
    );
  }
}
