import { Column, CreateDateColumn, Entity, Index, PrimaryColumn, PrimaryGeneratedColumn, Unique, UpdateDateColumn } from 'typeorm';

import type { Cible, TypeReaction } from '../forum.constants';

/** An up (+1) or down (−1) vote on a post or a reply — table `forum.vote`. One per person and content. */
@Entity('vote')
@Unique(['utilisateurId', 'cible', 'cibleId'])
@Index(['cible', 'cibleId'])
export class Vote {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  @Column({ type: 'varchar', length: 10 })
  cible: Cible;

  @Column({ type: 'int' })
  cibleId: number;

  /** +1 or −1. */
  @Column({ type: 'smallint' })
  valeur: number;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}

/** « Utile » / « Merci » on a post or a reply (FRM-04) — table `forum.reaction`. */
@Entity('reaction')
@Unique(['utilisateurId', 'cible', 'cibleId', 'type'])
@Index(['cible', 'cibleId'])
export class Reaction {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  @Column({ type: 'varchar', length: 10 })
  cible: Cible;

  @Column({ type: 'int' })
  cibleId: number;

  @Column({ type: 'varchar', length: 10 })
  type: TypeReaction;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}

/** A saved post (FRM-01 bookmark icon) — table `forum.favori`. */
@Entity('favori')
@Unique(['utilisateurId', 'sujetId'])
export class Favori {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  @Index()
  @Column({ type: 'int' })
  sujetId: number;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}

/**
 * Following a discussion (FRM-04 bell: notified of new replies) or a member (FRM-04 « Suivre »)
 * — table `forum.suivi`. Authors follow their own posts automatically.
 */
@Entity('suivi')
@Unique(['utilisateurId', 'type', 'cibleId'])
@Index(['type', 'cibleId'])
export class Suivi {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  /** `sujet` (a discussion) or `membre` (a user id of the utilisateur module). */
  @Column({ type: 'varchar', length: 10 })
  type: 'sujet' | 'membre';

  @Column({ type: 'int' })
  cibleId: number;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}

/** « Ne plus voir les messages de … » (FRM-05) — table `forum.blocage`. */
@Entity('blocage')
@Unique(['utilisateurId', 'bloqueId'])
export class Blocage {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  /** The author whose posts and replies are no longer shown to `utilisateurId`. */
  @Column({ type: 'int' })
  bloqueId: number;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}

/** When someone last opened the forum (FRM-01 « Nouveaux depuis ta dernière visite ») — table `forum.visite`. */
@Entity('visite')
export class Visite {
  /** One row per user: the user id is the key. */
  @PrimaryColumn({ type: 'int' })
  utilisateurId: number;

  @Column({ type: 'timestamptz' })
  derniereVisite: Date;
}
