-- Claim requests now need committee approval instead of being instant, and
-- "committee" becomes a permission on an individual account (is_committee)
-- instead of only the shared login. The shared committee login keeps
-- working as an emergency fallback -- see the write policies below.
--
-- Run this in the Supabase SQL editor, then do the one manual bootstrap
-- step at the bottom (there's no other way to create the first
-- committee-flagged account, since approving a claim requires already
-- being committee).

begin;

alter table players add column if not exists pending_user_id uuid references auth.users(id);
alter table players add column if not exists is_committee boolean not null default false;

-- ── Request a claim (replaces the old instant claim_player) ──────────
drop function if exists public.claim_player(text);

create or replace function public.request_claim(target_id text)
returns void as $$
begin
  if auth.uid() is null then
    raise exception 'Must be logged in to request a claim.';
  end if;
  if exists(select 1 from players where user_id = auth.uid()) then
    raise exception 'This account is already linked to a player.';
  end if;
  if exists(select 1 from players where pending_user_id = auth.uid()) then
    raise exception 'You already have a pending request.';
  end if;
  update players
    set pending_user_id = auth.uid()
    where id = target_id and user_id is null and pending_user_id is null;
  if not found then
    raise exception 'That player is already claimed or has a pending request.';
  end if;
end;
$$ language plpgsql security definer;

-- ── Committee check used by the approve/reject/list functions below ──
create or replace function public.is_caller_committee()
returns boolean as $$
begin
  return (auth.jwt() ->> 'email') = 'padel@yorksu.org'
    or exists(select 1 from players where user_id = auth.uid() and is_committee = true);
end;
$$ language plpgsql security definer;

create or replace function public.approve_claim(target_id text)
returns void as $$
begin
  if not public.is_caller_committee() then
    raise exception 'Only committee can approve claims.';
  end if;
  update players
    set user_id = pending_user_id, pending_user_id = null
    where id = target_id and pending_user_id is not null;
  if not found then
    raise exception 'No pending request for that player.';
  end if;
end;
$$ language plpgsql security definer;

create or replace function public.reject_claim(target_id text)
returns void as $$
begin
  if not public.is_caller_committee() then
    raise exception 'Only committee can reject claims.';
  end if;
  update players set pending_user_id = null where id = target_id;
end;
$$ language plpgsql security definer;

create or replace function public.list_pending_claims()
returns table(player_id text, player_name text, requester_email text) as $$
begin
  if not public.is_caller_committee() then
    raise exception 'Only committee can view pending claims.';
  end if;
  return query
    select p.id, p.name, u.email
    from players p
    join auth.users u on u.id = p.pending_user_id
    where p.pending_user_id is not null;
end;
$$ language plpgsql security definer;

-- ── Writes: committee email OR an account with is_committee = true ───
drop policy if exists players_write_committee on players;
create policy players_write_committee on players
  for all
  using (public.is_caller_committee())
  with check (public.is_caller_committee());

drop policy if exists sessions_write_committee on sessions;
create policy sessions_write_committee on sessions
  for all
  using (public.is_caller_committee())
  with check (public.is_caller_committee());

drop policy if exists settings_write_committee on settings;
create policy settings_write_committee on settings
  for all
  using (public.is_caller_committee())
  with check (public.is_caller_committee());

commit;

-- ── BOOTSTRAP (run once, by hand, after the migration above) ──────────
-- Find your own player id (the one you already claimed), then:
-- update players set is_committee = true where id = '<your player id>';
