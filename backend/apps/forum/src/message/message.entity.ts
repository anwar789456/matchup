import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

import { Sujet } from '../sujet/sujet.entity';

/** Message — table `forum.message`. */
@Entity('message')
export class Message {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  sujetId: number;

  @ManyToOne(() => Sujet, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'sujetId' })
  sujet?: Sujet;

  @Index()
  @Column({ type: 'int' })
  auteurId: number;

  @Column({ type: 'text' })
  contenu: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
