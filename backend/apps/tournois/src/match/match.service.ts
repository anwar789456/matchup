import { randomUUID } from 'crypto';

import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';

import { Equipe } from '../equipe/equipe.entity';
import { TableauService } from '../tableau/tableau.service';
import { Tournoi } from '../tournoi/tournoi.entity';
import { EvenementDto, QueryMatchDto, ScoreDto, TerminerDto, UpdateMatchDto } from './match.dto';
import { EvenementMatch, Match } from './match.entity';

type EquipeCourte = { id: number; nom: string; logoUrl: string | null; joueursIds: number[] } | null;
export type MatchVue = Match & { equipe1: EquipeCourte; equipe2: EquipeCourte; tournoi?: { id: number; nom: string; sport: string } };

/** Unité du score par sport, pour le résumé. */
const UNITE: Record<string, string> = { football: 'but', basketball: 'point', padel: 'set' };

@Injectable()
export class MatchService {
  constructor(
    @InjectRepository(Match) private readonly repo: Repository<Match>,
    @InjectRepository(Equipe) private readonly equipes: Repository<Equipe>,
    @InjectRepository(Tournoi) private readonly tournois: Repository<Tournoi>,
    private readonly tableau: TableauService,
  ) {}

  async liste(query: QueryMatchDto): Promise<MatchVue[]> {
    const qb = this.repo.createQueryBuilder('m').where('m.exempt = false');
    if (query.tournoiId) qb.andWhere('m.tournoiId = :t', { t: query.tournoiId });
    if (query.equipeId) qb.andWhere('(m.equipe1Id = :e OR m.equipe2Id = :e)', { e: query.equipeId });
    if (query.statut) qb.andWhere('m.statut = :s', { s: query.statut });
    if (query.phase) qb.andWhere('m.phase = :p', { p: query.phase });
    if (query.terrain) qb.andWhere('m.terrain = :terrain', { terrain: query.terrain });
    if (query.du) qb.andWhere('m.debut >= :du', { du: query.du });
    if (query.au) qb.andWhere('m.debut < :au', { au: query.au });
    qb.orderBy('m.debut', 'ASC', 'NULLS LAST').addOrderBy('m.terrain', 'ASC').addOrderBy('m.id', 'ASC');
    return this.avecEquipes(await qb.getMany());
  }

  async findOne(id: number): Promise<Match> {
    const m = await this.repo.findOne({ where: { id } });
    if (!m) throw new NotFoundException(`Match ${id} introuvable`);
    return m;
  }

  async detail(id: number): Promise<MatchVue> {
    const [vue] = await this.avecEquipes([await this.findOne(id)]);
    const t = await this.tournois.findOne({ where: { id: vue.tournoiId } });
    return Object.assign(vue, { tournoi: t ? { id: t.id, nom: t.nom, sport: t.sport } : undefined });
  }

  /** Déplacer un match (heure, terrain) : ni terrain ni équipe déjà pris à cette heure. */
  async update(id: number, data: UpdateMatchDto): Promise<MatchVue> {
    const m = await this.findOne(id);
    if (m.statut !== 'a_jouer') throw new ConflictException('Ce match a commencé : il ne peut plus être déplacé.');
    const t = await this.tournois.findOneOrFail({ where: { id: m.tournoiId } });
    const debut = data.debut ? new Date(data.debut) : m.debut;
    const terrain = data.terrain ?? m.terrain;
    if (debut) {
      const dur = t.dureeMatchMinutes * 60_000;
      const autres = await this.repo.find({ where: { tournoiId: m.tournoiId, exempt: false, statut: In(['a_jouer', 'en_direct']) } });
      for (const o of autres) {
        if (o.id === m.id || !o.debut) continue;
        const chevauche = Math.abs(o.debut.getTime() - debut.getTime()) < dur;
        if (!chevauche) continue;
        if (terrain && o.terrain === terrain) {
          throw new ConflictException(`${terrain} est déjà pris à cette heure par « ${o.label} ».`);
        }
        const communes = [m.equipe1Id, m.equipe2Id].filter((e) => e != null && (e === o.equipe1Id || e === o.equipe2Id));
        if (communes.length) throw new ConflictException(`Une équipe joue déjà « ${o.label} » à cette heure.`);
      }
    }
    await this.repo.update(id, { debut, terrain });
    return this.detail(id);
  }

