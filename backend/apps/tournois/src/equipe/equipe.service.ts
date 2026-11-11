import { randomInt } from 'crypto';

import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Match } from '../match/match.entity';
import { Tournoi } from '../tournoi/tournoi.entity';
import { CreateEquipeDto, PaiementEquipeDto, QueryEquipeDto, UpdateEquipeDto } from './equipe.dto';
import { Equipe, EQUIPES_ACTIVES } from './equipe.entity';

const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

@Injectable()
export class EquipeService extends CrudService<Equipe> {
  constructor(
    @InjectRepository(Equipe) repo: Repository<Equipe>,
    @InjectRepository(Tournoi) private readonly tournois: Repository<Tournoi>,
    @InjectRepository(Match) private readonly matchs: Repository<Match>,
  ) {
    super(repo, 'Équipe');
  }

  liste(query: QueryEquipeDto): Promise<Equipe[]> {
    const qb = this.repo.createQueryBuilder('e');
    if (query.tournoiId) qb.andWhere('e.tournoiId = :t', { t: query.tournoiId });
    if (query.capitaineId) qb.andWhere('e.capitaineId = :c', { c: query.capitaineId });
    if (query.joueurId) qb.andWhere(':j = ANY(e.joueursIds)', { j: query.joueurId });
    if (query.statut) qb.andWhere('e.statut = :s', { s: query.statut });
    return qb.orderBy('e.seed', 'ASC', 'NULLS LAST').addOrderBy('e.id', 'ASC').getMany();
  }

  async parCode(code: string): Promise<Equipe> {
    const equipe = await this.repo.findOne({ where: { codeInvitation: code.trim().toUpperCase() } });
    if (!equipe) throw new NotFoundException('Ce lien d’invitation n’existe pas ou a expiré.');
    return equipe;
  }

  /** Inscription : tournoi ouvert, nom libre, joueurs pas déjà inscrits ailleurs dans ce tournoi. */
  override async create(data: CreateEquipeDto): Promise<Equipe> {
    const tournoi = await this.tournoi(data.tournoiId);
    await this.verifierInscriptionsOuvertes(tournoi);

    const joueurs = [...new Set([data.capitaineId, ...(data.joueursIds ?? [])])];
    if (tournoi.type === 'evenement' && joueurs.length !== 1) {
      throw new BadRequestException('Un événement s’inscrit en individuel : un seul joueur.');
    }
    this.verifierTaille(tournoi, joueurs.length);
    await this.verifierNomLibre(tournoi.id, data.nom);
    await this.verifierJoueursLibres(tournoi.id, joueurs);

    return super.create({
      ...data,
      nom: data.nom.trim(),
      joueursIds: joueurs,
      statut: 'en_attente',
      statutPaiement: tournoi.fraisInscription > 0 ? 'non_paye' : 'gratuit',
      codeInvitation: await this.nouveauCode(),
    });
  }

  override async update(id: number, data: UpdateEquipeDto): Promise<Equipe> {
    const equipe = await this.findOne(id);
    const tournoi = await this.tournoi(equipe.tournoiId);
    this.verifierModifiable(equipe, tournoi);
    if (data.nom && data.nom.trim().toLowerCase() !== equipe.nom.toLowerCase()) {
      await this.verifierNomLibre(tournoi.id, data.nom, id);
    }
    const joueurs = data.joueursIds ? [...new Set(data.joueursIds)] : equipe.joueursIds;
    const capitaine = data.capitaineId ?? equipe.capitaineId;
    if (capitaine != null && !joueurs.includes(capitaine)) joueurs.unshift(capitaine);
    if (data.joueursIds) {
      this.verifierTaille(tournoi, joueurs.length);
      await this.verifierJoueursLibres(tournoi.id, joueurs.filter((j) => !equipe.joueursIds.includes(j)), id);
    }
    return super.update(id, { ...data, nom: data.nom?.trim() ?? equipe.nom, joueursIds: joueurs });
  }

  override async remove(id: number) {
    const equipe = await this.findOne(id);
    if (await this.dansLeTableau(equipe)) {
      throw new ConflictException('Cette équipe est dans le tableau : supprime le tableau ou déclare-la forfait.');
    }
    if (equipe.statutPaiement === 'paye' || equipe.statutPaiement === 'a_rembourser') {
      throw new ConflictException('Cette équipe a payé : refuse-la ou annule-la pour la rembourser d’abord.');
    }
    return super.remove(id);
  }

  /** Un coéquipier rejoint l’équipe avec le code du lien d’invitation. */
  async rejoindre(code: string, joueurId: number): Promise<Equipe> {
    return this.ajouterJoueur((await this.parCode(code)).id, joueurId);
  }

