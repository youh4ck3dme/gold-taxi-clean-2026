# Security and Persistence Configuration (Gold-Taxi)

## 1. Authentication & Role Security

### Frontend Checks
*   **Customer Routes:** Accessible to all authenticated users.
*   **Driver Dashboard (`/driver`):** Requires `role: 'driver'` in the `UserModel`.
*   **Admin Dashboard (`/admin`):** Requires `role: 'admin'` in the `UserModel`.
*   Guarded via `GoRouter` redirect logic in `app_router.dart`.

### Required Backend Rules (Production)
Frontend guards are for UX and basic safety. Real security must be enforced on the backend:

#### Supabase / PostgreSQL Policies (RLS)
*   **Users Table:**
    *   Authenticated users can read their own profile.
    *   Admins can read/write all profiles.
*   **Rides Table:**
    *   `SELECT`: Customers can see their own rides. Drivers can see available `requested` rides and rides assigned to them. Admins see all.
    *   `INSERT`: Only customers can create rides (setting themselves as `customerId`).
    *   `UPDATE`:
        *   Customers can only update status to `cancelled`.
        *   Drivers can update status to `accepted` (if unassigned), `driver_arriving`, `in_progress`, `completed`.
        *   Admins can update any field.

### Concurrency & Race Conditions (Accept Ride)
To prevent two drivers from accepting the same ride simultaneously, the logic is implemented in a PostgreSQL RPC function `accept_ride(p_ride_id)`.
The function uses an atomic `UPDATE ... WHERE id = p_ride_id AND status = 'requested'` statement. 
If two requests arrive at once, only the first one will find the status as `requested` and update it. The second one will fail the `WHERE` clause and raise an exception, ensuring a ride is never "double-booked".

#### Firebase Security Rules
*   Similar logic: `request.auth.uid == resource.data.customerId` or `request.auth.token.role == 'admin'`.

## 2. Environment Configuration (.env)

| Variable | Description | Example |
|----------|-------------|---------|
| `WP_BASE_URL` | WordPress Headless URL | `https://gold-taxi.sk` |
| `SUPABASE_URL` | Supabase Project URL | `https://xyz.supabase.co` |
| `SUPABASE_ANON_KEY`| Supabase Public Key | `eyJ...` |
| `FIREBASE_API_KEY` | Firebase Client Key | `AIza...` |
| `GOOGLE_MAPS_KEY` | Google Maps API Key | `AIza...` |
| `FEATURE_BLOG` | Toggle Blog Visibility | `false` |

## 3. PWA Deployment Notes
*   **Domain:** Must be served over HTTPS.
*   **Service Worker:** Do NOT cache `*/wp-json/*` or `*/rest/v1/*` endpoints to ensure live ride data.
*   **Safe Areas:** Use `SafeArea` widget and `viewport-fit=cover` in `index.html`.
