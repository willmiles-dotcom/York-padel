-- Sessions only ever stored a date, not a time, so committee had no
-- way to tell members when a session actually started. Run in the
-- Supabase SQL editor.

alter table sessions add column if not exists time text;
