-- Fix "structure of query does not match function result type" error:
-- auth.users.email is varchar(255), but list_pending_claims() declared
-- its return column as text - RETURN QUERY requires an exact type
-- match, so this needs an explicit cast. Run in the Supabase SQL editor.

create or replace function public.list_pending_claims()
returns table(player_id text, player_name text, requester_email text) as $$
begin
  if not public.is_caller_committee() then
    raise exception 'Only committee can view pending claims.';
  end if;
  return query
    select p.id, p.name, u.email::text
    from players p
    join auth.users u on u.id = p.pending_user_id
    where p.pending_user_id is not null;
end;
$$ language plpgsql security definer;
