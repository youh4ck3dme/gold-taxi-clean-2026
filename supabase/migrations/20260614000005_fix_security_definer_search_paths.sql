-- Fix Supabase Security Advisor Lints: "SECURITY DEFINER functions must have a search_path"
-- We are explicitly setting the search_path to 'public, private, pg_catalog' for all SECURITY DEFINER functions.
-- We are NOT revoking execute from authenticated for update_ride_status, since it is used by the client.

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
$$ language plpgsql security definer set search_path = public, private, pg_catalog;


create or replace function public.update_ride_status(p_ride_id uuid, p_new_status text)
returns void as $$
begin
  update public.rides 
  set status = p_new_status, 
      updated_at = now(), 
      started_at = case when p_new_status = 'in_progress' then now() else started_at end, 
      completed_at = case when p_new_status = 'completed' then now() else completed_at end 
  where id = p_ride_id 
    and (driver_id in (select id from public.drivers where user_id = auth.uid()) or private.is_admin());
  
  if not found then
    raise exception 'Ride not found or permission denied';
  end if;
  
  insert into public.ride_events (ride_id, actor_id, to_status, event_type) 
  values (p_ride_id, auth.uid(), p_new_status, 'status_updated');
end;
$$ language plpgsql security definer set search_path = public, private, pg_catalog;


create or replace function public.cancel_ride(p_ride_id uuid, p_reason text default null)
returns void as $$
begin
  update public.rides 
  set status = 'cancelled', 
      cancelled_at = now(), 
      updated_at = now(), 
      cancellation_reason = p_reason 
  where id = p_ride_id 
    and status in ('requested', 'accepted', 'driver_arriving') 
    and (customer_id = auth.uid() or driver_id in (select id from public.drivers where user_id = auth.uid()) or private.is_admin());
  
  if not found then
    raise exception 'Ride cannot be cancelled in current state';
  end if;
  
  insert into public.ride_events (ride_id, actor_id, to_status, event_type, message) 
  values (p_ride_id, auth.uid(), 'cancelled', 'ride_cancelled', p_reason);
end;
$$ language plpgsql security definer set search_path = public, private, pg_catalog;
