import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'database_factory.dart';
import '../sync/sync_outbox.dart';
import 'schema.dart';
import 'seed.dart';

/// The app's local database (sqflite): everything the app shows or changes lives on the phone
/// (IndexedDB in the browser). Opened once, on first use. A new file runs every schema version
/// (lib/core/db/schema.dart) and writes the story's data (design/screens/STORY-DATA.md); an
/// older file only runs the versions it lacks, keeping what the player already did.
///
/// v1: `utilisateurs`, `codes`, `terrains`, `reservations`, `reservation_joueurs`,
/// `annulations`, `invitations`, `matchs_notes`, `matchs_scores`.
///
/// v2: settings and drafts (`preferences`, `brouillons`, `recherches_recentes`,
/// `reglages_compte`, `sessions_appareils`), money (`porte_monnaie`, `transactions`,
/// `demandes_remboursement`, `cartes`, `paiements`, `codes_promo`, `abonnement`, `recus`,
/// `recu_lignes`), the player (`notifications`, `parties`, `partie_joueurs`, `participations`,
/// `profil_joueur`, `joueurs_suivis`, `niveaux_ajustes`), catalogues (`etablissements` and its
/// sports, amenities and slots, `tournois`, `zones`, `zone_etablissements`, `joueurs_recherche`,
/// `coequipiers`), the owner space (`proprio_terrains`, `proprio_reservations`,
/// `proprio_presences`, `proprio_blocages`, `tarifs`, `tarif_groupes`, `tarif_groupe_terrains`,
/// `dates_speciales`, `promos`, `avis_etablissement`, `avis_repartition`, `proprio_clientele`,
/// `proprio_clients`, `client_reservations`) and `admin_journal`.
///
/// v5: the Communauté (`forum_membres`, `forum_sujets`, `forum_messages`, `forum_votes`,
/// `forum_reactions`, `forum_favoris`, `forum_suivis`, `forum_blocages`, `forum_visites`,
/// `forum_signalements`, `forum_sanctions`), text ids and an `auteur_id` per row, ready for Supabase sync.
///
/// v6: Équipement as a marketplace (`forum_annonces`, `forum_avis`, synced) and messages
/// between friends and group chats (`msg_conversations`, `msg_participants`,
/// `msg_messages`, `msg_reactions`, `msg_votes`, `msg_lectures`), on the phone only until the
/// sync has a « participants only » scope.
class AppDatabase {
  /// [factory] and [path] default to [defaultFactory] / [defaultPath].
  AppDatabase({DatabaseFactory? factory, String? path})
      : factory = factory ?? defaultFactory,
        path = path ?? defaultPath;

  static const fileName = 'matchup.db';
  static final int version = schemaVersions.keys.reduce((a, b) => a > b ? a : b);

  /// The platform's factory unless changed (tests use sqflite's FFI one, in memory).
  static DatabaseFactory? defaultFactory;
  static String defaultPath = fileName;

  final DatabaseFactory? factory;
  final String path;
  Future<Database>? _db;

  /// Runs versions ([from], [to]] in order, each with its seed, in one transaction per version.
  static Future<void> _migrate(Database db, int from, int to) async {
    for (var v = from + 1; v <= to; v++) {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final statement in schemaVersions[v]!) {
          batch.execute(statement);
        }
        await batch.commit(noResult: true);
        await seedVersion(txn, v);
      });
    }
  }

  /// The open database (created or upgraded on the first call).
  Future<Database> get db => _db ??= (factory ?? appDatabaseFactory).openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: version,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, v) => _migrate(db, 0, v),
          onUpgrade: _migrate,
          // After the migrations: the triggers follow the synced tables' current columns.
          onOpen: installSyncTriggers,
        ),
      );

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await (await db).close();
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
