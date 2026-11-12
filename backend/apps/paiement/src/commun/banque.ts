import { BadRequestException } from '@nestjs/common';

/**
 * La banque simulée (pas de Stripe tant qu’on travaille en local, CLAUDE.md règle 10).
 * L’issue vient de `simulation` si on la donne, sinon du numéro de carte de test (mêmes numéros
 * que Stripe), sinon c’est un succès.
 */
export const SIMULATIONS = ['succes', '3ds', 'refuse', 'fonds_insuffisants', 'erreur_reseau', 'delai'] as const;
export type Simulation = (typeof SIMULATIONS)[number];

export type MarqueCarte = 'visa' | 'mastercard';

const CARTES_TEST: Record<string, Simulation> = {
  '4242424242424242': 'succes',
  '5555555555554444': 'succes',
  '4000002500003155': '3ds',
  '4000000000003220': '3ds',
  '4000000000000002': 'refuse',
  '4000000000009995': 'fonds_insuffisants',
};

/** Raison affichée quand la banque dit non (« Refusée à 18h02 · fonds insuffisants »). */
export const RAISONS: Partial<Record<Simulation, string>> = {
  refuse: 'carte refusée',
  fonds_insuffisants: 'fonds insuffisants',
  erreur_reseau: 'erreur réseau',
  delai: 'délai dépassé',
};

export const chiffres = (numero: string): string => numero.replace(/\D/g, '');

/** Clé de Luhn : écarte les numéros mal tapés avant la banque. */
export function luhnValide(numero: string): boolean {
  const n = chiffres(numero);
  if (n.length < 13 || n.length > 19) return false;
  let somme = 0;
  for (let i = 0; i < n.length; i++) {
    let c = Number(n[n.length - 1 - i]);
    if (i % 2 === 1) {
      c *= 2;
      if (c > 9) c -= 9;
    }
    somme += c;
  }
  return somme % 10 === 0;
}

export function marqueDe(numero: string): MarqueCarte {
  const n = chiffres(numero);
  if (n.startsWith('4')) return 'visa';
  const deux = Number(n.slice(0, 2));
  const quatre = Number(n.slice(0, 4));
  if ((deux >= 51 && deux <= 55) || (quatre >= 2221 && quatre <= 2720)) return 'mastercard';
  throw new BadRequestException('Seules les cartes Visa et Mastercard sont acceptées.');
}

/** Expirée après le dernier jour de son mois. */
export const expiree = (mois: number, annee: number, maintenant = new Date()): boolean =>
  new Date(Date.UTC(annee, mois, 1)) <= maintenant;

/** Expire ce mois-ci ou le mois prochain (avertissement dans le checkout). */
export function expireBientot(mois: number, annee: number, maintenant = new Date()): boolean {
  const limite = new Date(Date.UTC(maintenant.getUTCFullYear(), maintenant.getUTCMonth() + 2, 1));
  return !expiree(mois, annee, maintenant) && new Date(Date.UTC(annee, mois, 1)) <= limite;
}

export function verifierCarte(numero: string, mois: number, annee: number): MarqueCarte {
  if (!luhnValide(numero)) throw new BadRequestException('Numéro de carte invalide.');
  if (expiree(mois, annee)) throw new BadRequestException('Carte expirée.');
  return marqueDe(numero);
}

export const issueBanque = (simulation?: Simulation, numero?: string): Simulation =>
  simulation ?? (numero ? CARTES_TEST[chiffres(numero)] : undefined) ?? 'succes';

export const libelleCarte = (marque: string, derniers: string): string =>
  `${marque === 'visa' ? 'Visa' : 'Mastercard'} •••• ${derniers}`;
