-- Réservation (Mahmoud) — Supabase is the source of truth for booked courts; the phone keeps a
-- copy in SQFlite (shown first, used offline). Run this whole file in the Supabase SQL editor
-- (safe to run again). Unlike schema.sql it is written by hand: these tables have rules.
--
-- • A slot is held for 15 minutes before the checkout (statut 'pendingPayment'), then confirmed
--   after payment. Two live bookings can never overlap on the same court (exclusion constraint).
-- • References come from one sequence (MU-50001, MU-50002…): unique across every phone.
-- • A player reads and changes only their own bookings; creneaux_pris() tells everyone which
--   slots are taken, without saying by whom.

create extension if not exists btree_gist;

-- The per-user copies of the first sync (sync_tables.dart) are replaced by the real tables.
-- (Only the copies, recognisable by their owner_id column: running this file again keeps data.)
drop table if exists public.annulations cascade;
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'reservation_joueurs' and column_name = 'owner_id'
  ) then
    drop table public.reservation_joueurs cascade;
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'reservations' and column_name = 'owner_id'
  ) then
    drop table public.reservations cascade;
  end if;
end $$;

-- From MU-50001: the story's references (MU-48150 to MU-48219) stay unique on every phone.
create sequence if not exists public.reservation_ref start 50001;
select setval('public.reservation_ref', greatest(50000, (select last_value from public.reservation_ref)));

create table if not exists public.reservations (
  reference text primary key,
  organisateur_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  sport text not null,
  etablissement text not null,
  terrain text not null,
  lieu text not null,
  debut timestamptz not null,
  fin timestamptz not null,
  part numeric not null,
  statut text not null default 'upcoming'
    check (statut in ('upcoming', 'pendingPayment', 'past', 'cancelled')),
  payer_avant timestamptz,
  cree_le timestamptz not null default now(),
  -- Cancellation (MAT-03): who, why, when, what was refunded.
  annule_par text,
  par_moi boolean,
  raison text,
  rembourse_le timestamptz,
  remboursement numeric,
  joueurs_rembourses integer,
  total_rembourse numeric,
  constraint fin_apres_debut check (fin > debut),
  constraint pas_de_chevauchement exclude using gist (
    etablissement with =, terrain with =, tstzrange(debut, fin) with &&
  ) where (statut <> 'cancelled')
);
create index if not exists reservations_organisateur on public.reservations (organisateur_id);

create table if not exists public.reservation_joueurs (
  reference text not null references public.reservations (reference) on delete cascade,
  position integer not null,
  nom text not null,
  image_url text,
  primary key (reference, position)
);

alter table public.reservations enable row level security;
alter table public.reservation_joueurs enable row level security;

drop policy if exists "reservations_lecture" on public.reservations;
drop policy if exists "reservations_ajout" on public.reservations;
drop policy if exists "reservations_modif" on public.reservations;
create policy "reservations_lecture" on public.reservations
  for select to authenticated using (organisateur_id = auth.uid());
create policy "reservations_ajout" on public.reservations
  for insert to authenticated with check (organisateur_id = auth.uid());
create policy "reservations_modif" on public.reservations
  for update to authenticated using (organisateur_id = auth.uid())
  with check (organisateur_id = auth.uid());

drop policy if exists "reservation_joueurs_organisateur" on public.reservation_joueurs;
create policy "reservation_joueurs_organisateur" on public.reservation_joueurs
  for all to authenticated
  using (exists (select 1 from public.reservations r
                 where r.reference = reservation_joueurs.reference and r.organisateur_id = auth.uid()))
  with check (exists (select 1 from public.reservations r
                      where r.reference = reservation_joueurs.reference and r.organisateur_id = auth.uid()));

-- « MU-50001 »: the reference the next booking gets (asked before the checkout, BKG-03/04).
create or replace function public.prochaine_reference() returns text
language sql security definer set search_path = public as $$
  select 'MU-' || nextval('public.reservation_ref')
$$;

