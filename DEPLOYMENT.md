# Deployment & Verification Guide (Gold-Taxi)

This document provides instructions for deploying Gold-Taxi to production and verifying the integration.

---

## 🏆 PRODUCTION BASELINE (Phase 5B Complete)

| **Item** | **Value** |
|----------|-----------|
| **URL** | https://gold-taxi.vercel.app |
| **Backend** | Supabase: `nscxuxhapaabtsiduxlu.supabase.co` |
| **Release Tag** | `gold-taxi-production-pass-2026-06-14` |
| **Status** | Phase 5B production complete ✅ |
| **Zero critical technical debt** | Core launch flows verified |

---

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

### Vercel Deployment Guardrails

**⚠️ REQUIRED for Production Deployment**

| Variable | Required | Purpose | Security Note |
|----------|----------|---------|---------------|
| `BACKEND_MODE` | ✅ Yes | Backend mode selector | Must be `supabase` for production |
| `SUPABASE_URL` | ✅ Yes | Supabase project URL | Use `https://nscxuxhapaabtsiduxlu.supabase.co` |
| `SUPABASE_ANON_KEY` | ✅ Yes | Supabase publishable key | **NEVER use service_role** |
| `WP_BASE_URL` | ⚠️ Optional | WordPress fallback | Only for legacy features |
| `FIREBASE_*` | ⚠️ Optional | Firebase auth | For auth fallback |

**🔒 Security Enforcement:**
- ❌ **NO** `SUPABASE_SERVICE_ROLE_KEY` should ever be in client code
- ❌ **NO** `service_role` in any environment variable
- ✅ **ONLY** `anon`/`publishable` keys allowed in frontend

**SPA Fallback Note:**
All routes are rewrote to `/index.html` via `vercel.json`. Ensure your Supabase CORS settings allow the Vercel domain.

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

## 6. Release Baseline Protection

**Current Stable Release:** `gold-taxi-production-pass-2026-06-14`

### How to Rollback

#### To a Specific Tag:
```bash
# Checkout the baseline tag
git checkout gold-taxi-production-pass-2026-06-14

# Push to main (force push - use with caution!)
git push origin gold-taxi-production-pass-2026-06-14:main --force
```

#### To Mock Mode (Emergency):
```bash
# Temporarily switch to mock mode without redeploy
# In Vercel: Set BACKEND_MODE=mock
# Or rebuild with:
flutter build web --release --no-tree-shake-icons --dart-define=BACKEND_MODE=mock
```

#### Verify Previous Build:
```bash
# List all tags
git tag -l

# Check what changed since baseline
git diff gold-taxi-production-pass-2026-06-14..HEAD
```

**Emergency Contact:** If deployment fails, baseline tag `gold-taxi-production-pass-2026-06-14` is known stable.
