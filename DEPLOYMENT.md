# Deployment & Verification Guide (Gold-Taxi)

This document provides instructions for deploying Gold-Taxi to production and verifying the integration.

## 1. Supabase Setup (Live Migration)

Follow these steps to set up the live Supabase environment:

1.  **Database Migration:**
    *   Open the Supabase Dashboard -> SQL Editor.
    *   Copy and run the contents of `supabase_migration.sql`.
    *   Verify that tables `profiles`, `drivers`, `rides`, `ride_events`, and `driver_locations` are created.

2.  **Enable Realtime:**
    *   Go to Database -> Replication -> `supabase_realtime` publication.
    *   Ensure the following tables are toggled ON: `rides`, `drivers`, `driver_locations`.

3.  **Authentication:**
    *   Enable Email Auth (or Google Auth as per `AuthRepository`).
    *   Configure Redirect URLs for your production domain.

## 2. Environment Variables

### Local Development (.env)
Create a `.env` file in the root directory:
```env
BACKEND_MODE=supabase
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
```

### Production (Hosting / CI-CD)
Inject these variables during the build process using `--dart-define` or environment-specific `.env` files:
- `BACKEND_MODE`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## 3. Flutter Web Build Command

Run the following command to generate a production-ready PWA build:
```bash
flutter build web --release --no-tree-shake-icons --dart-define=BACKEND_MODE=supabase --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## 4. Verification Checklists

### RLS Verification (Manual Test Cases)
- [ ] **Customer Privacy:** User A cannot see User B's rides.
- [ ] **Data Integrity:** Customer can only set their own `customer_id` during ride creation.
- [ ] **Role Protection:** Non-driver users cannot access `/driver` dashboard.
- [ ] **Concurrency:** Two drivers trying to accept the same ride simultaneously (Handled by RPC `accept_ride`).

### Smoke Test Checklist (PWA)

#### Zákazník (Customer)
- [ ] Prihlásenie úspešné.
- [ ] Vyhľadávanie adresy v Košiciach funguje.
- [ ] Vytvorenie jazdy prebehne bez chyby.
- [ ] Sledovanie stavu jazdy (Realtime) funguje.

#### Vodič (Driver)
- [ ] Prihlásenie ako vodič úspešné.
- [ ] Prepnutie do stavu "Online" funguje.
- [ ] Prijatie novej požiadavky (Realtime) sa zobrazí okamžite.
- [ ] Aktualizácia stavu jazdy (Vodič na ceste -> Prebieha -> Dokončené).

#### Administrátor (Admin)
- [ ] Prístup do Admin Dashboardu povolený.
- [ ] Zobrazenie všetkých aktívnych jázd v reálnom čase.
- [ ] Štatistiky obratu a počtu jázd sa aktualizujú.

## 5. Rollback Procedure
If the Supabase integration fails in production:
1.  Set `BACKEND_MODE=mock` in your environment variables.
2.  Redeploy the application.
3.  The app will revert to in-memory mock mode, preserving UX functionality without backend dependency.
