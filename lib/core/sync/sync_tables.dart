/// The phone's tables that are copied to Supabase (same table and column names, plus `owner_id`).
///
/// To sync your module's table: add it here (parents before children, so a fresh phone pulls
/// them in order), run `flutter test test/supabase_schema_test.dart --update-goldens` to
/// regenerate `supabase/schema.sql`, and run that file in the Supabase SQL editor. Nothing else:
/// triggers record every insert, update and delete, and the sync service sends them.
///
/// [SyncScope.owner] rows are private to the user who wrote them (Row Level Security);
/// [SyncScope.shared] rows are readable by every signed-in user and writable by their owner.
library;

enum SyncScope { owner, shared }

class SyncTable {
  const SyncTable(this.name, {this.scope = SyncScope.owner});

  final String name;
  final SyncScope scope;
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

  // ── Réservation (Mahmoud) ────────────────────────────────────────────────────────────────
  // The player's side: booked courts, who plays, cancellations, invitations, ratings, scores.
  SyncTable('reservations'),
  SyncTable('reservation_joueurs'),
  SyncTable('annulations'),
  SyncTable('invitations'),
  SyncTable('matchs_notes'),
  SyncTable('matchs_scores'),
  // The venue owner's side: courts, bookings and arrivals, closed slots, prices and promos.
  // (`terrains` from the owner onboarding waits for `utilisateurs`: it points at an account id.)
  SyncTable('proprio_terrains'),
  SyncTable('proprio_reservations'),
  SyncTable('proprio_presences'),
  SyncTable('proprio_blocages'),
  SyncTable('tarifs'),
  SyncTable('tarif_groupes'),
  SyncTable('tarif_groupe_terrains'),
  SyncTable('dates_speciales'),
  SyncTable('promos'),

  // ── Utilisateur (Alaa) · Tournois (Ayoub) · Entraînement (Aziz) · Forum (Hani): add your
  //    tables here.
];
