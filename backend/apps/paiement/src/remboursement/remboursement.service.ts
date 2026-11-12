import { BadRequestException, ConflictException, ForbiddenException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { dt, formatDT } from '../commun/argent';
import { ENCAISSES } from '../paiement/paiement.entity';
import { PaiementService } from '../paiement/paiement.service';
import { DemandeRemboursement, DEMANDES_OUVERTES } from './demande-remboursement.entity';
import { AccepterDemandeDto, CreateDemandeDto, QueryDemandeDto, RefuserDemandeDto } from './remboursement.dto';

@Injectable()
export class RemboursementService extends CrudService<DemandeRemboursement> {
  constructor(
    @InjectRepository(DemandeRemboursement) repo: Repository<DemandeRemboursement>,
    private readonly paiements: PaiementService,
    private readonly dataSource: DataSource,
  ) {
    super(repo, 'Demande de remboursement');
  }

  liste(q: QueryDemandeDto): Promise<DemandeRemboursement[]> {
    return this.repo.find({
      where: {
        ...(q.utilisateurId ? { utilisateurId: q.utilisateurId } : {}),
        ...(q.paiementId ? { paiementId: q.paiementId } : {}),
        ...(q.statut ? { statut: q.statut } : {}),
      },
      order: { id: 'DESC' },
    });
  }

  /** WAL-04 « Envoyer la demande » : sur un paiement à soi, encaissé, sans autre demande en cours. */
  async creer(dto: CreateDemandeDto): Promise<DemandeRemboursement> {
    const p = await this.paiements.findOne(dto.paiementId);
    if (p.utilisateurId !== dto.utilisateurId) throw new ForbiddenException('Ce paiement n’est pas à toi.');
    if (!ENCAISSES.includes(p.statut) || p.statut === 'rembourse') {
      throw new ConflictException('Ce paiement ne peut pas être remboursé.');
    }
    if (await this.repo.exists({ where: { paiementId: p.id, statut: In(DEMANDES_OUVERTES) } })) {
      throw new ConflictException('Une demande est déjà en cours pour ce paiement.');
    }
    if (dto.cible === 'carte' && p.montantCarte <= 0) {
      throw new BadRequestException('Ce paiement n’est pas passé par une carte : choisis le solde.');
    }
    const restant = dt(p.montant - p.montantRembourse);
    const montant = dt(dto.montant ?? restant);
    if (montant > restant) throw new BadRequestException(`Au plus ${formatDT(restant)} à rembourser sur ce paiement.`);
    return super.create({
      utilisateurId: dto.utilisateurId,
      paiementId: p.id,
      motif: dto.motif,
      note: dto.note?.trim() ?? '',
      cible: dto.cible,
      photos: dto.photos ?? 0,
      montant,
      statut: 'envoyee',
    });
  }

  private async ouverte(id: number): Promise<DemandeRemboursement> {
    const d = await this.findOne(id);
    if (!DEMANDES_OUVERTES.includes(d.statut)) throw new ConflictException('Cette demande est déjà traitée.');
    return d;
  }

  /** WAL-05 « En cours d’examen ». */
  async examiner(id: number): Promise<DemandeRemboursement> {
    const d = await this.ouverte(id);
    if (d.statut === 'en_examen') return d;
    return super.update(id, { statut: 'en_examen', examenDepuis: new Date() });
  }

  /** Accepte et rembourse dans la même transaction (le solde est crédité tout de suite). */
  async accepter(id: number, dto: AccepterDemandeDto): Promise<DemandeRemboursement> {
    const d = await this.ouverte(id);
    const montant = dt(dto.montant ?? d.montant);
    await this.dataSource.transaction(async (em) => {
      await this.paiements.rembourser(d.paiementId, { montant, vers: d.cible as 'portefeuille' | 'carte' }, em);
      await em.update(DemandeRemboursement, { id }, {
        statut: 'remboursee',
        montant,
        traiteLe: new Date(),
        examenDepuis: d.examenDepuis ?? new Date(),
      });
    });
    return this.findOne(id);
  }

  async refuser(id: number, dto: RefuserDemandeDto): Promise<DemandeRemboursement> {
    await this.ouverte(id);
    return super.update(id, { statut: 'refusee', motifRefus: dto.motif.trim(), traiteLe: new Date() });
  }
}
