# Supabase Realtime Setup (Gold-Taxi)

This guide covers the database schema, RLS policies, and realtime configuration for the Gold-Taxi project.

## 1. Database Schema Migration

Run the following SQL in your Supabase SQL Editor:
(See `supabase_migration.sql` in the project root)

### Key Tables
- `profiles`: Extends `auth.users` with roles and metadata.
- `drivers`: Driver-specific information, online status, and current location.
- `rides`: Core ride-hailing data.
- `ride_events`: Audit log of ride status transitions.
- `driver_locations`: Realtime location history for drivers.

## 2. Row Level Security (RLS)

RLS is enabled on all tables to ensure data isolation:
- **Customers**: Can only access their own rides and profile.
- **Drivers**: Can see requested rides and those assigned to them.
- **Admins**: Full read/write access to all data.

### Critical Status Transitions (RPC)
Status transitions are handled via RPC functions to prevent race conditions:
- `accept_ride(ride_id)`
- `update_ride_status(ride_id, new_status)`
- `cancel_ride(ride_id, reason)`

## 3. Realtime Configuration

The following tables must be added to the `supabase_realtime` publication:
```sql
alter publication supabase_realtime add table public.rides;
alter publication supabase_realtime add table public.drivers;
alter publication supabase_realtime add table public.driver_locations;
```

## 4. Environment Variables (.env)

Add these to your `.env` file:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
```

**⚠️ SECURITY WARNING:** Never bundle the `service_role` key into the Flutter client. It bypasses all RLS policies.

## 5. Deployment Checklist
1. [ ] Run `supabase_migration.sql`.
2. [ ] Enable Realtime for the tables mentioned above.
3. [ ] Set `BackendMode.supabase` in `lib/main.dart`.
4. [ ] Verify RLS policies with a test user.
5. [ ] Ensure Google Maps API keys are restricted to your domain/app id.
