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

-- 6. MESSAGES Table
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid references public.rides(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) not null,
  receiver_id uuid references public.profiles(id) not null,
  message text not null,
  created_at timestamptz default now() not null
);

alter table public.messages enable row level security;

-- Policies for Messages
create policy "Anyone involved in the ride can read messages" on public.messages
  for select using (
    exists (
      select 1 from public.rides r
      where r.id = ride_id
      and (
        r.customer_id = auth.uid()
        or r.driver_id in (select id from public.drivers d where d.user_id = auth.uid())
      )
    )
  );

create policy "Anyone involved in the ride can insert messages" on public.messages
  for insert with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.rides r
      where r.id = ride_id
      and (
        r.customer_id = auth.uid()
        or r.driver_id in (select id from public.drivers d where d.user_id = auth.uid())
      )
    )
  );

alter publication supabase_realtime add table public.messages;

-- Enable PostGIS extension
create extension if not exists postgis;

-- 7. OPERATING ZONES Table
create table if not exists public.operating_zones (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  zone_polygon geometry(Polygon, 4326) not null,
  base_surge_multiplier numeric default 1.0 not null,
  created_at timestamptz default now() not null
);

alter table public.operating_zones enable row level security;

-- Policies for Operating Zones
create policy "Anyone can read operating zones" on public.operating_zones
  for select using (true);

create policy "Admins can modify operating zones" on public.operating_zones
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Insert Košice operating zone (approximate polygon)
insert into public.operating_zones (name, zone_polygon, base_surge_multiplier)
values (
  'Košice',
  ST_GeomFromText('POLYGON((21.20 48.70, 21.30 48.70, 21.30 48.75, 21.20 48.75, 21.20 48.70))', 4326),
  1.0
) on conflict (name) do nothing;

-- Geofencing Check Function
create or replace function public.check_location_in_zone(p_lat double precision, p_lng double precision)
returns boolean as $$
declare
  v_in_zone boolean;
begin
  select exists (
    select 1 
    from public.operating_zones 
    where ST_Contains(zone_polygon, ST_SetSRID(ST_Point(p_lng, p_lat), 4326))
  ) into v_in_zone;
  return v_in_zone;
end;
$$ language plpgsql security definer;

-- Surge Pricing calculation function
create or replace function public.calculate_surge_pricing(p_lat double precision, p_lng double precision)
returns numeric as $$
declare
  v_zone_id uuid;
  v_active_requests integer;
  v_free_drivers integer;
  v_ratio numeric;
  v_multiplier numeric := 1.0;
begin
  -- Find zone
  select id into v_zone_id 
  from public.operating_zones 
  where ST_Contains(zone_polygon, ST_SetSRID(ST_Point(p_lng, p_lat), 4326)) 
  limit 1;
  
  if v_zone_id is null then
    return 1.0;
  end if;

  -- Count active ride requests (within the last 30 minutes, status = 'requested')
  select count(*) into v_active_requests 
  from public.rides 
  where status = 'requested' 
  and created_at > now() - interval '30 minutes';

  -- Count free/online drivers
  select count(*) into v_free_drivers 
  from public.drivers 
  where is_online = true 
  and id not in (
    select distinct driver_id 
    from public.rides 
    where status in ('accepted', 'driver_arriving', 'in_progress') 
    and driver_id is not null
  );

  -- Determine multiplier
  if v_free_drivers = 0 then
    if v_active_requests > 0 then
      v_multiplier := 2.0;
    else
      v_multiplier := 1.0;
    end if;
  else
    v_ratio := v_active_requests::numeric / v_free_drivers::numeric;
    if v_ratio >= 1.5 then
      v_multiplier := 1.8;
    elsif v_ratio >= 1.0 then
      v_multiplier := 1.5;
    elsif v_ratio >= 0.5 then
      v_multiplier := 1.3;
    else
      v_multiplier := 1.0;
    end if;
  end if;

  return v_multiplier;