  async ajouterJoueur(id: number, joueurId: number): Promise<Equipe> {
    const equipe = await this.findOne(id);
    const tournoi = await this.tournoi(equipe.tournoiId);
    this.verifierModifiable(equipe, tournoi);
    if (equipe.joueursIds.includes(joueurId)) return equipe;
    if (tournoi.type === 'evenement') throw new BadRequestException('Un événement s’inscrit en individuel.');
    this.verifierTaille(tournoi, equipe.joueursIds.length + 1);
    await this.verifierJoueursLibres(tournoi.id, [joueurId], id);
    equipe.joueursIds = [...equipe.joueursIds, joueurId];
    return this.repo.save(equipe);
  }

  async retirerJoueur(id: number, joueurId: number): Promise<Equipe> {
    const equipe = await this.findOne(id);
    const tournoi = await this.tournoi(equipe.tournoiId);
    this.verifierModifiable(equipe, tournoi);
    if (equipe.capitaineId === joueurId) {
      throw new BadRequestException('Le capitaine ne peut pas quitter l’équipe : nomme d’abord un autre capitaine.');
    }
    equipe.joueursIds = equipe.joueursIds.filter((j) => j !== joueurId);
    return this.repo.save(equipe);
  }

  /** Les frais sont payés (paiement accepté par le module paiement). */
  async payer(id: number, data: PaiementEquipeDto): Promise<Equipe> {
    const equipe = await this.findOne(id);
    const tournoi = await this.tournoi(equipe.tournoiId);
    if (!EQUIPES_ACTIVES.includes(equipe.statut)) throw new ConflictException('Cette inscription n’est plus active.');
    if (equipe.statutPaiement === 'paye') throw new ConflictException('Les frais sont déjà payés.');
    if (equipe.statutPaiement === 'gratuit') throw new ConflictException('Ce tournoi est gratuit.');
    const montant = data.montant ?? tournoi.fraisInscription;
    if (montant < tournoi.fraisInscription) {
      throw new BadRequestException(`Le montant (${montant} DT) est inférieur aux frais (${tournoi.fraisInscription} DT).`);
    }
    await this.repo.update(id, { statutPaiement: 'paye', paiementId: data.paiementId ?? null, montantPaye: montant });
    return this.findOne(id);
  }

  /** L’organisateur valide : frais payés, assez de joueurs, une place libre. */
  async valider(id: number): Promise<Equipe> {
    const equipe = await this.findOne(id);
    const tournoi = await this.tournoi(equipe.tournoiId);
    if (equipe.statut !== 'en_attente') throw new ConflictException('Seule une inscription en attente peut être validée.');
    if (equipe.statutPaiement === 'non_paye') throw new ConflictException('Les frais d’inscription ne sont pas encore payés.');
    if (equipe.joueursIds.length < tournoi.joueursParEquipe) {
      throw new ConflictException(
        `L’équipe compte ${equipe.joueursIds.length} joueur(s) ; il en faut au moins ${tournoi.joueursParEquipe}.`,
      );
    }
    const confirmees = await this.repo.count({ where: { tournoiId: tournoi.id, statut: 'confirmee' } });
    if (confirmees >= tournoi.nbEquipesMax) throw new ConflictException('Le tournoi est complet.');
    await this.repo.update(id, { statut: 'confirmee', valideeLe: new Date(), motifRefus: null });
    return this.findOne(id);
  }

  /** L’organisateur refuse (motif obligatoire) ; si l’équipe a payé, elle est à rembourser. */
  async refuser(id: number, motif: string): Promise<Equipe> {
    const equipe = await this.findOne(id);
    if (!EQUIPES_ACTIVES.includes(equipe.statut)) throw new ConflictException('Cette inscription n’est plus active.');
    if (await this.dansLeTableau(equipe)) throw new ConflictException('Cette équipe est déjà dans le tableau.');
    await this.repo.update(id, {
      statut: 'refusee',
      motifRefus: motif,
      statutPaiement: equipe.statutPaiement === 'paye' ? 'a_rembourser' : equipe.statutPaiement,
    });
    return this.findOne(id);
  }

  /** Le capitaine retire son équipe avant le tirage ; remboursée si elle a payé. */
  async annuler(id: number): Promise<Equipe> {
    const equipe = await this.findOne(id);
    if (!EQUIPES_ACTIVES.includes(equipe.statut)) throw new ConflictException('Cette inscription n’est plus active.');
    if (await this.dansLeTableau(equipe)) {
      throw new ConflictException('Le tableau est publié : contacte l’organisateur pour déclarer forfait.');
    }
    await this.repo.update(id, {
      statut: 'annulee',
      statutPaiement: equipe.statutPaiement === 'paye' ? 'a_rembourser' : equipe.statutPaiement,
    });
    return this.findOne(id);
  }

