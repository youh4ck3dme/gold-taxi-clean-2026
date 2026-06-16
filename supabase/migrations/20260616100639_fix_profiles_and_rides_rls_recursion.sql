begin;

create schema if not exists private;

create or replace function private.is_admin_user(user_id uuid)
returns boolean
language sql
security definer
set search_path = public, private
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = user_id
      and p.role = 'admin'
  );
$$;

revoke all on function private.is_admin_user(uuid) from public;
grant execute on function private.is_admin_user(uuid) to authenticated;

create or replace function private.driver_id_for_user(user_id uuid)
returns uuid
language sql
security definer
set search_path = public, private
stable
as $$
  select d.id
  from public.drivers d
  where d.user_id = user_id
  limit 1
$$;

revoke all on function private.driver_id_for_user(uuid) from public;
grant execute on function private.driver_id_for_user(uuid) to authenticated;

drop policy if exists "Admins can read all profiles" on public.profiles;

create policy "Admins can read all profiles"
on public.profiles
for select
to authenticated
using (
  private.is_admin_user(auth.uid())
);

drop policy if exists "Admins can read all rides" on public.rides;
drop policy if exists "Drivers can read assigned or requested rides" on public.rides;
drop policy if exists "Drivers can update own assigned rides" on public.rides;
drop policy if exists "Drivers can update own ride status" on public.rides;
drop policy if exists "Drivers can view own rides" on public.rides;
drop policy if exists "Drivers can update assigned or requested rides" on public.rides;

create policy "Admins can read all rides"
on public.rides
for select
to authenticated
using (
  private.is_admin_user(auth.uid())
);

create policy "Drivers can read assigned or requested rides"
on public.rides
for select
to authenticated
using (
  private.driver_id_for_user(auth.uid()) is not null
  and (
    driver_id = private.driver_id_for_user(auth.uid())
    or (
      driver_id is null
      and status::text = 'requested'
    )
  )
);

create policy "Drivers can update assigned or requested rides"
on public.rides
for update
to authenticated
using (
  private.driver_id_for_user(auth.uid()) is not null
  and (
    driver_id = private.driver_id_for_user(auth.uid())
    or (
      driver_id is null
      and status::text = 'requested'
    )
  )
)
with check (
  driver_id = private.driver_id_for_user(auth.uid())
);

drop policy if exists "Customers can cancel own requested rides" on public.rides;

create policy "Customers can cancel own requested rides"
on public.rides
for update
to authenticated
using (
  customer_id = auth.uid()
  and status::text in ('requested', 'accepted')
)
with check (
  customer_id = auth.uid()
  and status::text = 'cancelled'
);

commit;

notify pgrst, 'reload schema';
