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

  // ── Utilisateur (Alaa): the account's profile (PRF-01/04) and settings (SET-02/05), private ──
  SyncTable('reglages_compte'),
  SyncTable('profil_joueur'),

  // ── Réservation (Mahmoud) ────────────────────────────────────────────────────────────────
  // Booked courts (reservations, reservation_joueurs, annulations) are not copied: Supabase is
  // their source of truth (supabase/reservation.sql, SupabaseBookingsRepository). Copied here:
  // what only concerns the player (invitations, ratings, scores)…
  SyncTable('invitations'),
  SyncTable('matchs_notes'),
  SyncTable('matchs_scores'),
  // The venue owner's side: courts, bookings and arrivals, the price list and promos. (Closed
  // slots live in Supabase's `blocages`: SupabaseOwnerRepository.)
  // (`terrains` from the owner onboarding waits for `utilisateurs`: it points at an account id.)
  SyncTable('proprio_terrains'),
  SyncTable('proprio_reservations'),
  SyncTable('proprio_presences'),
  SyncTable('tarifs'),
  SyncTable('tarif_groupes'),
  SyncTable('tarif_groupe_terrains'),
  SyncTable('dates_speciales'),
  SyncTable('promos'),

  // ── Entraînement (Aziz) ──────────────────────────────────────────────────────────────────
  SyncTable('entrainement_profil'),
  SyncTable('entrainement_inscriptions'),
  SyncTable('entrainement_seances'),
  SyncTable('entrainement_plans'),
  SyncTable('entrainement_analyses'),
  SyncTable('entrainement_favoris'),
  SyncTable('entrainement_avis'),
  SyncTable('coach_brouillons'),
  SyncTable('coach_actions'),
  SyncTable('coach_retours'),

  // ── Forum (Hani) ─────────────────────────────────────────────────────────────────────────
  // Shared: what every member must see (profiles, posts, replies, votes, reactions).
  SyncTable('forum_membres', scope: SyncScope.shared, ownerColumn: 'auteur_id'),
  SyncTable('forum_sujets', scope: SyncScope.shared, ownerColumn: 'auteur_id'),
  SyncTable('forum_messages', scope: SyncScope.shared, ownerColumn: 'auteur_id'),
  SyncTable('forum_votes', scope: SyncScope.shared, ownerColumn: 'auteur_id'),
  SyncTable('forum_reactions', scope: SyncScope.shared, ownerColumn: 'auteur_id'),
  // Private to their member: reports stay anonymous (FRM-05: the Supabase trigger counts them
  // without exposing who reported), saved / followed / muted lists and the last visit.
  SyncTable('forum_signalements'),
  SyncTable('forum_favoris'),
  SyncTable('forum_suivis'),
  SyncTable('forum_blocages'),
  SyncTable('forum_visites'),

  // ── Tournois (Ayoub): add your tables here.
];
