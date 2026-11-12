import { BadRequestException, ConflictException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Not, Repository } from 'typeorm';

import { ContenusService } from '../commun/contenus.service';
import { LIMITES } from '../forum.constants';
import type { Cible, Decision, MotifSignalement } from '../forum.constants';
import { analyserTexte } from '../ia/ia.logic';
import { Blocage } from '../interaction/interaction.entities';
import { SignalementDto } from '../interaction/interaction.dto';
import { Message } from '../message/message.entity';
import { Sujet } from '../sujet/sujet.entity';
import { texteBrut } from '../sujet/sujet.service';
import { DecisionDto, QueryFileDto } from './moderation.dto';
import { Sanction, Signalement } from './moderation.entities';

const LIBELLES_MOTIFS: Record<MotifSignalement, string> = {
  spam: 'Spam ou publicité',
  insulte: 'Propos insultants',
  choquant: 'Contenu choquant ou dangereux',
  fausse_information: 'Fausse information',
  autre: 'Autre',
};

function court(texte: string, n = 140): string {
  const t = texteBrut(texte);
  return t.length <= n ? t : `${t.slice(0, n - 1).trimEnd()}…`;
}

/**
 * Reports (FRM-05), the admin queue (ADM-09), the review drawer (ADM-10) and its decisions.
 * The AI only sorts the queue: a content is hidden by people (3 reports) or by its author's own
 * choice to publish despite the FRM-03 warning, never by the score alone.
 */
@Injectable()
export class ModerationService {
  constructor(
    private readonly contenus: ContenusService,
    @InjectRepository(Signalement) private readonly signalements: Repository<Signalement>,
    @InjectRepository(Sanction) private readonly sanctions: Repository<Sanction>,
    @InjectRepository(Blocage) private readonly blocages: Repository<Blocage>,
    @InjectRepository(Sujet) private readonly sujets: Repository<Sujet>,
    @InjectRepository(Message) private readonly messages: Repository<Message>,
  ) {}

  // --- FRM-05 -------------------------------------------------------------------------------

  async signaler(cible: Cible, cibleId: number, data: SignalementDto) {
    const c = await this.contenus.contenuActif(cible, cibleId);
    if (c.auteurId === data.signaleurId) throw new BadRequestException('Tu ne peux pas signaler ton propre message.');
    const deja = await this.signalements.findOne({ where: { cible, cibleId, signaleurId: data.signaleurId } });
    if (deja?.statut === 'ouvert') throw new ConflictException('Tu as déjà signalé ce message. Un modérateur le vérifie.');
    if (deja) {
      // Reported again after a decision: reopen it with the new reason.
      await this.signalements.update(deja.id, { statut: 'ouvert', motif: data.motif, details: data.details ?? null, decision: null, traiteLe: null, moderateurId: null });
    } else {
      await this.signalements.save(
        this.signalements.create({ cible, cibleId, signaleurId: data.signaleurId, motif: data.motif, details: data.details ?? null }),
      );
    }

    if (data.masquerAuteur) {
      await this.blocages.upsert({ utilisateurId: data.signaleurId, bloqueId: c.auteurId }, ['utilisateurId', 'bloqueId']);
    }

    // « masqué au 3e »: hidden for everyone once 3 different people reported it.
    const nb = await this.contenus.signalementsOuverts(cible, cibleId);
    let masque = c.statut === 'masque';
    if (!masque && nb >= LIMITES.signalementsAvantMasquage) {
      await this.repo(cible).update(cibleId, { statut: 'masque' });
      if (cible === 'message') await this.contenus.recompterReponses((c as Message).sujetId);
      masque = true;
    }
    return { cible, cibleId, signale: true, auteurMasque: !!data.masquerAuteur, contenuMasque: masque };
  }

  // --- ADM-09 -------------------------------------------------------------------------------

