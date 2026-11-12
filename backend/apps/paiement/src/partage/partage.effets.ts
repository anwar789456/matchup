import { ConflictException } from '@nestjs/common';
import { EntityManager } from 'typeorm';

import { Paiement } from '../paiement/paiement.entity';
import { Part, Partage } from './partage.entity';

/** Plus aucune part en attente → le partage est complet. */
export async function majStatutPartage(em: EntityManager, partageId: number): Promise<void> {
  const enAttente = await em.count(Part, { where: { partageId, statut: 'en_attente' } });
  if (enAttente === 0) await em.update(Partage, { id: partageId, statut: 'en_cours' }, { statut: 'complet' });
}

/** Une part payée par son joueur. Refusé si quelqu’un l’a payée entre-temps. */
export async function apresPaiementPart(em: EntityManager, partId: number, paiement: Paiement): Promise<void> {
  const part = await em.findOne(Part, { where: { id: partId }, lock: { mode: 'pessimistic_write' } });
  if (!part || part.statut !== 'en_attente') throw new ConflictException('Cette part est déjà réglée.');
  await em.update(Part, { id: partId }, { statut: 'payee', paiementId: paiement.id, payeeLe: paiement.payeLe });
  await majStatutPartage(em, part.partageId);
}

/** « Payer le reste » : l’organisateur avance toutes les parts encore en attente. */
export async function apresPaiementReste(em: EntityManager, partageId: number, paiement: Paiement): Promise<void> {
  const r = await em.update(
    Part,
    { partageId, statut: 'en_attente' },
    { statut: 'avancee', paiementId: paiement.id, payeeLe: paiement.payeLe },
  );
  if (!r.affected) throw new ConflictException('Il n’y a plus de part à payer.');
  await majStatutPartage(em, partageId);
}

/** Une part entièrement remboursée. */
export async function apresRemboursementPart(em: EntityManager, partId: number): Promise<void> {
  await em.update(Part, { id: partId }, { statut: 'remboursee' });
}