  async rembourser(id: number, paiementId?: number): Promise<Equipe> {
    const equipe = await this.findOne(id);
    if (equipe.statutPaiement !== 'a_rembourser') throw new ConflictException('Aucun remboursement en attente.');
    await this.repo.update(id, { statutPaiement: 'rembourse', ...(paiementId ? { paiementId } : {}) });
    return this.findOne(id);
  }

  /** Les matchs de l’équipe, dans l’ordre. */
  calendrier(id: number): Promise<Match[]> {
    return this.matchs.find({
      where: [{ equipe1Id: id }, { equipe2Id: id }],
      order: { debut: { direction: 'ASC', nulls: 'LAST' }, id: 'ASC' },
    });
  }

  // ---------------------------------------------------------------------------------------------

  private async tournoi(id: number): Promise<Tournoi> {
    const t = await this.tournois.findOne({ where: { id } });
    if (!t) throw new NotFoundException(`Tournoi ${id} introuvable`);
    return t;
  }

  private async verifierInscriptionsOuvertes(t: Tournoi) {
    if (t.statut !== 'inscriptions_ouvertes') throw new ConflictException('Les inscriptions de ce tournoi sont fermées.');
    if (t.dateLimiteInscription && new Date(t.dateLimiteInscription).getTime() < Date.now()) {
      throw new ConflictException('La date limite d’inscription est passée.');
    }
    const confirmees = await this.repo.count({ where: { tournoiId: t.id, statut: 'confirmee' } });
    if (confirmees >= t.nbEquipesMax) throw new ConflictException('Le tournoi est complet.');
  }

  private verifierModifiable(equipe: Equipe, t: Tournoi) {
    if (!EQUIPES_ACTIVES.includes(equipe.statut)) throw new ConflictException('Cette inscription n’est plus active.');
    if (['en_cours', 'termine', 'annule'].includes(t.statut)) {
      throw new ConflictException('Le tournoi a commencé : l’équipe ne peut plus être modifiée.');
    }
  }

  private verifierTaille(t: Tournoi, n: number) {
    if (t.joueursMaxParEquipe != null && n > t.joueursMaxParEquipe) {
      throw new BadRequestException(`Une équipe compte au plus ${t.joueursMaxParEquipe} joueurs.`);
    }
  }

  private async verifierNomLibre(tournoiId: number, nom: string, saufId?: number) {
    const qb = this.repo
      .createQueryBuilder('e')
      .where('e.tournoiId = :tournoiId', { tournoiId })
      .andWhere('LOWER(e.nom) = LOWER(:nom)', { nom: nom.trim() })
      .andWhere('e.statut IN (:...actifs)', { actifs: EQUIPES_ACTIVES });
    if (saufId) qb.andWhere('e.id <> :saufId', { saufId });
    if (await qb.getExists()) throw new ConflictException(`Le nom « ${nom.trim()} » est déjà pris dans ce tournoi.`);
  }

  private async verifierJoueursLibres(tournoiId: number, joueurs: number[], saufId?: number) {
    if (joueurs.length === 0) return;
    const qb = this.repo
      .createQueryBuilder('e')
      .where('e.tournoiId = :tournoiId', { tournoiId })
      .andWhere('e.statut IN (:...actifs)', { actifs: EQUIPES_ACTIVES })
      .andWhere('e.joueursIds && CAST(:joueurs AS int[])', { joueurs });
    if (saufId) qb.andWhere('e.id <> :saufId', { saufId });
    const deja = await qb.getMany();
    if (deja.length) {
      const pris = joueurs.filter((j) => deja.some((e) => e.joueursIds.includes(j)));
      throw new ConflictException(
        `Joueur(s) ${pris.join(', ')} déjà inscrit(s) dans ce tournoi avec « ${deja[0].nom} ».`,
      );
    }
  }

  private async dansLeTableau(equipe: Equipe): Promise<boolean> {
    return this.matchs.exist({
      where: [
        { tournoiId: equipe.tournoiId, equipe1Id: equipe.id },
        { tournoiId: equipe.tournoiId, equipe2Id: equipe.id },
      ],
    });
  }

  private async nouveauCode(): Promise<string> {
    for (;;) {
      const code = Array.from({ length: 8 }, () => CODE_CHARS[randomInt(CODE_CHARS.length)]).join('');
      if (!(await this.repo.exist({ where: { codeInvitation: code } }))) return code;
    }
  }

  /** Utilisé par le tableau : équipes confirmées, têtes de série d’abord. */
  confirmees(tournoiId: number): Promise<Equipe[]> {
    return this.repo.find({
      where: { tournoiId, statut: 'confirmee' },
      order: { seed: { direction: 'ASC', nulls: 'LAST' }, valideeLe: 'ASC', id: 'ASC' },
    });
  }
}