  /** Coup d’envoi : le match passe EN DIRECT à 0 – 0. */
  async demarrer(id: number): Promise<MatchVue> {
    const m = await this.findOne(id);
    if (m.statut !== 'a_jouer') throw new ConflictException('Ce match a déjà commencé.');
    if (m.equipe1Id == null || m.equipe2Id == null) throw new ConflictException('Les deux équipes ne sont pas encore connues.');
    const t = await this.tournois.findOneOrFail({ where: { id: m.tournoiId } });
    if (!t.tableauPublie) throw new ConflictException('Publie d’abord le tableau.');
    if (t.statut === 'annule' || t.statut === 'termine') throw new ConflictException('Ce tournoi est terminé ou annulé.');

    m.statut = 'en_direct';
    m.score1 = 0;
    m.score2 = 0;
    m.sets = [];
    m.evenements = [evenement({ type: 'Coup d’envoi', minute: '0’' }, m)];
    await this.repo.save(m);
    if (t.statut !== 'en_cours') await this.tournois.update(t.id, { statut: 'en_cours' });
    return this.detail(id);
  }

  /** Score en direct (gros boutons au bord du terrain). */
  async score(id: number, data: ScoreDto): Promise<MatchVue> {
    const m = await this.enDirect(id);
    await this.repo.update(id, {
      score1: data.score1,
      score2: data.score2,
      ...(data.sets ? { sets: data.sets } : {}),
      ...(data.minute !== undefined ? { minute: data.minute } : {}),
      ...(data.periode !== undefined ? { periode: data.periode } : {}),
    });
    return this.detail(m.id);
  }

  /** Ajoute un fait à la chronologie ; `points` met le score à jour. */
  async ajouterEvenement(id: number, data: EvenementDto): Promise<MatchVue> {
    const m = await this.enDirect(id);
    if (data.points && !data.equipe) throw new BadRequestException('Indique l’équipe qui marque.');
    if (data.points && data.equipe === 1) m.score1 = (m.score1 ?? 0) + data.points;
    if (data.points && data.equipe === 2) m.score2 = (m.score2 ?? 0) + data.points;
    if (data.minute) m.minute = data.minute;
    m.evenements = [evenement(data, m), ...(m.evenements ?? [])];
    await this.repo.save(m);
    return this.detail(id);
  }

  /** Annule un fait saisi par erreur (et ses points). */
  async supprimerEvenement(id: number, evenementId: string): Promise<MatchVue> {
    const m = await this.findOne(id);
    if (m.statut !== 'en_direct') throw new ConflictException('Le match n’est pas en direct.');
    const ev = (m.evenements ?? []).find((e) => e.id === evenementId);
    if (!ev) throw new NotFoundException('Fait de match introuvable.');
    const points = ev.points ?? 0;
    if (points && ev.equipe === 1) m.score1 = Math.max(0, (m.score1 ?? 0) - points);
    if (points && ev.equipe === 2) m.score2 = Math.max(0, (m.score2 ?? 0) - points);
    m.evenements = m.evenements.filter((e) => e.id !== evenementId);
    await this.repo.save(m);
    return this.detail(id);
  }

