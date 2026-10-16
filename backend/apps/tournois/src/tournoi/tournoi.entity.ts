import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

/** Tournoi — table `tournois.tournoi`. */
@Entity('tournoi')
export class Tournoi {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 255 })
  nom: string;

  @Index()
  @Column({ type: 'varchar', length: 40 })
  sport: string;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @Column({ type: 'timestamptz' })
  dateDebut: Date;

  @Column({ type: 'timestamptz', nullable: true })
  dateFin?: Date | null;

  @Column({ type: 'varchar', length: 255 })
  lieu: string;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  fraisInscription: number;

  @Column({ type: 'int', default: 16 })
  nbEquipesMax: number;

  @Index()
  @Column({ type: 'varchar', length: 40, default: 'brouillon' })
  statut: string;

  @Index()
  @Column({ type: 'int', nullable: true })
  organisateurId?: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
