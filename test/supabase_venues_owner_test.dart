import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/common/data/story_data.dart';
import 'package:matchup/features/matches/data/reservation_remote.dart';
import 'package:matchup/features/matches/data/sqlite_bookings_repository.dart';
import 'package:matchup/features/owner/data/owner_repository.dart';
import 'package:matchup/features/owner/data/sqlite_owner_repositories.dart';
import 'package:matchup/features/owner/data/supabase_owner_repositories.dart';
import 'package:matchup/features/venue/data/sqlite_venues_repository.dart';
import 'package:matchup/features/venue/data/supabase_venues_repository.dart';
import 'package:matchup/features/venue/data/venue_details.dart';
import 'package:matchup/features/venue/data/venue_remote.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Supabase's catalogue, closed slots and the venue's bookings, in memory.
class _Venues implements VenueRemote {
  _Venues({this.owner = true});

  /// Whether this account owns Arena Five (revendiquer_etablissement).
  bool owner;
  final catalogue = <String, RemoteVenue>{};
  final closed = <String, RemoteBlock>{};
  final atVenue = <RemoteBooking>[];
  ({num offPeak, num peak, int peakFrom, int peakTo})? prices;

  @override
  Future<List<RemoteVenue>> venues() async => catalogue.values.toList();

  @override
  Future<List<RemoteBlock>> blocks(String venueId, DateTime from, DateTime to) async =>
      closed.values.toList();

  @override
  Future<bool> claim(String venueId) async => owner;

  @override
  Future<void> saveBlock(String venueId, RemoteBlock block) async => closed[block.id] = block;

  @override
  Future<void> deleteBlock(String id) async => closed.remove(id);

  @override
  Future<void> updatePrices(String venueId,
          {required num offPeak, required num peak, required int peakFrom, required int peakTo}) async =>
      prices = (offPeak: offPeak, peak: peak, peakFrom: peakFrom, peakTo: peakTo);

  @override
  Future<List<RemoteBooking>> bookingsAt(String venueName, DateTime from, DateTime to) async => [
        for (final r in atVenue)
          if (r.booking.venue == venueName && !r.booking.start.isBefore(from) && r.booking.start.isBefore(to)) r,
      ];
}

RemoteVenue _arena({num offPeak = 120, num peak = 150, String name = 'Arena Five'}) => RemoteVenue(
      venue: MuVenue(
        id: 'arena-five',
        name: name,
        sports: const [MuSport.football],
        place: 'La Marsa',
        pricePerPerson: 12,
        courtPrice: offPeak,
        distanceKm: 1.4,
      ),
      street: 'Route de la Corniche, La Marsa',
      postalAddress: 'Route de la Corniche, 2070 La Marsa',
      format: '5 contre 5',
      surface: 'gazon synthétique',
      courts: const [('t1', 'Terrain 1', false), ('t2', 'Terrain 2', false), ('t3', 'Terrain 3', true)],
      opens: 480,
      closes: 1440,
      slotMinutes: 60,
      players: 10,
      offPeakPrice: offPeak,
      peakPrice: peak,
      peakFrom: 1080,
      peakTo: 1380,
      eveningFrom: 1200,
    );

