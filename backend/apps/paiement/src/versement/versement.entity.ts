import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

export const ROLES_BENEFICIAIRE = ['proprietaire', 'coach', 'organisateur'] as const;
export type RoleBeneficiaire = (typeof ROLES_BENEFICIAIRE)[number];

/**
 * Commission MatchUp prélevée sur un versement. Le brief fixe 10 % pour les coachs ; les
 * propriétaires paient leur abonnement (Starter / Pro) et les organisateurs ne paient rien de plus.
 */
export const COMMISSIONS: Record<RoleBeneficiaire, number> = { proprietaire: 0, coach: 0.1, organisateur: 0 };

/** en_attente → valide (admin, ADM-07) → envoye (virement parti). */
export const STATUTS_VERSEMENT = ['en_attente', 'valide', 'envoye'] as const;

/** Virement d’une période à un propriétaire, coach ou organisateur — table `paiement.versement`. */
@Entity('versement')
export class Versement {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  beneficiaireId: number;

  @Column({ type: 'varchar', length: 20 })
  role: RoleBeneficiaire;

  @Column({ type: 'timestamptz' })
  du: Date;

  @Column({ type: 'timestamptz' })
  au: Date;

  @Column({ type: 'int' })
  nbPaiements: number;

  /** Encaissé sur la période. */
  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  montantBrut: number;

  /** Déjà rendu aux joueurs. */
  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  montantRembourse: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  commission: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  montantNet: number;

  @Index()
  @Column({ type: 'varchar', length: 20, default: 'en_attente' })
  statut: string;

  /** « VIR-2026-00012 » une fois envoyé. */
  @Column({ type: 'varchar', length: 30, nullable: true })
  reference?: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  valideLe?: Date | null;

  @Column({ type: 'timestamptz', nullable: true })
  envoyeLe?: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
