-- Sessions had a start time only (017). This adds an end time, stored as
-- text in the same "HH:MM" 24-hour format as the start time. Existing
-- sessions keep a blank end time. Run in the Supabase SQL editor BEFORE
-- using the new end-time field in the app.

alter table sessions add column if not exists end_time text;
