import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

export const SPORTS = ['football', 'padel', 'basketball'] as const;
/** Un tournoi se joue en équipes ; un événement (soirée, initiation) s’inscrit en individuel. */
export const TYPES_TOURNOI = ['tournoi', 'evenement'] as const;
export const FORMATS = ['elimination_directe', 'poules_phase_finale'] as const;
/**
 * brouillon → inscriptions_ouvertes (publié) → inscriptions_fermees → en_cours → termine.
 * annule possible à tout moment avant la fin.
 */
export const STATUTS_TOURNOI = [
  'brouillon',
  'inscriptions_ouvertes',
  'inscriptions_fermees',
  'en_cours',
  'termine',
  'annule',
] as const;

/** Tournoi ou événement — table `tournois.tournoi`. */
@Entity('tournoi')
export class Tournoi {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 255 })
  nom: string;

  @Index()
  @Column({ type: 'varchar', length: 20, default: 'tournoi' })
  type: string;

  @Index()
  @Column({ type: 'varchar', length: 40 })
  sport: string;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  /** Affiche du tournoi (URL d’image). */
  @Column({ type: 'varchar', length: 500, nullable: true })
  afficheUrl?: string | null;

  @Column({ type: 'varchar', length: 40, default: 'elimination_directe' })
  format: string;

  @Column({ type: 'text', nullable: true })
  reglement?: string | null;

  /** Niveau MatchUp (1 à 7) conseillé ; null = ouvert à tous. */
  @Column({ type: 'numeric', precision: 3, scale: 1, transformer: decimal, nullable: true })
  niveauMin?: number | null;

  @Column({ type: 'numeric', precision: 3, scale: 1, transformer: decimal, nullable: true })
  niveauMax?: number | null;

  @Column({ type: 'timestamptz' })
  dateDebut: Date;

  @Column({ type: 'timestamptz', nullable: true })
  dateFin?: Date | null;

  /** Fin des inscriptions ; null = jusqu’à la clôture par l’organisateur. */
  @Column({ type: 'timestamptz', nullable: true })
  dateLimiteInscription?: Date | null;

  @Column({ type: 'varchar', length: 255 })
  lieu: string;

  @Index()
  @Column({ type: 'varchar', length: 120, nullable: true })
  ville?: string | null;

  /** id du lieu dans le module réservation (facultatif). */
  @Column({ type: 'int', nullable: true })
  terrainId?: number | null;

  /** Terrains / courts utilisés : « Terrain 1 », « Court 2 »… */
  @Column({ type: 'varchar', array: true, default: () => "'{}'" })
  terrains: string[];

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  fraisInscription: number;

  /** Dotation totale en DT (affichée sur la carte). */
  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  dotation: number;

  /** Détail des prix : [{ rang: 1, libelle: '600 DT + trophée' }, …] */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  prix: { rang: number; libelle: string }[];

  @Column({ type: 'int', default: 16 })
  nbEquipesMax: number;

  @Column({ type: 'int', default: 1 })
  joueursParEquipe: number;

  @Column({ type: 'int', nullable: true })
  joueursMaxParEquipe?: number | null;

  /** Format poules + phase finale. */
  @Column({ type: 'int', nullable: true })
  nbPoules?: number | null;

  @Column({ type: 'int', default: 2 })
  qualifiesParPoule: number;

  @Column({ type: 'int', default: 60 })
  dureeMatchMinutes: number;

  @Column({ type: 'int', default: 15 })
  reposMinutes: number;

  @Index()
  @Column({ type: 'varchar', length: 40, default: 'brouillon' })
  statut: string;

  @Column({ type: 'boolean', default: false })
  tableauPublie: boolean;

  @Column({ type: 'timestamptz', nullable: true })
  publieLe?: Date | null;

  @Column({ type: 'int', nullable: true })
  vainqueurEquipeId?: number | null;

  @Column({ type: 'text', nullable: true })
  motifAnnulation?: string | null;

  @Index()
  @Column({ type: 'int', nullable: true })
  organisateurId?: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
