-- Supabase Migration: Phase 2 Driver Mode and Realtime Ride Queue updates

-- 1. Add passenger_note column to rides table if not exists
alter table public.rides add column if not exists passenger_note text;

-- 2. Drop existing accept_ride functions (to avoid parameter signature conflicts)
drop function if exists public.accept_ride(uuid);

-- 3. Create updated accept_ride RPC returning the public.rides row
create or replace function public.accept_ride(p_ride_id uuid)
returns public.rides
language plpgsql
security definer
set search_path = public
as $$
declare
  v_driver_id uuid;
  v_ride public.rides;
begin
  -- Get the driver ID associated with the current authenticated user
  select id into v_driver_id from public.drivers where user_id = auth.uid();
  
  if v_driver_id is null then
    raise exception 'User is not a driver';
  end if;

  -- Atomic update: only update if status is 'requested' and no driver is assigned
  update public.rides
  set 
    driver_id = v_driver_id,
    status = 'accepted',
    accepted_at = now(),
    updated_at = now()
  where id = p_ride_id 
    and status = 'requested' 
    and driver_id is null
  returning * into v_ride;

  if v_ride.id is null then
    raise exception 'Ride is no longer available';
  end if;

  -- Insert ride event to record acceptance
  insert into public.ride_events (ride_id, actor_id, from_status, to_status, event_type)
  values (p_ride_id, auth.uid(), 'requested', 'accepted', 'ride_accepted');

  return v_ride;
end;
$$;

-- Grant execution permissions
grant execute on function public.accept_ride(uuid) to authenticated;

-- 4. Enable RLS policy for drivers to read passenger profiles using a security definer helper to avoid infinite recursion
create or replace function private.is_active_rider_for_driver(p_profile_id uuid, p_auth_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.rides r
    where r.customer_id = p_profile_id
      and (
        r.status = 'requested'
        or r.driver_id in (select id from public.drivers where user_id = p_auth_id)
      )
  );
$$;

grant execute on function private.is_active_rider_for_driver(uuid, uuid) to authenticated;

drop policy if exists "Drivers can read profiles of active riders" on public.profiles;

create policy "Drivers can read profiles of active riders" on public.profiles
  for select using (
    private.is_active_rider_for_driver(id, auth.uid())
  );
