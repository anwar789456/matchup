import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, IsNull, Repository } from 'typeorm';

import { dt } from '../commun/argent';
import { ENCAISSES, Paiement } from '../paiement/paiement.entity';
import { CalculerVersementDto, QueryVersementDto } from './versement.dto';
import { COMMISSIONS, Versement } from './versement.entity';

@Injectable()
export class VersementService {
  constructor(
    @InjectRepository(Versement) private readonly repo: Repository<Versement>,
    @InjectRepository(Paiement) private readonly paiements: Repository<Paiement>,
    private readonly dataSource: DataSource,
  ) {}

  async findOne(id: number): Promise<Versement> {
    const v = await this.repo.findOne({ where: { id } });
    if (!v) throw new NotFoundException(`Versement ${id} introuvable`);
    return v;
  }

  liste(q: QueryVersementDto): Promise<Versement[]> {
    return this.repo.find({
      where: {
        ...(q.beneficiaireId ? { beneficiaireId: q.beneficiaireId } : {}),
        ...(q.role ? { role: q.role as Versement['role'] } : {}),
        ...(q.statut ? { statut: q.statut } : {}),
      },
      order: { id: 'DESC' },
    });
  }

  /** Les paiements inclus dans un versement. */
  async paiementsDe(id: number): Promise<Paiement[]> {
    await this.findOne(id);
    return this.paiements.find({ where: { versementId: id }, order: { payeLe: 'ASC' } });
  }

  /**
   * Calcule le versement d’une période : les paiements encaissés pour ce bénéficiaire, pas encore
   * versés, moins ce qui a été remboursé et la commission. `apercu` ne réserve rien.
   */
  async calculer(dto: CalculerVersementDto) {
    const du = new Date(dto.du);
    const au = new Date(dto.au);
    if (au <= du) throw new BadRequestException('La fin de période doit suivre le début.');
    const trouver = (em = this.paiements.manager) =>
      em
        .getRepository(Paiement)
        .createQueryBuilder('p')
        .where('p.beneficiaireId = :b', { b: dto.beneficiaireId })
        .andWhere('p.statut IN (:...s)', { s: ENCAISSES })
        .andWhere('p.versementId IS NULL')
        .andWhere('p.payeLe >= :du AND p.payeLe < :au', { du, au })
        .orderBy('p.payeLe', 'ASC');

    const calcul = (liste: Paiement[]) => {
      const brut = dt(liste.reduce((s, p) => s + p.montant, 0));
      const rembourse = dt(liste.reduce((s, p) => s + p.montantRembourse, 0));
      const commission = dt((brut - rembourse) * COMMISSIONS[dto.role]);
      return { nbPaiements: liste.length, montantBrut: brut, montantRembourse: rembourse, commission, montantNet: dt(brut - rembourse - commission) };
    };

    if (dto.apercu) {
      const liste = await trouver().getMany();
      return { apercu: true, beneficiaireId: dto.beneficiaireId, role: dto.role, du, au, ...calcul(liste), paiementsIds: liste.map((p) => p.id) };
    }

    const versement = await this.dataSource.transaction(async (em) => {
      const liste = await trouver(em).setLock('pessimistic_write').getMany();
      if (!liste.length) throw new BadRequestException('Aucun paiement à verser sur cette période.');
      const v = await em.save(
        em.create(Versement, { beneficiaireId: dto.beneficiaireId, role: dto.role, du, au, statut: 'en_attente', ...calcul(liste) }),
      );
      await em.update(Paiement, { id: In(liste.map((p) => p.id)), versementId: IsNull() }, { versementId: v.id });
      return v;
    });
    return { apercu: false, ...versement };
  }

  /** ADM-07 « Valider la sélection ». Les versements déjà validés ou envoyés sont ignorés. */
  async valider(ids: number[]): Promise<Versement[]> {
    await this.repo.update({ id: In(ids), statut: 'en_attente' }, { statut: 'valide', valideLe: new Date() });
    return this.repo.find({ where: { id: In(ids) }, order: { id: 'ASC' } });
  }

  /** Le virement est parti : référence VIR-<année>-<id>. */
  async envoyer(id: number): Promise<Versement> {
    const v = await this.findOne(id);
    if (v.statut !== 'valide') throw new ConflictException('Un versement doit être validé avant d’être envoyé.');
    const maintenant = new Date();
    await this.repo.update(
      { id },
      { statut: 'envoye', envoyeLe: maintenant, reference: `VIR-${maintenant.getFullYear()}-${String(id).padStart(5, '0')}` },
    );
    return this.findOne(id);
  }

  /** Un versement en attente peut être recalculé : ses paiements sont libérés. */
  async supprimer(id: number): Promise<{ deleted: true; id: number }> {
    const v = await this.findOne(id);
    if (v.statut !== 'en_attente') throw new ConflictException('Seul un versement en attente peut être supprimé.');
    await this.dataSource.transaction(async (em) => {
      await em.update(Paiement, { versementId: id }, { versementId: null });
      await em.delete(Versement, { id });
    });
    return { deleted: true, id };
  }
}
