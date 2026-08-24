-- ============================================================================
-- LOCAL TEST SHIM — NOT a migration, NOT deployed.
-- Recreates the parts of Supabase that migrations depend on (auth.users,
-- auth.uid(), the three roles) so the schema and its authorization rules can be
-- executed and tested against a bare PostgreSQL in CI.
-- Under `supabase test db` this file is unnecessary; it exists so the security
-- suite can run without a Supabase project.
-- ============================================================================
create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  raw_user_meta_data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- Mirrors Supabase's auth.uid(): reads the request JWT claims GUC.
create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(
    coalesce(current_setting('request.jwt.claims', true)::jsonb ->> 'sub', ''),
    '')::uuid;
$$;

do $$ begin
  if not exists (select 1 from pg_roles where rolname='authenticated') then
    create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname='anon') then
    create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then
    create role service_role nologin bypassrls; end if;
end $$;

grant usage on schema auth to authenticated, anon;
grant select on auth.users to authenticated;
