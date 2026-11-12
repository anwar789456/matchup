import { Controller, Get, Injectable, Query } from '@nestjs/common';
import { ApiOperation, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Type } from 'class-transformer';
import { IsDate, IsOptional } from 'class-validator';
import { Repository } from 'typeorm';

import { Abonnement } from '../abonnement/abonnement.entity';
import { dt } from '../commun/argent';
import { ENCAISSES, Paiement } from '../paiement/paiement.entity';
import { Portefeuille } from '../portefeuille/portefeuille.entity';
import { DemandeRemboursement, DEMANDES_OUVERTES } from '../remboursement/demande-remboursement.entity';
import { Versement } from '../versement/versement.entity';

export class QueryFinanceDto {
  @ApiPropertyOptional({ example: '2026-10-01', description: 'Par défaut : le début du mois' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  du?: Date;

  @ApiPropertyOptional({ example: '2026-11-01', description: 'Exclu ; par défaut : maintenant' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  au?: Date;
}

type Somme = { total: string | null; nombre: string };
const num = (v: string | null | undefined): number => dt(Number(v ?? 0));

@Injectable()
export class FinanceService {
  constructor(
    @InjectRepository(Paiement) private readonly paiements: Repository<Paiement>,
    @InjectRepository(DemandeRemboursement) private readonly demandes: Repository<DemandeRemboursement>,
    @InjectRepository(Versement) private readonly versements: Repository<Versement>,
    @InjectRepository(Abonnement) private readonly abonnements: Repository<Abonnement>,
    @InjectRepository(Portefeuille) private readonly portefeuilles: Repository<Portefeuille>,
  ) {}

  /** ADM-06 Finance : encaissé, remboursé, par objet, échecs, versements, abonnements, soldes. */
  async resume(q: QueryFinanceDto) {
    const maintenant = new Date();
    const du = q.du ?? new Date(maintenant.getFullYear(), maintenant.getMonth(), 1);
    const au = q.au ?? maintenant;
    const encaisses = () =>
      this.paiements
        .createQueryBuilder('p')
        .where('p.statut IN (:...s)', { s: ENCAISSES })
        .andWhere('p.payeLe >= :du AND p.payeLe < :au', { du, au });

    const total = await encaisses()
      .select('SUM(p.montant)', 'total')
      .addSelect('SUM(p.montantRembourse)', 'rembourse')
      .addSelect('COUNT(*)', 'nombre')
      .getRawOne<{ total: string | null; rembourse: string | null; nombre: string }>();
    const parObjet = await encaisses()
      .select('p.objet', 'objet')
      .addSelect('SUM(p.montant)', 'total')
      .addSelect('COUNT(*)', 'nombre')
      .groupBy('p.objet')
      .getRawMany<Somme & { objet: string }>();
    const echecs = await this.paiements
      .createQueryBuilder('p')
      .where("p.statut = 'echoue'")
      .andWhere('p.createdAt >= :du AND p.createdAt < :au', { du, au })
      .getCount();
    const demandes = await this.demandes
      .createQueryBuilder('d')
      .select('SUM(d.montant)', 'total')
      .addSelect('COUNT(*)', 'nombre')
      .where('d.statut IN (:...s)', { s: DEMANDES_OUVERTES })
      .getRawOne<Somme>();
    const versements = await this.versements
      .createQueryBuilder('v')
      .select('v.statut', 'statut')
      .addSelect('SUM(v.montantNet)', 'total')
      .addSelect('COUNT(*)', 'nombre')
      .groupBy('v.statut')
      .getRawMany<Somme & { statut: string }>();
    const actifs = await this.abonnements.find({ where: [{ statut: 'actif' }, { statut: 'essai' }, { statut: 'impaye' }] });
    const soldes = await this.portefeuilles.createQueryBuilder('w').select('SUM(w.solde)', 'total').getRawOne<{ total: string | null }>();

    const encaisse = num(total?.total);
    const rembourse = num(total?.rembourse);
    const nombre = Number(total?.nombre ?? 0);
    const parStatut = (s: string) => actifs.filter((a) => a.statut === s).length;
    return {
      periode: { du, au },
      encaisse,
      rembourse,
      net: dt(encaisse - rembourse),
      paiements: nombre,
      panierMoyen: nombre ? dt(encaisse / nombre) : 0,
      paiementsEchoues: echecs,
      parObjet: parObjet.map((r) => ({ objet: r.objet, total: num(r.total), nombre: Number(r.nombre) })),
      remboursementsEnAttente: { total: num(demandes?.total), nombre: Number(demandes?.nombre ?? 0) },
      versements: versements.map((r) => ({ statut: r.statut, total: num(r.total), nombre: Number(r.nombre) })),
      abonnements: {
        actifs: parStatut('actif'),
        essais: parStatut('essai'),
        impayes: parStatut('impaye'),
        /** Revenu mensuel récurrent : les annuels comptent pour 1/12. */
        revenuMensuel: dt(
          actifs.filter((a) => a.statut === 'actif').reduce((s, a) => s + (a.periode === 'annuel' ? a.prix / 12 : a.prix), 0),
        ),
      },
      /** Ce que MatchUp doit aux joueurs (soldes). */
      soldesJoueurs: num(soldes?.total),
    };
  }
}

/** /api/paiement/finance — tableau de bord finance de l’admin. */
@ApiTags('finance')
@Controller('finance')
export class FinanceController {
  constructor(private readonly service: FinanceService) {}

  @Get('resume')
  @ApiOperation({ summary: 'Résumé de la période (par défaut : ce mois-ci)' })
  resume(@Query() q: QueryFinanceDto) {
    return this.service.resume(q);
  }
}
