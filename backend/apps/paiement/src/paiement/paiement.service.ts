import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';

import { apresPaiementAbonnement } from '../abonnement/abonnement.effets';
import { CarteResolue, CarteService } from '../carte/carte.service';
import { CodePromoService } from '../code-promo/code-promo.service';
import { dt, formatDT } from '../commun/argent';
import { issueBanque, RAISONS } from '../commun/banque';
import { MoyenPaiementDto } from '../commun/moyen.dto';
import { apresPaiementPart, apresPaiementReste, apresRemboursementPart } from '../partage/partage.effets';
import { PortefeuilleService } from '../portefeuille/portefeuille.service';
import { QueryPaiementDto } from './paiement.dto';
import { ENCAISSES, Objet, Paiement } from './paiement.entity';

/** Ce qu’un module (ou l’app) demande de payer. */
export interface DemandePaiement {
  utilisateurId: number;
  objet: Objet;
  objetId?: string | null;
  libelle: string;
  montant: number;
  beneficiaireId?: number | null;
  codePromo?: string;
  moyen?: MoyenPaiementDto;
  /** especes / virement : encaissé au guichet par le propriétaire, pas de banque. */
  methode?: 'carte' | 'portefeuille' | 'especes' | 'virement';
  /** Garder la nouvelle carte même sans « Enregistrer cette carte » (abonnements). */
  enregistrerCarte?: boolean;
}

export interface OptionsRemboursement {
  montant?: number;
  /** portefeuille (immédiat) ou carte (sous 10 jours ouvrés). Par défaut : la carte si elle a payé. */
  vers?: 'portefeuille' | 'carte';
}

/** Le premier reçu de l’histoire est MU-R-2026-01482. */
const PREMIER_RECU = 1482;

@Injectable()
export class PaiementService {
  constructor(
    @InjectRepository(Paiement) private readonly repo: Repository<Paiement>,
    private readonly dataSource: DataSource,
    private readonly cartes: CarteService,
    private readonly promos: CodePromoService,
    private readonly portefeuille: PortefeuilleService,
  ) {}

  async findOne(id: number): Promise<Paiement> {
    const p = await this.repo.findOne({ where: { id } });
    if (!p) throw new NotFoundException(`Paiement ${id} introuvable`);
    return p;
  }

  liste(q: QueryPaiementDto): Promise<Paiement[]> {
    const qb = this.repo.createQueryBuilder('p');
    if (q.utilisateurId) qb.andWhere('p.utilisateurId = :u', { u: q.utilisateurId });
    if (q.beneficiaireId) qb.andWhere('p.beneficiaireId = :b', { b: q.beneficiaireId });
    if (q.objet) qb.andWhere('p.objet = :o', { o: q.objet });
    if (q.objetId) qb.andWhere('p.objetId = :oi', { oi: q.objetId });
    if (q.statut) qb.andWhere('p.statut = :s', { s: q.statut });
    if (q.methode) qb.andWhere('p.methode = :m', { m: q.methode });
    if (q.du) qb.andWhere('p.createdAt >= :du', { du: q.du });
    if (q.au) qb.andWhere('p.createdAt <= :au', { au: q.au });
    return qb.orderBy('p.id', 'DESC').getMany();
  }

