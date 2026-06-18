begin;

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

do $$
begin
  if to_regclass('public.messages') is not null then
    execute 'alter table public.messages enable row level security';
    execute 'drop policy if exists "Users involved in ride can see messages" on public.messages';
    execute $policy$
      create policy "Users involved in ride can see messages"
      on public.messages
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.rides
          where rides.id = messages.ride_id
            and (
              rides.customer_id = (select auth.uid())
              or rides.driver_id in (
                select id
                from public.drivers
                where user_id = (select auth.uid())
              )
            )
        )
        or sender_id = (select auth.uid())
        or receiver_id = (select auth.uid())
        or private.is_admin()
      )
    $policy$;
    execute 'drop policy if exists "Users involved in ride can send messages" on public.messages';
    execute $policy$
      create policy "Users involved in ride can send messages"
      on public.messages
      for insert
      to authenticated
      with check (
        sender_id = (select auth.uid())
        and exists (
          select 1
          from public.rides
          where rides.id = messages.ride_id
            and (
              (
                rides.customer_id = (select auth.uid())
                and rides.driver_id in (
                  select id
                  from public.drivers
                  where user_id = messages.receiver_id
                )
              )
              or (
                rides.driver_id in (
                  select id
                  from public.drivers
                  where user_id = (select auth.uid())
                )
                and rides.customer_id = messages.receiver_id
              )
            )
        )
      )
    $policy$;
  end if;

  if to_regclass('public.driver_documents') is not null then
    execute 'alter table public.driver_documents enable row level security';
    execute 'drop policy if exists "Drivers can read own documents" on public.driver_documents';
    execute $policy$
      create policy "Drivers can read own documents"
      on public.driver_documents
      for select
      to authenticated
      using (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
        or private.is_admin()
      )
    $policy$;
    execute 'drop policy if exists "Drivers can manage own documents" on public.driver_documents';
    execute $policy$
      create policy "Drivers can manage own documents"
      on public.driver_documents
      for insert
      to authenticated
      with check (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
      )
    $policy$;
    execute 'drop policy if exists "Drivers can update own documents" on public.driver_documents';
    execute $policy$
      create policy "Drivers can update own documents"
      on public.driver_documents
      for update
      to authenticated
      using (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
      )
      with check (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
      )
    $policy$;
  end if;

  if to_regclass('public.driver_earnings') is not null then
    execute 'alter table public.driver_earnings enable row level security';
    execute 'drop policy if exists "Drivers can read own earnings" on public.driver_earnings';
    execute $policy$
      create policy "Drivers can read own earnings"
      on public.driver_earnings
      for select
      to authenticated
      using (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
        or private.is_admin()
      )
    $policy$;
  end if;

  if to_regclass('public.driver_bank_accounts') is not null then
    execute 'alter table public.driver_bank_accounts enable row level security';
    execute 'drop policy if exists "Drivers can read own bank account" on public.driver_bank_accounts';
    execute $policy$
      create policy "Drivers can read own bank account"
      on public.driver_bank_accounts
      for select
      to authenticated
      using (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
        or private.is_admin()
      )
    $policy$;
    execute 'drop policy if exists "Drivers can create own bank account" on public.driver_bank_accounts';
    execute $policy$
      create policy "Drivers can create own bank account"
      on public.driver_bank_accounts
      for insert
      to authenticated
      with check (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
      )
    $policy$;
    execute 'drop policy if exists "Drivers can update own bank account" on public.driver_bank_accounts';
    execute $policy$
      create policy "Drivers can update own bank account"
      on public.driver_bank_accounts
      for update
      to authenticated
      using (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
      )
      with check (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
      )
    $policy$;
  end if;

  if to_regclass('public.payouts') is not null then
    execute 'alter table public.payouts enable row level security';
    execute 'drop policy if exists "Drivers can read own payouts" on public.payouts';
    execute $policy$
      create policy "Drivers can read own payouts"
      on public.payouts
      for select
      to authenticated
      using (
        driver_id in (
          select id
          from public.drivers
          where user_id = (select auth.uid())
        )
        or private.is_admin()
      )
    $policy$;
  end if;

  if to_regclass('public.operating_zones') is not null then
    execute 'alter table public.operating_zones enable row level security';
    execute 'drop policy if exists "Authenticated users can read operating zones" on public.operating_zones';
    execute $policy$
      create policy "Authenticated users can read operating zones"
      on public.operating_zones
      for select
      to authenticated
      using ((select auth.uid()) is not null)
    $policy$;
    execute 'drop policy if exists "Admins can manage operating zones" on public.operating_zones';
    execute $policy$
      create policy "Admins can manage operating zones"
      on public.operating_zones
      for all
      to authenticated
      using (private.is_admin())
      with check (private.is_admin())
    $policy$;
  end if;

  if to_regclass('public.user_promos') is not null then
    execute 'alter table public.user_promos enable row level security';
    execute 'drop policy if exists "Users can read own promos" on public.user_promos';
    execute $policy$
      create policy "Users can read own promos"
      on public.user_promos
      for select
      to authenticated
      using (
        user_id = (select auth.uid())
        or private.is_admin()
      )
    $policy$;
    execute 'drop policy if exists "Users can create own promos" on public.user_promos';
    execute $policy$
      create policy "Users can create own promos"
      on public.user_promos
      for insert
      to authenticated
      with check (
        user_id = (select auth.uid())
      )
    $policy$;
  end if;

  if to_regclass('public.promo_codes') is not null then
    execute 'alter table public.promo_codes enable row level security';
    execute 'drop policy if exists "Authenticated users can read promo codes" on public.promo_codes';
    execute $policy$
      create policy "Authenticated users can read promo codes"
      on public.promo_codes
      for select
      to authenticated
      using ((select auth.uid()) is not null)
    $policy$;
  end if;
end
$$;

commit;

notify pgrst, 'reload schema';
