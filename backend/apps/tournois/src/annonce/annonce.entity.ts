import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';

import { Tournoi } from '../tournoi/tournoi.entity';

/** Annonce de l’organisateur aux équipes d’un tournoi — table `tournois.annonce`. */
@Entity('annonce')
export class Annonce {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  tournoiId: number;

  @ManyToOne(() => Tournoi, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tournoiId' })
  tournoi?: Tournoi;

  @Column({ type: 'varchar', length: 255 })
  titre: string;

  @Column({ type: 'text' })
  message: string;

  /** toutes | confirmees | en_attente */
  @Column({ type: 'varchar', length: 20, default: 'confirmees' })
  destinataires: string;

  /** Envoyer aussi par email (en plus de la notification). */
  @Column({ type: 'boolean', default: true })
  email: boolean;

  /** ids des joueurs visés au moment de l’envoi (pour le module notifications). */
  @Column({ type: 'int', array: true, default: () => "'{}'" })
  destinatairesIds: number[];

  @Column({ type: 'int', nullable: true })
  auteurId?: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
