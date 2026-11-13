# Module forum

The Communauté (brief, Module 6): discussions by category and sport, replies on 2 levels, votes,
« Utile » / « Merci », best answer, saved posts, follows, reports, user-side moderation (the
FRM-03 warning before publishing, hidden content) and the admin moderation queue (ADM-09/10).
Swagger: `http://localhost:3006/api/forum/docs`.

Tables (schema `forum`): `sujet`, `message`, `vote`, `reaction`, `favori`, `suivi`, `blocage`,
`visite`, `signalement`, `sanction`.

Screens: FRM-01 Communauté · FRM-02 Nouveau post · FRM-03 Message à revoir · FRM-04 Discussion ·
FRM-05 Signaler · ADM-09 Modération · ADM-10 Revue du contenu.

## Try it

```bash
npm run start:forum
curl -X POST "http://localhost:3006/api/forum/demo/remplir?remplacer=true"   # the story's forum
```

The demo uses these user ids (create them in the utilisateur module to see names):
1 Yassine B. · 2 Ines M. · 3 Skander T. · 4 Mariem K. · 5 Sami C. · 6 Hamza R. · 7 Aziz H. ·
8 Omar D. · 9 Bons Plans Sport TN · 10 Leila M. (admin) · 11 promo_crampons · 12 coach.bilel ·
13 Karim J. · 14 Rami S. Votes come from anonymous ids ≥ 100000.

## Lifecycle

```
sujet / message   publie ──(3 reports from different people)──→ masque ──decision──→ publie | supprime
                     └──(author publishes despite FRM-03: confirmerMalgreAlerte)──→ masque (+ AI report)
                  publie ──(author deletes)──→ supprime        (a deleted reply with answers stays as « Message supprimé »)
signalement       ouvert ──(moderator decides)──→ traite
sanction          avertissement ×3 ──→ suspension 7 days (no posting, replying, voting, reacting)
```

## Routes (under `/api/forum`)

