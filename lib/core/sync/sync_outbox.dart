import 'package:sqflite/sqflite.dart';

import 'sync_tables.dart';

/// A synced table as the phone's database describes it.
class TableShape {
  const TableShape(this.name, this.columns, this.keys, this.types, this.notNull);

  final String name;
  final List<String> columns;

  /// Primary key columns, in order (at most 3).
  final List<String> keys;

  /// Declared SQLite type of each column (TEXT, INTEGER, REAL…).
  final Map<String, String> types;
  final Set<String> notNull;
}

Future<TableShape> tableShape(DatabaseExecutor db, String table) async {
  final info = await db.rawQuery('PRAGMA table_info("$table")');
  if (info.isEmpty) throw StateError('Table de synchro inconnue : $table');
  final keyed = [for (final c in info) if ((c['pk']! as int) > 0) c]
    ..sort((a, b) => (a['pk']! as int).compareTo(b['pk']! as int));
  if (keyed.isEmpty || keyed.length > 3) {
    throw StateError('La table $table doit avoir une clé primaire de 1 à 3 colonnes pour être synchronisée.');
  }
  return TableShape(
    table,
    [for (final c in info) c['name']! as String],
    [for (final c in keyed) c['name']! as String],
    {for (final c in info) c['name']! as String: (c['type'] as String? ?? '').toUpperCase()},
    {for (final c in info) if (c['notnull'] == 1) c['name']! as String},
  );
}

/// (Re)creates the insert / update / delete triggers of every [syncTables] table, so a column
/// added by a later schema version is followed. Each change adds a `sync_outbox` row with the
/// table and the key; the sync service reads the row itself when it sends it. While the service
/// writes what it pulled, `sync_etat.application = 1` keeps the triggers quiet.
Future<void> installSyncTriggers(DatabaseExecutor db, {List<SyncTable> tables = syncTables}) async {
  for (final t in tables) {
    final s = await tableShape(db, t.name);
    String keys(String row) => [
          for (var i = 0; i < 3; i++) i < s.keys.length ? 'CAST($row."${s.keys[i]}" AS TEXT)' : 'NULL',
        ].join(', ');
    const quiet = '(SELECT application FROM sync_etat WHERE id = 1) = 0';
    const now = "strftime('%Y-%m-%dT%H:%M:%fZ', 'now')";
    const into = 'INSERT INTO sync_outbox (tableau, operation, k1, k2, k3, le)';
    for (final (event, op, row) in [('INSERT', 'upsert', 'NEW'), ('UPDATE', 'upsert', 'NEW'), ('DELETE', 'delete', 'OLD')]) {
      final name = 'sync_${event.toLowerCase()}_${t.name}';
      await db.execute('DROP TRIGGER IF EXISTS "$name"');
      await db.execute(
        'CREATE TRIGGER "$name" AFTER $event ON "${t.name}" WHEN $quiet '
        "BEGIN $into VALUES ('${t.name}', '$op', ${keys(row)}, $now); END",
      );
    }
  }
}

/// Changes waiting to be sent.
Future<int> pendingChanges(DatabaseExecutor db) async =>
    Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sync_outbox')) ?? 0;