  /** Open reports grouped by content, highest AI score first. */
  async file(q: QueryFileDto) {
    const ouverts = await this.signalements.find({ where: { statut: 'ouvert' }, order: { createdAt: 'ASC' } });
    const groupes = new Map<string, Signalement[]>();
    for (const s of ouverts) {
      const cle = `${s.cible}:${s.cibleId}`;
      groupes.set(cle, [...(groupes.get(cle) ?? []), s]);
    }
    const idsDe = (cible: Cible) => [...groupes.values()].filter((g) => g[0].cible === cible).map((g) => g[0].cibleId);
    const [sujets, messages] = await Promise.all([
      this.sujets.find({ where: { id: In(idsDe('sujet')) } }),
      this.messages.find({ where: { id: In(idsDe('message')) } }),
    ]);
    const sujetsDesMessages = await this.sujets.find({ where: { id: In([...new Set(messages.map((m) => m.sujetId))]) } });
    const sujetDe = new Map([...sujets, ...sujetsDesMessages].map((s) => [s.id, s]));

    const items = [...groupes.values()].flatMap((g) => {
      const { cible, cibleId } = g[0];
      const c = cible === 'sujet' ? sujets.find((s) => s.id === cibleId) : messages.find((m) => m.id === cibleId);
      if (!c) return [];
      const sujet = cible === 'sujet' ? (c as Sujet) : sujetDe.get((c as Message).sujetId);
      const personnes = g.filter((s) => s.signaleurId != null);
      const analyse = analyserTexte(cible === 'sujet' ? `${(c as Sujet).titre}\n${c.contenu}` : c.contenu);
      return [
        {
          cible,
          cibleId,
          sujetId: sujet?.id ?? null,
          sujetTitre: sujet?.titre ?? null,
          categorie: sujet?.categorie ?? null,
          extrait: court(cible === 'sujet' ? `${(c as Sujet).titre} — ${c.contenu}` : c.contenu),
          auteurId: c.auteurId,
          statut: c.statut,
          masque: c.statut === 'masque',
          nbSignalements: personnes.length,
          signaleParIa: g.some((s) => s.signaleurId == null),
          motifs: this.compterMotifs(personnes),
          scoreIa: analyse.score,
          niveauIa: analyse.niveau,
          motifIa: analyse.motif,
          premierSignalement: g[0].createdAt,
          creeLe: c.createdAt,
        },
      ];
    });

    const recherche = q.q?.trim().toLowerCase();
    const filtres = items
      .filter((i) => !q.type || q.type === 'tout' || i.cible === q.type)
      .filter(
        (i) =>
          !recherche ||
          i.extrait.toLowerCase().includes(recherche) ||
          (i.sujetTitre ?? '').toLowerCase().includes(recherche) ||
          String(i.auteurId) === recherche,
      )
      .sort((a, b) => b.scoreIa - a.scoreIa || b.nbSignalements - a.nbSignalements || +a.premierSignalement - +b.premierSignalement);

    const { n } = (await this.signalements
      .createQueryBuilder('s')
      .select('COUNT(DISTINCT (s.cible, s."cibleId"))', 'n')
      .where(`s.statut = 'traite'`)
      .andWhere(`s."traiteLe" >= date_trunc('week', now() AT TIME ZONE 'Africa/Tunis') AT TIME ZONE 'Africa/Tunis'`)
      .getRawOne()) as { n: string };

    return {
      ouverts: items.length,
      parType: {
        tout: items.length,
        sujet: items.filter((i) => i.cible === 'sujet').length,
        message: items.filter((i) => i.cible === 'message').length,
      },
      plusAncien: items.reduce<Date | null>((min, i) => (!min || i.premierSignalement < min ? i.premierSignalement : min), null),
      traitesCetteSemaine: Number(n),
      contenus: filtres,
    };
  }

  // --- ADM-10 -------------------------------------------------------------------------------

