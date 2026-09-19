-- Self check-in: a member can add themself to today's session without
-- needing committee to do it manually. Run in the Supabase SQL editor.

create or replace function public.check_in_session(target_session text)
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
      and date = to_char(current_date, 'YYYY-MM-DD')
      and status in ('upcoming','in_progress')
      and not (coalesce(attendees,'[]'::jsonb) @> jsonb_build_array(my_player_id));
  if not found then
    raise exception 'Could not check in - session not found, not happening today, or already checked in.';
  end if;
end;
$$ language plpgsql security definer;
