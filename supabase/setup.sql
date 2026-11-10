-- 35 Dollar Pot: one-time Supabase setup. Run all of it in Supabase -> SQL Editor -> New query.
-- Safe to run again: tables use "if not exists" and every policy is dropped before it is recreated.
-- Same open trust model as the original site: the browser uses the publishable key with no login,
-- and admin mode is a client-side password. The ESPN data job writes with the secret key.

-- League data: one JSON row 'current' (written by the data job) plus a 'heartbeat' row.
create table if not exists public.league_data (
  id          text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);
alter table public.league_data enable row level security;
drop policy if exists "league read" on public.league_data;
create policy "league read" on public.league_data for select to anon using (true);

-- Home page announcements, posted and deleted from Admin.
create table if not exists public.league_updates (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  message     text not null check (char_length(message) between 1 and 300),
  active      boolean not null default true
);
alter table public.league_updates enable row level security;
drop policy if exists "updates read" on public.league_updates;
drop policy if exists "updates insert" on public.league_updates;
drop policy if exists "updates delete" on public.league_updates;
create policy "updates read"   on public.league_updates for select to anon using (true);
create policy "updates insert" on public.league_updates for insert to anon with check (true);
create policy "updates delete" on public.league_updates for delete to anon using (true);

-- Trade Block: one listing per team.
create table if not exists public.trade_block (
  team_id     int primary key,
  listing     jsonb not null default '{}'::jsonb,   -- {available:[pid,...], needs:["RB",...], note:"..."}
  updated_at  timestamptz not null default now()
);
alter table public.trade_block enable row level security;
drop policy if exists "block read" on public.trade_block;
drop policy if exists "block insert" on public.trade_block;
drop policy if exists "block update" on public.trade_block;
drop policy if exists "block delete" on public.trade_block;
create policy "block read"   on public.trade_block for select to anon using (true);
create policy "block insert" on public.trade_block for insert to anon with check (true);
create policy "block update" on public.trade_block for update to anon using (true) with check (true);
create policy "block delete" on public.trade_block for delete to anon using (true);
-- Webhooks need the previous listing on UPDATE so note edits and removals are not counted as new players.
alter table public.trade_block replica identity full;

-- Site settings edited from Admin (row id 'home').
create table if not exists public.site_settings (
  id          text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);
alter table public.site_settings enable row level security;
drop policy if exists "settings read" on public.site_settings;
drop policy if exists "settings insert" on public.site_settings;
drop policy if exists "settings update" on public.site_settings;
create policy "settings read"   on public.site_settings for select to anon using (true);
create policy "settings insert" on public.site_settings for insert to anon with check (true);
create policy "settings update" on public.site_settings for update to anon using (true) with check (true);

-- Web Push subscriptions (one per device). The notify Edge Function reads these with the service role.
create table if not exists public.push_subscriptions (
  endpoint    text primary key,
  p256dh      text not null,
  auth        text not null,
  team_id     int,
  created_at  timestamptz not null default now()
);
alter table public.push_subscriptions enable row level security;
drop policy if exists "subs read" on public.push_subscriptions;
drop policy if exists "subs insert" on public.push_subscriptions;
drop policy if exists "subs update" on public.push_subscriptions;
drop policy if exists "subs delete" on public.push_subscriptions;
create policy "subs read"   on public.push_subscriptions for select to anon using (true);
create policy "subs insert" on public.push_subscriptions for insert to anon with check (true);
create policy "subs update" on public.push_subscriptions for update to anon using (true) with check (true);
create policy "subs delete" on public.push_subscriptions for delete to anon using (true);

-- Manual notification queue: the site inserts a row, a database webhook sends it through notify.
create table if not exists public.push_queue (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  title       text not null,
  body        text not null default '',
  team_ids    int[],
  url         text,
  tag         text
);
alter table public.push_queue enable row level security;
drop policy if exists "queue insert" on public.push_queue;
create policy "queue insert" on public.push_queue for insert to anon with check (true);

-- Table privileges (newer Supabase projects don't always grant these automatically).
grant usage on schema public to anon, service_role;
grant select on public.league_data to anon;
grant select, insert, delete on public.league_updates to anon;
grant select, insert, update, delete on public.trade_block to anon;
grant select, insert, update on public.site_settings to anon;
grant select, insert, update, delete on public.push_subscriptions to anon;
grant insert on public.push_queue to anon;
grant all on public.league_data, public.league_updates, public.trade_block, public.site_settings,
  public.push_subscriptions, public.push_queue to service_role;

-- Live updates for the Trade Block (listings appear without a page refresh).
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trade_block') then
    alter publication supabase_realtime add table public.trade_block;
  end if;
end $$;
