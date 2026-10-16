import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

/** Terrain — table `reservation.terrain`. */
@Entity('terrain')
export class Terrain {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 255 })
  nom: string;

  @Index()
  @Column({ type: 'varchar', length: 255 })
  etablissement: string;

  @Index()
  @Column({ type: 'varchar', length: 40 })
  sport: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  surface?: string | null;

  @Column({ type: 'boolean', default: false })
  interieur: boolean;

  @Column({ type: 'boolean', default: true })
  eclairage: boolean;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  prixHeure: number;

  @Index()
  @Column({ type: 'varchar', length: 255 })
  ville: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  adresse?: string | null;

  @Index()
  @Column({ type: 'int', nullable: true })
  proprietaireId?: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