  /**
   * Score final. Sans `confirme: true`, rien n’est enregistré et la réponse rappelle le score
   * à confirmer. Le vainqueur passe au tour suivant ; la finale termine le tournoi.
   * Un match déjà terminé peut être corrigé tant que la suite n’a pas commencé.
   */
  async terminer(id: number, data: TerminerDto): Promise<MatchVue> {
    const m = await this.findOne(id);
    if (m.exempt) throw new BadRequestException('Un exempt n’a pas de score.');
    if (m.equipe1Id == null || m.equipe2Id == null) throw new ConflictException('Les deux équipes ne sont pas encore connues.');
    const [e1, e2] = await Promise.all([this.equipes.findOneBy({ id: m.equipe1Id }), this.equipes.findOneBy({ id: m.equipe2Id })]);
    if (!data.confirme) {
      throw new BadRequestException(
        `Confirme le score final : ${e1?.nom ?? 'Équipe 1'} ${data.score1} – ${data.score2} ${e2?.nom ?? 'Équipe 2'}.`,
      );
    }

    let vainqueurId: number | null =
      data.score1 > data.score2 ? m.equipe1Id : data.score2 > data.score1 ? m.equipe2Id : (data.vainqueurId ?? null);
    if (vainqueurId != null && vainqueurId !== m.equipe1Id && vainqueurId !== m.equipe2Id) {
      throw new BadRequestException('Le vainqueur doit être une des deux équipes du match.');
    }
    if (data.score1 !== data.score2 && data.vainqueurId != null && data.vainqueurId !== vainqueurId) {
      throw new BadRequestException('Le vainqueur indiqué ne correspond pas au score.');
    }
    if (m.phase === 'elimination' && vainqueurId == null) {
      throw new BadRequestException('Égalité en phase finale : indique le vainqueur (tirs au but, tie-break…).');
    }
    if (m.phase === 'poule' && data.score1 === data.score2) vainqueurId = null;
    if (m.statut === 'termine') await this.verifierCorrigeable(m);

    await this.repo.manager.transaction(async (em) => {
      await em.update(Match, id, {
        statut: 'termine',
        score1: data.score1,
        score2: data.score2,
        sets: data.sets ?? m.sets,
        vainqueurId,
        note: data.note ?? null,
        periode: null,
        termineLe: new Date(),
        evenements:
          m.statut === 'en_direct'
            ? [evenement({ type: 'Fin du match', minute: data.minute ?? m.minute ?? undefined }, { ...m, score1: data.score1, score2: data.score2 }), ...(m.evenements ?? [])]
            : m.evenements,
      });
      await this.tableau.propager(em, m.tournoiId);
    });
    return this.detail(id);
  }

  /** Forfait : l’autre équipe gagne 3 – 0 (football), 2 – 0 (padel, en sets) ou 20 – 0 (basket). */
  async forfait(id: number, equipe: 1 | 2): Promise<MatchVue> {
    const m = await this.findOne(id);
    const t = await this.tournois.findOneOrFail({ where: { id: m.tournoiId } });
    const victoire = t.sport === 'basketball' ? 20 : t.sport === 'padel' ? 2 : 3;
    return this.terminer(id, {
      score1: equipe === 1 ? 0 : victoire,
      score2: equipe === 2 ? 0 : victoire,
      note: 'Forfait',
      confirme: true,
    });
  }

