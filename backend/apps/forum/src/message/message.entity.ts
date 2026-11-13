import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

import type { StatutContenu } from '../forum.constants';
import { Sujet } from '../sujet/sujet.entity';

/**
 * A reply in a discussion — table `forum.message`. FRM-04.
 *
 * Two levels, as in the screen: `parentId` is null for a reply to the post, or the id of a
 * level-1 reply. Answering a level-2 reply attaches to its level-1 parent (and mentions its
 * author), so the thread never goes deeper.
 */
@Entity('message')
@Index(['sujetId', 'parentId'])
export class Message {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  sujetId: number;

  @ManyToOne(() => Sujet, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'sujetId' })
  sujet?: Sujet;

  /** null = level 1 (reply to the post); else the level-1 reply it answers. */
  @Column({ type: 'int', nullable: true })
  parentId: number | null;

  @ManyToOne(() => Message, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'parentId' })
  parent?: Message | null;

  /** id of a user (utilisateur module). */
  @Index()
  @Column({ type: 'int' })
  auteurId: number;

  /** The user this reply answers (« Ta réponse à Omar D. »), when it answers a reply. */
  @Column({ type: 'int', nullable: true })
  enReponseAId: number | null;

  @Column({ type: 'text' })
  contenu: string;

  /** `@pseudo` handles found in the text, lower case. */
  @Column({ type: 'text', array: true, default: '{}' })
  mentions: string[];

  @Index()
  @Column({ type: 'varchar', length: 20, default: 'publie' })
  statut: StatutContenu;

  @Column({ type: 'int', default: 0 })
  score: number;

  @Column({ type: 'int', default: 0 })
  nbUtile: number;

  @Column({ type: 'int', default: 0 })
  nbMerci: number;

  /** AI toxicity / spam score when written (0 → 1). */
  @Column({ type: 'real', default: 0 })
  scoreIa: number;

  @Column({ type: 'varchar', length: 80, nullable: true })
  motifIa: string | null;

  /** The author saw the FRM-03 warning and chose « Publier quand même ». */
  @Column({ type: 'boolean', default: false })
  publieMalgreAlerte: boolean;

  /** Last edit by its author (« modifié »), null if never edited. */
  @Column({ type: 'timestamptz', nullable: true })
  modifieLe: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