  /** Everything the moderator needs to decide on one content. */
  async revue(cible: Cible, cibleId: number) {
    const c = await this.contenus.contenu(cible, cibleId);
    const sujet = cible === 'sujet' ? (c as Sujet) : await this.contenus.sujet((c as Message).sujetId);
    const texte = cible === 'sujet' ? `${(c as Sujet).titre}\n${c.contenu}` : c.contenu;

    let enReponseA: { cible: Cible; id: number; auteurId: number; extrait: string } | null = null;
    if (cible === 'message') {
      const m = c as Message;
      const parent = m.parentId ? await this.messages.findOne({ where: { id: m.parentId } }) : null;
      // The level-1 parent, or the level-2 reply it answered when it named its author.
      const cibleReponse =
        parent && m.enReponseAId && m.enReponseAId !== parent.auteurId
          ? await this.messages.findOne({
              where: { parentId: parent.id, auteurId: m.enReponseAId, id: Not(m.id) },
              order: { createdAt: 'DESC' },
            })
          : parent;
      enReponseA = cibleReponse
        ? { cible: 'message', id: cibleReponse.id, auteurId: cibleReponse.auteurId, extrait: court(cibleReponse.contenu, 60) }
        : { cible: 'sujet', id: sujet.id, auteurId: sujet.auteurId, extrait: court(sujet.titre, 60) };
    }

    const tous = await this.signalements.find({ where: { cible, cibleId }, order: { createdAt: 'ASC' } });
    const ouverts = tous.filter((s) => s.statut === 'ouvert');
    const personnes = ouverts.filter((s) => s.signaleurId != null);
    const masquePar =
      c.statut !== 'masque' ? null : c.publieMalgreAlerte ? 'alerte_ia' : personnes.length >= LIMITES.signalementsAvantMasquage ? 'signalements' : 'moderation';

    return {
      cible,
      cibleId,
      titre: cible === 'sujet' ? (c as Sujet).titre : null,
      contenu: c.contenu,
      auteurId: c.auteurId,
      creeLe: c.createdAt,
      statut: c.statut,
      masquePar,
      publieMalgreAlerte: c.publieMalgreAlerte,
      sujet: { id: sujet.id, titre: sujet.titre, categorie: sujet.categorie, sport: sujet.sport },
      enReponseA,
      ia: analyserTexte(texte),
      signalements: {
        total: personnes.length,
        parIa: ouverts.some((s) => s.signaleurId == null),
        motifs: this.compterMotifs(personnes),
        details: personnes.filter((s) => s.details).map((s) => ({ motif: s.motif, details: s.details, le: s.createdAt })),
        masqueAu: masquePar === 'signalements' ? LIMITES.signalementsAvantMasquage : null,
      },
      auteur: await this.dossier(c.auteurId),
    };
  }

  /** The author's record: warnings, suspension, how much of what they wrote was removed. */
  async dossier(utilisateurId: number) {
    const [avertissements, suspension, nbSujets, nbMessages, retiresS, retiresM] = await Promise.all([
      this.sanctions.count({ where: { utilisateurId, type: 'avertissement' } }),
      this.contenus.suspension(utilisateurId),
      this.sujets.count({ where: { auteurId: utilisateurId } }),
      this.messages.count({ where: { auteurId: utilisateurId } }),
      this.retires('sujet', utilisateurId),
      this.retires('message', utilisateurId),
    ]);
    const total = nbSujets + nbMessages;
    const retires = retiresS + retiresM;
    return {
      utilisateurId,
      nbContenus: total,
      nbRetires: retires,
      /** Share of their posts and replies never removed by moderation (« Fiable 96 % »). */
      fiabilite: total === 0 ? 1 : Math.round(((total - retires) / total) * 100) / 100,
      nbAvertissements: avertissements,
      jamaisAverti: avertissements === 0,
      suspenduJusquA: suspension?.jusquA ?? null,
      /** For the consequence line: « 1er avertissement… Au 3e : suspension de 7 jours ». */
      prochainAvertissement: avertissements + 1,
      avertissementsAvantSuspension: LIMITES.avertissementsAvantSuspension,
      joursSuspension: LIMITES.joursSuspension,
    };
  }

