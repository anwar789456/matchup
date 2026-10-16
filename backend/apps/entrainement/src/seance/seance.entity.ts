import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

import { Programme } from '../programme/programme.entity';

/** Séance — table `entrainement.seance`. */
@Entity('seance')
export class Seance {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  programmeId: number;

  @ManyToOne(() => Programme, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'programmeId' })
  programme?: Programme;

  @Column({ type: 'varchar', length: 255 })
  titre: string;

  @Column({ type: 'int', default: 1 })
  ordre: number;

  @Column({ type: 'text', nullable: true })
  contenu?: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  videoUrl?: string | null;

  @Column({ type: 'int', default: 45 })
  dureeMinutes: number;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
