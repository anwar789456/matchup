import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

import type { Categorie, Sport, StatutContenu } from '../forum.constants';

/**
 * A discussion (a post) — table `forum.sujet`. FRM-01 card, FRM-02 form, FRM-04 header.
 *
 * `score`, `nbReponses`, `nbUtile`, `nbMerci` and `derniereActivite` are counters kept up to date
 * by the services, so the list never has to count rows.
 */
@Entity('sujet')
@Index(['statut', 'derniereActivite'])
export class Sujet {
  @PrimaryGeneratedColumn()
  id: number;

  /** id of a user (utilisateur module). */
  @Index()
  @Column({ type: 'int' })
  auteurId: number;

  @Column({ type: 'varchar', length: 120 })
  titre: string;

  /** Light Markdown: **gras**, *italique*, lists « - » / « 1. », « > » quotes, links. */
  @Column({ type: 'text' })
  contenu: string;

  @Index()
  @Column({ type: 'varchar', length: 40 })
  categorie: Categorie;

  /** null = every sport (« Tous les sports »). */
  @Index()
  @Column({ type: 'varchar', length: 20, nullable: true })
  sport: Sport | null;

  /** As the author typed them (« Bandeja », « Côté gauche »), at most 5. */
  @Column({ type: 'text', array: true, default: '{}' })
  tags: string[];

  /** Image URLs (at most 4), uploaded with POST /images. */
  @Column({ type: 'text', array: true, default: '{}' })
  images: string[];

  /** `@pseudo` handles found in the text, lower case, to show « X t’a mentionné ». */
  @Column({ type: 'text', array: true, default: '{}' })
  mentions: string[];

  /** Pinned at the top of the list (moderators, organisers' announcements). */
  @Column({ type: 'boolean', default: false })
  epingle: boolean;

  @Index()
  @Column({ type: 'varchar', length: 20, default: 'publie' })
  statut: StatutContenu;

  /** The reply chosen by the author (FRM-04 « Meilleure réponse »). */
  @Column({ type: 'int', nullable: true })
  meilleureReponseId: number | null;

  /** Up votes minus down votes. */
  @Column({ type: 'int', default: 0 })
  score: number;

  /** Visible replies (both levels). */
  @Column({ type: 'int', default: 0 })
  nbReponses: number;

  @Column({ type: 'int', default: 0 })
  nbUtile: number;

  @Column({ type: 'int', default: 0 })
  nbMerci: number;

  /** AI toxicity / spam score when written (0 → 1), see `ia.logic.ts`. */
  @Column({ type: 'real', default: 0 })
  scoreIa: number;

  /** AI reason (« Spam · lien et contact »), null when nothing was found. */
  @Column({ type: 'varchar', length: 80, nullable: true })
  motifIa: string | null;

  /** The author saw the FRM-03 warning and chose « Publier quand même ». */
  @Column({ type: 'boolean', default: false })
  publieMalgreAlerte: boolean;

  /** Last edit by its author, null if never edited. */
  @Column({ type: 'timestamptz', nullable: true })
  modifieLe: Date | null;

  /** Last post or reply: drives « Tendance » and « Nouveaux depuis ta dernière visite ». */
  @Column({ type: 'timestamptz', default: () => 'now()' })
  derniereActivite: Date;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
