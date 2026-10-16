/**
 * The 6 backend modules. Each one is its own NestJS app (own process, own port, own Postgres
 * schema) so a push to one module rebuilds and restarts only that module.
 *
 * On the server, Nginx routes http://92.222.36.107/api/<module>/... to the module's port.
 */
export const MODULES = {
  utilisateur: { port: 3001, title: 'Utilisateur' },
  reservation: { port: 3002, title: 'Réservation' },
  paiement: { port: 3003, title: 'Paiement' },
  tournois: { port: 3004, title: 'Tournois' },
  entrainement: { port: 3005, title: 'Entraînement' },
  forum: { port: 3006, title: 'Forum' },
} as const;

export type ModuleName = keyof typeof MODULES;
