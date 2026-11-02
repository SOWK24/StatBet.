-- Pauly’Bet — migration de l'historique existant vers le compte propriétaire
-- À exécuter APRÈS :
-- 1) avoir exécuté paulybet-auth-setup.sql ;
-- 2) avoir créé le compte propriétaire dans Pauly’Bet ;
-- 3) avoir confirmé l'adresse e-mail si Supabase le demande.
--
-- IMPORTANT : remplacez l'adresse ci-dessous par l'e-mail EXACT du compte propriétaire.
-- Exécuter ce script dans Supabase > SQL Editor (rôle postgres).
-- Il copie l'ancienne ligne statbet_sync (code historique 1234) vers le compte propriétaire.
-- L'ancienne table et sa ligne ne sont PAS supprimées.
-- À faire avant d'ajouter de nouveaux paris sur le nouveau système.

do $$
declare
  owner_email text := 'REMPLACER-PAR-VOTRE-EMAIL';
  owner_id uuid;
  legacy_data jsonb;
  legacy_updated_at timestamptz;
begin
  select id into owner_id
  from auth.users
  where lower(email) = lower(owner_email)
  limit 1;

  if owner_id is null then
    raise exception 'Compte propriétaire introuvable. Vérifiez owner_email et créez/validez le compte avant de relancer.';
  end if;

  select data, updated_at
    into legacy_data, legacy_updated_at
  from public.statbet_sync
  where sync_code = '1234'
  limit 1;

  if legacy_data is null then
    raise exception 'Aucune ancienne donnée trouvée dans statbet_sync pour le code historique. Ne rien supprimer ; vérifier la table avant de continuer.';
  end if;

  insert into public.paulybet_user_data (user_id, data, updated_at)
  values (owner_id, legacy_data, coalesce(legacy_updated_at, now()))
  on conflict (user_id) do update
    set data = excluded.data,
        updated_at = excluded.updated_at;

  raise notice 'Historique historique copié pour le compte propriétaire %.', owner_email;
end $$;

-- Contrôle après migration : doit afficher une ligne pour le compte propriétaire.
select u.email, jsonb_array_length(d.data) as nombre_de_paris, d.updated_at
from public.paulybet_user_data d
join auth.users u on u.id = d.user_id
where lower(u.email) = lower('REMPLACER-PAR-VOTRE-EMAIL');
