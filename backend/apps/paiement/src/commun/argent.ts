/** Montants en dinars tunisiens, au millime près (numeric(10,3) en base). */
export const dt = (value: number): number => Math.round(value * 1000) / 1000;

/** « 15 DT », « 13,300 DT » : comme l’app (virgule décimale, millimes seulement s’il y en a). */
export function formatDT(value: number): string {
  const v = dt(value);
  const text = Number.isInteger(v) ? String(v) : v.toFixed(3).replace('.', ',');
  return `${text} DT`;
}

/** « 31 déc. 2025 ». */
export const formatDate = (d: Date): string =>
  d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'Africa/Tunis' });

export const ajouterJours = (d: Date, jours: number): Date => new Date(d.getTime() + jours * 86_400_000);

/** Même jour, n mois plus tard (31 janv. + 1 mois → 28/29 févr.). */
export function ajouterMois(d: Date, mois: number): Date {
  const r = new Date(d);
  const jour = r.getUTCDate();
  r.setUTCDate(1);
  r.setUTCMonth(r.getUTCMonth() + mois);
  const dernier = new Date(Date.UTC(r.getUTCFullYear(), r.getUTCMonth() + 1, 0)).getUTCDate();
  r.setUTCDate(Math.min(jour, dernier));
  return r;
}
