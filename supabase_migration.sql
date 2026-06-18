-- SUPABASE MIGRATION SQL for Gold-Taxi
-- Phase 3: Realtime Backend & Geospatial Optimization

-- Enable PostGIS extension
create extension if not exists postgis;

-- 1. PROFILES Table
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  full_name text,
  phone text,
  role text not null check (role in ('customer', 'driver', 'admin')) default 'customer',
  avatar_url text,
  saved_addresses jsonb default '{}'::jsonb,
  referral_code text unique,
  referred_by uuid references public.profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

-- 2. VEHICLES Table
create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  make text not null,
  model text not null,
  color text,
  plate_number text unique not null,
  year integer,
  vehicle_class text check (vehicle_class in ('standard', 'comfort', 'premium')) default 'standard',
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.vehicles enable row level security;

-- 3. DRIVERS Table
create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade unique,
  display_name text not null,
  phone text,
  active_vehicle_id uuid references public.vehicles(id),
  service_classes text[] default '{standard}',
  is_online boolean default false,
  verification_status text not null check (verification_status in ('pending_verification', 'active', 'suspended')) default 'pending_verification',
  -- Geospatial location using geography for high accuracy distance queries
  current_location geography(Point, 4326),
  last_location_update timestamptz,
  updated_at timestamptz default now()
);

alter table public.drivers enable row level security;

-- 4. RIDES Table
create table if not exists public.rides (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id),
  driver_id uuid references public.drivers(id),
  vehicle_id uuid references public.vehicles(id),
  pickup_address text not null,
  pickup_location geography(Point, 4326) not null,
  dropoff_address text not null,
  dropoff_location geography(Point, 4326) not null,
  stops jsonb default '[]'::jsonb,
  service_type text not null check (service_type in ('standard', 'comfort', 'premium')),
  estimated_distance_km numeric,
  estimated_duration_min numeric,
  estimated_price numeric,
  final_price numeric,
  status text not null check (status in ('requested', 'accepted', 'driver_arriving', 'in_progress', 'completed', 'cancelled')) default 'requested',
  cancellation_reason text,
  rating integer check (rating >= 1 and rating <= 5),
  review_text text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  accepted_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz
);

alter table public.rides enable row level security;

-- 5. RIDE_EVENTS Table
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

-- 6. DRIVER_LOCATIONS Table (History/Tracking)
create table if not exists public.driver_locations (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid references public.drivers(id) on delete cascade,
  ride_id uuid references public.rides(id) on delete set null,
  location geography(Point, 4326) not null,
  heading numeric,
  speed numeric,
  created_at timestamptz default now()
);

alter table public.driver_locations enable row level security;

-- 7. MESSAGES Table
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid references public.rides(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) not null,
  receiver_id uuid references public.profiles(id) not null,
  message text not null,
  created_at timestamptz default now() not null
);

alter table public.messages enable row level security;

-- 8. OPERATING ZONES Table
create table if not exists public.operating_zones (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  zone_polygon geography(Polygon, 4326) not null,
  base_surge_multiplier numeric default 1.0 not null,
  is_active boolean default true,
  created_at timestamptz default now() not null
);

alter table public.operating_zones enable row level security;

-- 9. DRIVER DOCUMENTS Table
create table if not exists public.driver_documents (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid references public.drivers(id) on delete cascade not null unique,
  profile_photo_url text,
  id_card_url text,
  license_url text,
  vehicle_insurance_url text,
  uploaded_at timestamptz default now() not null
);

alter table public.driver_documents enable row level security;

-- 10. DRIVER FINANCE (Earnings & Payouts)
create table if not exists public.driver_earnings (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid references public.rides(id) on delete cascade not null,
  driver_id uuid references public.drivers(id) on delete cascade not null,
  total_amount numeric(10, 2) not null,
  app_fee numeric(10, 2) not null,
  net_amount numeric(10, 2) not null,
  payment_status text not null check (payment_status in ('pending', 'completed', 'failed', 'refunded')) default 'pending',
  payment_method text not null check (payment_method in ('cash', 'card', 'stripe')) default 'cash',
  created_at timestamptz default now() not null
);

alter table public.driver_earnings enable row level security;

create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid references public.drivers(id) on delete cascade not null,
  amount numeric(10, 2) not null,
  stripe_payout_id text,
  status text not null check (status in ('pending', 'in_transit', 'paid', 'failed', 'cancelled')) default 'pending',
  requested_at timestamptz default now() not null,
  completed_at timestamptz,
  created_at timestamptz default now() not null
);

alter table public.payouts enable row level security;

-- 11. PROMO CODES
create table if not exists public.promo_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  discount_percentage numeric(5, 2) check (discount_percentage >= 0 and discount_percentage <= 100) default 0.0,
  discount_amount numeric(10, 2) check (discount_amount >= 0) default 0.0,
  valid_until timestamptz not null,
  max_uses integer default 0,
  created_at timestamptz default now() not null
);