  /**
   * Le checkout : code promo, puis le solde (s’il est utilisé), puis la carte pour le reste. La
   * réponse dit ce que l’écran fait ensuite : `paye` (reçu), `a_authentifier` (3-D Secure, puis
   * /authentifier) ou `echoue` (raisonEchec, rien n’est débité). Chaque essai reste une ligne.
   */
  async payer(d: DemandePaiement): Promise<Paiement> {
    const moyen = d.moyen ?? {};
    if (!(d.montant > 0)) throw new BadRequestException('Le montant doit être positif.');

    let remise = 0;
    let codePromo: string | null = null;
    if (d.codePromo) {
      const v = await this.promos.verifier(d.codePromo, d.montant);
      if (!v.valide) throw new BadRequestException(v.erreur);
      remise = v.remise;
      codePromo = v.code;
    }
    const total = dt(d.montant - remise);

    const guichet = d.methode === 'especes' || d.methode === 'virement';
    const recharge = d.objet === 'recharge';
    if (recharge && (d.methode === 'portefeuille' || moyen.utiliserSolde)) {
      throw new BadRequestException('Une recharge se paie par carte.');
    }

    let partSolde = 0;
    if (!guichet && !recharge && total > 0) {
      const { solde } = await this.portefeuille.solde(d.utilisateurId);
      if (d.methode === 'portefeuille') {
        if (solde < total) throw new ConflictException(`Solde insuffisant : ${formatDT(solde)} disponibles.`);
        partSolde = total;
      } else if (moyen.utiliserSolde) {
        partSolde = dt(Math.min(solde, total));
      }
    }
    const partCarte = guichet ? 0 : dt(total - partSolde);

    let carte: CarteResolue | null = null;
    if (partCarte > 0) carte = await this.cartes.resoudre(d.utilisateurId, moyen, d.enregistrerCarte);

    const methode = guichet
      ? d.methode!
      : partCarte > 0 && partSolde > 0
        ? 'mixte'
        : partCarte > 0
          ? 'carte'
          : 'portefeuille';
    const issue = partCarte > 0 ? issueBanque(moyen.simulation, carte?.numero) : 'succes';

    const p = await this.repo.save(
      this.repo.create({
        utilisateurId: d.utilisateurId,
        objet: d.objet,
        objetId: d.objetId ?? null,
        libelle: d.libelle,
        beneficiaireId: d.beneficiaireId ?? null,
        montantBrut: dt(d.montant),
        remise,
        codePromo,
        montant: total,
        montantPortefeuille: partSolde,
        montantCarte: partCarte,
        methode,
        carteId: carte?.carteId ?? null,
        carteLibelle: carte?.libelle ?? null,
        statut: issue === 'succes' ? 'en_attente' : issue === '3ds' ? 'a_authentifier' : 'echoue',
        raisonEchec: RAISONS[issue] ?? null,
      }),
    );
    return issue === 'succes' ? this.finaliserOuEchouer(p.id) : p;
  }

  /** Réponse de la banque après 3-D Secure (« Valider » ou « Annuler » dans la fenêtre de la banque). */
  async authentifier(id: number, approuve: boolean): Promise<Paiement> {
    const p = await this.findOne(id);
    if (p.statut !== 'a_authentifier') throw new ConflictException('Ce paiement n’attend pas d’authentification.');
    if (approuve) return this.finaliserOuEchouer(id);
    await this.repo.update({ id }, { statut: 'echoue', raisonEchec: 'authentification annulée' });
    return this.findOne(id);
  }

  /** Comme [finaliser], mais un refus (solde dépensé entre-temps, part déjà payée…) laisse un échec lisible. */
  private async finaliserOuEchouer(id: number): Promise<Paiement> {
    try {
      return await this.finaliser(id);
    } catch (e) {
      if (!(e instanceof ConflictException)) throw e;
      await this.repo.update({ id }, { statut: 'echoue', raisonEchec: e.message.slice(0, 120) });
      return this.findOne(id);
    }
  }

  /**
   * Encaisse en une transaction : débite le solde, compte le code promo, numérote le reçu, puis
   * applique l’effet (recharge, part, abonnement…). Tout ou rien.
   */
  private finaliser(id: number): Promise<Paiement> {
    return this.dataSource.transaction(async (em) => {
      const p = await em.findOneOrFail(Paiement, { where: { id }, lock: { mode: 'pessimistic_write' } });
      if (p.statut === 'paye') return p;
      if (p.statut !== 'en_attente' && p.statut !== 'a_authentifier') {
        throw new ConflictException('Ce paiement ne peut plus être encaissé.');
      }
      if (p.montantPortefeuille > 0) {
        await this.portefeuille.bouger(em, p.utilisateurId, -p.montantPortefeuille, 'paiement', p.libelle, p.id);
      }
      if (p.codePromo) await this.promos.utiliser(em, p.codePromo);
      p.reference = await this.prochaineReference(em);
      p.statut = 'paye';
      p.payeLe = new Date();
      p.raisonEchec = null;
      await em.save(p);
      await this.effets(em, p);
      return p;
    });
  }

  /** MU-R-<année>-<n° à 5 chiffres>, à la suite du dernier reçu (verrou pour deux paiements simultanés). */
  private async prochaineReference(em: EntityManager): Promise<string> {
    await em.query(`SELECT pg_advisory_xact_lock(hashtext('paiement.reference'))`);
    const annee = new Date().getFullYear();
    const prefixe = `MU-R-${annee}-`;
    const { max } = (await em
      .getRepository(Paiement)
      .createQueryBuilder('p')
      .select(`MAX(CAST(SUBSTRING(p.reference FROM ${prefixe.length + 1}) AS INT))`, 'max')
      .where('p.reference LIKE :pre', { pre: `${prefixe}%` })
      .getRawOne<{ max: number | null }>()) ?? { max: null };
    return `${prefixe}${String((max ?? PREMIER_RECU - 1) + 1).padStart(5, '0')}`;
  }

