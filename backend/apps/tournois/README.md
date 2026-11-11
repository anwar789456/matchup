# Module tournois

Tournaments and events (brief, Module 3): registration of teams, payment and validation, the bracket
and schedule generator, live scores, standings, organiser dashboard and announcements.
Swagger: `http://92.222.36.107/api/tournois/docs` (or `http://localhost:3004/api/tournois/docs`).

Tables (schema `tournois`): `tournoi`, `equipe`, `match`, `annonce`.

## Lifecycle

```
tournoi   brouillon ─/publier→ inscriptions_ouvertes ─/cloturer→ inscriptions_fermees ─(1st match)→ en_cours ─(final)→ termine
                                        ↑──────────────/rouvrir────────┘   (any time: /annuler → annule, paid teams → a_rembourser)
equipe    en_attente ─/valider→ confirmee        en_attente|confirmee ─/refuser (motif)→ refusee     ─/annuler (captain)→ annulee
paiement  non_paye ─/paiement→ paye ─(refused / cancelled)→ a_rembourser ─/rembourser→ rembourse      (free tournament: gratuit)
match     a_jouer ─/demarrer→ en_direct ─/terminer (confirme: true)→ termine
```

A `type: 'evenement'` (social game, initiation) uses the same routes with individual sign-up
(one player per `equipe`) and has no bracket.

## Routes (under `/api/tournois`)

| Route | What it does |
|---|---|
| `GET /tournois?sport&type&statut&ville&du&au&niveau&fraisMax&q&placesLibres&organisateurId` | List (soonest first) with `equipesConfirmees`, `equipesEnAttente`, `placesRestantes`, `inscriptionsOuvertes` |
| `GET /tournois/tableau-de-bord?organisateurId=` | Organiser dashboard: active tournaments, registrations, revenue, live and upcoming matches |
| `GET/POST/PATCH/DELETE /tournois[/:id]` | CRUD (created as draft; format/groups frozen once the bracket exists) |
| `POST /tournois/:id/publier · cloturer · rouvrir · annuler` | Lifecycle (`annuler` takes `{ motif }`) |
| `POST /tournois/:id/tableau/generer` | Draw + schedule from constraints `{ terrains, creneaux, dureeMatchMinutes, reposMinutes, nbPoules, qualifiesParPoule, melanger, apercu }`. `apercu: true` saves nothing. 422 with `manquants` when the slots are too few |
| `POST /tournois/:id/tableau/echanger` `{ equipeA, equipeB }` | Swap two teams before they play (drag and drop) |
| `POST /tournois/:id/tableau/publier` · `DELETE /tournois/:id/tableau` | Show the bracket to players · scrap it (no match played) |
| `GET /tournois/:id/tableau?equipeId=&brouillon=true` | Bracket for `MuBracket`: `poules` (standings, `qualifie`), `tours` (rounds and matches with placeholders « 1er Poule A », « Vainqueur QF 2 »), `journees` |
| `GET /tournois/:id/classement?equipeId=` | Group standings + overall leaderboard (`parcours`: Champion, Finaliste, Demi-finales…) |
| `GET /tournois/:id/calendrier?equipeId=` | Matches by day (Tunis time) |
| `GET/POST /tournois/:id/annonces` · `DELETE …/annonces/:annonceId` | Announcements; each keeps `destinatairesIds` for notifications/emails |
| `GET /equipes?tournoiId&capitaineId&joueurId&statut` · `GET /equipes/:id/matchs` | Teams · a team's matches |
| `POST /equipes` | Register `{ tournoiId, nom, capitaineId, joueursIds?, logoUrl? }` → `codeInvitation` |
| `GET /equipes/invitation/:code` · `POST /equipes/rejoindre` `{ code, joueurId }` | Invite link |
| `POST /equipes/:id/joueurs` · `DELETE /equipes/:id/joueurs/:joueurId` | Members |
| `POST /equipes/:id/paiement` `{ paiementId, montant? }` | Fee paid (after the paiement module accepted it) |
| `POST /equipes/:id/valider · refuser · annuler · rembourser` | Organiser / captain actions |
| `GET /matchs?tournoiId&equipeId&statut&phase&terrain&du&au` · `GET /matchs/:id` | Matches with team names |
| `PATCH /matchs/:id` `{ debut, terrain }` | Move a match (court and team clashes refused) |
| `POST /matchs/:id/demarrer · score · evenements · terminer · forfait` | Courtside entry. `evenements` `{ type, equipe, points, minute, joueur }` updates the score; `DELETE /matchs/:id/evenements/:evenementId` undoes it. `terminer` needs `confirme: true` and `vainqueurId` on a knockout draw |
| `GET /matchs/:id/resume` | After-match recap, ready to share |

## Rules worth knowing

- One player can be in only one active team per tournament; team names are unique per tournament.
- A team is validated only when paid (or free), with at least `joueursParEquipe` players, and while
  confirmed teams < `nbEquipesMax`.
- Seeds: `equipe.seed`, then validation order. Byes go to the best seeds. Groups are drawn in a
  snake; qualifiers cross (A1–B2, B1–A2). Group points: 3 win, 1 draw; ties on difference then scored.
- A result can be corrected until the match it feeds has started; the bracket refills itself.
- The pure logic (draw, standings, schedule) is in `src/tableau/tableau.logic.ts`.
