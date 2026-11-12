import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import 'booking_rows.dart';
import 'bookings_repository.dart';

/// [BookingsRepository] on the phone's database: booked courts (`reservations` +
/// `reservation_joueurs`), cancellations and refunds (`annulations`), invitations and their answer
/// (`invitations`), ratings (`matchs_notes`) and scores (`matchs_scores`) survive a restart.
///
/// The played matches and a booking's line-up and chat stay the story's
/// ([FakeBookingsRepository.storyPast], [FakeBookingsRepository.detailsOf]).
class SqliteBookingsRepository implements BookingsRepository {
  SqliteBookingsRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  /// Bookings not cancelled, by date.
  Future<List<MuBooking>> _active(DatabaseExecutor db) async => BookingRows.read(
        db,
        await db.rawQuery(
          'SELECT * FROM reservations WHERE reference NOT IN (SELECT reference FROM annulations) '
          'ORDER BY debut',
        ),
      );

  MatchInvitation _invitation(Map<String, Object?> r) => MatchInvitation(
        id: r['id'] as String,
        from: MuPerson(r['de'] as String),
        sport: MuSport.values.byName(r['sport'] as String),
        venue: r['etablissement'] as String,
        place: r['lieu'] as String,
        start: DateTime.parse(r['debut'] as String),
        share: r['part'] as num,
        spotsTotal: r['places_total'] as int,
        spotsLeft: r['places_restantes'] as int,
      );

  @override
  Future<UpcomingMatches> upcoming() async {
    final db = await _db;
    final invitations = await db.query('invitations', orderBy: 'debut');
    return UpcomingMatches(
      invitations: [
        for (final r in invitations)
          if (r['statut'] == 'attente') _invitation(r),
      ],
      games: [
        for (final r in invitations)
          if (r['statut'] == 'acceptee') FakeBookingsRepository.gameOf(_invitation(r)),
      ],
      bookings: await _active(db),
    );
  }

  @override
  Future<String> nextReference() async {
    final db = await _db;
    final rows = await db.rawQuery(
      "SELECT MAX(CAST(SUBSTR(reference, 4) AS INTEGER)) AS last FROM reservations "
      "WHERE reference LIKE 'MU-%'",
    );
    final last = rows.first['last'] as int? ?? FakeBookingsRepository.firstReference - 1;
    return 'MU-${last + 1}';
  }

  /// Nothing to hold on the phone alone: the slot is the player's as soon as they pay.
  @override
  Future<void> hold(MuBooking booking) async {}

  /// Stores [booking] as Supabase has it (the cache of [SupabaseBookingsRepository]): replaces
  /// the booking, its players and its cancellation.
  Future<void> keep(MuBooking booking, CancelledBooking? cancellation) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Cascades to reservation_joueurs and annulations.
      await txn.delete('reservations', where: 'reference = ?', whereArgs: [booking.id]);
      await BookingRows.insert(txn, booking, booking.id!);
      if (cancellation != null) await BookingRows.insertCancellation(txn, cancellation);
    });
  }

  @override
  Future<MuBooking> add(MuBooking booking) async {
    final reference = booking.id ?? await nextReference();
    final db = await _db;
    await db.transaction((txn) => BookingRows.insert(txn, booking, reference));
    return (await BookingRows.read(
      db,
      await db.query('reservations', where: 'reference = ?', whereArgs: [reference]),
    ))
        .single;
  }

  Future<MuBooking> _booking(DatabaseExecutor db, String id) async {
    final rows = await db.query('reservations', where: 'reference = ?', whereArgs: [id]);
    if (rows.isEmpty) throw StateError('Réservation introuvable : $id');
    return (await BookingRows.read(db, rows)).single;
  }

  @override
  Future<BookingDetails> details(String id) async =>
      FakeBookingsRepository.detailsOf(await _booking(await _db, id));

  @override
  Future<CancelledBooking> cancel(String id) async {
    final db = await _db;
    return db.transaction((txn) async {
      final b = await _booking(txn, id);
      await txn.update(
        'reservations',
        {'statut': MuBookingStatus.cancelled.name, 'remboursement': b.share},
        where: 'reference = ?',
        whereArgs: [id],
      );
      final c = CancelledBooking(
        booking: MuBooking(
          id: b.id,
          sport: b.sport,
          venue: b.venue,
          court: b.court,
          place: b.place,
          start: b.start,
          end: b.end,
          share: b.share,
          status: MuBookingStatus.cancelled,
          refund: b.share,
          players: b.players,
        ),
        cancelledBy: Story.yassine,
        byMe: true,
        refundedAt: DateTime.now(),
        refund: b.share,
        playersRefunded: b.players.length,
        totalRefund: b.share * b.players.length,
      );
      await BookingRows.insertCancellation(txn, c);
      return c;
    });
  }

  @override
  Future<List<PastMatch>> past() async {
    final db = await _db;
    final rated = {
      for (final r in await db.query('matchs_notes')) r['match_id'] as String,
    };
    final scores = <String, List<(int, int)>>{};
    for (final r in await db.query('matchs_scores', orderBy: 'match_id, set_index')) {
      (scores[r['match_id'] as String] ??= []).add((r['nous'] as int, r['eux'] as int));
    }
    return [
      for (final m in FakeBookingsRepository.storyPast)
        PastMatch(
          id: m.id,
          sport: m.sport,
          date: m.date,
          venue: m.venue,
          court: m.court,
          match: m.match,
          mates: m.mates,
          rated: m.rated || rated.contains(m.id),
          sets: scores[m.id] ?? m.sets,
          scoreConfirmed: !scores.containsKey(m.id),
        ),
    ];
  }

  @override
  Future<List<CancelledBooking>> cancelled() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT r.*, a.annule_par, a.par_moi, a.raison, a.rembourse_le, '
      'a.remboursement AS rembourse, a.joueurs_rembourses, a.total_rembourse '
      'FROM reservations r JOIN annulations a ON a.reference = r.reference '
      'ORDER BY a.rembourse_le DESC',
    );
    final bookings = await BookingRows.read(db, rows);
    return [
      for (final (i, r) in rows.indexed)
        BookingRows.cancellation({...r, 'remboursement': r['rembourse']}, bookings[i]),
    ];
  }

  @override
  Future<void> respond(String invitationId, {required bool accept}) async {
    final db = await _db;
    await db.update(
      'invitations',
      {'statut': accept ? 'acceptee' : 'refusee'},
      where: "id = ? AND statut = 'attente'",
      whereArgs: [invitationId],
    );
  }

  @override
  Future<void> rate(String matchId, List<MateRating> ratings) async {
    final db = await _db;
    await db.insert(
      'matchs_notes',
      {'match_id': matchId, 'note_le': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> submitScore(String matchId, List<(int, int)> sets) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('matchs_scores', where: 'match_id = ?', whereArgs: [matchId]);
      for (final (i, (us, them)) in sets.indexed) {
        await txn.insert('matchs_scores', {'match_id': matchId, 'set_index': i, 'nous': us, 'eux': them});
      }
    });
  }
}
