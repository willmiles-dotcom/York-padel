-- Public taster sign-up for a freshers-fair QR code. A taster sign-up is
-- NOT a player and NOT the existing single-session Guest pass (which
-- creates a real anonymous auth account) - it's just a name on a door
-- list, entered by a genuinely anonymous member of the public with no
-- login at all.
--
-- Security model: the public can only ever reach this data through
-- taster_signup() and list_open_taster_sessions() below, both
-- `security definer` so they run with elevated privileges regardless of
-- the caller's own (nonexistent) permissions - the same pattern already
-- used for redeem_guest_pass() in 011_guest_accounts.sql. taster_signups
-- has NO insert policy for any role, so there is no RLS policy anyone
-- could accidentally loosen into an open door later; the function is the
-- only door. Run this migration in the Supabase SQL editor.

begin;

alter table sessions add column if not exists is_taster boolean not null default false;
alter table sessions add column if not exists taster_signup_open boolean not null default false;

create table if not exists taster_signups (
  id text primary key,
  session_id text not null references sessions(id),
  name text not null,
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

alter table taster_signups enable row level security;

-- Committee-only direct access, for the door view (read/verify/remove).
-- Deliberately no insert policy - see note above.
drop policy if exists taster_signups_select_committee on taster_signups;
create policy taster_signups_select_committee on taster_signups
  for select using (public.is_caller_committee());

drop policy if exists taster_signups_update_committee on taster_signups;
create policy taster_signups_update_committee on taster_signups
  for update using (public.is_caller_committee());

drop policy if exists taster_signups_delete_committee on taster_signups;
create policy taster_signups_delete_committee on taster_signups
  for delete using (public.is_caller_committee());

create or replace function public.taster_signup(target_session text, guest_name text)
returns void as $$
declare
  trimmed_name text;
  new_id text;
  ok boolean;
begin
  trimmed_name := trim(guest_name);
  if length(trimmed_name) < 2 or length(trimmed_name) > 40 then
    raise exception 'Name must be between 2 and 40 characters.';
  end if;

  select exists(
    select 1 from sessions
    where id = target_session
      and is_taster
      and taster_signup_open
      and not archived
      and status <> 'completed'
  ) into ok;
  if not ok then
    raise exception 'Sign-ups for this session are not open.';
  end if;

  new_id := 'taster_' || substr(md5(random()::text), 1, 10);
  insert into taster_signups (id, session_id, name) values (new_id, target_session, trimmed_name);
end;
$$ language plpgsql security definer;

grant execute on function public.taster_signup(text, text) to anon, authenticated;

create or replace function public.list_open_taster_sessions()
returns table(id text, title text, date text, location text) as $$
begin
  return query
    select s.id, s.title, s.date, s.location
    from sessions s
    where s.is_taster
      and s.taster_signup_open
      and not s.archived
      and s.status <> 'completed';
end;
$$ language plpgsql security definer;

grant execute on function public.list_open_taster_sessions() to anon, authenticated;

commit;
