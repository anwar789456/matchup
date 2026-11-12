-- Réservation (Mahmoud) — Supabase is the source of truth for booked courts; the phone keeps a
-- copy in SQFlite (shown first, used offline). Run this whole file in the Supabase SQL editor
-- (safe to run again). Unlike schema.sql it is written by hand: these tables have rules.
--
-- • A slot is held for 15 minutes before the checkout (statut 'pendingPayment'), then confirmed
--   after payment. Two live bookings can never overlap on the same court (exclusion constraint).
-- • References come from one sequence (MU-48214, MU-48215…): unique across every phone.
-- • A player reads and changes only their own bookings; creneaux_pris() tells everyone which
--   slots are taken, without saying by whom.

create extension if not exists btree_gist;

-- The per-user copies of the first sync (sync_tables.dart) are replaced by the real tables.
drop table if exists public.annulations cascade;
drop table if exists public.reservation_joueurs cascade;
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'reservations' and column_name = 'owner_id'
  ) then
    drop table public.reservations cascade;
  end if;
end $$;

create sequence if not exists public.reservation_ref start 48214;

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

-- « MU-48214 »: the reference the next booking gets (asked before the checkout, BKG-03/04).
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
