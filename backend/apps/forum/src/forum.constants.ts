/**
 * The forum's vocabulary, as in the screens (FRM-01…05, ADM-09/10). Every list below is the
 * single source for the DTO validation, the entities and the Swagger docs.
 */

/** FRM-01 « Catégories ». */
export const CATEGORIES = ['conseils_technique', 'equipement', 'terrains', 'tournois', 'discussions_libres'] as const;
export type Categorie = (typeof CATEGORIES)[number];

/** Sport chips (FRM-01 / FRM-02). A post without sport is shown under « Tous les sports ». */
export const SPORTS = ['football', 'padel', 'basketball'] as const;
export type Sport = (typeof SPORTS)[number];

/** FRM-01 sort: Tendance · Récents · Top. */
export const TRIS_SUJETS = ['tendance', 'recents', 'top'] as const;
export type TriSujets = (typeof TRIS_SUJETS)[number];

/** FRM-04 « Les plus utiles » menu. */
export const TRIS_REPONSES = ['utiles', 'recentes', 'anciennes'] as const;
export type TriReponses = (typeof TRIS_REPONSES)[number];

/**
 * Life of a post or a reply.
 * - `publie`: visible to everyone.
 * - `masque`: hidden while a moderator checks it (« Masqué par la modération · en cours de
 *   vérification »). Its author still sees it, everyone else sees the placeholder.
 * - `supprime`: removed (by its author or a moderator). A reply that still has answers keeps its
 *   place as « Message supprimé » so the thread stays readable.
 */
export const STATUTS_CONTENU = ['publie', 'masque', 'supprime'] as const;
export type StatutContenu = (typeof STATUTS_CONTENU)[number];

/** What a vote, reaction, report or moderation decision points at. */
export const CIBLES = ['sujet', 'message'] as const;
export type Cible = (typeof CIBLES)[number];

/** FRM-04 reactions next to the votes. */
export const REACTIONS = ['utile', 'merci'] as const;
export type TypeReaction = (typeof REACTIONS)[number];

/** FRM-05 « Signaler ce commentaire ». */
export const MOTIFS_SIGNALEMENT = ['spam', 'insulte', 'choquant', 'fausse_information', 'autre'] as const;
export type MotifSignalement = (typeof MOTIFS_SIGNALEMENT)[number];

/** ADM-10 « Ta décision ». */
export const DECISIONS = ['approuver', 'supprimer', 'supprimer_avertir', 'suspendre'] as const;
export type Decision = (typeof DECISIONS)[number];

/** ADM-09 type filter. */
export const TYPES_FILE = ['tout', 'sujet', 'message'] as const;

export const LIMITES = {
  titreMin: 10,
  titreMax: 120,
  contenuMax: 2000,
  reponseMax: 2000,
  images: 4,
  tags: 5,
  tagMax: 30,
  /** Reports from different people that hide a content until a moderator decides (ADM-10 « masqué au 3e »). */
  signalementsAvantMasquage: 3,
  /** Warnings that trigger a suspension (ADM-10 « Au 3e : suspension de 7 jours »). */
  avertissementsAvantSuspension: 3,
  joursSuspension: 7,
  /** AI score from which the author is asked to review the text before publishing (FRM-03). */
  seuilAlerte: 0.5,
  pageMax: 50,
} as const;
