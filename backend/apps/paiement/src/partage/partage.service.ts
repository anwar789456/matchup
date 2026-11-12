import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, Repository } from 'typeorm';

import { dt } from '../commun/argent';
import { Paiement } from '../paiement/paiement.entity';
import { PaiementService } from '../paiement/paiement.service';
import { CreatePartageDto, PayerPartDto, PayerResteDto, QueryPartageDto, RelancerDto } from './partage.dto';
import { DELAI_ECHEANCE_HEURES, Part, Partage } from './partage.entity';

@Injectable()
export class PartageService {
  constructor(
    @InjectRepository(Partage) private readonly repo: Repository<Partage>,
    @InjectRepository(Part) private readonly parts: Repository<Part>,
    private readonly paiements: PaiementService,
    private readonly dataSource: DataSource,
  ) {}

  /** Le partage avec ses parts et le résumé de PAY-11 (collecté, reste, échéance). */
  async detail(id: number, maintenant = new Date()) {
    const partage = await this.repo.findOne({ where: { id }, relations: { parts: true } });
    if (!partage) throw new NotFoundException(`Partage ${id} introuvable`);
    const parts = [...(partage.parts ?? [])].sort((a, b) => a.position - b.position);
    const somme = (statuts: string[]) => dt(parts.filter((p) => statuts.includes(p.statut)).reduce((s, p) => s + p.montant, 0));
    const compte = (statut: string) => parts.filter((p) => p.statut === statut).length;
    const restant = somme(['en_attente']);
    return {
      ...partage,
      parts,
      resume: {
        collecte: somme(['payee', 'avancee']),
        restant,
        payees: compte('payee'),
        avancees: compte('avancee'),
        enAttente: compte('en_attente'),
        remboursees: compte('remboursee'),
        echeanceDepassee: partage.statut === 'en_cours' && restant > 0 && maintenant >= partage.echeance,
        minutesAvantEcheance: Math.max(0, Math.floor((partage.echeance.getTime() - maintenant.getTime()) / 60_000)),
      },
    };
  }

  async liste(q: QueryPartageDto) {
    const qb = this.repo.createQueryBuilder('pa').leftJoinAndSelect('pa.parts', 'part');
    if (q.reservationId) qb.andWhere('pa.reservationId = :r', { r: q.reservationId });
    if (q.organisateurId) qb.andWhere('pa.organisateurId = :o', { o: q.organisateurId });
    if (q.statut) qb.andWhere('pa.statut = :s', { s: q.statut });
    if (q.joueurId) {
      qb.andWhere('pa.id IN (SELECT p2."partageId" FROM paiement.part p2 WHERE p2."joueurId" = :j)', { j: q.joueurId });
    }
    return qb.orderBy('pa.id', 'DESC').addOrderBy('part.position', 'ASC').getMany();
  }

  /** Une part par joueur ; la dernière absorbe les millimes de l’arrondi. */
  async creer(dto: CreatePartageDto) {
    const debut = new Date(dto.debutMatch);
    const echeance = new Date(debut.getTime() - DELAI_ECHEANCE_HEURES * 3_600_000);
    if (echeance <= new Date()) throw new BadRequestException('Trop tard : tout doit être payé 3 h avant le match.');
    if (await this.repo.exists({ where: { reservationId: dto.reservationId, statut: In(['en_cours', 'complet']) } })) {
      throw new ConflictException('Cette réservation a déjà un paiement partagé.');
    }
    const n = dto.joueurs.length;
    const base = Math.floor((dto.montantTotal / n) * 1000) / 1000;
    const partage = await this.repo.save(
      this.repo.create({
        reservationId: dto.reservationId,
        organisateurId: dto.organisateurId,
        libelle: dto.libelle,
        montantTotal: dt(dto.montantTotal),
        beneficiaireId: dto.beneficiaireId ?? null,
        debutMatch: debut,
        echeance,
        statut: 'en_cours',
        parts: dto.joueurs.map((j, i) =>
          this.parts.create({
            joueurId: j.joueurId ?? null,
            nom: j.nom,
            partiePublique: j.partiePublique ?? false,
            montant: i === n - 1 ? dt(dto.montantTotal - base * (n - 1)) : base,
            statut: 'en_attente',
            position: i,
          }),
        ),
      }),
    );
    return this.detail(partage.id);
  }

