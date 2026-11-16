-- Interactive Business Model Canvas — Supabase schema
-- Run once in the Supabase SQL editor.

-- 1) Projects: 20 fixed rows, one per team
create table public.bmc_projects (
  id smallint primary key check (id between 1 and 20),
  project_name text not null default '' check (char_length(project_name) <= 120),
  key_partners text not null default '' check (char_length(key_partners) <= 4000),
  key_activities text not null default '' check (char_length(key_activities) <= 4000),
  key_resources text not null default '' check (char_length(key_resources) <= 4000),
  value_propositions text not null default '' check (char_length(value_propositions) <= 4000),
  customer_relationships text not null default '' check (char_length(customer_relationships) <= 4000),
  channels text not null default '' check (char_length(channels) <= 4000),
  customer_segments text not null default '' check (char_length(customer_segments) <= 4000),
  cost_structure text not null default '' check (char_length(cost_structure) <= 4000),
  revenue_streams text not null default '' check (char_length(revenue_streams) <= 4000),
  updated_at timestamptz
);

create or replace function public.bmc_set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger bmc_projects_updated_at
before update on public.bmc_projects
for each row execute function public.bmc_set_updated_at();

insert into public.bmc_projects (id) select generate_series(1, 20);

alter table public.bmc_projects enable row level security;

create policy "Public can read projects" on public.bmc_projects
  for select to anon, authenticated using (true);

create policy "Public can update the 20 projects" on public.bmc_projects
  for update to anon, authenticated using (true) with check (id between 1 and 20);

-- the public may read and edit text fields only: no insert, delete, or id changes
revoke insert, delete, truncate on public.bmc_projects from anon, authenticated;
revoke update on public.bmc_projects from anon, authenticated;
grant update (project_name, key_partners, key_activities, key_resources, value_propositions,
  customer_relationships, channels, customer_segments, cost_structure, revenue_streams)
  on public.bmc_projects to anon, authenticated;

-- 2) Presence heartbeat: powers "N in the room" on the home page
create table public.bmc_presence (
  client_id text primary key check (client_id ~ '^[a-z0-9]{6,16}$'),
  room smallint check (room between 1 and 20),
  is_desktop boolean not null default false,
  seen_at timestamptz not null default now()
);
create index bmc_presence_seen_idx on public.bmc_presence (seen_at);
alter table public.bmc_presence enable row level security;
revoke all on public.bmc_presence from anon, authenticated;   -- only reachable through the functions below

create or replace function public.bmc_heartbeat(p_client text, p_room int, p_desktop boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_client !~ '^[a-z0-9]{6,16}$' then return; end if;
  if p_room is not null and (p_room < 1 or p_room > 20) then p_room := null; end if;
  insert into public.bmc_presence (client_id, room, is_desktop, seen_at)
  values (p_client, p_room, coalesce(p_desktop,false), now())
  on conflict (client_id) do update set room = excluded.room, is_desktop = excluded.is_desktop, seen_at = now();
  if random() < 0.02 then
    delete from public.bmc_presence where seen_at < now() - interval '1 hour';
  end if;
end $$;

create or replace function public.bmc_online()
returns table (room smallint, people int, desktops int) language sql stable security definer set search_path = '' as $$
  select p.room, count(*)::int, count(*) filter (where p.is_desktop)::int
  from public.bmc_presence p
  where p.seen_at > now() - interval '75 seconds'
  group by p.room;
$$;

revoke all on function public.bmc_heartbeat(text,int,boolean) from public;
revoke all on function public.bmc_online() from public;
grant execute on function public.bmc_heartbeat(text,int,boolean) to anon, authenticated;
grant execute on function public.bmc_online() to anon, authenticated;
