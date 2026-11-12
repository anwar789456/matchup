import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../supabase/supabase_config.dart';
import 'sync_outbox.dart';
import 'sync_tables.dart';

/// Where synced rows go. [SupabaseSyncRemote] in the app, a map in tests.
abstract interface class SyncRemote {
  /// The signed-in user (rows are stored under this `owner_id`), null when signed out.
  String? get userId;

  Future<void> upsert(String table, List<Map<String, Object?>> rows, List<String> keys);
  Future<void> delete(String table, Map<String, Object?> key);

  /// The user's own rows of [table], or with [everyone] every row they can read (shared tables).
  Future<List<Map<String, Object?>>> fetchAll(String table, {bool everyone = false});
}

class SupabaseSyncRemote implements SyncRemote {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows, List<String> keys) =>
      _client.from(table).upsert(rows, onConflict: ['owner_id', ...keys].join(','));

  @override
  Future<void> delete(String table, Map<String, Object?> key) async {
    var q = _client.from(table).delete().eq('owner_id', userId!);
    for (final e in key.entries) {
      q = q.eq(e.key, e.value!);
    }
    await q;
  }

  @override
  Future<List<Map<String, Object?>>> fetchAll(String table, {bool everyone = false}) async {
    final q = _client.from(table).select();
    return List<Map<String, Object?>>.from(everyone ? await q : await q.eq('owner_id', userId!));
  }
}

@immutable
class SyncReport {
  const SyncReport({this.sent = 0, this.received = 0, this.errors = const []});

  final int sent;

  /// Rows written into the phone (new or changed).
  final int received;

  /// « paiements : relation "public.paiements" does not exist »…
  final List<String> errors;

  bool get ok => errors.isEmpty;
}

/// Sends the phone's changes to Supabase; on a phone that has never synced for this user, brings
/// their own rows down first; at every run, brings everyone's rows of the shared tables down.
/// The UI never waits for it: SQFlite stays the source of the screens, the network only copies.
class SyncService {
  SyncService(this._database, this._remote, {this.tables = syncTables});

  final AppDatabase _database;
  final SyncRemote _remote;
  final List<SyncTable> tables;
  Future<SyncReport>? _running;

  SyncTable? _table(String name) => tables.where((t) => t.name == name).firstOrNull;

  /// A Supabase user id (UUID), as opposed to a demo or local author id.
  static final _supabaseUser = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

  /// One run at a time; a call during a run waits for it.
  Future<SyncReport> sync() => _running ??= _run().whenComplete(() => _running = null);

  Future<SyncReport> _run() async {
    final user = _remote.userId;
    if (user == null) return const SyncReport(errors: ['pas de session Supabase']);
    final db = await _database.db;
    final errors = <String>[];
    final etat = (await db.query('sync_etat', where: 'id = 1')).first;
    var received = 0;
    if (etat['utilisateur'] != user) {
      received = await _pullOwn(db, errors);
      if (errors.isEmpty) {
        await db.update('sync_etat', {'utilisateur': user, 'dernier_pull': DateTime.now().toIso8601String()}, where: 'id = 1');
      }
    }
    final sent = await _push(db, user, errors);
    received += await _pullShared(db, user, errors);
    return SyncReport(sent: sent, received: received, errors: errors);
  }

  Future<int> _push(Database db, String user, List<String> errors) async {
    final outbox = await db.query('sync_outbox', orderBy: 'id', limit: 1000);
    if (outbox.isEmpty) return 0;
    var sent = 0;
    final byTable = <String, List<Map<String, Object?>>>{};
    for (final r in outbox) {
      (byTable[r['tableau']! as String] ??= []).add(r);
    }
    for (final MapEntry(key: table, value: changes) in byTable.entries) {
      try {
        final shape = await tableShape(db, table);
        final owner = _table(table)?.ownerColumn;
        // The latest change of each row wins; the row is read as it is now.
        final latest = <String, Map<String, Object?>>{};
        for (final c in changes) {
          latest['${c['k1']}|${c['k2']}|${c['k3']}'] = c;
        }
        final upserts = <Map<String, Object?>>[];
        for (final c in latest.values) {
          final keyValues = [for (var i = 0; i < shape.keys.length; i++) c['k${i + 1}']];
          final where = shape.keys.map((k) => '"$k" = ?').join(' AND ');
          final row = c['operation'] == 'upsert'
              ? (await db.query(table, where: where, whereArgs: keyValues)).firstOrNull
              : null;
          // Someone else's shared row, pulled here: never sent as ours.
          if (row != null && owner != null && row[owner] != user) continue;
          if (row == null) {
            await _remote.delete(table, {for (var i = 0; i < shape.keys.length; i++) shape.keys[i]: keyValues[i]});
          } else {
            upserts.add({...row, 'owner_id': user});
          }
          sent++;
        }
        if (upserts.isNotEmpty) await _remote.upsert(table, upserts, shape.keys);
        final ids = [for (final c in changes) c['id']];
        await db.delete('sync_outbox', where: 'id IN (${List.filled(ids.length, '?').join(',')})', whereArgs: ids);
      } catch (e) {
        errors.add('$table : $e');
      }
    }
    return sent;
  }