  /**
   * Résumé après le match (carte « IA » de l’app) : rédigé automatiquement à partir du score,
   * des sets et de la chronologie, avec un texte prêt à partager.
   */
  async resume(id: number) {
    const m = await this.detail(id);
    if (m.statut !== 'termine' || m.exempt) throw new ConflictException('Le résumé est prêt à la fin du match.');
    const n1 = m.equipe1?.nom ?? 'Équipe 1';
    const n2 = m.equipe2?.nom ?? 'Équipe 2';
    const s1 = m.score1 ?? 0;
    const s2 = m.score2 ?? 0;
    const sport = m.tournoi?.sport ?? 'football';
    const gagnant = m.vainqueurId === m.equipe1Id ? n1 : m.vainqueurId === m.equipe2Id ? n2 : null;
    const perdant = gagnant === n1 ? n2 : n1;
    const [hi, lo] = s1 >= s2 ? [s1, s2] : [s2, s1];

    const titre =
      m.note === 'Forfait'
        ? `${gagnant} qualifié par forfait`
        : gagnant
          ? s1 === s2
            ? `${gagnant} passe ${m.note ? `(${m.note})` : 'au bout du suspense'}`
            : `${gagnant} s’impose ${hi}–${lo} face à ${perdant}`
          : `Match nul ${s1}–${s2} entre ${n1} et ${n2}`;

    const faits: string[] = [];
    if (m.sets?.length) faits.push(`En ${m.sets.length} sets : ${m.sets.map((s) => `${s[0]}-${s[1]}`).join(', ')}.`);
    const marqueurs = new Map<string, number>();
    const evts = [...(m.evenements ?? [])].reverse();
    for (const e of evts) {
      const points = e.points ?? 0;
      if (points && e.joueur) marqueurs.set(e.joueur, (marqueurs.get(e.joueur) ?? 0) + points);
    }
    const top = [...marqueurs.entries()].sort((a, b) => b[1] - a[1])[0];
    if (top) {
      const unite = sport === 'football' ? 'but' : 'point';
      faits.push(`${top[0]} a marqué ${top[1]} ${unite}${top[1] > 1 ? 's' : ''}.`);
    }
    // Remontée : le vainqueur a été mené à un moment.
    if (gagnant && s1 !== s2) {
      const gagnantEst1 = gagnant === n1;
      const mene = evts.some((e) => {
        const [a, b] = (e.score ?? '').split(' – ').map(Number);
        return Number.isFinite(a) && Number.isFinite(b) && (gagnantEst1 ? a < b : b < a);
      });
      if (mene) faits.push(`${gagnant} a renversé la situation après avoir été mené.`);
      if (hi - lo === 1 && sport !== 'basketball') faits.push(`Un match serré, décidé sur un seul ${UNITE[sport] ?? 'point'}.`);
      if (hi - lo >= (sport === 'basketball' ? 20 : 4)) faits.push(`Une victoire nette, ${hi - lo} d’écart.`);
    }
    const cartons = evts.filter((e) => /carton/i.test(e.type)).length;
    if (cartons) faits.push(`${cartons} carton${cartons > 1 ? 's' : ''} distribué${cartons > 1 ? 's' : ''}.`);

    const contexte = `${m.label}${m.tournoi ? ` · ${m.tournoi.nom}` : ''}`;
    const texte = [titre + '.', ...faits].join(' ');
    return {
      matchId: m.id,
      titre,
      texte,
      faits,
      contexte,
      score: `${s1} – ${s2}`,
      partage: `${titre} (${contexte}). Suis le tournoi sur MatchUp.`,
      genereLe: new Date(),
    };
  }

  // ---------------------------------------------------------------------------------------------

  private async enDirect(id: number): Promise<Match> {
    const m = await this.findOne(id);
    if (m.statut !== 'en_direct') throw new ConflictException('Le match n’est pas en direct : démarre-le d’abord.');
    return m;
  }

  /** Une correction ne doit pas changer une équipe qui a déjà joué le tour suivant. */
  private async verifierCorrigeable(m: Match) {
    const suite = await this.repo.find({ where: { tournoiId: m.tournoiId, phase: 'elimination' } });
    const cle = m.phase === 'poule' ? `poule:${m.poule}:` : `match:${m.tour}:${m.ordre}`;
    const dependants = suite.filter((s) => [s.source1, s.source2].some((src) => src?.startsWith(cle)));
    if (dependants.some((s) => s.statut !== 'a_jouer' && !s.exempt)) {
      throw new ConflictException('Le tour suivant a déjà commencé : ce résultat ne peut plus être corrigé.');
    }
  }

  private async avecEquipes(matchs: Match[]): Promise<MatchVue[]> {
    const ids = [...new Set(matchs.flatMap((m) => [m.equipe1Id, m.equipe2Id]).filter((id): id is number => id != null))];
    const equipes = ids.length ? await this.equipes.find({ where: { id: In(ids) } }) : [];
    const parId = new Map(equipes.map((e) => [e.id, { id: e.id, nom: e.nom, logoUrl: e.logoUrl ?? null, joueursIds: e.joueursIds }]));
    return matchs.map((m) =>
      Object.assign(m, {
        equipe1: m.equipe1Id ? (parId.get(m.equipe1Id) ?? null) : null,
        equipe2: m.equipe2Id ? (parId.get(m.equipe2Id) ?? null) : null,
      }),
    );
  }
}

function evenement(data: Partial<EvenementDto> & { type: string }, m: Pick<Match, 'score1' | 'score2'>): EvenementMatch {
  return {
    id: randomUUID(),
    minute: data.minute ?? null,
    type: data.type,
    equipe: data.equipe ?? null,
    joueurId: data.joueurId ?? null,
    joueur: data.joueur ?? null,
    texte: data.texte ?? null,
    score: m.score1 != null && m.score2 != null ? `${m.score1} – ${m.score2}` : null,
    ...(data.points ? { points: data.points } : {}),
    createdAt: new Date().toISOString(),
  };
}
