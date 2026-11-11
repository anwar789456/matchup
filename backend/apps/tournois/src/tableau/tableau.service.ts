import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';

import { Equipe } from '../equipe/equipe.entity';
import { EquipeService } from '../equipe/equipe.service';
import { Match } from '../match/match.entity';
import { GenererTableauDto } from '../tournoi/tournoi.dto';
import { Tournoi } from '../tournoi/tournoi.entity';
import {
  drawGroupsAndKnockout,
  drawSingleElimination,
  GROUP_LETTERS,
  MatchPlan,
  placeholderFor,
  roundNames,
  schedule,
  ScheduleError,
  standings,
  StandingRow,
  Window,
} from './tableau.logic';

/** Un match tel que le tableau le lit (enregistré ou seulement en aperçu). */
type MatchLu = MatchPlan &
  Partial<Pick<Match, 'id' | 'score1' | 'score2' | 'sets' | 'note' | 'minute' | 'periode'>>;

const TUNIS_OFFSET = 60 * 60_000; // UTC+1, pas d’heure d’été
const DAY = 24 * 60 * 60_000;

@Injectable()
export class TableauService {
  constructor(
    @InjectRepository(Tournoi) private readonly tournois: Repository<Tournoi>,
    @InjectRepository(Equipe) private readonly equipes: Repository<Equipe>,
    @InjectRepository(Match) private readonly matchs: Repository<Match>,
    private readonly equipeService: EquipeService,
  ) {}

  /**
   * Générateur : tirage (têtes de série ou au sort) puis calendrier selon les contraintes
   * (terrains, plages horaires, durée, repos). `apercu: true` ne sauvegarde rien.
   */
  async generer(tournoiId: number, dto: GenererTableauDto) {
    const t = await this.tournoi(tournoiId);
    if (t.type === 'evenement') throw new BadRequestException('Un événement n’a pas de tableau.');
    if (t.statut !== 'inscriptions_fermees') {
      throw new ConflictException('Clôture d’abord les inscriptions pour générer le tableau.');
    }
    await this.verifierRienNaCommence(tournoiId);

    let equipes = await this.equipeService.confirmees(tournoiId);
    if (equipes.length < 2) throw new BadRequestException('Il faut au moins 2 équipes confirmées.');
    if (dto.melanger) equipes = melanger(equipes);
    const seeds = equipes.map((e) => ({ id: e.id, nom: e.nom }));

    let plans: MatchPlan[];
    let nbPoules: number | null = null;
    let qualifies = t.qualifiesParPoule;
    if (t.format === 'poules_phase_finale') {
      nbPoules = dto.nbPoules ?? t.nbPoules ?? Math.max(1, Math.round(equipes.length / 4));
      qualifies = dto.qualifiesParPoule ?? t.qualifiesParPoule;
      if (nbPoules > GROUP_LETTERS.length) throw new BadRequestException('Trop de poules.');
      if (equipes.length < nbPoules * 2) {
        throw new BadRequestException(`${equipes.length} équipes ne suffisent pas pour ${nbPoules} poules (2 minimum par poule).`);
      }
      const plusPetite = Math.floor(equipes.length / nbPoules);
      if (qualifies > plusPetite) {
        throw new BadRequestException(`Au plus ${plusPetite} qualifié(s) par poule avec ce nombre d’équipes.`);
      }
      if (nbPoules * qualifies < 2) throw new BadRequestException('Il faut au moins 2 qualifiés pour la phase finale.');
      plans = drawGroupsAndKnockout(seeds, nbPoules, qualifies);
    } else {
      plans = drawSingleElimination(seeds);
    }

    const terrains = dto.terrains ?? (t.terrains.length ? t.terrains : ['Terrain 1']);
    const dureeMatchMinutes = dto.dureeMatchMinutes ?? t.dureeMatchMinutes;
    const reposMinutes = dto.reposMinutes ?? t.reposMinutes;
    const creneaux: Window[] = dto.creneaux
      ? dto.creneaux.map((c) => ({ debut: new Date(c.debut), fin: new Date(c.fin) }))
      : creneauxParDefaut(t);
    if (creneaux.some((c) => c.fin <= c.debut)) throw new BadRequestException('Une plage horaire finit avant de commencer.');
    try {
      schedule(plans, { terrains, creneaux, dureeMatchMinutes, reposMinutes });
    } catch (e) {
      if (e instanceof ScheduleError) {
        throw new UnprocessableEntityException({ statusCode: 422, message: e.message, manquants: e.manquants });
      }
      throw e;
    }

    const parametres = { terrains, dureeMatchMinutes, reposMinutes, nbPoules, qualifiesParPoule: qualifies };
    if (dto.apercu) {
      return { apercu: true, ...this.vue({ ...t, ...parametres, tableauPublie: false }, plans, equipes) };
    }

    await this.matchs.manager.transaction(async (em) => {
      await em.delete(Match, { tournoiId });
      await em.save(plans.map((p) => em.create(Match, { ...p, tournoiId, note: p.exempt ? 'Exempt' : null })));
      await em.update(Tournoi, tournoiId, { ...parametres, tableauPublie: false });
    });
    return this.tableau(tournoiId, { brouillon: true });
  }

