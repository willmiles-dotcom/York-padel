-- Fix "permission denied for table taster_signups" in the committee door
-- view. RLS policies only decide which ROWS are visible - Postgres still
-- checks table-level GRANTs first, and 012_taster_signups.sql created the
-- policies but never granted the base privileges to `authenticated`
-- (every other RLS-protected table in this app has this grant - see
-- 001_auth_rls.sql / 005_member_accounts.sql - this one was missed).
--
-- No grant to `anon` here on purpose: the public must only ever reach
-- this table through taster_signup(), which runs as the table owner and
-- bypasses grants/RLS entirely. Run this in the Supabase SQL editor.

grant select, update, delete on taster_signups to authenticated;