  private async effets(em: EntityManager, p: Paiement): Promise<void> {
    const id = Number(p.objetId);
    switch (p.objet) {
      case 'recharge':
        await this.portefeuille.bouger(em, p.utilisateurId, p.montant, 'recharge', 'Recharge', p.id);
        break;
      case 'part':
        await apresPaiementPart(em, id, p);
        break;
      case 'partage_reste':
        await apresPaiementReste(em, id, p);
        break;
      case 'abonnement':
        await apresPaiementAbonnement(em, id, p);
        break;
      default:
        // reservation, partie, tournoi, programme : le module concerné enregistre le paiementId.
        break;
    }
  }

  /**
   * Rembourse tout ou partie d’un paiement encaissé, sur le solde (immédiat) ou sur la carte.
   * Une recharge se rembourse sur la carte et retire le montant du solde. Dans [em] si donné.
   */
  rembourser(id: number, options: OptionsRemboursement = {}, em?: EntityManager): Promise<Paiement> {
    const run = async (tx: EntityManager): Promise<Paiement> => {
      const p = await tx.findOne(Paiement, { where: { id }, lock: { mode: 'pessimistic_write' } });
      if (!p) throw new NotFoundException(`Paiement ${id} introuvable`);
      if (p.statut !== 'paye' && p.statut !== 'partiellement_rembourse') {
        throw new ConflictException('Ce paiement ne peut pas être remboursé.');
      }
      const restant = dt(p.montant - p.montantRembourse);
      const montant = dt(options.montant ?? restant);
      if (montant <= 0 || montant > restant) {
        throw new BadRequestException(`Au plus ${formatDT(restant)} à rembourser sur ce paiement.`);
      }
      const recharge = p.objet === 'recharge';
      const vers = recharge ? 'carte' : (options.vers ?? (p.montantCarte > 0 ? 'carte' : 'portefeuille'));
      if (vers === 'carte' && p.montantCarte <= 0) throw new BadRequestException('Ce paiement n’est pas passé par une carte.');
      if (recharge) {
        await this.portefeuille.bouger(tx, p.utilisateurId, -montant, 'remboursement', 'Remboursement de la recharge', p.id);
      } else if (vers === 'portefeuille') {
        await this.portefeuille.bouger(tx, p.utilisateurId, montant, 'remboursement', `Remboursement · ${p.libelle}`, p.id);
      }
      p.montantRembourse = dt(p.montantRembourse + montant);
      p.statut = p.montantRembourse >= p.montant ? 'rembourse' : 'partiellement_rembourse';
      p.rembourseLe = new Date();
      await tx.save(p);
      if (p.statut === 'rembourse' && p.objet === 'part') await apresRemboursementPart(tx, Number(p.objetId));
      return p;
    };
    return em ? run(em) : this.dataSource.transaction(run);
  }

  /** Le reçu (PAY-09, RCT) : lignes, remise, solde et carte, remboursement. */
  async recu(id: number) {
    const p = await this.findOne(id);
    if (!ENCAISSES.includes(p.statut)) throw new ConflictException('Pas de reçu : ce paiement n’est pas passé.');
    return {
      numero: p.reference,
      date: p.payeLe,
      libelle: p.libelle,
      objet: p.objet,
      objetId: p.objetId,
      lignes: [{ libelle: p.libelle, montant: p.montantBrut }],
      codePromo: p.codePromo,
      remise: p.remise,
      total: p.montant,
      reglement: [
        ...(p.montantPortefeuille > 0 ? [{ moyen: 'Solde MatchUp', montant: p.montantPortefeuille }] : []),
        ...(p.montantCarte > 0 ? [{ moyen: p.carteLibelle ?? 'Carte', montant: p.montantCarte }] : []),
        ...(p.methode === 'especes' ? [{ moyen: 'Espèces', montant: p.montant }] : []),
        ...(p.methode === 'virement' ? [{ moyen: 'Virement', montant: p.montant }] : []),
      ],
      rembourse: p.montantRembourse,
      statut: p.statut,
    };
  }
}