  /** Rend le tableau visible des joueurs (notification « Tableau publié »). */
  async publier(tournoiId: number) {
    await this.tournoi(tournoiId);
    if (!(await this.matchs.exist({ where: { tournoiId } }))) throw new ConflictException('Génère d’abord le tableau.');
    await this.tournois.update(tournoiId, { tableauPublie: true });
    return this.tableau(tournoiId);
  }

  async supprimer(tournoiId: number) {
    const t = await this.tournoi(tournoiId);
    await this.verifierRienNaCommence(tournoiId);
    await this.matchs.delete({ tournoiId });
    await this.tournois.update(tournoiId, { tableauPublie: false, statut: t.statut === 'en_cours' ? 'inscriptions_fermees' : t.statut });
    return { deleted: true, tournoiId };
  }

  /** Glisser-déposer : échange la place de deux équipes avant qu’elles aient joué. */
  async echanger(tournoiId: number, equipeA: number, equipeB: number) {
    if (equipeA === equipeB) throw new BadRequestException('Choisis deux équipes différentes.');
    const matchs = await this.matchs.find({ where: { tournoiId } });
    const touches = matchs.filter((m) =>
      [m.equipe1Id, m.equipe2Id].some((id) => id === equipeA || id === equipeB),
    );
    if (touches.length === 0) throw new NotFoundException('Ces équipes ne sont pas dans le tableau.');
    if (touches.some((m) => m.statut === 'en_direct' || (m.statut === 'termine' && !m.exempt))) {
      throw new ConflictException('Une de ces équipes a déjà joué : l’échange n’est plus possible.');
    }
    const swap = (id?: number | null) => (id === equipeA ? equipeB : id === equipeB ? equipeA : id);
    for (const m of touches) {
      m.equipe1Id = swap(m.equipe1Id);
      m.equipe2Id = swap(m.equipe2Id);
      m.vainqueurId = swap(m.vainqueurId);
    }
    await this.matchs.save(touches);
    return this.tableau(tournoiId, { brouillon: true });
  }

