# MatchUp backend

NestJS + PostgreSQL. **6 modules = 6 small apps** in one repo, each with its own process, port
and database schema. A push to one module rebuilds and restarts **only that module** on the
server — no more 6 GitHub repos.

| Module | Owner | Port | API on the server | Tables (schema) |
|---|---|---|---|---|
| utilisateur | | 3001 | http://92.222.36.107/api/utilisateur | `utilisateur.utilisateur` |
| reservation | | 3002 | http://92.222.36.107/api/reservation | `reservation.terrain`, `reservation.reservation` |
| paiement | | 3003 | http://92.222.36.107/api/paiement | `paiement.paiement` |
| tournois | | 3004 | http://92.222.36.107/api/tournois | `tournois.tournoi`, `tournois.equipe` |
| entrainement | | 3005 | http://92.222.36.107/api/entrainement | `entrainement.programme`, `entrainement.seance` |
| forum | | 3006 | http://92.222.36.107/api/forum | `forum.sujet`, `forum.message` |

Swagger (try every route in the browser): `http://92.222.36.107/api/<module>/docs`.
Index of all of them: http://92.222.36.107

## Every route

Each resource has the same 5 routes, e.g. for `terrains`:

```
GET    /api/reservation/terrains            list (filters: ?sport=padel&ville=La Marsa)
GET    /api/reservation/terrains/:id        one
POST   /api/reservation/terrains            create (JSON body)
PATCH  /api/reservation/terrains/:id        update (only the fields you send)
DELETE /api/reservation/terrains/:id        delete
```

Plus `POST /api/utilisateur/utilisateurs/login` `{ email, motDePasse }`.

## Work on your module from your laptop

```bash
cd backend
npm install
cp .env.example .env        # then put the DB password and DB_SYNC=<your module>
npm run start:reservation   # your module, with live reload, on http://localhost:3002/api/reservation/docs
```

Your laptop talks to **the one database on the server** (92.222.36.107:5432), like everyone.
To browse it: DBeaver / pgAdmin / VS Code → host `92.222.36.107`, port `5432`, database `matchup`,
user `matchup`, the team password.

**Rules that keep us out of each other's way**

1. Only touch `apps/<your module>/`. Code there redeploys only your module.
2. `libs/common/` and `package.json` are shared: changing them rebuilds **all 6** modules. Tell the
   team first.
3. `DB_SYNC` in your `.env` = your module only. When your module starts, TypeORM creates/updates
   your tables from your entities. Running someone else's module with sync on could rewrite their
   tables from an old copy of their code.
4. Need data from another module? Store its **id** (`utilisateurId`) and call its API. No foreign
   keys across modules.

### Add a resource to your module

Copy a folder (e.g. `apps/reservation/src/terrain/`) → rename the class, table and route → add the
entity, controller and service to `apps/<module>/src/<module>.module.ts`. Start your module: the
table appears in your schema.

## Deploy = git push

```bash
git add backend/apps/reservation
git commit -m "reservation: créneaux"
git push
```

GitHub calls the server's webhook (`http://92.222.36.107/webhook`); the server pulls `main`, looks
at which files changed and rebuilds only those modules (a 1-minute git poll catches any missed
webhook). See what happened: http://92.222.36.107/webhook/log

| You changed | Server rebuilds |
|---|---|
| `backend/apps/forum/**` | forum only |
| `backend/libs/**`, `tsconfig*.json`, `nest-cli.json` | all 6 |
| `backend/package.json` / `package-lock.json` | `npm ci`, then all 6 |
| anything outside `backend/` (Flutter app) | nothing |

A module that fails to build keeps running its previous version; the error is in the log.

## Server (92.222.36.107, Ubuntu)

- Code: `/opt/matchup` (clone of this repo), config `/opt/matchup/backend/.env`
- Processes: `pm2 ls`, `pm2 logs reservation`, `pm2 restart reservation`
- Redeploy by hand: `bash /opt/matchup/backend/deploy/deploy.sh reservation` (or `--all`)
- Logs: `/var/log/matchup/deploy.log`, `/var/log/matchup/build-<module>.log`
- First install: `deploy/setup-server.sh` (Postgres, Node 22, pm2, Nginx, webhook, cron)
