import { ForbiddenException, Injectable, NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, MoreThan, Not, Repository } from 'typeorm';

import { LIMITES } from '../forum.constants';
import type { Cible, MotifSignalement, TypeReaction } from '../forum.constants';
import { analyserTexte } from '../ia/ia.logic';
import type { Analyse } from '../ia/ia.logic';
import { Blocage, Reaction, Vote } from '../interaction/interaction.entities';
import { Message } from '../message/message.entity';
import { Sanction, Signalement } from '../moderation/moderation.entities';
import { Sujet } from '../sujet/sujet.entity';

/** What the person looking at a content did on it (FRM-04: filled arrow, « Utile » on…). */
export interface EtatLecteur {
  /** 1, −1 or 0. */
  vote: number;
  utile: boolean;
  merci: boolean;
  /** The reader wrote it (edit / delete menu, « Pourquoi ? » on a masked reply). */
  auteur: boolean;
}

/** Code of the 422 answer that opens FRM-03 in the app. */
export const CODE_ALERTE = 'ALERTE_MODERATION';

/** Dates shown in messages, in Tunis time: « ven. 23 oct. à 18h00 ». */
export function dateFr(date: Date): string {
  const jour = new Intl.DateTimeFormat('fr-FR', { weekday: 'short', day: 'numeric', month: 'short', timeZone: 'Africa/Tunis' }).format(date);
  const heure = new Intl.DateTimeFormat('fr-FR', { hour: '2-digit', minute: '2-digit', timeZone: 'Africa/Tunis' })
    .format(date)
    .replace(':', 'h');
  return `${jour} à ${heure}`;
}

/**
 * Rules shared by posts, replies, votes, reactions and moderation: loading a content, who may
 * write, the AI check before publishing, the counters, and what one reader sees.
 */
@Injectable()
export class ContenusService {
  constructor(
    @InjectRepository(Sujet) readonly sujets: Repository<Sujet>,
    @InjectRepository(Message) readonly messages: Repository<Message>,
    @InjectRepository(Vote) private readonly votes: Repository<Vote>,
    @InjectRepository(Reaction) private readonly reactions: Repository<Reaction>,
    @InjectRepository(Signalement) private readonly signalements: Repository<Signalement>,
    @InjectRepository(Sanction) private readonly sanctions: Repository<Sanction>,
    @InjectRepository(Blocage) private readonly blocages: Repository<Blocage>,
  ) {}

  // --- Loading ------------------------------------------------------------------------------

  async sujet(id: number): Promise<Sujet> {
    const s = await this.sujets.findOne({ where: { id } });
    if (!s) throw new NotFoundException(`Discussion ${id} introuvable`);
    return s;
  }

  async message(id: number): Promise<Message> {
    const m = await this.messages.findOne({ where: { id } });
    if (!m) throw new NotFoundException(`Réponse ${id} introuvable`);
    return m;
  }

  contenu(cible: Cible, id: number): Promise<Sujet | Message> {
    return cible === 'sujet' ? this.sujet(id) : this.message(id);
  }

  /** A content others can vote on, react to or report: published, or masked but not deleted. */
  async contenuActif(cible: Cible, id: number, pourVoter = false): Promise<Sujet | Message> {
    const c = await this.contenu(cible, id);
    if (c.statut === 'supprime') throw new NotFoundException(cible === 'sujet' ? 'Cette discussion a été supprimée.' : 'Cette réponse a été supprimée.');
    if (pourVoter && c.statut === 'masque') throw new ForbiddenException('Ce contenu est en cours de vérification.');
    return c;
  }

  // --- Who may write ------------------------------------------------------------------------

  /** Current forum suspension of a member, if any. */
  suspension(utilisateurId: number): Promise<Sanction | null> {
    return this.sanctions.findOne({
      where: { utilisateurId, type: 'suspension', jusquA: MoreThan(new Date()) },
      order: { jusquA: 'DESC' },
    });
  }

  /** Suspended members can read and report, but not post, reply, vote or react. */
  async verifierPeutEcrire(utilisateurId: number): Promise<void> {
    const s = await this.suspension(utilisateurId);
    if (s?.jusquA) {
      throw new ForbiddenException({
        code: 'SUSPENDU',
        message: `Tu ne peux plus publier ni réagir dans la communauté jusqu’au ${dateFr(s.jusquA)}.`,
        jusquA: s.jusquA,
        motif: s.motif,
      });
    }
  }

