-- The sessions table is missing points_to_play, which the app has always
-- expected (points per round for Americano sessions, default 16 matches
-- what the UI already falls back to everywhere it reads this field).
-- Run this in the Supabase SQL editor.

alter table sessions add column if not exists points_to_play integer not null default 16;
