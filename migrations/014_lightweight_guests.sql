-- Unify Guest pass and Taster sign-up into one lightweight mechanism: a
-- players row flagged is_guest, added straight to the session's
-- attendees, with NO login ever created. They differ only in how
-- someone reaches the form - Taster via one public link (whichever
-- session has sign-up open), Guest via a per-session code committee
-- generates - but land in the same place and get the same door-check.
--
-- This drops taster_signups (from 012_taster_signups.sql) - if you've
-- already collected real sign-ups there you want to keep, export them
-- first; otherwise this is safe to run as-is. Run in the Supabase SQL
-- editor.

begin;

alter table players add column if not exists door_verified boolean not null default false;

drop table if exists taster_signups;

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

  new_id := 'guest_' || substr(md5(random()::text), 1, 10);
  insert into players (id, name, is_guest, guest_session_id, elo_rating, is_active)
    values (new_id, trimmed_name, true, target_session, 1000, true);
  update sessions
    set attendees = coalesce(attendees,'[]'::jsonb) || jsonb_build_array(new_id)
    where id = target_session;
end;
$$ language plpgsql security definer;

grant execute on function public.taster_signup(text, text) to anon, authenticated;

create or replace function public.get_session_by_guest_code(code text)
returns table(id text, title text, date text, location text) as $$
begin
  return query
    select s.id, s.title, s.date, s.location
    from sessions s
    where s.guest_code = code and not s.archived and s.status <> 'completed';
end;
$$ language plpgsql security definer;

grant execute on function public.get_session_by_guest_code(text) to anon, authenticated;

-- Return type changes from text to void (no more "log the guest in"
-- step), so this needs dropping first - CREATE OR REPLACE can't change
-- a function's return type.
drop function if exists public.redeem_guest_pass(text, text);

create or replace function public.redeem_guest_pass(code text, guest_name text)
returns void as $$
declare
  target_session_id text;
  target_status text;
  trimmed_name text;
  new_id text;
begin
  trimmed_name := trim(guest_name);
  if length(trimmed_name) < 2 or length(trimmed_name) > 40 then
    raise exception 'Name must be between 2 and 40 characters.';
  end if;

  select id, status into target_session_id, target_status
    from sessions where guest_code = code and not archived;
  if target_session_id is null then
    raise exception 'Invalid or expired guest link.';
  end if;
  if target_status = 'completed' then
    raise exception 'This session has already finished.';
  end if;

  new_id := 'guest_' || substr(md5(random()::text), 1, 10);
  insert into players (id, name, is_guest, guest_session_id, elo_rating, is_active)
    values (new_id, trimmed_name, true, target_session_id, 1000, true);
  update sessions
    set attendees = coalesce(attendees,'[]'::jsonb) || jsonb_build_array(new_id)
    where id = target_session_id;
end;
$$ language plpgsql security definer;

grant execute on function public.redeem_guest_pass(text, text) to anon, authenticated;

commit;
