-- Guest accounts: a single-session pass. Committee generates a shareable
-- code for one session; whoever redeems it gets a real (anonymous)
-- Supabase auth session plus a lightweight `players` row flagged
-- is_guest, scoped to that one session. Guests can be put into real
-- scored rounds by committee, but are always skipped when ELO/games/wins
-- get written back, and excluded from the leaderboard, players page and
-- "add player to session" search (all handled client-side in index.html).
--
-- Requires enabling Anonymous Sign-Ins for this project:
-- Supabase dashboard -> Authentication -> Providers -> Anonymous Sign-Ins.
-- Run this migration in the Supabase SQL editor.

begin;

alter table players add column if not exists is_guest boolean not null default false;
alter table players add column if not exists guest_session_id text references sessions(id);
alter table sessions add column if not exists guest_code text unique;

-- Anonymous auth users have no email. The existing regex check happens to
-- already let a NULL email through (NULL comparisons are never true in
-- plpgsql's `if`), but that's fragile - make it explicit so it can't be
-- "fixed" later in a way that silently breaks guest sign-in.
create or replace function public.enforce_york_email()
returns trigger as $$
begin
  if new.email is not null and new.email !~* '@york\.ac\.uk$' then
    raise exception 'Only @york.ac.uk email addresses can sign up.';
  end if;
  return new;
end;
$$ language plpgsql security definer;

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
  new_code := substr(md5(random()::text || target_session), 1, 8);
  update sessions set guest_code = new_code where id = target_session;
  return new_code;
end;
$$ language plpgsql security definer;

create or replace function public.redeem_guest_pass(code text, guest_name text)
returns text as $$
declare
  target_session_id text;
  target_status text;
  existing_id text;
  new_id text;
begin
  if auth.uid() is null then
    raise exception 'Not signed in.';
  end if;
  select id, status into target_session_id, target_status
    from sessions where guest_code = code and not archived;
  if target_session_id is null then
    raise exception 'Invalid or expired guest link.';
  end if;
  if target_status = 'completed' then
    raise exception 'This session has already finished.';
  end if;

  select id into existing_id from players where user_id = auth.uid();
  if existing_id is not null then
    update sessions
      set attendees = coalesce(attendees,'[]'::jsonb) || jsonb_build_array(existing_id)
      where id = target_session_id
        and not (coalesce(attendees,'[]'::jsonb) @> jsonb_build_array(existing_id));
    return target_session_id;
  end if;

  new_id := 'guest_' || substr(md5(random()::text), 1, 10);
  insert into players (id, name, is_guest, guest_session_id, user_id, elo_rating, is_active)
    values (new_id, guest_name, true, target_session_id, auth.uid(), 1000, true);
  update sessions
    set attendees = coalesce(attendees,'[]'::jsonb) || jsonb_build_array(new_id)
    where id = target_session_id;
  return target_session_id;
end;
$$ language plpgsql security definer;

commit;