alter table public.promo_codes enable row level security;

create table if not exists public.user_promos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  promo_code_id uuid references public.promo_codes(id) on delete cascade not null,
  used_at timestamptz default now() not null,
  ride_id uuid references public.rides(id) on delete set null,
  created_at timestamptz default now() not null,
  unique (user_id, promo_code_id)
);

alter table public.user_promos enable row level security;

-- 12. BLOG Table (Posts)
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text,
  excerpt text,
  featured_image_url text,
  author_id uuid references public.profiles(id),
  category text,
  tags text[],
  status text check (status in ('draft', 'published')) default 'published',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.posts enable row level security;

-- 13. PRODUCTS Table
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price numeric(10, 2) not null,
  image_url text,
  category text,
  is_available boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.products enable row level security;

-- 14. FAQs Table
create table if not exists public.faqs (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  answer text not null,
  category text,
  order_index integer default 0,
  created_at timestamptz default now()
);

alter table public.faqs enable row level security;

-- 15. BOOKINGS Table (Scheduled Services)
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.profiles(id) on delete cascade,
  service_type text not null,
  booking_date timestamptz not null,
  status text check (status in ('pending', 'confirmed', 'completed', 'cancelled')) default 'pending',
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.bookings enable row level security;

-- INDEXES
create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_drivers_is_online on public.drivers(is_online);
create index if not exists idx_drivers_location on public.drivers using gist(current_location);
create index if not exists idx_rides_customer on public.rides(customer_id);
create index if not exists idx_rides_driver on public.rides(driver_id);
create index if not exists idx_rides_status on public.rides(status);
create index if not exists idx_rides_pickup on public.rides using gist(pickup_location);
create index if not exists idx_operating_zones_geom on public.operating_zones using gist(zone_polygon);
create index if not exists idx_messages_ride on public.messages(ride_id);

-- RLS POLICIES

-- Profiles: Users see own, Admins see all
create policy "Users can manage own profile" on public.profiles
  for all using (auth.uid() = id);

create policy "Admins can manage all profiles" on public.profiles
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Vehicles: Public read, Admins manage
create policy "Anyone can see vehicles" on public.vehicles for select using (true);
create policy "Admins can manage vehicles" on public.vehicles for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

-- Drivers: Online drivers public, Users manage own
create policy "Anyone can see online drivers" on public.drivers for select using (is_online = true);
create policy "Drivers can manage own record" on public.drivers for all using (user_id = auth.uid());

-- Rides: Customer/Driver involved or Admin
create policy "Users can see involved rides" on public.rides for select using (
    customer_id = auth.uid() 
    or driver_id in (select id from public.drivers where user_id = auth.uid())
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

create policy "Customers can create rides" on public.rides for insert with check (customer_id = auth.uid());

-- Blog: Public read, Admins manage
create policy "Anyone can read published posts" on public.posts for select using (status = 'published');
create policy "Admins can manage posts" on public.posts for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

-- Products: Public read, Admins manage
create policy "Anyone can read available products" on public.products for select using (is_available = true);
create policy "Admins can manage products" on public.products for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

-- FAQs: Public read, Admins manage
create policy "Anyone can read faqs" on public.faqs for select using (true);
create policy "Admins can manage faqs" on public.faqs for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

-- Bookings: Customers see own, Admins see all
create policy "Users can see own bookings" on public.bookings for select using (customer_id = auth.uid());
create policy "Admins can see all bookings" on public.bookings for select using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);
create policy "Customers can create bookings" on public.bookings for insert with check (customer_id = auth.uid());

-- RPC FUNCTIONS

-- Find Nearest Drivers
create or replace function public.find_nearest_drivers(p_lat double precision, p_lng double precision, p_limit integer default 10)
returns table (
  id uuid,
  display_name text,
  dist_meters float,
  lat double precision,
  lng double precision
) as $$
begin
  return query
  select 
    d.id,
    d.display_name,
    ST_Distance(d.current_location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography) as dist_meters,
    ST_Y(d.current_location::geometry) as lat,
    ST_X(d.current_location::geometry) as lng
  from public.drivers d
  where d.is_online = true and d.verification_status = 'active'
  order by d.current_location <-> ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
  limit p_limit;
end;
$$ language plpgsql security definer;

-- Accept Ride (with vehicle assignment)
create or replace function public.accept_ride(p_ride_id uuid)
returns void as $$
declare
  v_driver record;
begin
  select id, active_vehicle_id into v_driver from public.drivers where user_id = auth.uid();
  
  if v_driver.id is null then
    raise exception 'User is not a driver';
  end if;

  update public.rides
  set 
    driver_id = v_driver.id,
    vehicle_id = v_driver.active_vehicle_id,
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

-- Realtime Configuration
begin;
  drop publication if exists supabase_realtime;
  create publication supabase_realtime;
  alter publication supabase_realtime add table public.rides, public.drivers, public.driver_locations, public.messages;
commit;
