import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';

import { CarteService } from '../carte/carte.service';
import { ajouterJours, ajouterMois, dt, formatDate } from '../commun/argent';
import { Paiement } from '../paiement/paiement.entity';
import { PaiementService } from '../paiement/paiement.service';
import { Abonnement, ABONNEMENTS_VIVANTS, Periode } from './abonnement.entity';
import { AnnulerAbonnementDto, ChangerAbonnementDto, PreleverDto, QueryAbonnementDto, SouscrireDto } from './abonnement.dto';
import {
  debutDePeriode,
  economieAnnuelle,
  finEssai,
  OFFRE_RETENTION,
  Plan,
  PLAN_GRATUIT,
  PLANS,
  prixDe,
  RAPPEL_JOURS,
} from './plans';

@Injectable()
export class AbonnementService {
  constructor(
    @InjectRepository(Abonnement) private readonly repo: Repository<Abonnement>,
    private readonly paiements: PaiementService,
    private readonly cartes: CarteService,
  ) {}

  /** La page des offres (SUB-01) : prix mensuel / annuel et économie de l’annuel. */
  plans() {
    return [
      { ...PLAN_GRATUIT, essaiJours: 0, avantages: ['Rejoindre et réserver des parties', 'Paiement partagé'] },
      ...Object.values(PLANS).map((p) => ({ ...p, economieAnnuelle: economieAnnuelle(p) })),
    ];
  }

  private plan(code: string): Plan {
    const plan = PLANS[code];
    if (!plan) throw new BadRequestException(`Plan inconnu : ${code}.`);
    return plan;
  }

  /** L’abonnement tel que l’écran l’affiche (prix avec l’offre, date du rappel, jours d’essai). */
  vue(a: Abonnement, maintenant = new Date()) {
    const plan = PLANS[a.plan];
    const remiseActive = a.remisePourcentage > 0 && (!a.remiseJusqua || a.remiseJusqua > maintenant);
    return {
      ...a,
      planNom: plan?.nom ?? a.plan,
      famille: plan?.famille,
      prixActuel: remiseActive ? dt(a.prix * (1 - a.remisePourcentage / 100)) : a.prix,
      rappelLe: a.statut === 'essai' && a.finEssai ? ajouterJours(a.finEssai, -RAPPEL_JOURS) : null,
      joursRestantsEssai:
        a.statut === 'essai' && a.finEssai ? Math.max(0, Math.ceil((a.finEssai.getTime() - maintenant.getTime()) / 86_400_000)) : null,
    };
  }

  async findOne(id: number): Promise<Abonnement> {
    const a = await this.repo.findOne({ where: { id } });
    if (!a) throw new NotFoundException(`Abonnement ${id} introuvable`);
    return a;
  }

  async detail(id: number) {
    return this.vue(await this.findOne(id));
  }

  async liste(q: QueryAbonnementDto) {
    const rows = await this.repo.find({
      where: { ...(q.utilisateurId ? { utilisateurId: q.utilisateurId } : {}), ...(q.statut ? { statut: q.statut } : {}) },
      order: { id: 'DESC' },
    });
    return rows.map((a) => this.vue(a));
  }

  /**
   * S’abonner : 14 jours d’essai à 0 DT la première fois dans cette famille (joueur, propriétaire,
   * coach), sinon prélevé tout de suite. La carte est toujours gardée pour les prélèvements.
   */
  async souscrire(dto: SouscrireDto) {
    const plan = this.plan(dto.plan);
    const memeFamille = Object.values(PLANS).filter((p) => p.famille === plan.famille).map((p) => p.code);
    const anciens = await this.repo.find({ where: { utilisateurId: dto.utilisateurId, plan: In(memeFamille) } });
    if (anciens.some((a) => ABONNEMENTS_VIVANTS.includes(a.statut))) {
      throw new ConflictException('Tu as déjà un abonnement en cours pour ce profil : change de plan plutôt.');
    }
    const carte = await this.cartes.resoudre(dto.utilisateurId, dto.moyen ?? {}, true);
    const maintenant = new Date();
    const prix = prixDe(plan, dto.periode);
    const essai = anciens.length === 0 && plan.essaiJours > 0;

    if (essai) {
      const fin = finEssai(maintenant, plan);
      const a = await this.repo.save(
        this.repo.create({
          utilisateurId: dto.utilisateurId,
          plan: plan.code,
          periode: dto.periode,
          statut: 'essai',
          prix,
          debutLe: maintenant,
          finEssai: fin,
          prochainPrelevement: fin,
          carteId: carte.carteId,
        }),
      );
      return { abonnement: this.vue(a), paiement: null };
    }

    const a = await this.repo.save(
      this.repo.create({
        utilisateurId: dto.utilisateurId,
        plan: plan.code,
        periode: dto.periode,
        statut: 'en_attente_paiement',
        prix,
        debutLe: maintenant,
        carteId: carte.carteId,
      }),
    );
    const paiement = await this.prelevement(a, prix, dto.moyen?.simulation);
    if (paiement.statut === 'echoue') {
      await this.repo.remove(a);
      return { abonnement: null, paiement };
    }
    return { abonnement: await this.detail(a.id), paiement };
  }

