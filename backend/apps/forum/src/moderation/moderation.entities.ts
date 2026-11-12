import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, Unique } from 'typeorm';

import type { Cible, Decision, MotifSignalement } from '../forum.constants';

/**
 * A report — table `forum.signalement`. Made by a member (FRM-05) or by the AI when an author
 * publishes despite the FRM-03 warning (`signaleurId` null). One open report per person and
 * content. Closed together when a moderator decides (ADM-10).
 */
@Entity('signalement')
@Unique(['signaleurId', 'cible', 'cibleId'])
@Index(['cible', 'cibleId', 'statut'])
export class Signalement {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 10 })
  cible: Cible;

  @Column({ type: 'int' })
  cibleId: number;

  /** Who reported (user id), null when it is the AI. Never shown to the author: reports are anonymous. */
  @Column({ type: 'int', nullable: true })
  signaleurId: number | null;

  @Column({ type: 'varchar', length: 30 })
  motif: MotifSignalement;

  /** Free text for « Autre chose ». */
  @Column({ type: 'varchar', length: 500, nullable: true })
  details: string | null;

  /** `ouvert` until a moderator decides, then `traite`. */
  @Index()
  @Column({ type: 'varchar', length: 10, default: 'ouvert' })
  statut: 'ouvert' | 'traite';

  @Column({ type: 'varchar', length: 30, nullable: true })
  decision: Decision | null;

  @Column({ type: 'int', nullable: true })
  moderateurId: number | null;

  @Column({ type: 'timestamptz', nullable: true })
  traiteLe: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}

/**
 * A warning or a suspension given in the forum — table `forum.sanction`. Suspended members can
 * still read but cannot post, reply, vote or react until `jusquA`.
 */
@Entity('sanction')
@Index(['utilisateurId', 'type'])
export class Sanction {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int' })
  utilisateurId: number;

  @Column({ type: 'varchar', length: 15 })
  type: 'avertissement' | 'suspension';

  /** Shown to the member (« Propos insultants envers un joueur »). */
  @Column({ type: 'varchar', length: 255 })
  motif: string;

  /** The content that led to it. */
  @Column({ type: 'varchar', length: 10, nullable: true })
  cible: Cible | null;

  @Column({ type: 'int', nullable: true })
  cibleId: number | null;

  /** End of a suspension; null for a warning. */
  @Column({ type: 'timestamptz', nullable: true })
  jusquA: Date | null;

  @Column({ type: 'int', nullable: true })
  moderateurId: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
