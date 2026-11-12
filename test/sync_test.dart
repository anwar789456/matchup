import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/sync/sync_outbox.dart';
import 'package:matchup/core/sync/sync_service.dart';
import 'package:matchup/core/sync/sync_tables.dart';
import 'package:matchup/features/payments/data/payment_repository.dart';
import 'package:matchup/features/payments/data/sqlite_payment_repository.dart';
import 'package:matchup/features/profile/data/sqlite_me_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Supabase in memory: table → key → row (rows carry owner_id like the real tables).
class MemoryRemote implements SyncRemote {
  MemoryRemote(this.userId, {Map<String, Map<String, Map<String, Object?>>>? store}) : tables = store ?? {};

  @override
  String? userId;

  /// Shared between two remotes to play two users on one Supabase.
  final Map<String, Map<String, Map<String, Object?>>> tables;
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
  Future<List<Map<String, Object?>>> fetchAll(String table, {bool everyone = false}) async => [
        for (final r in (tables[table] ?? {}).values)
          if (everyone || r['owner_id'] == userId) {...r},
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

  test('shared table: everyone’s rows come down, only your own go up, deletions follow', () async {
    const posts = SyncTable('test_posts', scope: SyncScope.shared, ownerColumn: 'auteur_id');
    final tables = [...syncTables, posts];
    final dir = await Directory.systemTemp.createTemp('matchup_shared');
    addTearDown(() => dir.delete(recursive: true));
    Future<AppDatabase> phone(String name) async {
      final d = AppDatabase(factory: databaseFactoryFfi, path: '${dir.path}${Platform.pathSeparator}$name.db');
      addTearDown(d.close);
      final db = await d.db;
      await db.execute('CREATE TABLE test_posts (id TEXT PRIMARY KEY, auteur_id TEXT NOT NULL, texte TEXT NOT NULL)');
      await installSyncTriggers(db, tables: tables);
      return d;
    }

    // Supabase user ids are UUIDs; demo and pre-sign-in authors are not.
    const ua = '0b6f1c2e-1111-4a1b-9c2d-aaaaaaaaaaaa';
    const ub = '7d3e9f40-2222-4c5d-8e6f-bbbbbbbbbbbb';
    final store = <String, Map<String, Map<String, Object?>>>{};
    final a = await phone('a');
    final b = await phone('b');
    final syncA = SyncService(a, MemoryRemote(ua, store: store), tables: tables);
    final syncB = SyncService(b, MemoryRemote(ub, store: store), tables: tables);
    Future<List<String>> texts(AppDatabase d) async =>
        [for (final r in await (await d.db).query('test_posts', orderBy: 'id')) r['texte']! as String];

    // On B: a demo row and one written before sign-in. Neither is ever sent nor removed.
    await (await b.db).insert('test_posts', {'id': 'demo-1', 'auteur_id': '1', 'texte': 'Démo'});
    await (await b.db).insert('test_posts', {'id': 'hors-ligne', 'auteur_id': 'local', 'texte': 'Avant connexion'});
    await (await a.db).insert('test_posts', {'id': 'p-a', 'auteur_id': ua, 'texte': 'Salut de A'});
    await syncA.sync();
    expect((await syncB.sync()).received, 1);
    expect(await texts(b), ['Démo', 'Avant connexion', 'Salut de A']);
    expect(await syncB.pending(), 0, reason: 'pulled rows are not queued; local-author rows are not sent');
    expect(store['test_posts']!.values.map((r) => r['id']), ['p-a']);

    // B edits A's post on its phone: never sent as B's.
    await (await b.db).update('test_posts', {'texte': 'Modifié par B'}, where: 'id = ?', whereArgs: ['p-a']);
    await syncB.sync();
    expect(store['test_posts']!.values.single['texte'], 'Salut de A');
    expect(await syncB.pending(), 0);

    await (await b.db).insert('test_posts', {'id': 'p-b', 'auteur_id': ub, 'texte': 'Salut de B'});
    await syncB.sync();
    await syncA.sync();
    expect(await texts(a), ['Salut de A', 'Salut de B']);

    // A deletes its post: gone on Supabase, then on B; B's own post stays.
    await (await a.db).delete('test_posts', where: 'id = ?', whereArgs: ['p-a']);
    await syncA.sync();
    await syncB.sync();
    expect(await texts(b), ['Démo', 'Avant connexion', 'Salut de B']);
  });
}