  private prelevement(a: Abonnement, montant: number, simulation?: PreleverDto['simulation']): Promise<Paiement> {
    const plan = PLANS[a.planEnAttente ?? a.plan];
    const periode = (a.periodeEnAttente as Periode | null) ?? a.periode;
    return this.paiements.payer({
      utilisateurId: a.utilisateurId,
      objet: 'abonnement',
      objetId: String(a.id),
      libelle: `MatchUp ${plan.nom} · ${periode === 'annuel' ? 'annuel' : 'mensuel'}`,
      montant,
      moyen: { carteId: a.carteId ?? undefined, simulation },
    });
  }

  /**
   * Changer de plan ou de période (SUB-04). Pendant l’essai : rien à payer, le nouveau prix vaut
   * au premier prélèvement. Abonnement actif : on paie le nouveau prix moins ce qui reste de la
   * période payée (prorata), et une nouvelle période commence aujourd’hui. `apercu` ne change rien.
   */
  async changer(id: number, dto: ChangerAbonnementDto) {
    const a = await this.findOne(id);
    if (!['essai', 'actif'].includes(a.statut)) throw new ConflictException('Seul un abonnement en cours peut changer de plan.');
    const plan = this.plan(dto.plan ?? a.plan);
    if (plan.famille !== PLANS[a.plan].famille) throw new BadRequestException('Ce plan est pour un autre profil.');
    const periode = dto.periode ?? a.periode;
    if (plan.code === a.plan && periode === a.periode) throw new BadRequestException('C’est déjà ton plan.');
    const nouveauPrix = prixDe(plan, periode);
    const maintenant = new Date();

    let credit = 0;
    if (a.statut === 'actif' && a.prochainPrelevement) {
      const debut = debutDePeriode(a.prochainPrelevement, a.periode).getTime();
      const total = a.prochainPrelevement.getTime() - debut;
      const reste = Math.max(0, a.prochainPrelevement.getTime() - maintenant.getTime());
      credit = dt((a.prix * reste) / total);
    }
    const aPayer = a.statut === 'essai' ? 0 : dt(Math.max(0, nouveauPrix - credit));
    const calcul = {
      plan: plan.code,
      periode,
      nouveauPrix,
      credit,
      aPayer,
      prochainPrelevement: a.statut === 'essai' ? a.prochainPrelevement : aPayer > 0 ? ajouterMois(maintenant, periode === 'annuel' ? 12 : 1) : a.prochainPrelevement,
    };
    if (dto.apercu) return { apercu: true, ...calcul, abonnement: this.vue(a) };

    if (aPayer === 0) {
      // Essai, ou passage à moins cher : la période en cours continue au nouveau prix.
      await this.repo.update({ id }, { plan: plan.code, periode, prix: nouveauPrix });
      return { apercu: false, ...calcul, paiement: null, abonnement: await this.detail(id) };
    }
    await this.repo.update({ id }, { planEnAttente: plan.code, periodeEnAttente: periode });
    const paiement = await this.prelevement({ ...a, planEnAttente: plan.code, periodeEnAttente: periode }, aPayer, dto.simulation);
    if (paiement.statut === 'echoue') await this.repo.update({ id }, { planEnAttente: null, periodeEnAttente: null });
    return { apercu: false, ...calcul, paiement, abonnement: await this.detail(id) };
  }

