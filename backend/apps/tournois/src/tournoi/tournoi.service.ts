import { BadRequestException, ConflictException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Equipe, EQUIPES_ACTIVES } from '../equipe/equipe.entity';
import { Match } from '../match/match.entity';
import { CreateTournoiDto, QueryTournoiDto, UpdateTournoiDto } from './tournoi.dto';
import { Tournoi } from './tournoi.entity';

/** Le tournoi tel que l’app l’affiche : la ligne + les places. */
export type TournoiVue = Tournoi & {
  equipesConfirmees: number;
  equipesEnAttente: number;
  placesRestantes: number;
  inscriptionsOuvertes: boolean;
};

/** Changements de statut permis par PATCH (les routes dédiées font les vérifications). */
const TRANSITIONS: Record<string, string[]> = {
  brouillon: ['inscriptions_ouvertes', 'annule'],
  inscriptions_ouvertes: ['inscriptions_fermees', 'annule'],
  inscriptions_fermees: ['inscriptions_ouvertes', 'en_cours', 'annule'],
  en_cours: ['termine', 'annule'],
  termine: [],
  annule: [],
};

/** Champs figés une fois le tableau généré. */
const FIGES_APRES_TABLEAU: (keyof UpdateTournoiDto)[] = ['format', 'nbPoules', 'qualifiesParPoule', 'type'];

@Injectable()
export class TournoiService extends CrudService<Tournoi> {
  constructor(
    @InjectRepository(Tournoi) repo: Repository<Tournoi>,
    @InjectRepository(Equipe) private readonly equipes: Repository<Equipe>,
    @InjectRepository(Match) private readonly matchs: Repository<Match>,
  ) {
    super(repo, 'Tournoi');
  }

  /** Liste filtrée (sport, ville, dates, niveau, frais…), les prochains d’abord. */
  async liste(query: QueryTournoiDto): Promise<TournoiVue[]> {
    const qb = this.repo.createQueryBuilder('t');
    if (query.sport) qb.andWhere('t.sport = :sport', { sport: query.sport });
    if (query.type) qb.andWhere('t.type = :type', { type: query.type });
    if (query.statut) qb.andWhere('t.statut = :statut', { statut: query.statut });
    if (query.organisateurId) qb.andWhere('t.organisateurId = :org', { org: query.organisateurId });
    if (query.ville) qb.andWhere('t.ville ILIKE :ville', { ville: query.ville });
    if (query.du) qb.andWhere('t.dateDebut >= :du', { du: query.du });
    if (query.au) qb.andWhere('t.dateDebut < (CAST(:au AS date) + 1)', { au: query.au });
    if (query.fraisMax != null) qb.andWhere('t.fraisInscription <= :fraisMax', { fraisMax: query.fraisMax });
    if (query.niveau != null) {
      qb.andWhere('(t.niveauMin IS NULL OR t.niveauMin <= :niveau)', { niveau: query.niveau });
      qb.andWhere('(t.niveauMax IS NULL OR t.niveauMax >= :niveau)', { niveau: query.niveau });
    }
    if (query.q) qb.andWhere('(t.nom ILIKE :q OR t.lieu ILIKE :q OR t.ville ILIKE :q)', { q: `%${query.q}%` });
    qb.orderBy('t.dateDebut', 'ASC').addOrderBy('t.id', 'DESC');

    const vues = await this.avecPlaces(await qb.getMany());
    return query.placesLibres === 'true' ? vues.filter((t) => t.placesRestantes > 0) : vues;
  }

  async detail(id: number): Promise<TournoiVue> {
    const [vue] = await this.avecPlaces([await this.findOne(id)]);
    return vue;
  }

  /** Ajoute les compteurs d’équipes en une seule requête. */
  async avecPlaces(tournois: Tournoi[]): Promise<TournoiVue[]> {
    if (tournois.length === 0) return [];
    const rows: { tournoiId: number; statut: string; n: string }[] = await this.equipes
      .createQueryBuilder('e')
      .select('e.tournoiId', 'tournoiId')
      .addSelect('e.statut', 'statut')
      .addSelect('COUNT(*)', 'n')
      .where({ tournoiId: In(tournois.map((t) => t.id)), statut: In(EQUIPES_ACTIVES) })
      .groupBy('e.tournoiId')
      .addGroupBy('e.statut')
      .getRawMany();
    const now = Date.now();
    return tournois.map((t) => {
      const count = (statut: string) =>
        Number(rows.find((r) => r.tournoiId === t.id && r.statut === statut)?.n ?? 0);
      const equipesConfirmees = count('confirmee');
      const placesRestantes = Math.max(0, t.nbEquipesMax - equipesConfirmees);
      const avantLimite = !t.dateLimiteInscription || new Date(t.dateLimiteInscription).getTime() > now;
      return Object.assign(t, {
        equipesConfirmees,
        equipesEnAttente: count('en_attente'),
        placesRestantes,
        inscriptionsOuvertes: t.statut === 'inscriptions_ouvertes' && avantLimite && placesRestantes > 0,
      });
    });
  }

