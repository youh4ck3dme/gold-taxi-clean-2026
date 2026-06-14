-- SUPABASE HARDENING MIGRATION
-- Phase 4: Security & Privacy Improvements

-- 1. Fix Profiles Role Escalation
create or replace function public.check_profile_update()
returns trigger as $$
begin
  -- Prevent non-admins from changing roles
  if (NEW.role <> OLD.role) then
    if not exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') then
      NEW.role := OLD.role;
    end if;
  end if;
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_profile_update on public.profiles;
create trigger on_profile_update
  before update on public.profiles
  for each row execute function public.check_profile_update();

-- 2. Ride Events Policies
create policy "Users involved in ride can see events" on public.ride_events
  for select using (
    exists (
      select 1 from public.rides 
      where id = ride_id 
      and (customer_id = auth.uid() or driver_id in (select id from public.drivers where user_id = auth.uid()))
    )
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- 3. Driver Locations Privacy & Policies
drop policy if exists "Anyone can read locations" on public.driver_locations; -- Remove any permissive ones

create policy "Customers can see assigned driver location" on public.driver_locations
  for select using (
    exists (
      select 1 from public.rides 
      where id = ride_id 
      and customer_id = auth.uid()
      and status in ('accepted', 'driver_arriving', 'in_progress')
    )
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or driver_id in (select id from public.drivers where user_id = auth.uid())
  );

create policy "Drivers can insert own location" on public.driver_locations
  for insert with check (
    driver_id in (select id from public.drivers where user_id = auth.uid())
  );

-- 4. Refined accept_ride RPC (Double-booking protection)
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

  -- Atomic update with status AND null check
  update public.rides
  set 
    driver_id = v_driver_id,
    status = 'accepted',
    accepted_at = now(),
    updated_at = now()
  where id = p_ride_id 
    and status = 'requested' 
    and driver_id is null;

  if not found then
    raise exception 'Ride not found, already taken, or cancelled';
  end if;

  insert into public.ride_events (ride_id, actor_id, from_status, to_status, event_type)
  values (p_ride_id, auth.uid(), 'requested', 'accepted', 'ride_accepted');
end;
$$ language plpgsql security definer;
