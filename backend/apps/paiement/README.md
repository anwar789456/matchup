# Module paiement

Payments and subscriptions (brief, Module 5 and section 10): checkout with card and/or balance,
3-D Secure, receipts, the MatchUp balance, saved cards, promo codes, split payment (PAY-11/12),
refund requests, Premium / Starter / Pro / Coach plans, payouts to venues and coaches, admin finance.
Swagger: `http://localhost:3003/api/paiement/docs`.

Tables (schema `paiement`): `paiement`, `portefeuille`, `mouvement`, `carte`, `code_promo`,
`partage`, `part`, `demande_remboursement`, `abonnement`, `versement`.

No Stripe yet: the bank is simulated. Its answer comes from `moyen.simulation` (`succes`, `3ds`,
`refuse`, `fonds_insuffisants`, `erreur_reseau`, `delai`), otherwise from Stripe's test card numbers,
otherwise success.

| Card | Answer |
|---|---|
| 4242 4242 4242 4242 · 5555 5555 5555 4444 | success |
| 4000 0025 0000 3155 · 4000 0000 0000 3220 | 3-D Secure |
| 4000 0000 0000 0002 | declined (« carte refusée ») |
| 4000 0000 0000 9995 | declined (« fonds insuffisants ») |

## Lifecycle

```
paiement     en_attente ─(bank ok)→ paye ─/rembourser→ partiellement_rembourse → rembourse
                       ─(3ds)→ a_authentifier ─/authentifier true→ paye   (false → echoue)
                       ─(refused, network)→ echoue (raisonEchec; every try stays a row)
partage      en_cours ─(every part paid or advanced)→ complet      (/annuler or past the deadline → annule, all refunded)
part         en_attente → payee | avancee (organiser paid it) → remboursee
demande      envoyee → en_examen → remboursee | refusee
abonnement   essai (14 d, 0 DT) ─(charge)→ actif ─(charge refused)→ impaye
             essai|actif ─/annuler (offer first, then confirmer)→ annule ─(finLe)→ expire   (/reactiver before finLe)
versement    en_attente ─/valider→ valide ─/envoyer→ envoye
```

## Routes (under `/api/paiement`)

| Route | What it does |
|---|---|
| `POST /paiements` | Checkout `{ utilisateurId, objet, objetId, libelle, montant, beneficiaireId?, codePromo?, methode?, moyen? }` for `reservation`, `partie`, `tournoi`, `programme`. `moyen` = `{ carteId? \| nouvelleCarte?, utiliserSolde?, simulation? }`. The balance pays first, the card pays the rest (`methode: mixte`). `methode: especes \| virement` = paid at the counter |
| `POST /paiements/:id/authentifier` `{ approuve }` | 3-D Secure answer |
| `POST /paiements/:id/rembourser` `{ montant?, vers? }` | Refund all or part, to the balance (immediate) or the card |
| `GET /paiements?utilisateurId&beneficiaireId&objet&objetId&statut&methode&du&au` · `GET /paiements/:id` · `GET /paiements/:id/recu` | List, detail, receipt (lines, discount, balance + card split) |
| `GET /portefeuilles/:utilisateurId` · `GET …/mouvements?type&du&au` | Balance · history with `soldeApres` |
| `POST /portefeuilles/:utilisateurId/recharger` `{ montant, moyen? }` | Top-up by card, 5 to 500 DT, credited when the payment goes through |
| `POST /portefeuilles/:utilisateurId/ajuster` `{ montant, libelle }` | Admin adjustment (signed) |
| `GET /cartes?utilisateurId` · `POST /cartes` · `POST /cartes/:id/par-defaut` · `DELETE /cartes/:id` | Saved cards: brand + last 4 digits only, `expireBientot` |
| `POST /codes-promo/verifier` `{ code, montant }` · CRUD `/codes-promo` | « Code promo » field (BIENVENUE10 and the expired MARSA2025 are created on first start) |
| `POST /partages` | Split a booking `{ reservationId, organisateurId, libelle, montantTotal, debutMatch, beneficiaireId?, joueurs: [{ joueurId?, nom, partiePublique? }] }`; deadline = 3 h before the match |
| `GET /partages?reservationId&organisateurId&joueurId&statut` · `GET /partages/:id` | Parts and `resume` (collected, remaining, minutes before the deadline) |
| `POST /partages/:id/parts/:partId/payer` · `…/relancer` `{ partIds? }` · `…/payer-le-reste` | Pay a part · remind (returns `destinatairesIds` to notify) · organiser pays every pending part |
| `POST /partages/:id/verifier-echeance` · `POST /partages/:id/annuler` | Past the deadline with parts pending, or booking cancelled: everyone refunded to their balance |
| `POST /remboursements` · `POST /remboursements/:id/examiner · accepter · refuser` · `GET /remboursements?utilisateurId&paiementId&statut` | Refund requests (WAL-04/05) and the admin queue; `accepter` refunds in the same transaction |
| `GET /abonnements/plans` · `POST /abonnements` `{ utilisateurId, plan, periode, moyen? }` · `GET /abonnements?utilisateurId&statut` | Plans · subscribe (14-day trial the first time per profile) |
| `POST /abonnements/:id/changer` `{ plan?, periode?, apercu? }` | Change plan or period: free during the trial, otherwise new price minus what is left of the paid period |
| `POST /abonnements/:id/annuler` `{ motif, note?, confirmer? }` · `…/accepter-offre` · `…/reactiver` · `…/prelever` `{ forcer?, simulation? }` | Cancel (the −30 % for 2 months offer comes first), accept it, undo, charge the due date |
| `POST /versements/calculer` `{ beneficiaireId, role, du, au, apercu? }` · `POST /versements/valider` `{ ids }` · `POST /versements/:id/envoyer` · `GET /versements[/:id][/paiements]` · `DELETE /versements/:id` | Payouts: paid minus refunded minus commission (coach 10 %) |
| `GET /finance/resume?du&au` | Admin finance: collected, refunded, by object, failures, pending refunds, payouts, subscriptions (monthly revenue), balances owed |

## For the other modules

- Pay something: `POST /paiements` with your `objet` and `objetId`, then store the returned `id`
  when `statut` is `paye` (e.g. tournois: `POST /equipes/:id/paiement { paiementId }`).
- Put the venue owner, coach or organiser in `beneficiaireId` so the payment counts in their payouts.
- Cancelling a booking: `POST /paiements/:id/rembourser` (your module decides the amount from the
  cancellation policy), or `POST /partages/:id/annuler` for a split booking.

## Rules worth knowing

- Amounts are DT with 3 decimals. The balance never goes below zero; each move is locked and logged.
- Receipt numbers follow the last one: `MU-R-<year>-01482`, `…01483`… (failed tries get none).
- A promo code is counted only when the payment goes through, and refused if its limit was reached meanwhile.
- A top-up cannot be paid with the balance, and is refunded to the card (taking it back from the balance).
- Never the full card number nor the CVC: only brand, last 4 digits and expiry are stored.
- `node apps/paiement/test/scenario.mjs` runs every flow against the running module (15 steps).