end;
$$ language plpgsql security definer;

-- 8. DRIVER VERIFICATION & KYC
alter table public.drivers add column if not exists verification_status text not null check (verification_status in ('pending_verification', 'active', 'suspended')) default 'pending_verification';

create table if not exists public.driver_documents (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid references public.drivers(id) on delete cascade not null unique,
  profile_photo_url text,
  id_card_url text,
  license_url text,
  uploaded_at timestamptz default now() not null
);

alter table public.driver_documents enable row level security;

-- Policies for Driver Documents
create policy "Drivers can read own documents" on public.driver_documents
  for select using (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

create policy "Drivers can upload/modify own documents" on public.driver_documents
  for all using (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

-- Create bucket for driver documents if not exists
insert into storage.buckets (id, name, public) 
values ('driver-documents', 'driver-documents', false)
on conflict (id) do nothing;

-- Add storage policies for the bucket
create policy "Drivers can upload their own documents"
on storage.objects for insert
with check (
  bucket_id = 'driver-documents' 
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Drivers can view their own documents"
on storage.objects for select
using (
  bucket_id = 'driver-documents' 
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- 9. EARNINGS & PAYOUTS TABLES FOR DRIVER FINANCE

-- Driver Earnings Table (per ride breakdown)
create table if not exists public.driver_earnings (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid references public.rides(id) on delete cascade not null,
  driver_id uuid references public.drivers(id) on delete cascade not null,
  total_amount numeric(10, 2) not null,           -- Total paid by customer
  app_fee numeric(10, 2) not null,               -- Application fee (e.g., 15%)
  net_amount numeric(10, 2) not null,            -- Driver's net earnings
  payment_status text not null check (payment_status in ('pending', 'completed', 'failed', 'refunded')) default 'pending',
  payment_method text not null check (payment_method in ('cash', 'card', 'stripe')) default 'cash',
  created_at timestamptz default now() not null
);

alter table public.driver_earnings enable row level security;

-- Policies for Driver Earnings
create policy "Drivers can view own earnings" on public.driver_earnings
  for select using (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

create policy "Drivers can insert own earnings" on public.driver_earnings
  for insert with check (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

-- Payouts Table
create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid references public.drivers(id) on delete cascade not null,
  amount numeric(10, 2) not null,                 -- Total payout amount
  stripe_payout_id text,                          -- Stripe Connect payout ID
  bank_account_last4 text,                       -- Last 4 digits of bank account
  status text not null check (status in ('pending', 'in_transit', 'paid', 'failed', 'cancelled')) default 'pending',
  requested_at timestamptz default now() not null,
  completed_at timestamptz,
  created_at timestamptz default now() not null
);

alter table public.payouts enable row level security;

-- Policies for Payouts
create policy "Drivers can view own payouts" on public.payouts
  for select using (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

create policy "Drivers can create own payouts" on public.payouts
  for insert with check (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

-- Enable Realtime for earnings and payouts
alter publication supabase_realtime add table public.driver_earnings;
alter publication supabase_realtime add table public.payouts;

-- RPC Function: Get driver earnings summary (today, week, month)
create or replace function public.get_driver_earnings_summary(p_driver_id uuid)
returns json as $$
declare
  v_today numeric := 0;
  v_week numeric := 0;
  v_month numeric := 0;
  v_total numeric := 0;
begin
  -- Today's earnings (net amount)
  select coalesce(sum(net_amount), 0) into v_today
  from public.driver_earnings
  where driver_id = p_driver_id
  and created_at >= date_trunc('day', now())
  and payment_status = 'completed';

  -- This week's earnings
  select coalesce(sum(net_amount), 0) into v_week
  from public.driver_earnings
  where driver_id = p_driver_id
  and created_at >= date_trunc('week', now())
  and payment_status = 'completed';

  -- This month's earnings
  select coalesce(sum(net_amount), 0) into v_month
  from public.driver_earnings
  where driver_id = p_driver_id
  and created_at >= date_trunc('month', now())
  and payment_status = 'completed';

  -- Total earnings
  select coalesce(sum(net_amount), 0) into v_total
  from public.driver_earnings
  where driver_id = p_driver_id
  and payment_status = 'completed';

  return json_build_object(
    'today', v_today,
    'this_week', v_week,
    'this_month', v_month,
    'total', v_total
  );
end;
$$ language plpgsql security definer;

-- RPC Function: Request payout via Stripe Connect
create or replace function public.request_driver_payout(
  p_driver_id uuid,
  p_amount numeric(10, 2),
  p_stripe_account_id text
)
returns json as $$
declare
  v_payout_id text;
  v_status text;
  v_error text;
begin
  -- Create payout record
  insert into public.payouts (driver_id, amount, status, stripe_payout_id)
  values (p_driver_id, p_amount, 'pending', null)
  returning id, stripe_payout_id, status into v_payout_id, v_stripe_payout_id, v_status;

  -- In a real implementation with Stripe Connect, you would:
  -- 1. Call Stripe API to create a Transfer to the connected account
  -- 2. Update the payout record with the Stripe payout ID
  -- 3. Update status to 'in_transit' or 'paid'
  -- For now, we simulate this by returning the created record
  
  return json_build_object(
    'payout_id', v_payout_id,
    'status', 'pending',
    'message', 'Payout request created. In production, this would call Stripe Connect API.'
  );
end;
$$ language plpgsql security definer;

-- RPC Function: Get ride earnings breakdown
create or replace function public.get_ride_earnings_breakdown(p_ride_id uuid)
returns json as $$
declare
  v_earning record;
begin
  select * into v_earning
  from public.driver_earnings
  where ride_id = p_ride_id
  limit 1;

  if v_earning is null then
    return json_build_object(
      'error', 'No earnings record found for this ride'
    );
  end if;

  return json_build_object(
    'ride_id', v_earning.ride_id,
    'total_amount', v_earning.total_amount,
    'app_fee', v_earning.app_fee,
    'net_amount', v_earning.net_amount,
    'payment_status', v_earning.payment_status,
    'payment_method', v_earning.payment_method
  );
end;
$$ language plpgsql security definer;

-- Indexes for performance on earnings and payouts
create index if not exists idx_driver_earnings_driver_id on public.driver_earnings(driver_id);
create index if not exists idx_payouts_driver_id on public.payouts(driver_id);

-- RLS update policy for drivers to change ride status
create policy "Drivers can update own assigned rides" on public.rides
  for update using (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );


-- ============================================================================
-- MISSING INDEXES AND POLICIES (Added for Performance & Security)
-- ============================================================================

-- 1. INDEXES FOR PERFORMANCE

-- Rides table indexes
create index if not exists idx_rides_customer_id on public.rides(customer_id);
create index if not exists idx_rides_driver_id on public.rides(driver_id);
create index if not exists idx_rides_status on public.rides(status);
create index if not exists idx_rides_created_at on public.rides(created_at);
create index if not exists idx_rides_pickup_location on public.rides(pickup_lat, pickup_lng);

-- Messages table indexes
create index if not exists idx_messages_ride_id on public.messages(ride_id);
create index if not exists idx_messages_sender_id on public.messages(sender_id);
create index if not exists idx_messages_created_at on public.messages(created_at);

-- Driver Locations table indexes
create index if not exists idx_driver_locations_driver_id on public.driver_locations(driver_id);
create index if not exists idx_driver_locations_created_at on public.driver_locations(created_at);

-- Operating Zones table indexes
create index if not exists idx_operating_zones_name on public.operating_zones(name);
create index if not exists idx_operating_zones_geometry on public.operating_zones using gist(zone_polygon);

-- Driver Earnings table indexes
create index if not exists idx_driver_earnings_driver_id on public.driver_earnings(driver_id);
create index if not exists idx_driver_earnings_ride_id on public.driver_earnings(ride_id);
create index if not exists idx_driver_earnings_created_at on public.driver_earnings(created_at);
create index if not exists idx_driver_earnings_payment_status on public.driver_earnings(payment_status);

-- Payouts table indexes
create index if not exists idx_payouts_driver_id on public.payouts(driver_id);
create index if not exists idx_payouts_status on public.payouts(status);
create index if not exists idx_payouts_requested_at on public.payouts(requested_at);

-- 2. MISSING RLS POLICY FOR RIDES TABLE

-- Allow drivers to view their own rides
create policy "Drivers can view own rides" on public.rides
  for select using (
    driver_id in (select id from public.drivers where user_id = auth.uid())
    or customer_id = auth.uid()
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Allow drivers to update their own ride status
create policy "Drivers can update own ride status" on public.rides
  for update to status using (
    driver_id in (select id from public.drivers where user_id = auth.uid())
    and old.status in ('accepted', 'driver_arriving', 'in_progress')
  );

-- 3. BANK ACCOUNTS TABLE FOR STRIPE CONNECT

create table if not exists public.driver_bank_accounts (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid references public.drivers(id) on delete cascade not null unique,
  stripe_account_id text not null unique,
  bank_account_id text,
  bank_account_last4 text,
  bank_name text,
  account_holder_name text,
  account_holder_type text not null check (account_holder_type in ('individual', 'company')) default 'individual',
  currency text not null default 'eur',
  status text not null check (status in ('pending', 'verified', 'failed', 'revoked', 'disabled')) default 'pending',
  verification_document_url text,
  payout_enabled boolean default false,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

alter table public.driver_bank_accounts enable row level security;

-- Policies for Driver Bank Accounts
create policy "Drivers can view own bank account" on public.driver_bank_accounts
  for select using (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

create policy "Drivers can create own bank account" on public.driver_bank_accounts
  for insert with check (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

create policy "Drivers can update own bank account" on public.driver_bank_accounts
  for update using (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

-- Enable Realtime for bank accounts
alter publication supabase_realtime add table public.driver_bank_accounts;

-- Indexes for driver_bank_accounts
create index if not exists idx_driver_bank_accounts_driver_id on public.driver_bank_accounts(driver_id);
create index if not exists idx_driver_bank_accounts_stripe_account_id on public.driver_bank_accounts(stripe_account_id);
create index if not exists idx_driver_bank_accounts_status on public.driver_bank_accounts(status);
create index if not exists idx_driver_bank_accounts_payout_enabled on public.driver_bank_accounts(payout_enabled);

-- =========================================================================
-- 4. PROMO CODES & REFERRAL SYSTEM
-- =========================================================================

-- Add columns to public.profiles
alter table public.profiles add column if not exists referral_code text unique;
alter table public.profiles add column if not exists referred_by uuid references public.profiles(id);

-- Promo Codes Table
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

create policy "Anyone can view active promo codes" on public.promo_codes
  for select using (valid_until > now());

-- User Promos Table
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

create policy "Users can view own promo usage" on public.user_promos
  for select using (auth.uid() = user_id);

create policy "Users can record promo usage" on public.user_promos
  for insert with check (auth.uid() = user_id);

-- Function to validate promo code
create or replace function public.validate_promo_code(
  p_user_id uuid,
  p_code text,
  p_ride_amount numeric
) returns table (
  id uuid,
  code text,
  discount_percentage numeric,
  discount_amount numeric,
  calculated_discount numeric,
  is_valid boolean,
  error_message text
) language plpgsql security definer as $$
declare
  v_promo_id uuid;
  v_pct numeric;
  v_amt numeric;
  v_valid_until timestamptz;
  v_max_uses int;
  v_current_uses int;
  v_user_uses int;
begin
  -- Find promo code (case insensitive matching)
  select p.id, p.discount_percentage, p.discount_amount, p.valid_until, p.max_uses
  into v_promo_id, v_pct, v_amt, v_valid_until, v_max_uses
  from public.promo_codes p
  where upper(p.code) = upper(p_code);

  if v_promo_id is null then
    -- Check if it's a referral code of another user
    declare
      v_referrer_id uuid;
    begin
      select p.id into v_referrer_id
      from public.profiles p
      where upper(p.referral_code) = upper(p_code);

      if v_referrer_id is not null then
        if v_referrer_id = p_user_id then
          return query select null::uuid, p_code, 0::numeric, 0::numeric, 0::numeric, false, 'Nemôžete použiť vlastný referenčný kód'::text;
          return;
        end if;

        -- Referrals give flat 5 EUR discount as standard reward
        -- Check if user has already been referred
        select count(*)::int into v_user_uses
        from public.profiles
        where id = p_user_id and referred_by is not null;
        
        if v_user_uses > 0 then
          return query select null::uuid, p_code, 0::numeric, 0::numeric, 0::numeric, false, 'Už ste využili referenčnú zľavu'::text;
          return;
        end if;

        return query select null::uuid, p_code, 0::numeric, 5.00::numeric, 5.00::numeric, true, null::text;
        return;
      end if;
    end;

    return query select null::uuid, p_code, 0::numeric, 0::numeric, 0::numeric, false, 'Neplatný kód'::text;
    return;
  end if;

  -- Check validity date
  if v_valid_until < now() then
    return query select v_promo_id, p_code, v_pct, v_amt, 0::numeric, false, 'Platnosť kódu vypršala'::text;
    return;
  end if;

  -- Check max uses
  if v_max_uses > 0 then
    select count(*)::int into v_current_uses
    from public.user_promos
    where promo_code_id = v_promo_id;
    if v_current_uses >= v_max_uses then
      return query select v_promo_id, p_code, v_pct, v_amt, 0::numeric, false, 'Kód bol už plne využitý'::text;
      return;
    end if;
  end if;

  -- Check if current user already used it
  select count(*)::int into v_user_uses
  from public.user_promos
  where promo_code_id = v_promo_id and user_id = p_user_id;
  if v_user_uses > 0 then
    return query select v_promo_id, p_code, v_pct, v_amt, 0::numeric, false, 'Tento kód ste už využili'::text;
    return;
  end if;

  -- Calculate discount
  declare
    v_discount numeric := 0;
  begin
    if v_pct > 0 then
      v_discount := round(p_ride_amount * (v_pct / 100.0), 2);
    elsif v_amt > 0 then
      v_discount := least(v_amt, p_ride_amount);
    end if;
    
    return query select v_promo_id, p_code, v_pct, v_amt, v_discount, true, null::text;
  end;
end;
$$;

-- Trigger/Function to set referral code for new profiles
create or replace function public.generate_referral_code_for_profile()
returns trigger as $$
declare
  v_code text;
  v_exists boolean;
begin
  if new.referral_code is null then
    loop
      -- Generate random uppercase code like 'GOLD12'
      v_code := upper(substring(coalesce(new.full_name, 'GOLD'), 1, 4)) || floor(random() * 90 + 10)::text;
      
      select exists(select 1 from public.profiles where referral_code = v_code) into v_exists;
      if not v_exists then
        new.referral_code := v_code;
        exit;
      end if;
    end loop;
  end if;
  return new;
end;
$$ language plpgsql;

create or replace trigger tr_generate_referral_code
  before insert on public.profiles
  for each row execute function public.generate_referral_code_for_profile();

-- Add default promo codes for testing/demo
insert into public.promo_codes (code, discount_percentage, discount_amount, valid_until, max_uses)
values 
  ('ZNAK10', 10.00, 0.00, now() + interval '1 year', 100),
  ('TAXI5', 0.00, 5.00, now() + interval '1 year', 500)
on conflict (code) do nothing;

-- =========================================================================
-- 5. MULTI-STOP ROUTING
-- =========================================================================
alter table public.rides add column if not exists stops jsonb default '[]'::jsonb;
