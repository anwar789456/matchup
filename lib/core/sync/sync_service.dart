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

  /// Every row of [table] this user can read.
  Future<List<Map<String, Object?>>> fetchAll(String table);
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
  Future<List<Map<String, Object?>>> fetchAll(String table) async =>
      List<Map<String, Object?>>.from(await _client.from(table).select().eq('owner_id', userId!));
}

@immutable
class SyncReport {
  const SyncReport({this.sent = 0, this.received = 0, this.errors = const []});

  final int sent;
  final int received;

  /// « paiements : relation "public.paiements" does not exist »…
  final List<String> errors;

  bool get ok => errors.isEmpty;
}

/// Sends the phone's changes to Supabase and, on a phone that has never synced for this user,
/// brings their rows down first. The UI never waits for it: SQFlite stays the source of the
/// screens, the network only copies.
class SyncService {
  SyncService(this._database, this._remote);

  final AppDatabase _database;
  final SyncRemote _remote;
  Future<SyncReport>? _running;

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
      received = await _pull(db, user, errors);
      if (errors.isEmpty) {
        await db.update('sync_etat', {'utilisateur': user, 'dernier_pull': DateTime.now().toIso8601String()}, where: 'id = 1');
      }
    }
    final sent = await _push(db, user, errors);
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
          if (row == null) {
            await _remote.delete(table, {for (var i = 0; i < shape.keys.length; i++) shape.keys[i]: keyValues[i]});
          } else {
            upserts.add({...row, 'owner_id': user});
          }
        }
        if (upserts.isNotEmpty) await _remote.upsert(table, upserts, shape.keys);
        final ids = [for (final c in changes) c['id']];
        await db.delete('sync_outbox', where: 'id IN (${List.filled(ids.length, '?').join(',')})', whereArgs: ids);
        sent += latest.length;
      } catch (e) {
        errors.add('$table : $e');
      }
    }
    return sent;
  }

  /// Writes the user's rows from Supabase into the phone (update, else insert), triggers off.
  Future<int> _pull(Database db, String user, List<String> errors) async {
    var received = 0;
    for (final t in syncTables) {
      try {
        final rows = await _remote.fetchAll(t.name);
        if (rows.isEmpty) continue;
        final shape = await tableShape(db, t.name);
        await db.transaction((txn) async {
          await txn.update('sync_etat', {'application': 1}, where: 'id = 1');
          for (final remote in rows) {
            final row = {for (final c in shape.columns) if (remote.containsKey(c)) c: remote[c]};
            final where = shape.keys.map((k) => '"$k" = ?').join(' AND ');
            final args = [for (final k in shape.keys) row[k]];
            if (await txn.update(t.name, row, where: where, whereArgs: args) == 0) {
              await txn.insert(t.name, row);
            }
            received++;
          }
          await txn.update('sync_etat', {'application': 0}, where: 'id = 1');
        });
      } catch (e) {
        errors.add('${t.name} : $e');
      }
    }
    return received;
  }

  Future<int> pending() async => pendingChanges(await _database.db);
}

final syncRemoteProvider = Provider<SyncRemote>((ref) => SupabaseSyncRemote());

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(appDatabaseProvider), ref.watch(syncRemoteProvider)),
);

/// The last run, for the debug menu.
class LastSync extends Notifier<SyncReport?> {
  @override
  SyncReport? build() => null;

  void set(SyncReport r) => state = r;
}

final lastSyncProvider = NotifierProvider<LastSync, SyncReport?>(LastSync.new);

/// Syncs at start and every 30 s while the app runs, when Supabase is configured. Read it once
/// (main.dart); tests never start it.
final syncLoopProvider = Provider<void>((ref) {
  if (!SupabaseConfig.configured) return;
  Future<void> tick() async {
    if (!await SupabaseConfig.ensureSession()) return;
    ref.read(lastSyncProvider.notifier).set(await ref.read(syncServiceProvider).sync());
  }

  unawaited(tick());
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => tick());
  ref.onDispose(timer.cancel);
});