| Route | What it does |
|---|---|
| `GET /sujets?categorie&sport&tri&q&tag&auteurId&utilisateurId&pseudo&favoris&limite&decalage` | FRM-01 list → `{ total, sujets }`. Pinned first, then `tendance` (default), `recents` or `top`. `utilisateurId` = who reads: their vote / reactions / favourite / follow in `moi`, their own masked posts, blocked authors removed. `pseudo` sets `mentionneMoi` |
| `GET /categories?utilisateurId&sport` | The 5 categories with `nbSujets` and `nouveaux` (since the last visit) |
| `POST /visites` `{ utilisateurId }` | Saves the visit — call it when the member leaves the Communauté |
| `GET /sujets/similaires?titre&sport&tags&exclureId` | FRM-02 « Discussions similaires » (score ≥ 0,25, 3 max) |
| `POST /ia/tags` `{ titre, contenu, tags }` | FRM-02 « Suggérés par l’IA » → `[{ tag, raison }]` |
| `POST /ia/analyser` `{ texte }` | FRM-03 → `{ score, niveau, motif, explication, categorie, extraits, reformulation, seuilAlerte }` |
| `POST /images` (multipart `image`) · `GET /images/:nom` | Post images (JPEG/PNG/WebP, 5 MB), saved in `apps/forum/uploads/` |
| `POST /sujets` | FRM-02 publish `{ auteurId, titre (10–120), contenu (≤ 2000, light Markdown), categorie, sport?, tags? (≤ 5), images? (≤ 4), confirmerMalgreAlerte? }` |
| `GET /sujets/:id?utilisateurId&tri` | FRM-04 → `{ sujet, meilleureReponse, reponses, tri }`. `tri`: `utiles` (default), `recentes`, `anciennes`. Level-1 replies carry their answers in `reponses` (oldest first) |
| `PATCH /sujets/:id` · `DELETE /sujets/:id?utilisateurId=` | Author only |
| `POST /sujets/:id/meilleure-reponse` `{ utilisateurId, messageId \| null }` | Author only; a published level-1 reply by someone else |
| `POST /messages` `{ sujetId, auteurId, contenu, parentId?, confirmerMalgreAlerte? }` | Reply → `{ message, notifier: { abonnesIds, repondA, mentions } }` for the notification system |
| `PATCH /messages/:id` · `DELETE /messages/:id?utilisateurId=` | Author only |
| `PUT /sujets/:id/vote` · `PUT /messages/:id/vote` `{ utilisateurId, valeur: 1 \| 0 \| -1 }` | Vote, change or remove → new `score` |
| `PUT /sujets/:id/reactions/:type` · `PUT /messages/:id/reactions/:type` `{ utilisateurId, actif }` | `utile` / `merci` → counters |
| `PUT /sujets/:id/favori` · `PUT /sujets/:id/suivi` `{ utilisateurId, actif }` | Save the post · follow it (bell) |
| `POST /sujets/:id/signalements` · `POST /messages/:id/signalements` `{ signaleurId, motif, details?, masquerAuteur? }` | FRM-05. `motif`: `spam`, `insulte`, `choquant`, `fausse_information`, `autre` |
| `GET /membres/:id?utilisateurId` | Forum profile: posts, replies, votes received, best answers, followers, `suiviParMoi`, `bloqueParMoi`, `peutPublier` |
| `PUT /membres/:id/suivi` · `PUT /membres/:id/blocage` `{ utilisateurId, actif }` | « Suivre » · « Ne plus voir les messages de … » |
| `GET /membres/:id/blocages` · `GET /membres/:id/abonnements` | Blocked members · followed members and discussions |
| `GET /moderation/file?type&q` | ADM-09 → `{ ouverts, parType, plusAncien, traitesCetteSemaine, contenus }`, AI score first |
| `GET /moderation/{sujets\|messages}/:id` | ADM-10: content, what it answers, AI analysis with highlights, reports by reason, `masquePar`, the author's record (`fiabilite`, warnings, `prochainAvertissement`) |
| `POST /moderation/{sujets\|messages}/:id/decision` `{ moderateurId, decision, motif?, jours? }` | `approuver`, `supprimer`, `supprimer_avertir`, `suspendre`. Closes every open report on it |
| `POST /moderation/sujets/:id/epingle` `{ moderateurId, epingle }` | Pin / unpin |
| `GET /moderation/membres/:id/sanctions` · `…/dossier` | A member's warnings and suspensions · record |
| `POST /demo/remplir?remplacer=true` | Development data (refused with `NODE_ENV=production`) |

## Errors the app handles

| Status | Body | Screen |
|---|---|---|
| 422 | `{ code: "ALERTE_MODERATION", message, analyse }` | FRM-03: highlight `analyse.extraits`, offer `analyse.reformulation` when not null, « Publier quand même » resends with `confirmerMalgreAlerte: true` |
| 403 | `{ code: "SUSPENDU", message, jusquA, motif }` | Suspended: reading is fine, writing is not |
| 400 / 403 / 404 / 409 | `{ message }` in French | Show the message |

## Rules worth knowing

- **The AI never hides or deletes on its own.** It scores (`ia/ia.logic.ts`, rule-based French +
  derja, no external service) and sorts the queue. A content is hidden only by 3 reports from
  different people, or when its author publishes despite the FRM-03 warning (then the AI files a
  report, and a moderator answers within 24 h).
- Masked content: its author still sees it (`masque: true` with `contenu`); others get
  `contenu: null` and show « Masqué par la modération · en cours de vérification ».
- Replies have 2 levels. Answering a level-2 reply attaches to its level-1 parent and records who
  is answered in `enReponseAId`.
- You cannot vote for, react to or report your own content, or follow / block yourself.
- Every write on votes, reactions, favourites, follows and blocks is idempotent (send the state).
- Counters (`score`, `nbReponses`, `nbUtile`, `nbMerci`) are recounted from the rows after each
  change, so they never drift. `nbReponses` counts published replies only.
- « Tendance » = (score + 2 × replies + reactions + 1) / (hours since last activity + 2)^1.3.
- Authors follow their own posts. A new reply returns who to notify; sending notifications is
  the notification system's job, not the forum's.
- Reports are anonymous: `signaleurId` is never returned to the reported author.
- Names, pseudos, levels and avatars come from the utilisateur module: the forum stores ids only.