  /**
   * Après chaque résultat : remplit les tours suivants (vainqueurs, classements de poule
   * terminées, exempts) et termine le tournoi quand la finale est jouée.
   */
  async propager(em: EntityManager, tournoiId: number): Promise<void> {
    const t = await em.findOneOrFail(Tournoi, { where: { id: tournoiId } });
    const matchs = await em.find(Match, { where: { tournoiId } });
    const changes = new Set<Match>();
    const equipes = await em.find(Equipe, { where: { tournoiId, statut: 'confirmee' } });
    const ordre = equipes.map((e) => e.id);

    const classement = new Map<string, StandingRow[] | null>();
    const classementDe = (lettre: string) => {
      if (!classement.has(lettre)) {
        const poule = matchs.filter((m) => m.phase === 'poule' && m.poule === lettre);
        const finie = poule.length > 0 && poule.every((m) => m.statut === 'termine');
        classement.set(lettre, finie ? standings(equipesDePoule(poule, ordre), poule as never, t.qualifiesParPoule) : null);
      }
      return classement.get(lettre) ?? null;
    };
    const parCle = new Map(
      matchs.filter((m) => m.phase === 'elimination').map((m) => [`match:${m.tour}:${m.ordre}`, m]),
    );
    const resoudre = (source?: string | null): number | null => {
      if (!source) return null;
      const [kind, a, b] = source.split(':');
      if (kind === 'poule') return classementDe(a)?.[Number(b) - 1]?.equipeId ?? null;
      const m = parCle.get(source);
      return m?.statut === 'termine' ? (m.vainqueurId ?? null) : null;
    };

    const elimination = matchs
      .filter((m) => m.phase === 'elimination')
      .sort((a, b) => a.tour - b.tour || a.ordre - b.ordre);
    for (const m of elimination) {
      if (m.statut !== 'a_jouer' && !(m.exempt && m.statut === 'termine')) continue;
      const e1 = m.source1 ? resoudre(m.source1) : (m.equipe1Id ?? null);
      const e2 = m.source2 ? resoudre(m.source2) : (m.equipe2Id ?? null);
      if (e1 !== (m.equipe1Id ?? null) || e2 !== (m.equipe2Id ?? null)) {
        m.equipe1Id = e1;
        m.equipe2Id = e2;
        changes.add(m);
      }
      if (m.exempt) {
        const qualifie = e1 ?? e2;
        const statut = qualifie != null ? 'termine' : 'a_jouer';
        if (m.vainqueurId !== qualifie || m.statut !== statut) {
          m.vainqueurId = qualifie;
          m.statut = statut;
          changes.add(m);
        }
      }
    }
    if (changes.size) await em.save([...changes]);

    const finale = elimination[elimination.length - 1];
    if (finale && finale.statut === 'termine' && finale.vainqueurId != null) {
      await em.update(Tournoi, tournoiId, { statut: 'termine', vainqueurEquipeId: finale.vainqueurId });
    } else if (t.statut === 'termine') {
      await em.update(Tournoi, tournoiId, { statut: 'en_cours', vainqueurEquipeId: null });
    }
  }

  /** Le tableau pour MuBracket (poules + tours). `equipeId` marque « Ton équipe ». */
  async tableau(tournoiId: number, opts: { equipeId?: number; brouillon?: boolean } = {}) {
    const t = await this.tournoi(tournoiId);
    const vide = { tournoiId, format: t.format, publie: t.tableauPublie, vainqueur: null, poules: [], tours: [], journees: [] };
    if (!t.tableauPublie && !opts.brouillon) return vide;
    const matchs = await this.matchs.find({ where: { tournoiId } });
    if (matchs.length === 0) return vide;
    const equipes = await this.equipes.find({ where: { tournoiId } });
    return this.vue(t, matchs as MatchLu[], equipes, opts.equipeId);
  }

  /** Classements de poule + classement général (parcours, puis points). */
  async classement(tournoiId: number, equipeId?: number) {
    const t = await this.tournoi(tournoiId);
    const matchs = await this.matchs.find({ where: { tournoiId } });
    const equipes = await this.equipes.find({ where: { tournoiId, statut: 'confirmee' } });
    const nom = new Map(equipes.map((e) => [e.id, e]));
    const joues = matchs.filter((m) => !m.exempt);
    const general = standings(equipes.map((e) => e.id), joues as never);

    const elimination = matchs.filter((m) => m.phase === 'elimination');
    const nbTours = elimination.reduce((max, m) => Math.max(max, m.tour + 1), 0);
    const finale = elimination.find((m) => m.tour === nbTours - 1);
    const parcours = (id: number): { niveau: number; libelle: string } => {
      if (finale?.statut === 'termine' && finale.vainqueurId === id) return { niveau: nbTours + 1, libelle: 'Champion' };
      const tours = elimination.filter((m) => !m.exempt || m.vainqueurId === id).filter((m) => m.equipe1Id === id || m.equipe2Id === id);
      if (tours.length === 0) return { niveau: 0, libelle: matchs.some((m) => m.phase === 'poule') ? 'Phase de poules' : 'Inscrite' };
      const max = Math.max(...tours.map((m) => m.tour));
      const enCours = tours.some((m) => m.tour === max && m.statut !== 'termine');
      const libelle = max === nbTours - 1 ? (enCours ? 'Finale' : 'Finaliste') : roundNames(2 ** (nbTours - 1 - max)).name;
      return { niveau: max + 1, libelle };
    };

    return {
      tournoiId,
      vainqueur: t.vainqueurEquipeId ? { id: t.vainqueurEquipeId, nom: nom.get(t.vainqueurEquipeId)?.nom ?? null } : null,
      poules: this.vue(t, matchs as MatchLu[], equipes, equipeId).poules,
      general: general
        .map((r) => ({ ...r, equipe: nom.get(r.equipeId)?.nom ?? null, logoUrl: nom.get(r.equipeId)?.logoUrl ?? null, parcours: parcours(r.equipeId), toi: r.equipeId === equipeId }))
        .sort((a, b) => b.parcours.niveau - a.parcours.niveau || b.points - a.points || b.diff - a.diff || b.pour - a.pour)
        .map(({ qualifie: _qualifie, ...r }, i) => ({ ...r, rang: i + 1 })),
    };
  }

