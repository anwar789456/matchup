import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/connectivity.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/matches/data/reservation_remote.dart';
import 'package:matchup/features/matches/data/sqlite_bookings_repository.dart';
import 'package:matchup/features/matches/data/supabase_bookings_repository.dart';
import 'package:matchup/features/venue/data/venue_details.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Supabase's `reservations` in memory, shared by every phone: one sequence for references and
/// the same rule as the real table, no two live bookings overlapping on a court.
class _Server {
  int next = 48214;
  final rows = <String, ({String owner, MuBooking booking, CancelledBooking? cancellation, bool held})>{};

  bool overlaps(MuBooking b) => rows.entries.any((e) =>
      e.key != b.id &&
      e.value.cancellation == null &&
      e.value.booking.venue == b.venue &&
      e.value.booking.court == b.court &&
      b.start.isBefore(e.value.booking.end) &&
      b.end.isAfter(e.value.booking.start));
}

class _Remote implements ReservationRemote {
  _Remote(this.server, this.user);

  final _Server server;
  final String user;

  @override
  Future<String> nextReference() async => 'MU-${server.next++}';

  @override
  Future<void> hold(MuBooking b) async {
    if (server.overlaps(b)) throw const SlotTaken();
    server.rows[b.id!] = (owner: user, booking: b, cancellation: null, held: true);
  }

  @override
  Future<void> confirm(MuBooking b) async {
    final mine = server.rows[b.id]?.owner == user;
    if (!mine && server.overlaps(b)) throw const SlotTaken();
    server.rows[b.id!] = (owner: user, booking: b, cancellation: null, held: false);
  }

  @override
  Future<void> cancel(CancelledBooking c) async {
    final r = server.rows[c.booking.id];
    if (r == null || r.owner != user) return;
    server.rows[c.booking.id!] = (owner: r.owner, booking: c.booking, cancellation: c, held: false);
  }

  @override
  Future<List<RemoteBooking>> mine() async => [
        for (final r in server.rows.values)
          if (r.owner == user && !r.held) (booking: r.booking, cancellation: r.cancellation),
      ];

  @override
  Future<List<TakenSlot>> taken(String venue, DateTime from, DateTime to) async => [
        for (final r in server.rows.values)
          if (r.cancellation == null &&
              r.booking.venue == venue &&
              r.booking.start.isBefore(to) &&
              r.booking.end.isAfter(from))
            TakenSlot(court: r.booking.court!, start: r.booking.start, end: r.booking.end),
      ];
}

void main() {
  sqfliteFfiInit();
  late _Server server;
  late Directory dir;
  final open = <AppDatabase>[];

  setUp(() async {
    server = _Server();
    dir = await Directory.systemTemp.createTemp('matchup_resa');
  });
  tearDown(() async {
    for (final d in open) {
      await d.close();
    }
    open.clear();
    await dir.delete(recursive: true);
  });

  /// A phone of [user]: its own database file (two in-memory opens would share one), the
  /// shared server.
  SupabaseBookingsRepository phone(String user, {bool online = true}) {
    final db = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${dir.path}${Platform.pathSeparator}phone${open.length}.db',
    );
    open.add(db);
    return SupabaseBookingsRepository(
      SqliteBookingsRepository(db),
      _Remote(server, user),
      connect: () async => online,
    );
  }

  MuBooking court(String reference, {String court = 'Terrain 3x3', int hour = 20}) => MuBooking(
        id: reference,
        sport: MuSport.basketball,
        venue: 'Hoop Zone',
        court: court,
        place: 'Ennasr',
        start: DateTime(2026, 10, 23, hour),
        end: DateTime(2026, 10, 23, hour + 1),
        share: 9,
        players: const [MuPerson('Yassine B.'), MuPerson('Skander T.')],
      );

  test('hold, pay, confirm: the booking is on Supabase and in the phone’s copy', () async {
    final a = phone('yassine');
    final reference = await a.nextReference();
    expect(reference, 'MU-48214'); // from the server's sequence
    await a.hold(court(reference));
    expect(server.rows[reference]!.held, isTrue);

    final saved = await a.add(court(reference));
    expect(saved.id, reference);
    expect(server.rows[reference]!.held, isFalse);
    final upcoming = await a.upcoming();
    final mine = upcoming.bookings.firstWhere((b) => b.id == reference);
    expect(mine.players.map((p) => p.name), ['Yassine B.', 'Skander T.']);
  });

  test('two phones cannot book the same court at the same time', () async {
    final a = phone('yassine');
    final b = phone('mariem');
    final first = await a.nextReference();
    await a.hold(court(first));

    // Mariem asks for the same slot while Yassine pays: refused before her checkout.
    final second = await b.nextReference();
    expect(second, isNot(first));
    await expectLater(b.hold(court(second)), throwsA(isA<SlotTaken>()));
    // Another court, or the next hour, is fine.
    await b.hold(court(second, court: 'Terrain 5x5'));
    final third = await b.nextReference();
    await b.hold(court(third, hour: 21));
  });

  test('cancelling frees the slot for everyone', () async {
    final a = phone('yassine');
    final b = phone('mariem');
    final ref = await a.nextReference();
    await a.hold(court(ref));
    await a.add(court(ref));

    final other = await b.nextReference();
    await expectLater(b.hold(court(other)), throwsA(isA<SlotTaken>()));
    await a.cancel(ref);
    expect(server.rows[ref]!.cancellation, isNotNull);
    await b.hold(court(other));
    expect((await a.cancelled()).first.booking.id, ref);
  });

  test('a new phone of the same player finds their bookings', () async {
    final a = phone('yassine');
    final ref = await a.nextReference();
    await a.hold(court(ref));
    await a.add(court(ref));

    final again = phone('yassine');
    final back = (await again.upcoming()).bookings.firstWhere((b) => b.id == ref);
    expect(back.court, 'Terrain 3x3');
    expect(back.players, hasLength(2));
    // Someone else's phone sees none of it.
    expect((await phone('mariem').upcoming()).bookings.any((b) => b.id == ref), isFalse);
  });

  test('offline: the copy still shows, booking and cancelling are refused', () async {
    final offline = phone('yassine', online: false);
    final upcoming = await offline.upcoming();
    expect(upcoming.bookings.single.id, 'MU-48213'); // the story's booking, from the copy
    await expectLater(offline.nextReference(), throwsA(isA<OfflineException>()));
    await expectLater(offline.hold(court('MU-1')), throwsA(isA<OfflineException>()));
    await expectLater(offline.cancel('MU-48213'), throwsA(isA<OfflineException>()));
    expect(await offline.taken('Hoop Zone', DateTime(2026, 10, 23), DateTime(2026, 10, 24)), isEmpty);
  });

  test('the slot grid shows other players’ bookings as « Réservé »', () async {
    final a = phone('yassine');
    final b = phone('mariem');
    final grid = FakeVenueDetailsRepository(bookings: a);
    final day = DateTime(2026, 10, 23);
    final now = DateTime(2026, 10, 16, 18);

    final before = await grid.schedule('hoop-zone', day, now: now);
    final free = before.slots['b1']!.firstWhere((s) => s.status == MuSlotStatus.available);

    final ref = await b.nextReference();
    await b.hold(court(ref, hour: free.start.hour));
    await b.add(court(ref, hour: free.start.hour));

    final after = await grid.schedule('hoop-zone', day, now: now);
    final same = after.slots['b1']!.firstWhere((s) => s.start == free.start);
    expect(same.status, MuSlotStatus.booked);
  });
}
