# MatchUp on Supabase + SQFlite

The app keeps working on the phone's SQLite database (SQFlite): every screen reads and writes it,
offline included. Supabase is the shared copy in the cloud: the tables listed in
`lib/core/sync/sync_tables.dart` are sent there in the background.

```
screen → repository → SQFlite ──(trigger)──> sync_outbox ──(SyncService, every 30 s)──> Supabase
                                                              <── first sync on a new phone: pull
```

- Every insert, update and delete on a synced table adds a row to `sync_outbox` (SQLite triggers,
  recreated each time the database opens). The service sends the row as it is now, with
  `owner_id` = the signed-in Supabase user, then empties the outbox. Offline, changes wait.
- A phone that never synced for this user first pulls their rows (a new phone, a reinstall).
- Each phone signs in anonymously for now. When the Utilisateur module links real accounts,
  the same rows follow the user.
- Row Level Security: a user only sees and writes their own rows (`owner`), or reads everyone's
  rows and writes their own (`shared`).

## One-time setup (one person, for the team)

1. Create a project on supabase.com (free plan).
2. Authentication › Sign In / Providers: turn on **Allow anonymous sign-ins**.
3. SQL editor: paste and run all of `supabase/schema.sql`.
4. Project Settings › API Keys: copy the Project URL and the **publishable** key, and share them
   with the team (the publishable key is meant for apps; Row Level Security protects the data).

## Every developer

```bash
cp supabase.example.json supabase.json     # then paste the URL and the publishable key
flutter run --dart-define-from-file=supabase.json
```

`supabase.json` is git-ignored. Without it the app runs on SQFlite alone (tests always do).
The debug menu (bug button) shows the last sync and has « Synchroniser maintenant ».

## Sync your module's tables

1. Add your table to `syncTables` in `lib/core/sync/sync_tables.dart` (parents before children).
   It needs a primary key of 1 to 3 columns. Use `SyncScope.shared` for data everyone must see.
2. `flutter test test/supabase_schema_test.dart --update-goldens` regenerates `supabase/schema.sql`.
3. Run `supabase/schema.sql` again in the SQL editor (safe to run again), commit, push.

Your repositories do not change. The same goes for a new column: add it with a new schema
version in `lib/core/db/schema.dart`, then steps 2 and 3.

## Shared tables (forum, tournaments: what everyone must see)

`SyncScope.owner` rows are private and come down once per phone. `SyncScope.shared` rows come
down from **everyone at every sync** (every 30 s), and rows others deleted disappear. Declare:

```dart
SyncTable('forum_sujets', scope: SyncScope.shared, ownerColumn: 'auteur_id'),
```

The table must follow three rules, or rows clash or get refused:

1. **Text ids made on the phone** (a random UUID), never 1, 2, 3 per phone.
2. **An author column** (`ownerColumn`) holding `SupabaseConfig.userId`, the signed-in Supabase
   user. A phone only sends rows it authored; Supabase refuses a row whose author is someone
   else. When `SupabaseConfig.userId` is null (no Supabase, or not reached yet) use a local id:
   the row stays on that phone.
3. **One row per person** for what several people change: a vote, a report, a registration.
   Count them; never write a counter into someone else's row. Moderation of other people's rows
   (« hidden after 3 reports ») belongs in a Supabase trigger, not on the phone.

Lists refresh when new rows arrive if their provider watches the sync:
`ref.watch(syncRevisionProvider);`

## Good to know

- The story's seed rows stay on each phone; only what the user changes is sent.
- Integer ids made by one phone (`AUTOINCREMENT`) are unique per user, not across phones of the
  same user. Prefer text ids for data a user creates on two phones.
- Synced today: Paiement (balance, history, refunds, cards, payments, attempts, split shares,
  Premium, receipts). The other modules add theirs.

## Réservation: Supabase decides, SQFlite keeps a copy

Booked courts are shared data with a rule (two players can never get the same slot), so they
do not use the copy above. `supabase/reservation.sql` (written by hand, run it once in the SQL
editor, safe to run again) creates `reservations` and `reservation_joueurs` with:

- an exclusion constraint: no two live bookings overlap on a court;
- `prochaine_reference()`: « MU-48214 », one sequence for every phone;
- `bloquer_creneau()` before the checkout (a 15-minute hold), `confirmer_reservation()` after
  payment, `creneaux_pris()` for the slot grid (taken slots, not who took them);
- Row Level Security: a player reads and changes only their own bookings.

In the app, `SupabaseBookingsRepository` books and cancels on Supabase (network needed) and keeps
the phone's tables as its cache (shown first, refreshed, used offline). Invitations, ratings,
scores and the owner's tables still use the copy above.