  /// The user's own rows of the owner tables, once per phone and user.
  Future<int> _pullOwn(Database db, List<String> errors) async {
    var received = 0;
    for (final t in tables.where((t) => !t.shared)) {
      try {
        received += await _write(db, t, await _remote.fetchAll(t.name));
      } catch (e) {
        errors.add('${t.name} : $e');
      }
    }
    return received;
  }

  /// Everyone's rows of the shared tables, at every run. Rows others deleted on Supabase go away
  /// here too; the user's own rows not sent yet are kept.
  Future<int> _pullShared(Database db, String user, List<String> errors) async {
    var received = 0;
    for (final t in tables.where((t) => t.shared)) {
      try {
        received += await _write(db, t, await _remote.fetchAll(t.name, everyone: true), removeOthersMissing: user);
      } catch (e) {
        errors.add('${t.name} : $e');
      }
    }
    return received;
  }

  /// Writes pulled rows into the phone (insert, or update when something changed) with the
  /// triggers quiet. With [removeOthersMissing], also deletes the rows of other authors than
  /// this user that Supabase no longer has.
  Future<int> _write(Database db, SyncTable t, List<Map<String, Object?>> rows, {String? removeOthersMissing}) async {
    if (rows.isEmpty && removeOthersMissing == null) return 0;
    final shape = await tableShape(db, t.name);
    final where = shape.keys.map((k) => '"$k" = ?').join(' AND ');
    String key(Map<String, Object?> r) => [for (final k in shape.keys) '${r[k]}'].join('|');
    var changed = 0;
    await db.transaction((txn) async {
      await txn.update('sync_etat', {'application': 1}, where: 'id = 1');
      for (final remote in rows) {
        final row = {for (final c in shape.columns) if (remote.containsKey(c)) c: remote[c]};
        final args = [for (final k in shape.keys) row[k]];
        final local = (await txn.query(t.name, where: where, whereArgs: args)).firstOrNull;
        if (local == null) {
          await txn.insert(t.name, row);
          changed++;
        } else if (row.entries.any((e) => '${local[e.key]}' != '${e.value}')) {
          await txn.update(t.name, row, where: where, whereArgs: args);
          changed++;
        }
      }
      final owner = t.ownerColumn;
      if (removeOthersMissing != null && owner != null) {
        final present = {for (final r in rows) key(r)};
        final others = await txn.query(t.name, where: '"$owner" IS NOT ?', whereArgs: [removeOthersMissing]);
        for (final local in others) {
          // Only rows another Supabase user wrote (a UUID author) can have been pulled; the
          // story's demo rows and rows written before sign-in (local author ids) stay.
          if (!_supabaseUser.hasMatch('${local[owner]}')) continue;
          if (present.contains(key(local))) continue;
          await txn.delete(t.name, where: where, whereArgs: [for (final k in shape.keys) local[k]]);
          changed++;
        }
      }
      await txn.update('sync_etat', {'application': 0}, where: 'id = 1');
    });
    return changed;
  }

  Future<int> pending() async => pendingChanges(await _database.db);
}

final syncRemoteProvider = Provider<SyncRemote>((ref) => SupabaseSyncRemote());

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(appDatabaseProvider), ref.watch(syncRemoteProvider)),
);

/// Goes up each time a sync wrote pulled rows into the phone. A list fed by a synced table
/// watches it to refresh: `ref.watch(syncRevisionProvider);` in its provider.
class SyncRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final syncRevisionProvider = NotifierProvider<SyncRevision, int>(SyncRevision.new);

/// The last run, for the debug menu.
class LastSync extends Notifier<SyncReport?> {
  @override
  SyncReport? build() => null;

  void set(SyncReport r) => state = r;
}

final lastSyncProvider = NotifierProvider<LastSync, SyncReport?>(LastSync.new);

/// Runs a sync, records it for the debug menu and tells lists to refresh if rows came in.
Future<SyncReport> runSync(Ref ref) async {
  final report = await ref.read(syncServiceProvider).sync();
  ref.read(lastSyncProvider.notifier).set(report);
  if (report.received > 0) ref.read(syncRevisionProvider.notifier).bump();
  return report;
}

/// Syncs at start and every 30 s while the app runs, when Supabase is configured. Read it once
/// (main.dart); tests never start it.
final syncLoopProvider = Provider<void>((ref) {
  if (!SupabaseConfig.configured) return;
  Future<void> tick() async {
    if (await SupabaseConfig.ensureSession()) await runSync(ref);
  }

  unawaited(tick());
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => tick());
  ref.onDispose(timer.cancel);
});
