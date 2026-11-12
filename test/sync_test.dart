import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/sync/sync_outbox.dart';
import 'package:matchup/core/sync/sync_service.dart';
import 'package:matchup/features/payments/data/payment_repository.dart';
import 'package:matchup/features/payments/data/sqlite_payment_repository.dart';
import 'package:matchup/features/profile/data/sqlite_me_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Supabase in memory: table → key → row (rows carry owner_id like the real tables).
class MemoryRemote implements SyncRemote {
  MemoryRemote(this.userId);

  @override
  String? userId;
  final tables = <String, Map<String, Map<String, Object?>>>{};
  final failing = <String>{};

  String _key(Map<String, Object?> row, List<String> keys) => [row['owner_id'], for (final k in keys) '${row[k]}'].join('|');

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows, List<String> keys) async {
    if (failing.contains(table)) throw Exception('relation "public.$table" does not exist');
    for (final r in rows) {
      (tables[table] ??= {})[_key(r, keys)] = {...r};
    }
  }

  @override
  Future<void> delete(String table, Map<String, Object?> key) async {
    tables[table]?.removeWhere((_, r) => r['owner_id'] == userId && key.entries.every((e) => '${r[e.key]}' == '${e.value}'));
  }

  @override
  Future<List<Map<String, Object?>>> fetchAll(String table) async => [
        for (final r in (tables[table] ?? {}).values)
          if (r['owner_id'] == userId) {...r},
      ];
}

void main() {
  sqfliteFfiInit();
  late AppDatabase database;

  setUp(() => database = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath));
  tearDown(() => database.close());

  test('the story seed is not queued; a change is, and is sent once with owner_id', () async {
    final remote = MemoryRemote('user-a');
    final sync = SyncService(database, remote);
    expect(await sync.pending(), 0);

    await SqliteMeRepository(database).debit(10);
    final card = await SqlitePaymentRepository(database, latency: Duration.zero)
        .addCard(brand: CardBrand.mastercard, last4: '4444', expMonth: 12, expYear: 2029);
    await SqliteMeRepository(database).credit(4);
    expect(await sync.pending(), 3);

    final report = await sync.sync();
    expect(report.errors, isEmpty);
    expect(report.sent, 2); // the balance row (latest state) and the card
    expect(await sync.pending(), 0);
    expect(remote.tables['porte_monnaie']!.values.single, {'id': 1, 'solde': 24, 'owner_id': 'user-a'});
    expect(remote.tables['cartes']!.values.single['derniers_chiffres'], '4444');

    await (await database.db).delete('cartes', where: 'id = ?', whereArgs: [card.id]);
    await sync.sync();
    expect(remote.tables['cartes'], isEmpty);
  });

  test('a fresh phone pulls the user’s rows without queuing them again', () async {
    // Each other phone is its own file (two in-memory opens share one database).
    final dir = await Directory.systemTemp.createTemp('matchup_sync');
    addTearDown(() => dir.delete(recursive: true));
    AppDatabase phone(String name) {
      final d = AppDatabase(factory: databaseFactoryFfi, path: '${dir.path}${Platform.pathSeparator}$name.db');
      addTearDown(d.close);
      return d;
    }

    final remote = MemoryRemote('user-a');
    await SqlitePaymentRepository(database, latency: Duration.zero)
        .charge(amount: 15, reason: 'Arena Five', method: PayWith.card, reference: 'MU-48213');
    await SyncService(database, remote).sync();
    expect(remote.tables['paiements'], hasLength(1));
    expect(remote.tables['tentatives_paiement'], hasLength(1));

    final phone2 = phone('phone2');
    final report = await SyncService(phone2, remote).sync();
    expect(report.received, greaterThanOrEqualTo(2));
    final paid = await SqlitePaymentRepository(phone2).payments(reference: 'MU-48213');
    expect(paid.single.amount, 15);
    expect(await pendingChanges(await phone2.db), 0);

    // Someone else's rows stay theirs.
    remote.userId = 'user-b';
    final phone3 = phone('phone3');
    await SyncService(phone3, remote).sync();
    expect(await SqlitePaymentRepository(phone3).payments(), isEmpty);
  });

  test('a table missing on Supabase keeps its changes; the others go through', () async {
    final remote = MemoryRemote('user-a')..failing.add('cartes');
    final sync = SyncService(database, remote);
    await SqliteMeRepository(database).credit(5);
    await SqlitePaymentRepository(database).addCard(brand: CardBrand.visa, last4: '0005', expMonth: 1, expYear: 2030);
    final report = await sync.sync();
    expect(report.errors.single, startsWith('cartes'));
    expect(remote.tables['porte_monnaie'], hasLength(1));
    expect(await sync.pending(), 1);

    remote.failing.clear();
    expect((await sync.sync()).ok, isTrue);
    expect(await sync.pending(), 0);
  });

  test('without a session nothing is sent', () async {
    final sync = SyncService(database, MemoryRemote(null));
    await SqliteMeRepository(database).credit(5);
    expect((await sync.sync()).ok, isFalse);
    expect(await sync.pending(), 1);
  });
}
