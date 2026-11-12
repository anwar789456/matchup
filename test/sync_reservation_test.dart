import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/sync/sync_service.dart';
import 'package:matchup/features/matches/data/sqlite_bookings_repository.dart';
import 'package:matchup/features/owner/data/owner_drafts.dart';
import 'package:matchup/features/owner/data/owner_repository.dart';
import 'package:matchup/features/owner/data/sqlite_owner_repositories.dart';
import 'package:matchup/features/owner/data/tariffs_repository.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'sync_test.dart' show MemoryRemote;

/// Réservation: the player's bookings and the venue owner's side are copied to Supabase.
void main() {
  sqfliteFfiInit();
  late AppDatabase database;

  setUp(() => database = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath));
  tearDown(() => database.close());

  MuBooking padel() => MuBooking(
        sport: MuSport.padel,
        venue: 'Smash Padel Club',
        court: 'Court 3',
        place: 'Lac 2',
        start: DateTime(2026, 10, 23, 19),
        end: DateTime(2026, 10, 23, 20, 30),
        share: 22.5,
        players: const [MuPerson('Yassine B.'), MuPerson('Mariem K.')],
      );

  test('a booking, its players, its cancellation and the player’s answers are sent', () async {
    final remote = MemoryRemote('user-a');
    final sync = SyncService(database, remote);
    final bookings = SqliteBookingsRepository(database);
    expect(await sync.pending(), 0); // the story's MU-48213 stays on the phone

    final saved = await bookings.add(padel());
    await bookings.cancel(saved.id!);
    await bookings.respond('inv-mariem', accept: true);
    await bookings.rate('pm-padel-oct9', const []);
    await bookings.submitScore('pm-padel-oct9', const [(6, 2), (7, 5)]);

    final report = await sync.sync();
    expect(report.errors, isEmpty);
    expect(await sync.pending(), 0);

    final reservation = remote.tables['reservations']!.values.single;
    expect(reservation['reference'], 'MU-48214');
    expect(reservation['statut'], MuBookingStatus.cancelled.name); // the row as it is now
    expect(reservation['owner_id'], 'user-a');
    expect(remote.tables['reservation_joueurs']!.values.map((r) => r['nom']), ['Yassine B.', 'Mariem K.']);
    expect(remote.tables['annulations']!.values.single['reference'], 'MU-48214');
    expect(remote.tables['invitations']!.values.single['statut'], 'acceptee');
    expect(remote.tables['matchs_notes']!.values.single['match_id'], 'pm-padel-oct9');
    expect(remote.tables['matchs_scores'], hasLength(2));
  });

  test('the owner’s blocks, no-shows and prices are sent; removed rows are deleted', () async {
    final remote = MemoryRemote('owner-a');
    final sync = SyncService(database, remote);
    final owner = SqliteOwnerRepository(database);

    final block = await owner.block(
      courts: [2],
      start: DateTime(2026, 10, 22, 8),
      end: DateTime(2026, 10, 22, 12),
      reason: BlockReason.maintenance,
      note: 'Entretien du gazon',
    );
    await owner.markNoShow('MU-48213', ['Ines M.', 'Lina F.']);
    final tariffs = SqliteTariffsRepository(database);
    final t = await tariffs.load();
    await tariffs.save(t.copyWith(prices: [for (final p in t.prices) p.copyWith(peak: 160)]));
    await tariffs.publishPromo(OwnerPromo(
      draft: PromoDraft.thursdayAfternoon,
      firstDay: DateTime(2026, 10, 22),
      weekly: true,
    ));

    expect((await sync.sync()).errors, isEmpty);
    expect(remote.tables['proprio_blocages']!.values.single['note'], 'Entretien du gazon');
    final presences = remote.tables['proprio_presences']!.values.where((r) => r['ref'] == 'MU-48213');
    expect([for (final r in presences) if (r['etat'] == 'absent') r['nom']], ['Ines M.', 'Lina F.']);
    expect([for (final r in presences) if (r['etat'] == 'attendu') r['nom']], ['Rami S.', 'Salma G.']);
    expect(remote.tables['tarif_groupes']!.values.every((g) => g['prix_pointe'] == 160), isTrue);
    expect(remote.tables['promos']!.values.single['pourcentage'], 20);

    await owner.unblock(block.id);
    expect((await sync.sync()).errors, isEmpty);
    expect(remote.tables['proprio_blocages'], isEmpty);
  });

  test('a new phone of the same player gets their bookings back', () async {
    final dir = await Directory.systemTemp.createTemp('matchup_sync_resa');
    addTearDown(() => dir.delete(recursive: true));
    AppDatabase phone(String name) {
      final d = AppDatabase(factory: databaseFactoryFfi, path: '${dir.path}${Platform.pathSeparator}$name.db');
      addTearDown(d.close);
      return d;
    }

    final remote = MemoryRemote('user-a');
    final first = phone('first');
    await SqliteBookingsRepository(first).add(padel());
    expect((await SyncService(first, remote).sync()).errors, isEmpty);

    final second = phone('second');
    final sync = SyncService(second, remote);
    final report = await sync.sync();
    expect(report.errors, isEmpty);
    expect(report.received, 3); // the booking and its two players
    expect(await sync.pending(), 0); // pulled rows are not sent back

    final upcoming = await SqliteBookingsRepository(second).upcoming();
    final back = upcoming.bookings.firstWhere((b) => b.id == 'MU-48214');
    expect(back.players.map((p) => p.name), ['Yassine B.', 'Mariem K.']);
    expect(back.share, 22.5);
  });
}
