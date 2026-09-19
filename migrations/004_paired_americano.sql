-- Adds support for fixed-pair Doubles Americano sessions and an optional
-- court cap for any Americano session. Run this in the Supabase SQL editor.

alter table sessions add column if not exists pairs jsonb not null default '[]'::jsonb;
alter table sessions add column if not exists max_courts integer;
