/// The phone's tables that are copied to Supabase (same table and column names, plus `owner_id`).
///
/// To sync your module's table: add it here (parents before children, so a fresh phone pulls
/// them in order), run `flutter test test/supabase_schema_test.dart --update-goldens` to
/// regenerate `supabase/schema.sql`, and run that file in the Supabase SQL editor. Nothing else:
/// triggers record every insert, update and delete, and the sync service sends them.
///
/// [SyncScope.owner] rows are private to the user who wrote them (Row Level Security); a phone
/// pulls them once, when it first syncs for that user.
///
/// [SyncScope.shared] rows (forum posts, tournaments…) are read by everyone and pulled from
/// everyone at every sync. Such a table needs:
/// - text ids made on the phone (a UUID), so two people's rows never share a key;
/// - an [SyncTable.ownerColumn] holding the author's Supabase user id
///   (`SupabaseConfig.userId`): a phone only sends the rows it authored, and Supabase refuses
///   a row whose author is someone else;
/// - one row per person for what several people change (a vote, a report), never a counter
///   written into someone else's row.
library;

enum SyncScope { owner, shared }

class SyncTable {
  const SyncTable(this.name, {this.scope = SyncScope.owner, this.ownerColumn})
    : assert(scope == SyncScope.owner || ownerColumn != null, 'A shared table needs an ownerColumn.');

  final String name;
  final SyncScope scope;

  /// Shared tables: the column with the author's Supabase user id (`auteur_id`…).
  final String? ownerColumn;

  bool get shared => scope == SyncScope.shared;
}

const syncTables = <SyncTable>[
  // ── Paiement (Anwar) ─────────────────────────────────────────────────────────────────────
  SyncTable('porte_monnaie'),
  SyncTable('transactions'),
  SyncTable('demandes_remboursement'),
  SyncTable('cartes'),
  SyncTable('paiements'),
  SyncTable('tentatives_paiement'),
  SyncTable('parts_paiement'),
  SyncTable('abonnement'),
  SyncTable('recus'),
  SyncTable('recu_lignes'),

  // ── Utilisateur (Alaa) · Réservation (Mahmoud) · Tournois (Ayoub) · Entraînement (Aziz) ·
  //    Forum (Hani): add your tables here.
];
