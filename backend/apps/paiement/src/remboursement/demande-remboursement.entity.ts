import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

export const MOTIFS_REMBOURSEMENT = ['terrain_ferme', 'partie_annulee', 'paye_deux_fois', 'autre'] as const;
export const CIBLES_REMBOURSEMENT = ['portefeuille', 'carte'] as const;
/** envoyee → en_examen → remboursee | refusee */
export const STATUTS_DEMANDE = ['envoyee', 'en_examen', 'remboursee', 'refusee'] as const;
export const DEMANDES_OUVERTES = ['envoyee', 'en_examen'];

/** Demande de remboursement d’un joueur (WAL-04 / WAL-05) — table `paiement.demande_remboursement`. */
@Entity('demande_remboursement')
export class DemandeRemboursement {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  @Index()
  @Column({ type: 'int' })
  paiementId: number;

  @Column({ type: 'varchar', length: 20 })
  motif: string;

  @Column({ type: 'text', default: '' })
  note: string;

  /** Solde : sous 5 jours ouvrés · carte : sous 10. */
  @Column({ type: 'varchar', length: 20 })
  cible: string;

  @Column({ type: 'int', default: 0 })
  photos: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  montant: number;

  @Index()
  @Column({ type: 'varchar', length: 20, default: 'envoyee' })
  statut: string;

  @Column({ type: 'text', nullable: true })
  motifRefus?: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  examenDepuis?: Date | null;

  @Column({ type: 'timestamptz', nullable: true })
  traiteLe?: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
