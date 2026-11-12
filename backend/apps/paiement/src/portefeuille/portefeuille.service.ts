import { ConflictException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';

import { dt } from '../commun/argent';
import { Mouvement, Portefeuille, TypeMouvement } from './portefeuille.entity';

@Injectable()
export class PortefeuilleService {
  constructor(
    @InjectRepository(Portefeuille) private readonly repo: Repository<Portefeuille>,
    @InjectRepository(Mouvement) private readonly mouvements: Repository<Mouvement>,
    private readonly dataSource: DataSource,
  ) {}

  /** Le solde (0 si l’utilisateur n’a jamais eu de mouvement). */
  async solde(utilisateurId: number): Promise<{ utilisateurId: number; solde: number }> {
    const pf = await this.repo.findOne({ where: { utilisateurId } });
    return { utilisateurId, solde: pf?.solde ?? 0 };
  }

  historique(utilisateurId: number, filtres: { type?: string; du?: Date; au?: Date } = {}): Promise<Mouvement[]> {
    const qb = this.mouvements.createQueryBuilder('m').where('m.utilisateurId = :u', { u: utilisateurId });
    if (filtres.type) qb.andWhere('m.type = :t', { t: filtres.type });
    if (filtres.du) qb.andWhere('m.createdAt >= :du', { du: filtres.du });
    if (filtres.au) qb.andWhere('m.createdAt <= :au', { au: filtres.au });
    return qb.orderBy('m.id', 'DESC').getMany();
  }

  /**
   * Bouge le solde dans la transaction [em] : la ligne est verrouillée, le solde ne passe jamais
   * sous zéro, chaque mouvement garde le solde après.
   */
  async bouger(
    em: EntityManager,
    utilisateurId: number,
    montant: number,
    type: TypeMouvement,
    libelle: string,
    paiementId?: number | null,
  ): Promise<Mouvement> {
    await em.createQueryBuilder().insert().into(Portefeuille).values({ utilisateurId, solde: 0 }).orIgnore().execute();
    const pf = await em.findOneOrFail(Portefeuille, { where: { utilisateurId }, lock: { mode: 'pessimistic_write' } });
    const apres = dt(pf.solde + montant);
    if (apres < 0) throw new ConflictException('Solde insuffisant.');
    await em.update(Portefeuille, { utilisateurId }, { solde: apres });
    return em.save(
      Mouvement,
      em.create(Mouvement, { utilisateurId, type, montant: dt(montant), soldeApres: apres, libelle, paiementId: paiementId ?? null }),
    );
  }

  /** Geste commercial ou correction de l’admin. */
  ajuster(utilisateurId: number, montant: number, libelle: string): Promise<Mouvement> {
    return this.dataSource.transaction((em) => this.bouger(em, utilisateurId, montant, 'ajustement', libelle));
  }
}
