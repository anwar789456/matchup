import { ajouterJours, ajouterMois, dt } from '../commun/argent';
import { Periode } from './abonnement.entity';

export type FamillePlan = 'joueur' | 'proprietaire' | 'coach';

export interface Plan {
  code: string;
  nom: string;
  famille: FamillePlan;
  mensuel: number;
  annuel: number;
  essaiJours: number;
  /** Commission MatchUp sur les revenus (coach). */
  commission?: number;
  avantages: string[];
}

/** STORY-DATA « Plans » (annuel = 2 mois offerts, −17 %). */
export const PLANS: Record<string, Plan> = {
  joueur_premium: {
    code: 'joueur_premium',
    nom: 'Premium',
    famille: 'joueur',
    mensuel: 19,
    annuel: 190,
    essaiJours: 14,
    avantages: ['Réservation prioritaire', 'Statistiques avancées', 'Aucune commission sur les parts'],
  },
  proprietaire_starter: {
    code: 'proprietaire_starter',
    nom: 'Starter',
    famille: 'proprietaire',
    mensuel: 79,
    annuel: 790,
    essaiJours: 14,
    avantages: ['Planning et réservations en ligne', 'Check-in par QR code', 'Jusqu’à 4 terrains'],
  },
  proprietaire_pro: {
    code: 'proprietaire_pro',
    nom: 'Pro',
    famille: 'proprietaire',
    mensuel: 149,
    annuel: 1490,
    essaiJours: 14,
    avantages: ['Terrains illimités', 'Tarifs dynamiques et promos', 'Statistiques et clientèle'],
  },
  coach: {
    code: 'coach',
    nom: 'Coach',
    famille: 'coach',
    mensuel: 39,
    annuel: 390,
    essaiJours: 14,
    commission: 0.1,
    avantages: ['Programmes et séances', 'Suivi des élèves', 'Paiements en ligne (10 % de commission)'],
  },
};

/** Le plan gratuit, affiché pour comparer seulement. */
export const PLAN_GRATUIT = { code: 'joueur_gratuit', nom: 'Gratuit', famille: 'joueur', mensuel: 0, annuel: 0 };

/** Rappel avant la fin de l’essai (mar. 27 oct. pour un premier prélèvement le ven. 30 oct.). */
export const RAPPEL_JOURS = 3;

/** L’offre de rétention : −30 % pendant 2 mois. */
export const OFFRE_RETENTION = { pourcentage: 30, mois: 2 };

export const prixDe = (plan: Plan, periode: Periode): number => (periode === 'annuel' ? plan.annuel : plan.mensuel);

export const finDePeriode = (debut: Date, periode: Periode): Date => ajouterMois(debut, periode === 'annuel' ? 12 : 1);

export const debutDePeriode = (fin: Date, periode: Periode): Date => ajouterMois(fin, periode === 'annuel' ? -12 : -1);

/** Ce que l’annuel fait économiser par rapport à 12 mois. */
export function economieAnnuelle(plan: Plan): { montant: number; pourcentage: number; moisOfferts: number } {
  const douze = plan.mensuel * 12;
  return {
    montant: dt(douze - plan.annuel),
    pourcentage: Math.round((1 - plan.annuel / douze) * 100),
    moisOfferts: Math.round((douze - plan.annuel) / plan.mensuel),
  };
}

export const finEssai = (debut: Date, plan: Plan): Date => ajouterJours(debut, plan.essaiJours);