  /**
   * ADM-10 decision. Closes every open report on the content.
   * - approuver: published again (the AI's report was wrong, or the reports were unfair).
   * - supprimer: removed for everyone.
   * - supprimer_avertir: removed + a warning; the 3rd warning suspends for 7 days.
   * - suspendre: removed + a suspension (`jours`, 7 by default).
   */
  async decider(cible: Cible, cibleId: number, data: DecisionDto) {
    const c = await this.contenus.contenu(cible, cibleId);
    const ouverts = await this.signalements.find({ where: { cible, cibleId, statut: 'ouvert' } });
    if (ouverts.length === 0 && c.statut === 'publie' && data.decision === 'approuver') {
      throw new ConflictException('Rien à approuver : ce contenu est publié et n’a pas de signalement ouvert.');
    }
    const motif =
      data.motif ??
      (ouverts.length ? LIBELLES_MOTIFS[this.motifPrincipal(ouverts)] : 'Contenu contraire aux règles de la communauté');

    const statut = data.decision === 'approuver' ? 'publie' : 'supprime';
    await this.repo(cible).update(cibleId, { statut });
    if (cible === 'message') {
      const m = c as Message;
      if (statut === 'supprime') await this.sujets.update({ id: m.sujetId, meilleureReponseId: cibleId }, { meilleureReponseId: null });
      await this.contenus.recompterReponses(m.sujetId);
    }
    await this.signalements.update(
      { cible, cibleId, statut: 'ouvert' },
      { statut: 'traite', decision: data.decision, moderateurId: data.moderateurId, traiteLe: new Date() },
    );

    const sanctions: Sanction[] = [];
    const sanctionner = async (type: Sanction['type'], jours?: number) => {
      const jusquA = jours ? new Date(Date.now() + jours * 24 * 3600 * 1000) : null;
      sanctions.push(
        await this.sanctions.save(
          this.sanctions.create({ utilisateurId: c.auteurId, type, motif, cible, cibleId, jusquA, moderateurId: data.moderateurId }),
        ),
      );
    };
    if (data.decision === 'supprimer_avertir') {
      await sanctionner('avertissement');
      const n = await this.sanctions.count({ where: { utilisateurId: c.auteurId, type: 'avertissement' } });
      if (n % LIMITES.avertissementsAvantSuspension === 0) await sanctionner('suspension', LIMITES.joursSuspension);
    }
    if (data.decision === 'suspendre') await sanctionner('suspension', data.jours ?? LIMITES.joursSuspension);

    return {
      cible,
      cibleId,
      decision: data.decision as Decision,
      statut,
      signalementsTraites: ouverts.length,
      sanctions,
      auteur: await this.dossier(c.auteurId),
    };
  }

  /** Pin or unpin a post (announcements, rules). */
  async epingler(sujetId: number, epingle: boolean) {
    await this.contenus.contenuActif('sujet', sujetId);
    await this.sujets.update(sujetId, { epingle });
    return { sujetId, epingle };
  }

  /** A member's warnings and suspensions, newest first. */
  sanctionsDe(utilisateurId: number) {
    return this.sanctions.find({ where: { utilisateurId }, order: { createdAt: 'DESC' } });
  }

  // --- Helpers ------------------------------------------------------------------------------

  private repo(cible: Cible): Repository<Sujet | Message> {
    return (cible === 'sujet' ? this.sujets : this.messages) as Repository<Sujet | Message>;
  }

  private compterMotifs(signalements: Signalement[]): Partial<Record<MotifSignalement, number>> {
    const out: Partial<Record<MotifSignalement, number>> = {};
    for (const s of signalements) out[s.motif] = (out[s.motif] ?? 0) + 1;
    return out;
  }

  private motifPrincipal(signalements: Signalement[]): MotifSignalement {
    const compte = this.compterMotifs(signalements);
    return (Object.entries(compte).sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'autre') as MotifSignalement;
  }

  /** Contents of a member removed by a moderator decision. */
  private async retires(cible: Cible, auteurId: number): Promise<number> {
    const { n } = (await this.signalements
      .createQueryBuilder('s')
      .select('COUNT(DISTINCT s."cibleId")', 'n')
      .innerJoin(cible === 'sujet' ? Sujet : Message, 'c', 'c.id = s."cibleId"')
      .where('s.cible = :cible', { cible })
      .andWhere(`s.decision IN ('supprimer', 'supprimer_avertir', 'suspendre')`)
      .andWhere('c."auteurId" = :auteurId', { auteurId })
      .getRawOne()) as { n: string };
    return Number(n);
  }
}
