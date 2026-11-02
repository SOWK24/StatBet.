-- Pauly’Bet — base de données multi-comptes
-- À exécuter une seule fois dans Supabase > SQL Editor.
-- Cette migration crée une NOUVELLE table et ne modifie/supprime PAS statbet_sync
-- ni aucune donnée historique existante.

create table if not exists public.paulybet_user_data (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.paulybet_user_data enable row level security;

-- Aucun accès anonyme. Chaque compte authentifié ne peut agir que sur sa ligne.
revoke all on table public.paulybet_user_data from anon;
grant select, insert, update, delete on table public.paulybet_user_data to authenticated;

drop policy if exists "Users can read their own PaulyBet data" on public.paulybet_user_data;
create policy "Users can read their own PaulyBet data"
  on public.paulybet_user_data
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own PaulyBet data" on public.paulybet_user_data;
create policy "Users can insert their own PaulyBet data"
  on public.paulybet_user_data
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own PaulyBet data" on public.paulybet_user_data;
create policy "Users can update their own PaulyBet data"
  on public.paulybet_user_data
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own PaulyBet data" on public.paulybet_user_data;
create policy "Users can delete their own PaulyBet data"
  on public.paulybet_user_data
  for delete
  to authenticated
  using (auth.uid() = user_id);

-- Vérification attendue : RLS activé sur public.paulybet_user_data.
select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname = 'paulybet_user_data';