  /** Calendrier des matchs par jour (heure de Tunis), filtrable par équipe. */
  async calendrier(tournoiId: number, equipeId?: number) {
    await this.tournoi(tournoiId);
    const equipes = await this.equipes.find({ where: { tournoiId } });
    const nom = new Map(equipes.map((e) => [e.id, e.nom]));
    const matchs = (await this.matchs.find({ where: { tournoiId }, order: { debut: { direction: 'ASC', nulls: 'LAST' }, terrain: 'ASC' } }))
      .filter((m) => !m.exempt)
      .filter((m) => equipeId == null || m.equipe1Id === equipeId || m.equipe2Id === equipeId);
    const jours = new Map<string, unknown[]>();
    for (const m of matchs) {
      const jour = m.debut ? new Date(m.debut.getTime() + TUNIS_OFFSET).toISOString().slice(0, 10) : 'a_planifier';
      if (!jours.has(jour)) jours.set(jour, []);
      jours.get(jour)!.push({
        ...m,
        equipe1: m.equipe1Id ? nom.get(m.equipe1Id) : null,
        equipe2: m.equipe2Id ? nom.get(m.equipe2Id) : null,
        toi: equipeId != null,
      });
    }
    return [...jours.entries()].map(([jour, liste]) => ({ jour, matchs: liste }));
  }

  // ---------------------------------------------------------------------------------------------

  private vue(
    t: Pick<Tournoi, 'id' | 'format' | 'tableauPublie' | 'qualifiesParPoule' | 'vainqueurEquipeId'>,
    matchs: MatchLu[],
    equipes: Equipe[],
    toi?: number,
  ) {
    const parId = new Map(equipes.map((e) => [e.id, e]));
    const ordre = equipes.filter((e) => e.statut === 'confirmee').map((e) => e.id);
    const seed = new Map<number, string>(ordre.map((id, i) => [id, String(parId.get(id)?.seed ?? i + 1)]));

    const poules = [...new Set(matchs.filter((m) => m.phase === 'poule').map((m) => m.poule as string))].sort();
    const vuePoules = poules.map((lettre) => {
      const ms = matchs.filter((m) => m.phase === 'poule' && m.poule === lettre);
      const ids = equipesDePoule(ms, ordre);
      const journees = Math.max(...ms.map((m) => m.tour));
      const jouees = new Set(ms.filter((m) => m.statut === 'termine').map((m) => m.tour));
      const finie = ms.every((m) => m.statut === 'termine');
      const rows = standings(ids, ms as never, t.qualifiesParPoule);
      rows.forEach((r) => seed.set(r.equipeId, `${lettre}${r.rang}`));
      return {
        nom: `Poule ${lettre}`,
        lettre,
        note: `${jouees.size} journée${jouees.size > 1 ? 's' : ''} sur ${journees}`,
        terminee: finie,
        lignes: rows.map((r) => ({
          ...r,
          equipe: parId.get(r.equipeId)?.nom ?? null,
          logoUrl: parId.get(r.equipeId)?.logoUrl ?? null,
          seed: `${lettre}${r.rang}`,
          // Qualifié seulement une fois la poule finie ; avant, c’est la ligne de coupe.
          qualifie: finie && r.qualifie,
          toi: r.equipeId === toi,
        })),
      };
    });

    const elimination = matchs.filter((m) => m.phase === 'elimination');
    const tailles: number[] = [];
    for (const m of elimination) tailles[m.tour] = (tailles[m.tour] ?? 0) + 1;

    const equipeVue = (id: number | null | undefined, score: number | null | undefined) => {
      if (id == null) return null;
      const e = parId.get(id);
      return { id, nom: e?.nom ?? null, logoUrl: e?.logoUrl ?? null, seed: seed.get(id) ?? null, score: score ?? null, toi: id === toi };
    };
    const matchVue = (m: MatchLu) => ({
      id: m.id ?? null,
      label: m.label,
      phase: m.phase,
      poule: m.poule,
      statut: m.statut,
      exempt: m.exempt,
      equipes: [equipeVue(m.equipe1Id, m.score1), equipeVue(m.equipe2Id, m.score2)],
      placeholders: [
        m.equipe1Id == null ? (placeholderFor(m.source1, tailles) ?? (m.exempt ? 'Exempt' : null)) : null,
        m.equipe2Id == null ? (placeholderFor(m.source2, tailles) ?? (m.exempt ? 'Exempt' : null)) : null,
      ],
      vainqueur: m.vainqueurId == null ? null : m.vainqueurId === m.equipe1Id ? 0 : 1,
      note: m.note ?? (m.exempt ? 'Exempt' : null),
      sets: m.sets ?? [],
      minute: m.minute ?? null,
      periode: m.periode ?? null,
      debut: m.debut,
      terrain: m.terrain,
      tonEquipe: toi != null && (m.equipe1Id === toi || m.equipe2Id === toi),
    });

    const tours = tailles.map((n, tour) => {
      const ms = elimination.filter((m) => m.tour === tour).sort((a, b) => a.ordre - b.ordre);
      const debuts = ms.map((m) => m.debut).filter((d): d is Date => d != null).sort((a, b) => a.getTime() - b.getTime());
      return { ...roundNames(n), tour, date: debuts[0] ?? null, matchs: ms.map(matchVue) };
    });

    const journees = poules.flatMap((lettre) => {
      const ms = matchs.filter((m) => m.phase === 'poule' && m.poule === lettre);
      return [...new Set(ms.map((m) => m.tour))].sort((a, b) => a - b).map((j) => ({
        poule: lettre,
        journee: j,
        matchs: ms.filter((m) => m.tour === j).sort((a, b) => a.ordre - b.ordre).map(matchVue),
      }));
    });

    const champion = t.vainqueurEquipeId ? parId.get(t.vainqueurEquipeId) : undefined;
    return {
      tournoiId: t.id,
      format: t.format,
      publie: t.tableauPublie,
      vainqueur: champion ? { id: champion.id, nom: champion.nom, logoUrl: champion.logoUrl ?? null } : null,
      poules: vuePoules,
      tours: tours.map(({ prefix: _prefix, ...rest }) => rest),
      journees,
    };
  }

