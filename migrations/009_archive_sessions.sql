-- Soft-delete for sessions, matching the same never-hard-delete
-- convention already used for players (is_active). Run in the Supabase
-- SQL editor.

alter table sessions add column if not exists archived boolean not null default false;
