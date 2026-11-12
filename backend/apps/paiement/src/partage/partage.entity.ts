import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, OneToMany, PrimaryGeneratedColumn } from 'typeorm';

/** en_cours → complet (tout est payé) | annule (pas tout payé 3 h avant : chacun est remboursé). */
export const STATUTS_PARTAGE = ['en_cours', 'complet', 'annule'] as const;
export const STATUTS_PART = ['en_attente', 'payee', 'avancee', 'remboursee'] as const;

/** Le règlement « 3 h avant le match ». */
export const DELAI_ECHEANCE_HEURES = 3;

/** Paiement partagé d’une réservation (PAY-11) — table `paiement.partage`. */
@Entity('partage')
export class Partage {
  @PrimaryGeneratedColumn()
  id: number;

  /** La réservation (module reservation), « MU-48213 ». */
  @Index()
  @Column({ type: 'varchar', length: 40 })
  reservationId: string;

  @Index()
  @Column({ type: 'int' })
  organisateurId: number;

  /** « Arena Five · Terrain 1 » */
  @Column({ type: 'varchar', length: 255 })
  libelle: string;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  montantTotal: number;

  @Column({ type: 'int', nullable: true })
  beneficiaireId?: number | null;

  @Column({ type: 'timestamptz' })
  debutMatch: Date;

  /** debutMatch − 3 h. */
  @Column({ type: 'timestamptz' })
  echeance: Date;

  @Index()
  @Column({ type: 'varchar', length: 20, default: 'en_cours' })
  statut: string;

  @OneToMany(() => Part, (p) => p.partage, { cascade: true })
  parts?: Part[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}

/** La part d’un joueur — table `paiement.part`. */
@Entity('part')
export class Part {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  partageId: number;

  @ManyToOne(() => Partage, (p) => p.parts, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'partageId' })
  partage?: Partage;

  /** null pour un invité sans compte. */
  @Index()
  @Column({ type: 'int', nullable: true })
  joueurId?: number | null;

  @Column({ type: 'varchar', length: 120 })
  nom: string;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  montant: number;

  /** en_attente · payee · avancee (l’organisateur a payé pour lui) · remboursee */
  @Column({ type: 'varchar', length: 20, default: 'en_attente' })
  statut: string;

  /** A rejoint par la partie publique (Explorer). */
  @Column({ type: 'boolean', default: false })
  partiePublique: boolean;

  @Column({ type: 'int', nullable: true })
  paiementId?: number | null;

  @Column({ type: 'timestamptz', nullable: true })
  relanceLe?: Date | null;

  @Column({ type: 'timestamptz', nullable: true })
  payeeLe?: Date | null;

  @Column({ type: 'int', default: 0 })
  position: number;
}
