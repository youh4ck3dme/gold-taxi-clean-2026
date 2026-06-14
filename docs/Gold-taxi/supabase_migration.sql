-- SUPABASE MIGRATION SQL for Gold-Taxi
-- Phase 3: Realtime Backend

-- 1. PROFILES Table
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  full_name text,
  phone text,
  role text not null check (role in ('customer', 'driver', 'admin')) default 'customer',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

-- 2. DRIVERS Table
create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade unique,
  display_name text not null,
  phone text,
  vehicle_type text,
  vehicle_plate text,
  service_classes text[] default '{standard}',
  is_online boolean default false,
  current_lat double precision,
  current_lng double precision,
  updated_at timestamptz default now()
);

alter table public.drivers enable row level security;

-- 3. RIDES Table
create table if not exists public.rides (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id),
  driver_id uuid references public.drivers(id),
  pickup_address text not null,
  pickup_lat double precision not null,
  pickup_lng double precision not null,
  dropoff_address text not null,
  dropoff_lat double precision not null,
  dropoff_lng double precision not null,
  service_type text not null check (service_type in ('standard', 'comfort', 'premium')),
  estimated_distance_km numeric,
  estimated_duration_min numeric,
  estimated_price numeric,
  final_price numeric,
  status text not null check (status in ('requested', 'accepted', 'driver_arriving', 'in_progress', 'completed', 'cancelled')) default 'requested',
  cancellation_reason text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  accepted_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz
);

alter table public.rides enable row level security;

-- 4. RIDE_EVENTS Table
create table if not exists public.ride_events (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid references public.rides(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  from_status text,
  to_status text not null,
  event_type text not null,
  message text,
  created_at timestamptz default now()
);

alter table public.ride_events enable row level security;

-- 5. DRIVER_LOCATIONS Table
create table if not exists public.driver_locations (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid references public.drivers(id) on delete cascade,
  ride_id uuid references public.rides(id) on delete set null,
  lat double precision not null,
  lng double precision not null,
  heading numeric,
  speed numeric,
  created_at timestamptz default now()
);

alter table public.driver_locations enable row level security;

-- INDEXES
create index if not exists rides_customer_id_idx on public.rides(customer_id);
create index if not exists rides_driver_id_idx on public.rides(driver_id);
create index if not exists rides_status_idx on public.rides(status);
create index if not exists rides_created_at_desc_idx on public.rides(created_at desc);
create index if not exists drivers_user_id_idx on public.drivers(user_id);
create index if not exists drivers_is_online_idx on public.drivers(is_online);
create index if not exists driver_locations_driver_id_created_at_idx on public.driver_locations(driver_id, created_at desc);
create index if not exists ride_events_ride_id_created_at_idx on public.ride_events(ride_id, created_at desc);

-- RLS POLICIES

-- Profiles
create policy "Users can read own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Admins can read all profiles" on public.profiles
  for select using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Drivers
create policy "Anyone can read online drivers" on public.drivers
  for select using (is_online = true);

create policy "Drivers can update own record" on public.drivers
  for update using (user_id = auth.uid());

-- Rides
create policy "Customers can read own rides" on public.rides
  for select using (customer_id = auth.uid());

create policy "Drivers can read assigned or requested rides" on public.rides
  for select using (
    driver_id in (select id from public.drivers where user_id = auth.uid()) 
    or status = 'requested'
  );

create policy "Admins can read all rides" on public.rides
  for select using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "Customers can create rides" on public.rides
  for insert with check (customer_id = auth.uid());

-- RPC FUNCTIONS FOR SAFETY

-- Accept Ride
create or replace function public.accept_ride(p_ride_id uuid)
returns void as $$
declare
  v_driver_id uuid;
begin
  -- Get current user's driver ID
  select id into v_driver_id from public.drivers where user_id = auth.uid();
  
  if v_driver_id is null then
    raise exception 'User is not a driver';
  end if;

  update public.rides
  set 
    driver_id = v_driver_id,
    status = 'accepted',
    accepted_at = now(),
    updated_at = now()
  where id = p_ride_id and status = 'requested';

  if not found then
    raise exception 'Ride not found or already taken';
  end if;

  insert into public.ride_events (ride_id, actor_id, from_status, to_status, event_type)
  values (p_ride_id, auth.uid(), 'requested', 'accepted', 'ride_accepted');
end;
$$ language plpgsql security definer;

-- Update Ride Status
create or replace function public.update_ride_status(p_ride_id uuid, p_new_status text)
returns void as $$
begin
  update public.rides
  set 
    status = p_new_status,
    updated_at = now(),
    started_at = case when p_new_status = 'in_progress' then now() else started_at end,
    completed_at = case when p_new_status = 'completed' then now() else completed_at end
  where id = p_ride_id 
  and (
    driver_id in (select id from public.drivers where user_id = auth.uid())
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

  if not found then
    raise exception 'Ride not found or permission denied';
  end if;

  insert into public.ride_events (ride_id, actor_id, to_status, event_type)
  values (p_ride_id, auth.uid(), p_new_status, 'status_updated');
end;
$$ language plpgsql security definer;

-- Cancel Ride
create or replace function public.cancel_ride(p_ride_id uuid, p_reason text default null)
returns void as $$
begin
  update public.rides
  set 
    status = 'cancelled',
    cancelled_at = now(),
    updated_at = now(),
    cancellation_reason = p_reason
  where id = p_ride_id 
  and status in ('requested', 'accepted', 'driver_arriving')
  and (
    customer_id = auth.uid()
    or driver_id in (select id from public.drivers where user_id = auth.uid())
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

  if not found then
    raise exception 'Ride cannot be cancelled in current state';
  end if;

  insert into public.ride_events (ride_id, actor_id, to_status, event_type, message)
  values (p_ride_id, auth.uid(), 'cancelled', 'ride_cancelled', p_reason);
end;
$$ language plpgsql security definer;

-- Realtime enablement
alter publication supabase_realtime add table public.rides;
alter publication supabase_realtime add table public.drivers;
alter publication supabase_realtime add table public.driver_locations;
