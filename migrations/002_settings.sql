-- Shared app-wide settings, starting with a rankings on/off switch.
-- Run this in the Supabase SQL editor.

begin;

create table if not exists settings (
  id text primary key,
  rankings_enabled boolean not null default true
);

insert into settings (id, rankings_enabled)
values ('global', true)
on conflict (id) do nothing;

alter table settings enable row level security;

drop policy if exists settings_select_all on settings;
create policy settings_select_all on settings for select using (true);

drop policy if exists settings_write_authenticated on settings;
create policy settings_write_authenticated on settings
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

grant select on settings to anon, authenticated;
grant insert, update, delete on settings to authenticated;

commit;
