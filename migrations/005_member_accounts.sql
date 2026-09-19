-- Real individual member accounts (not just committee's shared login),
-- restricted to @york.ac.uk addresses, each claiming one existing player
-- profile. Also fixes a real gap: write policies below previously checked
-- "is this session authenticated at all" (migrations/001_auth_rls.sql),
-- which was fine when only committee could ever have a session -- now
-- that ordinary members do too, that check would give every member
-- committee-level write access. Every write policy now checks
-- specifically for the committee account's email.
--
-- Run this in the Supabase SQL editor AFTER deploying the app code that
-- expects it (same sequencing as every prior migration).

begin;

-- ── Link a player row to the member account that claimed it ──────────
alter table players add column if not exists user_id uuid references auth.users(id);
create unique index if not exists players_user_id_unique on players(user_id) where user_id is not null;

-- ── Restrict signup to @york.ac.uk addresses (server-side, not just UI) ──
create or replace function public.enforce_york_email()
returns trigger as $$
begin
  if new.email !~* '@york\.ac\.uk$' then
    raise exception 'Only @york.ac.uk email addresses can sign up.';
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists enforce_york_email_trigger on auth.users;
create trigger enforce_york_email_trigger
before insert on auth.users
for each row execute function public.enforce_york_email();

-- ── Reads now require login (member or committee), not just anon ─────
revoke select on players from anon;
revoke select on sessions from anon;
revoke select on settings from anon;
grant select on players to authenticated;
grant select on sessions to authenticated;
grant select on settings to authenticated;

drop policy if exists players_select_all on players;
create policy players_select_all on players for select using (auth.role() = 'authenticated');

drop policy if exists sessions_select_all on sessions;
create policy sessions_select_all on sessions for select using (auth.role() = 'authenticated');

drop policy if exists settings_select_all on settings;
create policy settings_select_all on settings for select using (auth.role() = 'authenticated');

-- ── Writes require specifically the committee account, not any login ──
drop policy if exists players_write_authenticated on players;
create policy players_write_committee on players
  for all
  using ((auth.jwt() ->> 'email') = 'padel@yorksu.org')
  with check ((auth.jwt() ->> 'email') = 'padel@yorksu.org');

drop policy if exists sessions_write_authenticated on sessions;
create policy sessions_write_committee on sessions
  for all
  using ((auth.jwt() ->> 'email') = 'padel@yorksu.org')
  with check ((auth.jwt() ->> 'email') = 'padel@yorksu.org');

drop policy if exists settings_write_authenticated on settings;
create policy settings_write_committee on settings
  for all
  using ((auth.jwt() ->> 'email') = 'padel@yorksu.org')
  with check ((auth.jwt() ->> 'email') = 'padel@yorksu.org');

-- ── Narrow door for a member to claim exactly one unclaimed player ────
create or replace function public.claim_player(target_id text)
returns void as $$
begin
  if auth.uid() is null then
    raise exception 'Must be logged in to claim a player.';
  end if;
  update players
    set user_id = auth.uid()
    where id = target_id and user_id is null;
  if not found then
    raise exception 'That player is already claimed or does not exist.';
  end if;
end;
$$ language plpgsql security definer;

commit;

-- ── ROLLBACK (paste and run this block only if something goes wrong) ──
-- begin;
-- drop trigger if exists enforce_york_email_trigger on auth.users;
-- drop function if exists public.enforce_york_email();
-- drop function if exists public.claim_player(text);
-- drop policy if exists players_write_committee on players;
-- drop policy if exists sessions_write_committee on sessions;
-- drop policy if exists settings_write_committee on settings;
-- create policy players_write_authenticated on players for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
-- create policy sessions_write_authenticated on sessions for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
-- create policy settings_write_authenticated on settings for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
-- drop policy if exists players_select_all on players;
-- create policy players_select_all on players for select using (true);
-- drop policy if exists sessions_select_all on sessions;
-- create policy sessions_select_all on sessions for select using (true);
-- drop policy if exists settings_select_all on settings;
-- create policy settings_select_all on settings for select using (true);
-- grant select on players to anon;
-- grant select on sessions to anon;
-- grant select on settings to anon;
-- commit;
