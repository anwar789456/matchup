import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

import { Tournoi } from '../tournoi/tournoi.entity';

/** Équipe — table `tournois.equipe`. */
@Entity('equipe')
export class Equipe {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  tournoiId: number;

  @ManyToOne(() => Tournoi, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tournoiId' })
  tournoi?: Tournoi;

  @Column({ type: 'varchar', length: 255 })
  nom: string;

  @Index()
  @Column({ type: 'int', nullable: true })
  capitaineId?: number | null;

  @Column({ type: 'int', array: true, default: () => "'{}'" })
  joueursIds: number[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