-- Holds of more than 15 minutes that were never paid free their slot.
create or replace function public.liberer_reservations_expirees() returns void
language sql security definer set search_path = public as $$
  delete from public.reservations where statut = 'pendingPayment' and payer_avant < now()
$$;

-- Before the checkout: holds the slot for 15 minutes. Fails with 23P01 when it is taken.
create or replace function public.bloquer_creneau(r jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'non connecté' using errcode = '28000'; end if;
  -- A slot the owner closed (blocages, below) is taken too.
  if exists (
    select 1 from public.blocages b join public.etablissements e on e.id = b.etablissement_id
    where e.nom = r->>'etablissement' and b.terrain = r->>'terrain'
      and ((not b.hebdo and b.debut < (r->>'fin')::timestamptz and b.fin > (r->>'debut')::timestamptz)
        or (b.hebdo and (r->>'debut')::timestamptz >= b.debut
            and extract(isodow from (r->>'debut')::timestamptz) = extract(isodow from b.debut)
            and ((r->>'debut')::timestamptz)::time < b.fin::time
            and ((r->>'fin')::timestamptz)::time > b.debut::time))
  ) then
    raise exception 'créneau fermé par le terrain' using errcode = '23P01';
  end if;
  perform public.liberer_reservations_expirees();
  insert into public.reservations
    (reference, organisateur_id, sport, etablissement, terrain, lieu, debut, fin, part, statut, payer_avant)
  values
    (r->>'reference', auth.uid(), r->>'sport', r->>'etablissement', r->>'terrain', r->>'lieu',
     (r->>'debut')::timestamptz, (r->>'fin')::timestamptz, (r->>'part')::numeric,
     'pendingPayment', now() + interval '15 minutes');
end $$;

-- After payment: the hold becomes the booking, with its players. If the hold had expired, the
-- booking is made again (and fails with 23P01 if someone took the slot meanwhile).
create or replace function public.confirmer_reservation(r jsonb, joueurs jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'non connecté' using errcode = '28000'; end if;
  update public.reservations set statut = 'upcoming', payer_avant = null
    where reference = r->>'reference' and organisateur_id = auth.uid();
  if not found then
    perform public.liberer_reservations_expirees();
    insert into public.reservations
      (reference, organisateur_id, sport, etablissement, terrain, lieu, debut, fin, part, statut)
    values
      (r->>'reference', auth.uid(), r->>'sport', r->>'etablissement', r->>'terrain', r->>'lieu',
       (r->>'debut')::timestamptz, (r->>'fin')::timestamptz, (r->>'part')::numeric, 'upcoming');
  end if;
  delete from public.reservation_joueurs where reference = r->>'reference';
  insert into public.reservation_joueurs (reference, position, nom, image_url)
    select r->>'reference', (j->>'position')::integer, j->>'nom', j->>'image_url'
    from jsonb_array_elements(joueurs) j;
end $$;

-- The slot grid (VEN-02): taken slots of a venue between two times, from everyone, anonymous.
create or replace function public.creneaux_pris(p_etablissement text, p_de timestamptz, p_a timestamptz)
returns table (terrain text, debut timestamptz, fin timestamptz)
language sql stable security definer set search_path = public as $$
  select r.terrain, r.debut, r.fin from public.reservations r
  where r.etablissement = p_etablissement and r.debut < p_a and r.fin > p_de
    and r.statut <> 'cancelled' and not (r.statut = 'pendingPayment' and r.payer_avant < now())
$$;

revoke all on function public.prochaine_reference() from public, anon;
revoke all on function public.liberer_reservations_expirees() from public, anon;
revoke all on function public.bloquer_creneau(jsonb) from public, anon;
revoke all on function public.confirmer_reservation(jsonb, jsonb) from public, anon;
revoke all on function public.creneaux_pris(text, timestamptz, timestamptz) from public, anon;
grant execute on function public.prochaine_reference() to authenticated;
grant execute on function public.bloquer_creneau(jsonb) to authenticated;
grant execute on function public.confirmer_reservation(jsonb, jsonb) to authenticated;
grant execute on function public.creneaux_pris(text, timestamptz, timestamptz) to authenticated;

-- ── The venue catalogue (EXP-03, VEN-01/02): read by everyone, changed by the venue's owner ──

create table if not exists public.etablissements (
  id text primary key,
  nom text not null unique,
  lieu text not null,
  rue text not null,
  adresse_postale text not null,
  sports text[] not null,
  format text not null,
  surface text not null,
  ouvre integer not null,
  ferme integer not null,
  duree_creneau integer not null,
  joueurs integer not null,
  prix_creuse numeric not null,
  prix_pointe numeric not null,
  pointe_de integer not null default 1080,
  pointe_a integer not null default 1380,
  soiree_des integer not null default 1200,
  prix_joueur numeric not null,
  note numeric,
  nb_avis integer not null default 0,
  verifie boolean not null default false,
  distance_km numeric,
  latitude double precision,
  longitude double precision,
  proprietaire_id uuid references auth.users (id) on delete set null
);
-- ouvre, ferme, soiree_des, pointe_de, pointe_a: minutes after midnight; prices per slot.

create table if not exists public.etablissement_terrains (
  etablissement_id text not null references public.etablissements (id) on delete cascade,
  id text not null,
  nom text not null,
  interieur boolean not null default false,
  position integer not null,
  primary key (etablissement_id, id)
);

alter table public.etablissements enable row level security;
alter table public.etablissement_terrains enable row level security;
drop policy if exists "etablissements_lecture" on public.etablissements;
drop policy if exists "etablissements_proprietaire" on public.etablissements;
create policy "etablissements_lecture" on public.etablissements
  for select to authenticated using (true);
create policy "etablissements_proprietaire" on public.etablissements
  for update to authenticated using (proprietaire_id = auth.uid())
  with check (proprietaire_id = auth.uid());
drop policy if exists "etablissement_terrains_lecture" on public.etablissement_terrains;
drop policy if exists "etablissement_terrains_proprietaire" on public.etablissement_terrains;
create policy "etablissement_terrains_lecture" on public.etablissement_terrains
  for select to authenticated using (true);
create policy "etablissement_terrains_proprietaire" on public.etablissement_terrains
  for all to authenticated
  using (exists (select 1 from public.etablissements e
                 where e.id = etablissement_id and e.proprietaire_id = auth.uid()))
  with check (exists (select 1 from public.etablissements e
                      where e.id = etablissement_id and e.proprietaire_id = auth.uid()));

-- The story's four venues (design/screens/STORY-DATA.md). Owners change them afterwards.
insert into public.etablissements
  (id, nom, lieu, rue, adresse_postale, sports, format, surface, ouvre, ferme, duree_creneau,
   joueurs, prix_creuse, prix_pointe, soiree_des, prix_joueur, note, nb_avis, verifie,
   distance_km, latitude, longitude)
values
  ('arena-five', 'Arena Five', 'La Marsa', 'Route de la Corniche, La Marsa',
   'Route de la Corniche, 2070 La Marsa', '{football}', '5 contre 5', 'gazon synthétique',
   480, 1440, 60, 10, 120, 150, 1200, 12, 4.7, 128, true, 1.4, 36.8805, 10.3215),
  ('smash-padel', 'Smash Padel Club', 'Lac 2', 'Rue du Lac Biwa, Lac 2',
   'Rue du Lac Biwa, 1053 Les Berges du Lac 2', '{padel}', 'Double', 'gazon synthétique · vitré',
   480, 1440, 90, 4, 80, 100, 1110, 20, 4.8, 86, true, 3.1, 36.8455, 10.2705),
  ('padel-house-menzah', 'Padel House Menzah', 'Menzah 6', 'Avenue Hédi Nouira, Menzah 6',
   'Avenue Hédi Nouira, 2091 Menzah 6', '{padel}', 'Double', 'gazon synthétique · vitré',
   540, 1440, 90, 4, 72, 88, 1170, 18, 4.6, 52, false, 5.0, 36.8445, 10.1790),
  ('hoop-zone', 'Hoop Zone', 'Ennasr', 'Rue Abou Kacem Chebbi, Ennasr',
   'Rue Abou Kacem Chebbi, 2037 Ennasr', '{basketball}', '3x3 et 5x5', 'parquet',
   600, 1380, 60, 10, 90, 90, 1200, 9, 4.5, 41, false, 6.2, 36.8615, 10.1625)
on conflict (id) do nothing;

insert into public.etablissement_terrains (etablissement_id, id, nom, interieur, position) values
  ('arena-five', 't1', 'Terrain 1', false, 0), ('arena-five', 't2', 'Terrain 2', false, 1),
  ('arena-five', 't3', 'Terrain 3', true, 2),
  ('smash-padel', 'c1', 'Court 1', false, 0), ('smash-padel', 'c2', 'Court 2', false, 1),
  ('smash-padel', 'c3', 'Court 3', true, 2), ('smash-padel', 'c4', 'Court 4', true, 3),
  ('padel-house-menzah', 'c1', 'Court 1', false, 0), ('padel-house-menzah', 'c2', 'Court 2', false, 1),
  ('hoop-zone', 'b1', 'Terrain 3x3', true, 0), ('hoop-zone', 'b2', 'Terrain 5x5', true, 1)
on conflict do nothing;

-- The owner space (OWN-10…): the first account that opens it for a venue without an owner
-- becomes its owner (until the Utilisateur module verifies owners). True when it is the
-- caller's venue.
create or replace function public.revendiquer_etablissement(p_id text) returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return false; end if;
  update public.etablissements set proprietaire_id = auth.uid()
    where id = p_id and proprietaire_id is null;
  return exists (select 1 from public.etablissements where id = p_id and proprietaire_id = auth.uid());
end $$;
revoke all on function public.revendiquer_etablissement(text) from public, anon;
grant execute on function public.revendiquer_etablissement(text) to authenticated;

-- ── Closed slots (OWN-13): every player's grid shows them, only the owner sets them ─────────

create table if not exists public.blocages (
  id text primary key,
  etablissement_id text not null references public.etablissements (id) on delete cascade,
  terrain text not null,
  debut timestamptz not null,
  fin timestamptz not null,
  motif text not null,
  note text,
  hebdo boolean not null default false,
  constraint blocage_fin_apres_debut check (fin > debut)
);
create index if not exists blocages_etablissement on public.blocages (etablissement_id, debut);

alter table public.blocages enable row level security;
drop policy if exists "blocages_lecture" on public.blocages;
drop policy if exists "blocages_proprietaire" on public.blocages;
create policy "blocages_lecture" on public.blocages for select to authenticated using (true);
create policy "blocages_proprietaire" on public.blocages
  for all to authenticated
  using (exists (select 1 from public.etablissements e
                 where e.id = etablissement_id and e.proprietaire_id = auth.uid()))
  with check (exists (select 1 from public.etablissements e
                      where e.id = etablissement_id and e.proprietaire_id = auth.uid()));

-- ── The owner sees the bookings players make at their venue (OWN-10, 11, 14) ────────────────

drop policy if exists "reservations_proprietaire" on public.reservations;
create policy "reservations_proprietaire" on public.reservations
  for select to authenticated
  using (exists (select 1 from public.etablissements e
                 where e.nom = reservations.etablissement and e.proprietaire_id = auth.uid()));
drop policy if exists "reservation_joueurs_proprietaire" on public.reservation_joueurs;
create policy "reservation_joueurs_proprietaire" on public.reservation_joueurs
  for select to authenticated
  using (exists (select 1 from public.reservations r
                 join public.etablissements e on e.nom = r.etablissement
                 where r.reference = reservation_joueurs.reference and e.proprietaire_id = auth.uid()));
