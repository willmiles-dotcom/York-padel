-- The next Americano round's draw (court assignments + who's sitting
-- out) used to live only in each browser tab's memory, recomputed with
-- a random shuffle on every reload - so someone logging in again, or
-- opening the same session on another device, silently redrew the
-- round out from under players mid-match. Persisting it here means
-- every device sees the exact same draw until it's actually submitted.
-- Run in the Supabase SQL editor.

alter table sessions add column if not exists draft_round jsonb;
