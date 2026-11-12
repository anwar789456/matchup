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

  test('the player’s answers, ratings and scores are copied; booked courts are not', () async {
    final remote = MemoryRemote('user-a');
    final sync = SyncService(database, remote);
    final bookings = SqliteBookingsRepository(database);
    expect(await sync.pending(), 0); // the story's MU-48213 stays on the phone

    // Booked courts live in Supabase's own tables (supabase/reservation.sql), not in the copy.
    final saved = await bookings.add(padel());
    await bookings.cancel(saved.id!);
    await bookings.respond('inv-mariem', accept: true);
    await bookings.rate('pm-padel-oct9', const []);
    await bookings.submitScore('pm-padel-oct9', const [(6, 2), (7, 5)]);

    final report = await sync.sync();
    expect(report.errors, isEmpty);
    expect(await sync.pending(), 0);
    expect(remote.tables.keys, isNot(contains('reservations')));
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
}