  private async tournoi(id: number): Promise<Tournoi> {
    const t = await this.tournois.findOne({ where: { id } });
    if (!t) throw new NotFoundException(`Tournoi ${id} introuvable`);
    return t;
  }

  private async verifierRienNaCommence(tournoiId: number) {
    const joue = await this.matchs
      .createQueryBuilder('m')
      .where('m.tournoiId = :tournoiId', { tournoiId })
      .andWhere("(m.statut = 'en_direct' OR (m.statut = 'termine' AND m.exempt = false))")
      .getExists();
    if (joue) throw new ConflictException('Des matchs ont déjà été joués : le tableau ne peut plus être refait.');
  }
}

/** Les équipes d’une poule, dans l’ordre des têtes de série. */
function equipesDePoule(matchs: { equipe1Id?: number | null; equipe2Id?: number | null }[], ordre: number[]): number[] {
  const ids = new Set<number>();
  for (const m of matchs) for (const id of [m.equipe1Id, m.equipe2Id]) if (id != null) ids.add(id);
  return [...ids].sort((a, b) => ordre.indexOf(a) - ordre.indexOf(b));
}

function melanger<T>(list: T[]): T[] {
  const copy = [...list];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

/** 9h–21h (heure de Tunis) chaque jour du tournoi, à partir de l’heure de début le premier jour. */
export function creneauxParDefaut(t: Pick<Tournoi, 'dateDebut' | 'dateFin'>): Window[] {
  const debut = new Date(t.dateDebut).getTime();
  const fin = t.dateFin ? new Date(t.dateFin).getTime() : debut;
  const minuitLocal = (ms: number) => Math.floor((ms + TUNIS_OFFSET) / DAY) * DAY - TUNIS_OFFSET;
  const fenetres: Window[] = [];
  for (let jour = minuitLocal(debut); jour <= minuitLocal(fin); jour += DAY) {
    const ouverture = Math.max(jour + 9 * 3_600_000, debut);
    const fermeture = jour + 21 * 3_600_000;
    if (ouverture < fermeture) fenetres.push({ debut: new Date(ouverture), fin: new Date(fermeture) });
  }
  return fenetres;
}