  private async ouvert(id: number): Promise<Partage> {
    const partage = await this.repo.findOne({ where: { id } });
    if (!partage) throw new NotFoundException(`Partage ${id} introuvable`);
    if (partage.statut !== 'en_cours') throw new ConflictException('Ce paiement partagé est terminé.');
    if (new Date() >= partage.echeance) throw new ConflictException('L’échéance est passée : 3 h avant le match.');
    return partage;
  }

  /** Un joueur paie sa part (PAY-01 avec « Ta part : 15 DT sur 150 DT »). */
  async payerPart(id: number, partId: number, dto: PayerPartDto) {
    const partage = await this.ouvert(id);
    const part = await this.parts.findOne({ where: { id: partId, partageId: id } });
    if (!part) throw new NotFoundException(`Part ${partId} introuvable dans ce partage`);
    if (part.statut !== 'en_attente') throw new ConflictException('Cette part est déjà réglée.');
    const utilisateurId = dto.utilisateurId ?? part.joueurId;
    if (utilisateurId == null) throw new BadRequestException('utilisateurId est obligatoire pour un invité sans compte.');
    const paiement = await this.paiements.payer({
      utilisateurId,
      objet: 'part',
      objetId: String(part.id),
      libelle: `Part · ${partage.libelle}`,
      montant: part.montant,
      beneficiaireId: partage.beneficiaireId,
      moyen: dto.moyen,
    });
    return { paiement, partage: await this.detail(id) };
  }

  /** « Relancer » / « Relancer tout le monde » : la date est gardée ; les notifications partent des ids. */
  async relancer(id: number, dto: RelancerDto) {
    await this.ouvert(id);
    const where = { partageId: id, statut: 'en_attente', ...(dto.partIds?.length ? { id: In(dto.partIds) } : {}) };
    const relancees = await this.parts.find({ where });
    if (relancees.length) await this.parts.update({ id: In(relancees.map((p) => p.id)) }, { relanceLe: new Date() });
    return {
      relancees: relancees.map((p) => p.id),
      destinatairesIds: relancees.map((p) => p.joueurId).filter((j): j is number => j != null),
      partage: await this.detail(id),
    };
  }

  /** PAY-12 « Payer le reste » : l’organisateur avance toutes les parts en attente. */
  async payerLeReste(id: number, dto: PayerResteDto) {
    const partage = await this.ouvert(id);
    const enAttente = await this.parts.find({ where: { partageId: id, statut: 'en_attente' } });
    if (!enAttente.length) throw new ConflictException('Il n’y a plus de part à payer.');
    const paiement = await this.paiements.payer({
      utilisateurId: dto.utilisateurId ?? partage.organisateurId,
      objet: 'partage_reste',
      objetId: String(id),
      libelle: `Parts avancées · ${partage.libelle}`,
      montant: dt(enAttente.reduce((s, p) => s + p.montant, 0)),
      beneficiaireId: partage.beneficiaireId,
      moyen: dto.moyen,
    });
    return { paiement, partage: await this.detail(id) };
  }

  /**
   * « La réservation sera annulée si tout n’est pas payé 3 h avant le match » : passé l’échéance
   * avec des parts en attente, le partage est annulé et chacun est remboursé sur son solde.
   * À appeler par le module reservation (ou un cron) ; sans effet avant l’échéance.
   */
  async verifierEcheance(id: number) {
    const d = await this.detail(id);
    if (!d.resume.echeanceDepassee) return { annule: false, partage: d };
    return { annule: true, partage: await this.annuler(id) };
  }

  /** Réservation annulée (ou échéance) : rembourse chaque part payée et le paiement « reste ». */
  async annuler(id: number) {
    await this.dataSource.transaction(async (em) => {
      const partage = await em.findOne(Partage, { where: { id }, lock: { mode: 'pessimistic_write' } });
      if (!partage) throw new NotFoundException(`Partage ${id} introuvable`);
      if (partage.statut === 'annule') return;
      const parts = await em.find(Part, { where: { partageId: id } });
      const paiementsIds = [...new Set(parts.filter((p) => ['payee', 'avancee'].includes(p.statut) && p.paiementId).map((p) => p.paiementId!))];
      for (const paiementId of paiementsIds) {
        const p = await em.findOneOrFail(Paiement, { where: { id: paiementId } });
        if (p.statut === 'paye' || p.statut === 'partiellement_rembourse') {
          await this.paiements.rembourser(paiementId, { vers: 'portefeuille' }, em);
        }
      }
      await em.update(Part, { partageId: id, statut: In(['payee', 'avancee']) }, { statut: 'remboursee' });
      await em.update(Partage, { id }, { statut: 'annule' });
    });
    return this.detail(id);
  }
}
