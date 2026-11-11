import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

import { Tournoi } from '../tournoi/tournoi.entity';

/** Un fait de match pour la chronologie du direct. */
export interface EvenementMatch {
  id: string;
  minute: string | null;
  /** « But », « Panier », « Set », « Carton jaune », « Temps mort »… */
  type: string;
  /** 1 ou 2 ; null pour un fait neutre (« Mi-temps »). */
  equipe: 1 | 2 | null;
  joueurId: number | null;
  joueur: string | null;
  texte: string | null;
  /** Points ajoutés au score par ce fait (retirés si on l’annule). */
  points?: number;
  /** Score après le fait, « 2 – 1 ». */
  score: string | null;
  createdAt: string;
}

/** Match d’un tournoi (poule ou tableau final) — table `tournois.match`. */
@Entity('match')
@Index(['tournoiId', 'phase', 'tour', 'ordre'])
export class Match {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  tournoiId: number;

  @ManyToOne(() => Tournoi, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tournoiId' })
  tournoi?: Tournoi;

  /** poule | elimination */
  @Column({ type: 'varchar', length: 20 })
  phase: string;

  @Column({ type: 'varchar', length: 4, nullable: true })
  poule?: string | null;

  /** Poule : journée (1, 2…). Élimination : tour (0 = premier tour). */
  @Column({ type: 'int' })
  tour: number;

  @Column({ type: 'int' })
  ordre: number;

  /** « QF 1 », « Demie 2 », « Finale », « Poule A · J1 » */
  @Column({ type: 'varchar', length: 60 })
  label: string;

  @Index()
  @Column({ type: 'int', nullable: true })
  equipe1Id?: number | null;

  @Index()
  @Column({ type: 'int', nullable: true })
  equipe2Id?: number | null;

  /** D’où vient l’équipe : `match:<tour>:<ordre>`, `poule:<A>:<rang>`, null = exempt. */
  @Column({ type: 'varchar', length: 40, nullable: true })
  source1?: string | null;

  @Column({ type: 'varchar', length: 40, nullable: true })
  source2?: string | null;

  @Column({ type: 'int', nullable: true })
  score1?: number | null;

  @Column({ type: 'int', nullable: true })
  score2?: number | null;

  /** Padel : [[6, 4], [3, 6], [7, 5]] */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  sets: number[][];

  @Column({ type: 'int', nullable: true })
  vainqueurId?: number | null;

  /** « t.a.b. 4–3 », « Forfait », « Exempt » */
  @Column({ type: 'varchar', length: 120, nullable: true })
  note?: string | null;

  /** a_jouer | en_direct | termine */
  @Index()
  @Column({ type: 'varchar', length: 20, default: 'a_jouer' })
  statut: string;

  /** Exempt : une seule équipe, qualifiée d’office. */
  @Column({ type: 'boolean', default: false })
  exempt: boolean;

  @Index()
  @Column({ type: 'timestamptz', nullable: true })
  debut?: Date | null;

  @Column({ type: 'varchar', length: 60, nullable: true })
  terrain?: string | null;

  /** Minute en direct : « 34’ » (football) ou « 6:12 » (basket). */
  @Column({ type: 'varchar', length: 20, nullable: true })
  minute?: string | null;

  /** Période : « 2e mi-temps », « Set 3 ». */
  @Column({ type: 'varchar', length: 40, nullable: true })
  periode?: string | null;

  @Column({ type: 'jsonb', default: () => "'[]'" })
  evenements: EvenementMatch[];

  @Column({ type: 'timestamptz', nullable: true })
  termineLe?: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
