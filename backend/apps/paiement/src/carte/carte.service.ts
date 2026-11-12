import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { chiffres, expiree, expireBientot, libelleCarte, verifierCarte } from '../commun/banque';
import { MoyenPaiementDto, NouvelleCarteDto } from '../commun/moyen.dto';
import { Carte } from './carte.entity';

/** Une carte telle que l’app l’affiche. */
export type VueCarte = Carte & { libelle: string; expiration: string; expireBientot: boolean; expiree: boolean };

/** La carte qui paie : enregistrée (carteId) ou tapée pour ce paiement seulement. */
export interface CarteResolue {
  carteId: number | null;
  libelle: string;
  numero?: string;
}

@Injectable()
export class CarteService {
  constructor(@InjectRepository(Carte) private readonly repo: Repository<Carte>) {}

  static vue(c: Carte): VueCarte {
    return {
      ...c,
      libelle: libelleCarte(c.marque, c.derniersChiffres),
      expiration: `${String(c.moisExp).padStart(2, '0')}/${c.anneeExp % 100}`,
      expireBientot: expireBientot(c.moisExp, c.anneeExp),
      expiree: expiree(c.moisExp, c.anneeExp),
    };
  }

  async liste(utilisateurId: number): Promise<VueCarte[]> {
    const cartes = await this.repo.find({ where: { utilisateurId }, order: { parDefaut: 'DESC', id: 'ASC' } });
    return cartes.map(CarteService.vue);
  }

  async findOne(id: number): Promise<Carte> {
    const carte = await this.repo.findOne({ where: { id } });
    if (!carte) throw new NotFoundException(`Carte ${id} introuvable`);
    return carte;
  }

  /** La première carte devient la carte par défaut. */
  async ajouter(utilisateurId: number, dto: NouvelleCarteDto): Promise<VueCarte> {
    const marque = verifierCarte(dto.numero, dto.moisExp, dto.anneeExp);
    const derniers = chiffres(dto.numero).slice(-4);
    const deja = await this.repo.findOne({
      where: { utilisateurId, marque, derniersChiffres: derniers, moisExp: dto.moisExp, anneeExp: dto.anneeExp },
    });
    if (deja) return CarteService.vue(deja);
    const premiere = (await this.repo.count({ where: { utilisateurId } })) === 0;
    const carte = await this.repo.save(
      this.repo.create({
        utilisateurId,
        marque,
        derniersChiffres: derniers,
        moisExp: dto.moisExp,
        anneeExp: dto.anneeExp,
        titulaire: dto.titulaire?.trim() ?? null,
        parDefaut: premiere,
      }),
    );
    return CarteService.vue(carte);
  }

  async definirParDefaut(id: number): Promise<VueCarte> {
    const carte = await this.findOne(id);
    await this.repo.update({ utilisateurId: carte.utilisateurId }, { parDefaut: false });
    await this.repo.update({ id }, { parDefaut: true });
    return CarteService.vue({ ...carte, parDefaut: true });
  }

  /** Si c’était la carte par défaut, la plus ancienne qui reste prend sa place. */
  async supprimer(id: number): Promise<{ deleted: true; id: number }> {
    const carte = await this.findOne(id);
    await this.repo.remove(carte);
    if (carte.parDefaut) {
      const suivante = await this.repo.findOne({ where: { utilisateurId: carte.utilisateurId }, order: { id: 'ASC' } });
      if (suivante) await this.repo.update({ id: suivante.id }, { parDefaut: true });
    }
    return { deleted: true, id };
  }

  /**
   * La carte d’un paiement : la nouvelle carte (enregistrée si demandé ou si [enregistrer]),
   * sinon la carte choisie, sinon la carte par défaut.
   */
  async resoudre(utilisateurId: number, moyen: MoyenPaiementDto, enregistrer = false): Promise<CarteResolue> {
    const nouvelle = moyen.nouvelleCarte;
    if (nouvelle) {
      if (nouvelle.enregistrer || enregistrer) {
        const carte = await this.ajouter(utilisateurId, nouvelle);
        return { carteId: carte.id, libelle: carte.libelle, numero: nouvelle.numero };
      }
      const marque = verifierCarte(nouvelle.numero, nouvelle.moisExp, nouvelle.anneeExp);
      return { carteId: null, libelle: libelleCarte(marque, chiffres(nouvelle.numero).slice(-4)), numero: nouvelle.numero };
    }
    const carte = moyen.carteId
      ? await this.findOne(moyen.carteId)
      : await this.repo.findOne({ where: { utilisateurId }, order: { parDefaut: 'DESC', id: 'ASC' } });
    if (!carte) throw new BadRequestException('Aucune carte enregistrée : ajoute une carte pour payer.');
    if (carte.utilisateurId !== utilisateurId) throw new ForbiddenException('Cette carte n’est pas à toi.');
    if (expiree(carte.moisExp, carte.anneeExp)) throw new BadRequestException('Carte expirée.');
    return { carteId: carte.id, libelle: libelleCarte(carte.marque, carte.derniersChiffres) };
  }
}
