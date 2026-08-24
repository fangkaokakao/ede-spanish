-- Test helpers. Local only.
--
-- NOTE: role switching is done at the psql level, not inside a function.
-- SET ROLE inside a plpgsql function is reverted when the function exits, and
-- SECURITY DEFINER forbids it outright. Only the JWT claim is set here, via
-- set_config(..., is_local => true), which IS transaction-scoped and survives
-- the function return.
create schema if not exists tests;

create or replace function tests.claim_as(p_uid uuid, p_role text default 'learner')
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'app_role', p_role)::text, true);
end $$;

create or replace function tests.claim_none() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{}', true);
end $$;

create or replace function tests.mk_learner(p_email text) returns uuid
language plpgsql as $$
declare v uuid;
begin
  insert into auth.users (email) values (p_email) returning id into v;
  return v;
end $$;

grant usage on schema tests to authenticated, anon;
grant execute on all functions in schema tests to authenticated, anon;