void main() {
  sqfliteFfiInit();
  late Directory dir;
  final open = <AppDatabase>[];

  setUp(() async => dir = await Directory.systemTemp.createTemp('matchup_venues'));
  tearDown(() async {
    for (final d in open) {
      await d.close();
    }
    open.clear();
    await dir.delete(recursive: true);
  });

  AppDatabase phone() {
    final d = AppDatabase(factory: databaseFactoryFfi, path: '${dir.path}${Platform.pathSeparator}p${open.length}.db');
    open.add(d);
    return d;
  }

  final day = DateTime(2026, 10, 23);
  final now = DateTime(2026, 10, 16, 18);

  test('the venue list comes from Supabase, the phone keeps a copy for offline', () async {
    final db = phone();
    final remote = _Venues()..catalogue['arena-five'] = _arena(name: 'Arena Five Marsa');
    final online = SupabaseVenuesRepository(SqliteVenuesRepository(db), remote, connect: () async => true);
    final list = await online.venues();
    expect(list.firstWhere((v) => v.id == 'arena-five').name, 'Arena Five Marsa');

    final offline = SupabaseVenuesRepository(SqliteVenuesRepository(db), remote, connect: () async => false);
    expect((await offline.venues()).firstWhere((v) => v.id == 'arena-five').name, 'Arena Five Marsa');
  });

  test('the venue page uses Supabase’s prices and courts, the bundled ones offline', () async {
    final db = phone();
    final remote = _Venues()..catalogue['arena-five'] = _arena(offPeak: 100, peak: 130);
    final bookings = SqliteBookingsRepository(db);
    final online = FakeVenueDetailsRepository(bookings: bookings, remote: remote, connect: () async => true);
    final d = await online.details('arena-five');
    expect((d.offPeakPrice, d.peakPrice), (100, 130));
    expect(d.courts.map((c) => c.name), ['Terrain 1', 'Terrain 2', 'Terrain 3']);
    expect(d.review, isNotNull); // kept from the bundled details

    final offline = FakeVenueDetailsRepository(bookings: bookings, remote: remote, connect: () async => false);
    expect((await offline.details('arena-five')).offPeakPrice, 120);
  });

  test('a slot the owner closes is « Bloqué » in every player’s grid, and reopens', () async {
    final remote = _Venues()..catalogue['arena-five'] = _arena();
    final ownerPhone = phone();
    final owner = SupabaseOwnerRepository(
      SqliteOwnerRepository(ownerPhone),
      OwnerVenueLink(remote, connect: () async => true),
    );
    final block = await owner.block(
      courts: [2],
      start: DateTime(2026, 10, 23, 19),
      end: DateTime(2026, 10, 23, 21),
      reason: BlockReason.maintenance,
      note: 'Entretien',
    );
    expect(remote.closed.values.single.court, 'Terrain 2');

    final player = FakeVenueDetailsRepository(
      bookings: SqliteBookingsRepository(phone()),
      remote: remote,
      connect: () async => true,
    );
    final grid = await player.schedule('arena-five', day, now: now);
    MuSlotStatus at(int hour) => grid.slots['t2']!.firstWhere((s) => s.start.hour == hour).status;
    expect(at(19), MuSlotStatus.blocked);
    expect(at(20), MuSlotStatus.blocked);
    expect(grid.slots['t1']!.firstWhere((s) => s.start.hour == 19).status, isNot(MuSlotStatus.blocked));

    await owner.unblock(block.id);
    expect(remote.closed, isEmpty);
    final again = await player.schedule('arena-five', day, now: now);
    expect(again.slots['t2']!.firstWhere((s) => s.start.hour == 19).status, isNot(MuSlotStatus.blocked));
  });

  test('another phone of the owner gets the closed slots', () async {
    final remote = _Venues()
      ..closed['arena-five-b2-1'] = RemoteBlock(
        id: 'arena-five-b2-1',
        court: 'Terrain 3',
        start: DateTime(2026, 10, 23, 8),
        end: DateTime(2026, 10, 23, 12),
        reason: 'maintenance',
      );
    final owner = SupabaseOwnerRepository(SqliteOwnerRepository(phone()), OwnerVenueLink(remote, connect: () async => true));
    final blocks = await owner.blocksOn(day);
    expect(blocks.where((b) => b.id == 'arena-five-b2-1').single.court, 3);
  });

  test('the owner sees the bookings players made, and can check them in', () async {
    final booking = MuBooking(
      id: 'MU-50001',
      sport: MuSport.football,
      venue: Story.arenaFive.name,
      court: 'Terrain 1',
      place: 'La Marsa',
      start: DateTime(2026, 10, 16, 14),
      end: DateTime(2026, 10, 16, 15),
      share: 12,
      players: const [MuPerson('Rami S.'), MuPerson('Salma G.')],
    );
    final remote = _Venues()..atVenue.add((booking: booking, cancellation: null));
    final owner = SupabaseOwnerRepository(SqliteOwnerRepository(phone()), OwnerVenueLink(remote, connect: () async => true));

    final today = await owner.bookingsOn(DateTime(2026, 10, 16));
    final theirs = today.firstWhere((b) => b.ref == 'MU-50001');
    expect((theirs.court, theirs.organiser, theirs.players), (1, 'Rami S.', 2));
    expect(today.any((b) => b.ref == 'MU-48150'), isTrue); // the venue's own bookings stay
    expect((await owner.booking('MU-50001'))!.organiser, 'Rami S.');
    final scan = await owner.checkIn('mu-50001', DateTime(2026, 10, 16, 13, 50));
    expect(scan.status, CheckInStatus.valid);
  });

  test('the owner sees whether a player’s game is public or private', () async {
    MuBooking at(String id, int hour, {required bool isPublic}) => MuBooking(
          id: id,
          sport: MuSport.football,
          venue: Story.arenaFive.name,
          court: 'Terrain 2',
          place: 'La Marsa',
          start: DateTime(2026, 10, 16, hour),
          end: DateTime(2026, 10, 16, hour + 1),
          share: 12,
          players: const [MuPerson('Rami S.')],
          isPublic: isPublic,
        );
    final remote = _Venues()
      ..atVenue.add((booking: at('MU-50001', 9, isPublic: true), cancellation: null))
      ..atVenue.add((booking: at('MU-50002', 10, isPublic: false), cancellation: null));
    final owner = SupabaseOwnerRepository(SqliteOwnerRepository(phone()), OwnerVenueLink(remote, connect: () async => true));
    final today = await owner.bookingsOn(DateTime(2026, 10, 16));
    expect(today.firstWhere((b) => b.ref == 'MU-50001').kind, OwnerBookingKind.public);
    expect(today.firstWhere((b) => b.ref == 'MU-50002').kind, OwnerBookingKind.private);
  });

  test('a booking’s public flag goes to Supabase and comes back', () {
    final row = SupabaseReservationRemote.readRemote({
      'reference': 'MU-50003',
      'sport': 'football',
      'etablissement': 'Arena Five',
      'terrain': 'Terrain 1',
      'lieu': 'La Marsa',
      'debut': '2026-10-16T19:00:00Z',
      'fin': '2026-10-16T20:00:00Z',
      'part': 12,
      'statut': 'upcoming',
      'publique': true,
    });
    expect(row.booking.isPublic, isTrue);
  });

  test('saved tariffs reach the players; a non-owner changes nothing on Supabase', () async {
    final remote = _Venues();
    final tariffs = SupabaseTariffsRepository(
      SqliteTariffsRepository(phone()),
      OwnerVenueLink(remote, connect: () async => true),
    );
    final t = await tariffs.load();
    await tariffs.save(t.copyWith(prices: [for (final p in t.prices) p.copyWith(offPeak: 110, peak: 160)]));
    expect(remote.prices, (offPeak: 110, peak: 160, peakFrom: 18 * 60, peakTo: 23 * 60));

    final stranger = _Venues(owner: false);
    final owner = SupabaseOwnerRepository(SqliteOwnerRepository(phone()), OwnerVenueLink(stranger, connect: () async => true));
    await owner.block(
      courts: [1],
      start: DateTime(2026, 10, 23, 8),
      end: DateTime(2026, 10, 23, 9),
      reason: BlockReason.other,
    );
    expect(stranger.closed, isEmpty);
    expect(await owner.bookingsOn(DateTime(2026, 10, 16)), isNot(contains(predicate<OwnerBooking>((b) => b.ref.startsWith('MU-5')))));
  });
}
