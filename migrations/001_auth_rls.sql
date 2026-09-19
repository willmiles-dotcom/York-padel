-- Phase 1b: replace the client-side committee password with real Supabase Auth.
-- Run this in the Supabase SQL editor AFTER you've created the committee account
-- in Authentication > Users (email: will.r.miles@gmail.com).
--
-- Before this migration: anon has blanket write grants (`grant all ... to anon`),
-- and the "committee" gate is just a JS string comparison — anyone can write via
-- the anon key regardless of what the UI shows.
--
-- After this migration: anon can only read; only an authenticated session
-- (i.e. someone who signed in with the committee password via supabase-js) can write.

begin;

alter table players enable row level security;
alter table sessions enable row level security;

-- Remove the old blanket anon write access so there's no silent fallback path.
revoke insert, update, delete on players from anon;
revoke insert, update, delete on sessions from anon;

-- Public read stays open to everyone (members don't log in at all).
grant select on players to anon, authenticated;
grant select on sessions to anon, authenticated;

-- Only an authenticated (signed-in) session may write.
grant insert, update, delete on players to authenticated;
grant insert, update, delete on sessions to authenticated;

drop policy if exists players_select_all on players;
create policy players_select_all on players for select using (true);

drop policy if exists players_write_authenticated on players;
create policy players_write_authenticated on players
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists sessions_select_all on sessions;
create policy sessions_select_all on sessions for select using (true);

drop policy if exists sessions_write_authenticated on sessions;
create policy sessions_write_authenticated on sessions
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

commit;

-- ── ROLLBACK (paste and run this block only if the committee gets locked out) ──
-- begin;
-- drop policy if exists players_write_authenticated on players;
-- drop policy if exists sessions_write_authenticated on sessions;
-- grant insert, update, delete on players to anon;
-- grant insert, update, delete on sessions to anon;
-- alter table players disable row level security;
-- alter table sessions disable row level security;
-- commit;
