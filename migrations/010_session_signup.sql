-- Replace self-check-in (today-only) with self sign-up/withdraw that works
-- for any upcoming or in-progress session. Signing up adds you straight
-- into the same `attendees` array used for match recording; withdrawing is
-- only allowed while the session is still `upcoming`, so a self-removal
-- never has to reason about already-recorded rounds. Run in the Supabase
-- SQL editor.

create or replace function public.sign_up_session(target_session text)
returns void as $$
declare
  my_player_id text;
begin
  select id into my_player_id from players where user_id = auth.uid();
  if my_player_id is null then
    raise exception 'No player profile linked to this account.';
  end if;
  update sessions
    set attendees = coalesce(attendees,'[]'::jsonb) || jsonb_build_array(my_player_id)
    where id = target_session
      and not archived
      and status in ('upcoming','in_progress')
      and not (coalesce(attendees,'[]'::jsonb) @> jsonb_build_array(my_player_id));
  if not found then
    raise exception 'Could not sign up - session not found, already started/finished, or already signed up.';
  end if;
end;
$$ language plpgsql security definer;

create or replace function public.withdraw_session(target_session text)
returns void as $$
declare
  my_player_id text;
begin
  select id into my_player_id from players where user_id = auth.uid();
  if my_player_id is null then
    raise exception 'No player profile linked to this account.';
  end if;
  update sessions
    set attendees = coalesce(attendees,'[]'::jsonb) - my_player_id
    where id = target_session
      and status = 'upcoming'
      and coalesce(attendees,'[]'::jsonb) @> jsonb_build_array(my_player_id);
  if not found then
    raise exception 'Could not withdraw - session already started, or you are not signed up.';
  end if;
end;
$$ language plpgsql security definer;

drop function if exists public.check_in_session(text);