  override async create(data: CreateTournoiDto): Promise<Tournoi> {
    if (data.statut && data.statut !== 'brouillon') {
      throw new BadRequestException('Un tournoi est créé en brouillon ; publie-le avec /publier.');
    }
    const draft = { ...data, statut: 'brouillon' };
    if (draft.type === 'evenement') draft.joueursParEquipe = 1;
    this.verifierCoherence(draft);
    return super.create(draft as never);
  }

  override async update(id: number, data: UpdateTournoiDto): Promise<Tournoi> {
    const t = await this.findOne(id);
    if (t.statut === 'termine' || t.statut === 'annule') {
      throw new ConflictException('Ce tournoi est terminé ou annulé : il ne peut plus être modifié.');
    }
    if (data.statut && data.statut !== t.statut && !TRANSITIONS[t.statut]?.includes(data.statut)) {
      throw new BadRequestException(`Impossible de passer de « ${t.statut} » à « ${data.statut} ».`);
    }
    if (await this.matchs.exist({ where: { tournoiId: id } })) {
      const figes = FIGES_APRES_TABLEAU.filter((k) => data[k] !== undefined && data[k] !== t[k as keyof Tournoi]);
      if (figes.length) {
        throw new ConflictException(
          `Le tableau est déjà généré : ${figes.join(', ')} ne peut plus changer. Supprime le tableau d’abord.`,
        );
      }
    }
    if (data.nbEquipesMax != null) {
      const confirmees = await this.equipes.count({ where: { tournoiId: id, statut: 'confirmee' } });
      if (data.nbEquipesMax < confirmees) {
        throw new ConflictException(`${confirmees} équipes sont déjà confirmées : le maximum ne peut pas être plus bas.`);
      }
    }
    this.verifierCoherence({ ...t, ...data } as never);
    return super.update(id, data as never);
  }

  override async remove(id: number) {
    const t = await this.findOne(id);
    if (!['brouillon', 'annule', 'termine'].includes(t.statut)) {
      throw new ConflictException('Annule d’abord le tournoi (les équipes seront prévenues et remboursées).');
    }
    const aRembourser = await this.equipes.count({ where: { tournoiId: id, statutPaiement: In(['paye', 'a_rembourser']) } });
    if (t.statut === 'annule' && aRembourser > 0) {
      throw new ConflictException(`${aRembourser} équipe(s) attendent encore leur remboursement.`);
    }
    return super.remove(id);
  }

  /** brouillon → inscriptions ouvertes, visible dans Explorer. */
  async publier(id: number): Promise<TournoiVue> {
    const t = await this.findOne(id);
    if (t.statut !== 'brouillon') throw new ConflictException('Ce tournoi est déjà publié.');
    const manque: string[] = [];
    if (!t.nom?.trim()) manque.push('le nom');
    if (!t.lieu?.trim()) manque.push('le lieu');
    if (new Date(t.dateDebut).getTime() <= Date.now()) manque.push('une date de début à venir');
    if (t.type === 'tournoi' && t.format === 'poules_phase_finale' && t.nbEquipesMax < 4) {
      manque.push('au moins 4 équipes pour des poules');
    }
    if (manque.length) throw new BadRequestException(`Pour publier, il faut ${manque.join(', ')}.`);
    await this.repo.update(id, { statut: 'inscriptions_ouvertes', publieLe: new Date() });
    return this.detail(id);
  }

  async cloturer(id: number): Promise<TournoiVue> {
    const t = await this.findOne(id);
    if (t.statut !== 'inscriptions_ouvertes') throw new ConflictException('Les inscriptions ne sont pas ouvertes.');
    await this.repo.update(id, { statut: 'inscriptions_fermees' });
    return this.detail(id);
  }

  async rouvrir(id: number): Promise<TournoiVue> {
    const t = await this.findOne(id);
    if (t.statut !== 'inscriptions_fermees') throw new ConflictException('Les inscriptions ne sont pas fermées.');
    if (await this.matchs.exist({ where: { tournoiId: id } })) {
      throw new ConflictException('Le tableau est déjà généré : supprime-le avant de rouvrir les inscriptions.');
    }
    await this.repo.update(id, { statut: 'inscriptions_ouvertes' });
    return this.detail(id);
  }

  /** Annule le tournoi : les équipes qui ont payé passent « à rembourser ». */
  async annuler(id: number, motif: string): Promise<TournoiVue> {
    const t = await this.findOne(id);
    if (t.statut === 'termine' || t.statut === 'annule') throw new ConflictException('Ce tournoi est déjà terminé ou annulé.');
    await this.repo.manager.transaction(async (em) => {
      await em.update(Tournoi, id, { statut: 'annule', motifAnnulation: motif });
      await em.update(Equipe, { tournoiId: id, statutPaiement: 'paye' }, { statutPaiement: 'a_rembourser' });
    });
    return this.detail(id);
  }

