import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

/**
 * essai (14 jours, 0 DT) → actif (prélevé) ; impaye (prélèvement refusé) ;
 * annule (reste actif jusqu’à finLe) → expire ; en_attente_paiement (3-D Secure du 1er paiement).
 */
export const STATUTS_ABONNEMENT = ['essai', 'actif', 'impaye', 'annule', 'expire', 'en_attente_paiement'] as const;
export const ABONNEMENTS_VIVANTS = ['essai', 'actif', 'impaye', 'annule', 'en_attente_paiement'];
export const PERIODES = ['mensuel', 'annuel'] as const;
export type Periode = (typeof PERIODES)[number];

/** Abonnement d’un utilisateur à un plan — table `paiement.abonnement`. */
@Entity('abonnement')
export class Abonnement {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  /** joueur_premium, proprietaire_starter, proprietaire_pro, coach (plans.ts). */
  @Column({ type: 'varchar', length: 40 })
  plan: string;

  @Column({ type: 'varchar', length: 10 })
  periode: Periode;

  @Index()
  @Column({ type: 'varchar', length: 30 })
  statut: string;

  /** Prix de la période, hors offre. */
  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  prix: number;

  @Column({ type: 'timestamptz' })
  debutLe: Date;

  @Column({ type: 'timestamptz', nullable: true })
  finEssai?: Date | null;

  /** Date du prochain prélèvement (null une fois annulé). */
  @Column({ type: 'timestamptz', nullable: true })
  prochainPrelevement?: Date | null;

  /** Fin d’accès d’un abonnement annulé. */
  @Column({ type: 'timestamptz', nullable: true })
  finLe?: Date | null;

  @Column({ type: 'int', nullable: true })
  carteId?: number | null;

  @Column({ type: 'varchar', length: 40, nullable: true })
  motifAnnulation?: string | null;

  @Column({ type: 'text', nullable: true })
  noteAnnulation?: string | null;

  /** L’offre de rétention a déjà été proposée (une seule fois). */
  @Column({ type: 'boolean', default: false })
  offreProposee: boolean;

  /** −30 % pendant 2 mois si l’offre est acceptée. */
  @Column({ type: 'int', default: 0 })
  remisePourcentage: number;

  @Column({ type: 'timestamptz', nullable: true })
  remiseJusqua?: Date | null;

  @Column({ type: 'int', nullable: true })
  dernierPaiementId?: number | null;

  /** Changement de plan payé mais pas encore confirmé (3-D Secure) : appliqué au paiement. */
  @Column({ type: 'varchar', length: 40, nullable: true })
  planEnAttente?: string | null;

  @Column({ type: 'varchar', length: 10, nullable: true })
  periodeEnAttente?: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
