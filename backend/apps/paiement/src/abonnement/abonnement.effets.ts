import { NotFoundException } from '@nestjs/common';
import { EntityManager } from 'typeorm';

import { Paiement } from '../paiement/paiement.entity';
import { Abonnement, Periode } from './abonnement.entity';
import { finDePeriode, PLANS, prixDe } from './plans';

/**
 * Un prélèvement d’abonnement est passé : la période suivante commence. Un changement de plan
 * en attente s’applique et repart d’aujourd’hui ; un renouvellement repart de l’échéance.
 */
export async function apresPaiementAbonnement(em: EntityManager, id: number, paiement: Paiement): Promise<void> {
  const a = await em.findOne(Abonnement, { where: { id }, lock: { mode: 'pessimistic_write' } });
  if (!a) throw new NotFoundException(`Abonnement ${id} introuvable`);
  const maintenant = paiement.payeLe ?? new Date();
  const changement = a.planEnAttente != null || a.periodeEnAttente != null;
  if (changement) {
    a.plan = a.planEnAttente ?? a.plan;
    a.periode = (a.periodeEnAttente as Periode | null) ?? a.periode;
    a.prix = prixDe(PLANS[a.plan], a.periode);
    a.planEnAttente = null;
    a.periodeEnAttente = null;
  }
  const echeance = a.prochainPrelevement && a.prochainPrelevement > maintenant ? a.prochainPrelevement : maintenant;
  a.prochainPrelevement = finDePeriode(changement ? maintenant : echeance, a.periode);
  a.statut = 'actif';
  a.dernierPaiementId = paiement.id;
  if (a.remiseJusqua && a.remiseJusqua < maintenant) {
    a.remisePourcentage = 0;
    a.remiseJusqua = null;
  }
  await em.save(a);
}
