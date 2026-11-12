import { ConflictException, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { dt, formatDate, formatDT } from '../commun/argent';
import { CodePromo } from './code-promo.entity';

export interface VerificationPromo {
  code: string;
  valide: boolean;
  remise: number;
  total: number;
  pourcentage?: number | null;
  erreur?: string;
}

@Injectable()
export class CodePromoService extends CrudService<CodePromo> implements OnModuleInit {
  constructor(@InjectRepository(CodePromo) repo: Repository<CodePromo>) {
    super(repo, 'Code promo');
  }

  /** Les codes de l’histoire (STORY-DATA) si la table est vide : BIENVENUE10 valide, MARSA2025 expiré. */
  async onModuleInit(): Promise<void> {
    try {
      if ((await this.repo.count()) > 0) return;
      await this.repo.save([
        this.repo.create({ code: 'BIENVENUE10', pourcentage: 10 }),
        this.repo.create({ code: 'MARSA2025', pourcentage: 15, fin: new Date('2025-12-31T22:59:59Z') }),
      ]);
    } catch (e) {
      new Logger('CodePromo').warn(`Codes de démo non créés : ${(e as Error).message}`);
    }
  }

  static normaliser(code: string): string {
    return code.trim().toUpperCase();
  }

  override create(data: Partial<CodePromo>): Promise<CodePromo> {
    return super.create({ ...data, code: CodePromoService.normaliser(data.code ?? '') });
  }

  override update(id: number, data: Partial<CodePromo>): Promise<CodePromo> {
    return super.update(id, data.code ? { ...data, code: CodePromoService.normaliser(data.code) } : data);
  }

  /** La réponse du champ « Code promo » du checkout (valide ou la raison du refus). */
  async verifier(saisie: string, montant: number, maintenant = new Date()): Promise<VerificationPromo> {
    const code = CodePromoService.normaliser(saisie);
    const refus = (erreur: string): VerificationPromo => ({ code, valide: false, remise: 0, total: dt(montant), erreur });
    const promo = await this.repo.findOne({ where: { code } });
    if (!promo || !promo.actif) return refus('Ce code n’existe pas.');
    if (promo.fin && promo.fin < maintenant) return refus(`Ce code a expiré le ${formatDate(promo.fin)}.`);
    if (promo.debut && promo.debut > maintenant) return refus(`Ce code sera valable à partir du ${formatDate(promo.debut)}.`);
    if (promo.utilisationsMax != null && promo.utilisations >= promo.utilisationsMax) {
      return refus('Ce code a déjà été utilisé le nombre maximum de fois.');
    }
    if (promo.montantMin != null && montant < promo.montantMin) {
      return refus(`Ce code demande un montant d’au moins ${formatDT(promo.montantMin)}.`);
    }
    const remise = promo.pourcentage
      ? dt((montant * promo.pourcentage) / 100)
      : dt(Math.min(promo.montantFixe ?? 0, montant));
    return { code, valide: true, remise, total: dt(montant - remise), pourcentage: promo.pourcentage };
  }

  /** Compte une utilisation dans la transaction du paiement (refusé si le plafond est atteint entre-temps). */
  async utiliser(em: EntityManager, code: string): Promise<void> {
    const r = await em
      .createQueryBuilder()
      .update(CodePromo)
      .set({ utilisations: () => 'utilisations + 1' })
      .where('code = :code', { code })
      .andWhere('("utilisationsMax" IS NULL OR utilisations < "utilisationsMax")')
      .execute();
    if (!r.affected) throw new ConflictException('Ce code n’est plus disponible.');
  }
}
