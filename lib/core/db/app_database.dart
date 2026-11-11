import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'database_factory.dart';
import 'seed.dart';

/// The app's local database (sqflite): accounts, courts, bookings and their follow-ups all live on
/// the phone (the team's server is gone). Opened once, on first use; the story's data
/// (design/screens/STORY-DATA.md) is written in when the file is created.
///
/// Tables (French names, like the old backend):
/// - `utilisateurs`: accounts (AUTH-01, PLY-10, AUTH-11); the password is a salted SHA-256.
/// - `codes`: the SMS and reset codes (AUTH-03, AUTH-07), hashed, with tries and blocks.
/// - `terrains`: the courts an owner publishes (OWN-08).
/// - `reservations` + `reservation_joueurs`: booked courts and who plays (BKG-05, MAT-01).
/// - `annulations`: the cancelled ones and their refunds (MAT-03).
/// - `invitations`: invitations to a game and the answer (MAT-01).
/// - `matchs_notes`, `matchs_scores`: ratings and scores entered after a match (MAT-07, MAT-09).
class AppDatabase {
  /// [factory] defaults to the platform's ([appDatabaseFactory]); tests pass sqflite's FFI one.
  AppDatabase({this.factory, this.path = fileName});

  static const fileName = 'matchup.db';
  static const version = 1;

  final DatabaseFactory? factory;
  final String path;
  Future<Database>? _db;

  /// The open database (opened and seeded on the first call).
  Future<Database> get db => _db ??= (factory ?? appDatabaseFactory).openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: version,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, _) async {
            final batch = db.batch();
            for (final statement in schema) {
              batch.execute(statement);
            }
            await batch.commit(noResult: true);
            await seedStory(db);
          },
        ),
      );

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await (await db).close();
  }

  static const schema = [
    '''
    CREATE TABLE utilisateurs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL UNIQUE,
      mot_de_passe TEXT NOT NULL,
      sel TEXT NOT NULL,
      pseudo TEXT UNIQUE,
      prenom TEXT,
      nom TEXT,
      telephone TEXT,
      telephone_verifie INTEGER NOT NULL DEFAULT 0,
      email_verifie INTEGER NOT NULL DEFAULT 0,
      role TEXT NOT NULL DEFAULT 'joueur',
      cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE codes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL,
      usage TEXT NOT NULL CHECK (usage IN ('telephone', 'reinitialisation')),
      hash TEXT NOT NULL,
      expire_le TEXT NOT NULL,
      essais INTEGER NOT NULL DEFAULT 0,
      bloque_jusqua TEXT,
      utilise INTEGER NOT NULL DEFAULT 0,
      cree_le TEXT NOT NULL
    )''',
    'CREATE INDEX codes_email ON codes (email, usage)',
    '''
    CREATE TABLE terrains (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      proprietaire_id INTEGER REFERENCES utilisateurs (id) ON DELETE CASCADE,
      nom TEXT NOT NULL,
      etablissement TEXT NOT NULL,
      sport TEXT NOT NULL,
      surface TEXT,
      interieur INTEGER NOT NULL DEFAULT 0,
      eclairage INTEGER NOT NULL DEFAULT 0,
      prix_heure REAL NOT NULL,
      ville TEXT,
      adresse TEXT,
      cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE reservations (
      reference TEXT PRIMARY KEY,
      sport TEXT NOT NULL,
      etablissement TEXT NOT NULL,
      terrain TEXT,
      lieu TEXT NOT NULL,
      debut TEXT NOT NULL,
      fin TEXT NOT NULL,
      part REAL NOT NULL,
      statut TEXT NOT NULL,
      payer_avant TEXT,
      remboursement REAL,
      cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE reservation_joueurs (
      reference TEXT NOT NULL REFERENCES reservations (reference) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      nom TEXT NOT NULL,
      image_url TEXT,
      PRIMARY KEY (reference, position)
    )''',
    '''
    CREATE TABLE annulations (
      reference TEXT PRIMARY KEY REFERENCES reservations (reference) ON DELETE CASCADE,
      annule_par TEXT NOT NULL,
      par_moi INTEGER NOT NULL DEFAULT 0,
      raison TEXT,
      rembourse_le TEXT NOT NULL,
      remboursement REAL NOT NULL,
      joueurs_rembourses INTEGER NOT NULL DEFAULT 1,
      total_rembourse REAL
    )''',
    '''
    CREATE TABLE invitations (
      id TEXT PRIMARY KEY,
      de TEXT NOT NULL,
      sport TEXT NOT NULL,
      etablissement TEXT NOT NULL,
      lieu TEXT NOT NULL,
      debut TEXT NOT NULL,
      part REAL NOT NULL,
      places_total INTEGER NOT NULL,
      places_restantes INTEGER NOT NULL,
      statut TEXT NOT NULL DEFAULT 'attente' CHECK (statut IN ('attente', 'acceptee', 'refusee'))
    )''',
    'CREATE TABLE matchs_notes (match_id TEXT PRIMARY KEY, note_le TEXT NOT NULL)',
    '''
    CREATE TABLE matchs_scores (
      match_id TEXT NOT NULL,
      set_index INTEGER NOT NULL,
      nous INTEGER NOT NULL,
      eux INTEGER NOT NULL,
      PRIMARY KEY (match_id, set_index)
    )''',
  ];
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
