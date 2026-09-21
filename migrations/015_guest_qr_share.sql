-- "Share guest link": a Guest sign-up: On/Off toggle (mirroring Taster's
-- taster_signup_open) so the Share button can be meaningfully disabled,
-- plus a way to regenerate a session's guest code on demand. Run in the
-- Supabase SQL editor.

begin;

alter table sessions add column if not exists guest_signup_open boolean not null default false;

-- Longer, harder-to-guess codes (was 8 hex chars, now ~20 - still short
-- enough to keep the QR scannable at a small print size).
create or replace function public.generate_guest_code(target_session text)
returns text as $$
declare
  existing_code text;
  new_code text;
begin
  if not public.is_caller_committee() then
    raise exception 'Only committee can create guest passes.';
  end if;
  select guest_code into existing_code from sessions where id = target_session;
  if existing_code is not null then
    return existing_code;
  end if;
  new_code := substr(md5(random()::text || target_session || clock_timestamp()::text), 1, 20);
  update sessions set guest_code = new_code where id = target_session;
  return new_code;
end;
$$ language plpgsql security definer;

create or replace function public.regenerate_guest_code(target_session text)
returns text as $$
declare
  new_code text;
begin
  if not public.is_caller_committee() then
    raise exception 'Only committee can manage guest passes.';
  end if;
  new_code := substr(md5(random()::text || target_session || clock_timestamp()::text), 1, 20);
  update sessions set guest_code = new_code where id = target_session;
  return new_code;
end;
$$ language plpgsql security definer;

grant execute on function public.regenerate_guest_code(text) to authenticated;

-- Both the join-screen lookup and the actual redemption now also require
-- guest_signup_open, so turning the toggle off stops things server-side,
-- not just in the UI.
create or replace function public.get_session_by_guest_code(code text)
returns table(id text, title text, date text, location text) as $$
begin
  return query
    select s.id, s.title, s.date, s.location
    from sessions s
    where s.guest_code = code
      and s.guest_signup_open
      and not s.archived
      and s.status <> 'completed';
end;
$$ language plpgsql security definer;

-- Guards against the live function still being an older signature (e.g.
-- if 014_lightweight_guests.sql wasn't run first) - CREATE OR REPLACE
-- can't change a function's return type.
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
    from sessions
    where guest_code = code and guest_signup_open and not archived;
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

-- Dropping the function above also drops its grants, so these must be
-- reissued (get_session_by_guest_code was CREATE OR REPLACE'd, not
-- dropped, so its existing grant to anon/authenticated survives as-is).
grant execute on function public.redeem_guest_pass(text, text) to anon, authenticated;

commit;
