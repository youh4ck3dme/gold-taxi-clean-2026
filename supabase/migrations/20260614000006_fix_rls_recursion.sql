-- Capture changes made directly to DB by external AI to fix RLS recursion (Error 42P17)

create schema if not exists private;

create or replace function private.is_admin()
returns boolean
language sql
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
  );
$$;

grant execute on function private.is_admin() to anon, authenticated;

-- Replace admin checks inside remaining policies to avoid reading public.profiles under RLS
drop policy if exists "Admins can read all profiles" on public.profiles;
create policy "Admins can read all profiles" on public.profiles
  using (private.is_admin());

drop policy if exists "Admins can read all rides" on public.rides;
create policy "Admins can read all rides" on public.rides
  using (private.is_admin());

create or replace function public.check_profile_update()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
begin
  if (NEW.role <> OLD.role) then
    if not private.is_admin() then
      NEW.role := OLD.role;
    end if;
  end if;
  return NEW;
end;
$$;

drop policy if exists "Users involved in ride can see events" on public.ride_events;
create policy "Users involved in ride can see events" on public.ride_events
  using (
    (
      exists (
        select 1
        from public.rides
        where rides.id = ride_events.ride_id
          and (
            rides.customer_id = auth.uid()
            or rides.driver_id in (
              select drivers.id from public.drivers where drivers.user_id = auth.uid()
            )
          )
      )
    )
    or private.is_admin()
  );

drop policy if exists "Customers can see assigned driver location" on public.driver_locations;
create policy "Customers can see assigned driver location" on public.driver_locations
  using (
    (
      exists (
        select 1
        from public.rides
        where rides.id = driver_locations.ride_id
          and rides.customer_id = auth.uid()
          and rides.status in ('accepted','driver_arriving','in_progress')
      )
    )
    or private.is_admin()
    or driver_locations.driver_id in (
      select drivers.id from public.drivers where drivers.user_id = auth.uid()
    )
  );
