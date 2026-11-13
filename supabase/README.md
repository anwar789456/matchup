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

## Accounts and emails (Utilisateur module)

With `supabase.json`, sign-up, sign-in and « Mot de passe oublié » go through Supabase Auth
(`SupabaseAuthRepository`), and Supabase sends the emails. The phone keeps its copy of the
account, so the app still opens offline. Once the email is confirmed, the device's session is the
real account, and the synced rows follow it. Set up once in the dashboard:

1. **Authentication › Sign In / Providers › Email**: enabled, **Confirm email** on.
2. **Authentication › Emails › SMTP Settings**: turn on custom SMTP (the built-in sender only
   delivers to the project's team members, a few emails per hour). With Gmail: host
   `smtp.gmail.com`, port `465`, the Gmail address as user, a Google **app password** as
   password, sender name `MatchUp`.
3. **Authentication › Emails › Templates**: paste the files of `supabase/emails/` (the subject is
   in the comment at the top of each file):
   - « Confirm signup » ← `confirm-signup.html` (EML-01)
   - « Reset password » ← `reset-password.html` (EML-02). It must show `{{ .Token }}`: the app
     asks for the 6-digit code, not a link.
4. **Authentication › URL Configuration › Redirect URLs**: add `http://localhost:*/**` so the
   confirmation link opens the web app you are running.

Check: `curl -s <SUPABASE_URL>/auth/v1/settings -H "apikey: <publishable key>"` must show
`"mailer_autoconfirm": false` once « Confirm email » is on.

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

## Stripe (test mode: free, fake money)

The checkout's « Nouvelle carte » uses Stripe's own card field when Stripe is set up; saved
cards and the debug menu's simulated bank keep working as before. The secret key stays on the
server, in the `stripe-payment-intent` Edge Function (`supabase/functions/`).

One person, once:

1. Create a free account on stripe.com and stay in **Test mode**. Developers › API keys: copy the
   publishable key (`pk_test_…`) and the secret key (`sk_test_…`).
2. Supabase › Edge Functions › Secrets: add `STRIPE_SECRET_KEY` = the `sk_test_…` key. Never put
   it in the app or the repo.
3. Supabase › Edge Functions › Deploy a new function › Via editor: name it
   `stripe-payment-intent`, paste `supabase/functions/stripe-payment-intent/index.ts`, deploy.
4. Everyone adds `"STRIPE_PUBLISHABLE_KEY": "pk_test_…"` to their `supabase.json`.

Test cards: 4242 4242 4242 4242 (paid), 4000 0025 0000 3155 (3-D Secure), 4000 0000 0000 9995
(declined, insufficient funds); any future date, any CVC. Stripe does not take Tunisian dinars:
the function charges the DT amount converted to euros (`TND_PER_UNIT`, default 3.4), the app's
receipt keeps the DT amount. Payments show in the Stripe dashboard (Test mode › Payments).

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
- `prochaine_reference()`: « MU-50001 », one sequence for every phone;
- `bloquer_creneau()` before the checkout (a 15-minute hold), `confirmer_reservation()` after
  payment, `creneaux_pris()` for the slot grid (taken slots, not who took them);
- Row Level Security: a player reads and changes only their own bookings.

It also holds the venue catalogue (`etablissements`, `etablissement_terrains`, readable by
everyone), the slots an owner closed (`blocages`: every player's grid shows them and booking
them is refused) and lets an owner read the bookings made at their venue. The first account that
opens the owner space of a venue without an owner claims it (`revendiquer_etablissement`).

In the app, `SupabaseBookingsRepository`, `SupabaseVenuesRepository`, `SupabaseOwnerRepository`
and `SupabaseTariffsRepository` use Supabase and keep the phone's tables as their cache (shown
first, refreshed, used offline). Invitations, ratings and scores are personal to the player, and
the owner's courts, own bookings, arrivals and full price list stay on the phone: they still use
the copy above.
