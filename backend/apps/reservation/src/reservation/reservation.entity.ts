import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

import { Terrain } from '../terrain/terrain.entity';

/** Réservation — table `reservation.reservation`. */
@Entity('reservation')
export class Reservation {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  terrainId: number;

  @ManyToOne(() => Terrain, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'terrainId' })
  terrain?: Terrain;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  @Column({ type: 'timestamptz' })
  debut: Date;

  @Column({ type: 'timestamptz' })
  fin: Date;

  @Column({ type: 'int', default: 10 })
  nbJoueurs: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  prixTotal: number;

  @Index()
  @Column({ type: 'varchar', length: 40, default: 'en_attente' })
  statut: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