  /** Tableau de bord organisateur : tournois actifs, inscriptions, revenus, prochains matchs. */
  async tableauDeBord(organisateurId: number) {
    const tournois = await this.repo.find({ where: { organisateurId }, order: { dateDebut: 'ASC' } });
    const ids = tournois.map((t) => t.id);
    const actifs = await this.avecPlaces(
      tournois.filter((t) => ['inscriptions_ouvertes', 'inscriptions_fermees', 'en_cours'].includes(t.statut)),
    );
    const equipes = ids.length ? await this.equipes.find({ where: { tournoiId: In(ids) } }) : [];
    const frais = new Map(tournois.map((t) => [t.id, t.fraisInscription]));
    const nom = new Map(tournois.map((t) => [t.id, t.nom]));

    const now = new Date();
    const matchs = ids.length
      ? await this.matchs
          .createQueryBuilder('m')
          .where({ tournoiId: In(ids) })
          .andWhere("(m.statut = 'en_direct' OR (m.statut = 'a_jouer' AND m.debut >= :now))", { now })
          .orderBy('m.debut', 'ASC')
          .take(20)
          .getMany()
      : [];
    const nomEquipe = new Map(equipes.map((e) => [e.id, e.nom]));
    const vueMatch = (m: Match) => ({
      ...m,
      tournoi: nom.get(m.tournoiId),
      equipe1: m.equipe1Id ? nomEquipe.get(m.equipe1Id) : null,
      equipe2: m.equipe2Id ? nomEquipe.get(m.equipe2Id) : null,
    });

    const sum = (list: Equipe[], f: (e: Equipe) => number) => list.reduce((s, e) => s + f(e), 0);
    const payees = equipes.filter((e) => e.statutPaiement === 'paye');
    const attendues = equipes.filter((e) => e.statut === 'en_attente' && e.statutPaiement === 'non_paye');
    return {
      tournoisActifs: actifs,
      compteurs: {
        tournois: tournois.length,
        actifs: actifs.length,
        brouillons: tournois.filter((t) => t.statut === 'brouillon').length,
        termines: tournois.filter((t) => t.statut === 'termine').length,
      },
      inscriptions: {
        enAttente: equipes.filter((e) => e.statut === 'en_attente').length,
        confirmees: equipes.filter((e) => e.statut === 'confirmee').length,
        refusees: equipes.filter((e) => e.statut === 'refusee').length,
        aRembourser: equipes.filter((e) => e.statutPaiement === 'a_rembourser').length,
        dernieres: [...equipes]
          .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
          .slice(0, 8)
          .map((e) => ({ ...e, tournoi: nom.get(e.tournoiId) })),
      },
      revenus: {
        encaisse: sum(payees, (e) => e.montantPaye),
        attendu: sum(attendues, (e) => frais.get(e.tournoiId) ?? 0),
        aRembourser: sum(equipes.filter((e) => e.statutPaiement === 'a_rembourser'), (e) => e.montantPaye),
      },
      enDirect: matchs.filter((m) => m.statut === 'en_direct').map(vueMatch),
      prochainsMatchs: matchs.filter((m) => m.statut === 'a_jouer').slice(0, 10).map(vueMatch),
    };
  }

  private verifierCoherence(
    t: Omit<Partial<Tournoi>, 'dateDebut' | 'dateFin' | 'dateLimiteInscription'> & {
      dateDebut?: Date | string;
      dateFin?: Date | string | null;
      dateLimiteInscription?: Date | string | null;
    },
  ) {
    const time = (d?: Date | string | null) => (d ? new Date(d).getTime() : null);
    const debut = time(t.dateDebut);
    const fin = time(t.dateFin);
    const limite = time(t.dateLimiteInscription);
    if (debut != null && fin != null && fin < debut) throw new BadRequestException('La date de fin est avant la date de début.');
    if (debut != null && limite != null && limite > debut) {
      throw new BadRequestException('La fin des inscriptions doit être avant le début du tournoi.');
    }
    if (t.niveauMin != null && t.niveauMax != null && t.niveauMin > t.niveauMax) {
      throw new BadRequestException('Le niveau minimum est plus haut que le niveau maximum.');
    }
    if (t.joueursMaxParEquipe != null && t.joueursParEquipe != null && t.joueursMaxParEquipe < t.joueursParEquipe) {
      throw new BadRequestException('Le nombre maximum de joueurs est plus petit que le minimum.');
    }
    if (t.type === 'evenement' && t.joueursParEquipe != null && t.joueursParEquipe !== 1) {
      throw new BadRequestException('Un événement s’inscrit en individuel (1 joueur par inscription).');
    }
  }
}
