begin;

do $$
begin
  if to_regclass('public.spatial_ref_sys') is not null then
    execute 'revoke all on table public.spatial_ref_sys from anon';
    execute 'revoke all on table public.spatial_ref_sys from authenticated';
    execute 'alter table public.spatial_ref_sys enable row level security';
  end if;
end
$$;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "Admins can read all profiles" on public.profiles;
create policy "Admins can read all profiles"
on public.profiles
for select
to authenticated
using (private.is_admin());

drop policy if exists "Drivers can read profiles of active riders" on public.profiles;
create policy "Drivers can read profiles of active riders"
on public.profiles
for select
to authenticated
using (
  private.is_active_rider_for_driver(id, (select auth.uid()))
);

drop policy if exists "Drivers can update own record" on public.drivers;
create policy "Drivers can update own record"
on public.drivers
for update
to authenticated
using ((user_id = (select auth.uid())));

drop policy if exists "Customers can read own rides" on public.rides;
create policy "Customers can read own rides"
on public.rides
for select
to authenticated
using ((customer_id = (select auth.uid())));

drop policy if exists "Drivers can read assigned or requested rides" on public.rides;
create policy "Drivers can read assigned or requested rides"
on public.rides
for select
to authenticated
using (
  driver_id in (
    select id
    from public.drivers
    where user_id = (select auth.uid())
  )
  or status = 'requested'
);

drop policy if exists "Admins can read all rides" on public.rides;
create policy "Admins can read all rides"
on public.rides
for select
to authenticated
using (private.is_admin());

drop policy if exists "Customers can create rides" on public.rides;
create policy "Customers can create rides"
on public.rides
for insert
to authenticated
with check ((customer_id = (select auth.uid())));

drop policy if exists "Drivers can update assigned or requested rides" on public.rides;
create policy "Drivers can update assigned or requested rides"
on public.rides
for update
to authenticated
using (
  private.driver_id_for_user((select auth.uid())) is not null
  and (
    driver_id = private.driver_id_for_user((select auth.uid()))
    or (
      driver_id is null
      and status::text = 'requested'
    )
  )
)
with check (
  driver_id = private.driver_id_for_user((select auth.uid()))
);

drop policy if exists "Customers can cancel own requested rides" on public.rides;
create policy "Customers can cancel own requested rides"
on public.rides
for update
to authenticated
using (
  customer_id = (select auth.uid())
  and status::text in ('requested', 'accepted')
)
with check (
  customer_id = (select auth.uid())
  and status::text = 'cancelled'
);

drop policy if exists "Users involved in ride can see events" on public.ride_events;
create policy "Users involved in ride can see events"
on public.ride_events
for select
to authenticated
using (
  exists (
    select 1
    from public.rides
    where rides.id = ride_events.ride_id
      and (
        customer_id = (select auth.uid())
        or driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
      )
  )
  or private.is_admin()
);

drop policy if exists "Customers can see assigned driver location" on public.driver_locations;
create policy "Customers can see assigned driver location"
on public.driver_locations
for select
to authenticated
using (
  exists (
    select 1
    from public.rides
    where rides.id = driver_locations.ride_id
      and rides.customer_id = (select auth.uid())
      and rides.status in ('accepted', 'driver_arriving', 'in_progress')
  )
  or private.is_admin()
  or driver_locations.driver_id in (
    select id
    from public.drivers
    where user_id = (select auth.uid())
  )
);

drop policy if exists "Drivers can insert own location" on public.driver_locations;
create policy "Drivers can insert own location"
on public.driver_locations
for insert
to authenticated
with check (
  driver_id in (
    select id
    from public.drivers
    where user_id = (select auth.uid())
  )
);

commit;

notify pgrst, 'reload schema';