  /**
   * Résilier (SUB-05) : la première fois, l’offre « −30 % pendant 2 mois » est proposée et rien ne
   * change ; « Non merci, résilier » renvoie avec `confirmer: true`. L’accès reste jusqu’à la fin
   * de la période (ou de l’essai), sans autre prélèvement.
   */
  async annuler(id: number, dto: AnnulerAbonnementDto) {
    const a = await this.findOne(id);
    if (!['essai', 'actif', 'impaye'].includes(a.statut)) throw new ConflictException('Cet abonnement n’est pas en cours.');
    if (!dto.confirmer && !a.offreProposee && a.remisePourcentage === 0) {
      await this.repo.update({ id }, { offreProposee: true, motifAnnulation: dto.motif, noteAnnulation: dto.note ?? null });
      return {
        annule: false,
        offre: { ...OFFRE_RETENTION, prixAvecOffre: dt(a.prix * (1 - OFFRE_RETENTION.pourcentage / 100)), periode: a.periode },
        abonnement: await this.detail(id),
      };
    }
    const fin = a.statut === 'essai' ? a.finEssai : a.statut === 'impaye' ? new Date() : a.prochainPrelevement;
    await this.repo.update(
      { id },
      {
        statut: 'annule',
        finLe: fin ?? new Date(),
        prochainPrelevement: null,
        motifAnnulation: dto.motif,
        noteAnnulation: dto.note ?? a.noteAnnulation ?? null,
        planEnAttente: null,
        periodeEnAttente: null,
      },
    );
    return { annule: true, offre: null, abonnement: await this.detail(id) };
  }

  async accepterOffre(id: number) {
    const a = await this.findOne(id);
    if (!['essai', 'actif'].includes(a.statut)) throw new ConflictException('Cet abonnement n’est pas en cours.');
    if (!a.offreProposee) throw new ConflictException('Aucune offre n’a été proposée.');
    if (a.remisePourcentage > 0) throw new ConflictException('L’offre est déjà appliquée.');
    const depuis = a.prochainPrelevement ?? new Date();
    await this.repo.update(
      { id },
      { remisePourcentage: OFFRE_RETENTION.pourcentage, remiseJusqua: ajouterMois(depuis, OFFRE_RETENTION.mois), motifAnnulation: null },
    );
    return this.detail(id);
  }

  /** Revenir sur une résiliation avant la fin de l’accès. */
  async reactiver(id: number) {
    const a = await this.findOne(id);
    const maintenant = new Date();
    if (a.statut !== 'annule' || !a.finLe || a.finLe <= maintenant) {
      throw new ConflictException('Seul un abonnement résilié, encore actif, peut être réactivé.');
    }
    await this.repo.update(
      { id },
      {
        statut: a.finEssai && a.finEssai > maintenant ? 'essai' : 'actif',
        prochainPrelevement: a.finLe,
        finLe: null,
        motifAnnulation: null,
        noteAnnulation: null,
      },
    );
    return this.detail(id);
  }

  /**
   * Le prélèvement de l’échéance (fin d’essai, renouvellement) — à appeler par un cron ou le menu
   * debug. Refusé avant l’échéance sauf `forcer`. Un abonnement résilié arrivé au bout expire.
   */
  async prelever(id: number, dto: PreleverDto) {
    const a = await this.findOne(id);
    const maintenant = new Date();
    if (a.statut === 'annule') {
      if (!dto.forcer && a.finLe && a.finLe > maintenant) {
        throw new ConflictException(`Résilié : l’accès reste ouvert jusqu’au ${formatDate(a.finLe)}.`);
      }
      await this.repo.update({ id }, { statut: 'expire' });
      return { abonnement: await this.detail(id), paiement: null };
    }
    if (!['essai', 'actif', 'impaye'].includes(a.statut)) throw new ConflictException('Rien à prélever sur cet abonnement.');
    if (!dto.forcer && a.prochainPrelevement && a.prochainPrelevement > maintenant) {
      throw new ConflictException(`Prochain prélèvement le ${formatDate(a.prochainPrelevement)}.`);
    }
    // Un changement de plan resté en 3-D Secure ne doit pas s’appliquer au renouvellement.
    if (a.planEnAttente || a.periodeEnAttente) {
      await this.repo.update({ id }, { planEnAttente: null, periodeEnAttente: null });
      a.planEnAttente = null;
      a.periodeEnAttente = null;
    }
    if (a.carteId && !(await this.cartes.liste(a.utilisateurId)).some((c) => c.id === a.carteId)) a.carteId = null;
    const montant = this.vue(a, maintenant).prixActuel;
    const paiement = await this.prelevement(a, montant, dto.simulation);
    if (paiement.statut === 'echoue') await this.repo.update({ id }, { statut: 'impaye' });
    return { abonnement: await this.detail(id), paiement };
  }
}