  /**
   * The AI check before publishing (FRM-03). Above the alert threshold, the first try is refused
   * with a 422 carrying the analysis; with `confirmer` the text is published masked and reported
   * by the AI, so a moderator decides within 24 h.
   */
  controler(texte: string, confirmer = false): { analyse: Analyse; masquer: boolean } {
    const analyse = analyserTexte(texte);
    if (analyse.score < LIMITES.seuilAlerte) return { analyse, masquer: false };
    if (!confirmer) {
      throw new UnprocessableEntityException({
        code: CODE_ALERTE,
        message: 'Ce message pourrait blesser. Le modifier avant de publier ?',
        analyse,
      });
    }
    return { analyse, masquer: true };
  }

  /** The AI's own report when an author publishes despite the warning. */
  async signalerParIa(cible: Cible, cibleId: number, analyse: Analyse): Promise<void> {
    const deja = await this.signalements.exist({ where: { cible, cibleId, signaleurId: IsNull(), statut: 'ouvert' } });
    if (deja) return;
    const motif: MotifSignalement =
      analyse.categorie === 'spam' ? 'spam' : analyse.categorie === 'coordonnees' ? 'autre' : 'insulte';
    await this.signalements.save(
      this.signalements.create({ cible, cibleId, signaleurId: null, motif, details: `IA · ${analyse.motif} · ${analyse.score}` }),
    );
  }

  // --- Counters -----------------------------------------------------------------------------

  /** Visible replies and last activity of a post, recounted (never drifts). */
  async recompterReponses(sujetId: number, activite = false): Promise<void> {
    const table = this.messages.metadata.tablePath;
    const set: Record<string, () => string> = {
      nbReponses: () => `(SELECT COUNT(*) FROM ${table} m WHERE m."sujetId" = :id AND m."statut" = 'publie')`,
    };
    if (activite) set.derniereActivite = () => 'now()';
    await this.sujets.createQueryBuilder().update().set(set).where('id = :id', { id: sujetId }).execute();
  }

  async recompterVotes(cible: Cible, cibleId: number): Promise<number> {
    const { total } = (await this.votes
      .createQueryBuilder('v')
      .select('COALESCE(SUM(v.valeur), 0)', 'total')
      .where({ cible, cibleId })
      .getRawOne()) as { total: string };
    const score = Number(total);
    await (cible === 'sujet' ? this.sujets : this.messages).update(cibleId, { score });
    return score;
  }

  async recompterReactions(cible: Cible, cibleId: number): Promise<{ nbUtile: number; nbMerci: number }> {
    const rows = (await this.reactions
      .createQueryBuilder('r')
      .select('r.type', 'type')
      .addSelect('COUNT(*)', 'n')
      .where({ cible, cibleId })
      .groupBy('r.type')
      .getRawMany()) as { type: TypeReaction; n: string }[];
    const n = (t: TypeReaction) => Number(rows.find((r) => r.type === t)?.n ?? 0);
    const compte = { nbUtile: n('utile'), nbMerci: n('merci') };
    await (cible === 'sujet' ? this.sujets : this.messages).update(cibleId, compte);
    return compte;
  }

  // --- What one reader sees -----------------------------------------------------------------

  /** Authors a reader chose not to see (FRM-05 « Ne plus voir les messages de … »). */
  async bloques(utilisateurId?: number): Promise<Set<number>> {
    if (!utilisateurId) return new Set();
    const rows = await this.blocages.find({ where: { utilisateurId }, select: { bloqueId: true } });
    return new Set(rows.map((r) => r.bloqueId));
  }

  /** The reader's votes and reactions on a set of contents, in two queries. */
  async etats(utilisateurId: number | undefined, cible: Cible, contenus: { id: number; auteurId: number }[]): Promise<Map<number, EtatLecteur>> {
    const out = new Map<number, EtatLecteur>();
    for (const c of contenus) out.set(c.id, { vote: 0, utile: false, merci: false, auteur: c.auteurId === utilisateurId });
    if (!utilisateurId || contenus.length === 0) return out;
    const ids = contenus.map((c) => c.id);
    const [votes, reactions] = await Promise.all([
      this.votes.find({ where: { utilisateurId, cible, cibleId: In(ids) } }),
      this.reactions.find({ where: { utilisateurId, cible, cibleId: In(ids) } }),
    ]);
    for (const v of votes) out.get(v.cibleId)!.vote = v.valeur;
    for (const r of reactions) out.get(r.cibleId)![r.type] = true;
    return out;
  }

  /** Open reports from people (not the AI) on a content. */
  signalementsOuverts(cible: Cible, cibleId: number): Promise<number> {
    return this.signalements.count({ where: { cible, cibleId, statut: 'ouvert', signaleurId: Not(IsNull()) } });
  }
}
