# MatchUp backend

NestJS + PostgreSQL, run on your own PC. **6 modules = 6 small apps** in one folder, each with its
own process, port and database schema, all in one local PostgreSQL database (`matchup`).

| Module | Port | API | Tables (schema) |
|---|---|---|---|
| utilisateur | 3001 | http://localhost:3001/api/utilisateur | `utilisateur.utilisateur` |
| reservation | 3002 | http://localhost:3002/api/reservation | `reservation.terrain`, `reservation.reservation` |
| paiement | 3003 | http://localhost:3003/api/paiement | `paiement.paiement` |
| tournois | 3004 | http://localhost:3004/api/tournois | `tournois.tournoi`, `tournois.equipe` |
| entrainement | 3005 | http://localhost:3005/api/entrainement | `entrainement.programme`, `entrainement.seance` |
| forum | 3006 | http://localhost:3006/api/forum | `forum.sujet`, `forum.message` |

Swagger (try every route in the browser): `http://localhost:<port>/api/<module>/docs`.

## First start

1. Install PostgreSQL 16+ (Windows installer from postgresql.org). Remember the password you give
   the `postgres` user.
2. Then:

```bash
cd backend
npm install
cp .env.example .env        # then put that password in DB_PASSWORD
npm run start:all           # the 6 modules, with live reload (Ctrl+C stops them)
npm run start:utilisateur   # or only one module
```

On the first start the `matchup` database is created if it is missing, each module creates its
schema, and with `DB_SYNC=all` each module creates/updates its tables from its entities.

To browse the data: pgAdmin (installed with PostgreSQL), DBeaver or VS Code → host `localhost`,
port `5432`, database `matchup`, user `postgres`, your password.

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

## The Flutter app and the backend

The app keeps everything on the phone (sqflite) by default and never needs the backend. To make
the auth screens use the utilisateur module (real confirmation emails), start it, then:

```bash
flutter run --dart-define=API_URL=http://localhost:3001/api/utilisateur
```

From the Android emulator the PC is `10.0.2.2` instead of `localhost`
(`http://10.0.2.2:3001/api/utilisateur`); from a real phone, use the PC's address on the Wi-Fi.

## Rules

1. Only touch `apps/<your module>/`. `libs/common/` and `package.json` are shared by all 6
   modules: tell the team first.
2. Need data from another module? Store its **id** (`utilisateurId`) and call its API. No foreign
   keys across modules.

### Add a resource to your module

Copy a folder (e.g. `apps/reservation/src/terrain/`) → rename the class, table and route → add the
entity, controller and service to `apps/<module>/src/<module>.module.ts`. Start your module: the
table appears in your schema.
