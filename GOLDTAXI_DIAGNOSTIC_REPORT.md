# GOLDTAXI_DIAGNOSTIC_REPORT

## PHASE 0 — REPOSITORY DIAGNOSTIC

### 0.1 — Project Structure Audit

#### Top-level folders and purpose
| Directory | Purpose |
|---|---|
| `.agents` | Local Copilot/agent skill assets and references (non-runtime app assets). |
| `.dart-tool` | Dart/Flutter tool cache. |
| `.git` | Git metadata. |
| `.github` | GitHub workflows (CI/CD). |
| `.vscode` | Editor settings. |
| `android` | Flutter Android host app. |
| `assets` | App static assets (icons/images). |
| `bin` | Dart helper scripts. |
| `integration_test` | Flutter integration tests. |
| `ios` | Flutter iOS host app. |
| `lib` | Main application code (core, features, models, routes, entrypoints). |
| `linux` | Flutter Linux host app. |
| `macos` | Flutter macOS host app. |
| `ops` | Operational HTML dashboards/artifacts. |
| `scripts` | Shell utilities (build/smoke scripts). |
| `supabase` | Supabase edge functions/config. |
| `test` | Unit/widget tests. |
| `web` | Flutter web host files (manifest/icons/index). |
| `windows` | Flutter Windows host app. |

#### Framework / stack
- Primary app: **Flutter (Dart)** multi-platform (web + mobile + desktop hosts).
- Backend/data: **Supabase** + **WordPress/WooCommerce APIs**.
- Hosting/deploy: **Firebase Hosting** and **Vercel** scripts/workflows.

#### Application entry point
- Build targets use flavor entrypoints:
  - `lib/main_dev.dart`
  - `lib/main_prod.dart`
- Shared bootstrapping in `lib/main_common.dart`.

#### Multiple apps?
- No separate standalone repos/apps detected.
- One Flutter app serving multiple roles (customer/driver/admin views), plus ops/support artifacts.

---

### 0.2 — Technology Stack Inventory

| Layer | Technology | Version | Status (✅ / ⚠️ / ❌) |
|---|---|---|---|
| Frontend framework | Flutter | Dart SDK constraint `^3.12.0` | ✅ Working |
| State management | `flutter_bloc`, `bloc`, `provider`, `get_it` | `flutter_bloc ^9.0.0`, `bloc ^9.0.0`, `provider ^6.1.5+1`, `get_it ^7.5.0` | ✅ Working |
| Backend / API | Supabase + WordPress/WooCommerce via Dio | `supabase_flutter ^2.12.4`, `dio ^5.3.1` | ⚠️ Partial (mixed integrations; some placeholders) |
| Database | Supabase Postgres | via Supabase project | ✅ Working (schema + repos present) |
| Authentication | Supabase Auth (email/password, Google OAuth, OTP), Firebase auth provider config in `firebase.json` | Supabase SDK-managed | ⚠️ Partial (docs and config mention Firebase path, runtime code centered on Supabase) |
| Maps / GPS integration | Google Maps Flutter + `flutter_map` fallback + geolocator/geocoding | `google_maps_flutter ^2.10.0`, `flutter_map ^8.2.2`, `geolocator ^9.0.2`, `geocoding ^4.0.0` | ✅ Working |
| Payment gateway | WooCommerce order payment method flags, Stripe references/models, Supabase edge function docs | no Stripe Flutter SDK in dependencies | ⚠️ Partial |
| Push notifications | Local `NotificationService` stub (Firebase disabled) | custom service | ❌ Missing (production push implementation) |
| Deployment / CI-CD | GitHub Actions + Firebase/Vercel config | workflow-based | ⚠️ Partial (multiple overlapping workflows; release uploads commented/skipped) |
| Testing framework | Flutter test + integration_test + bloc_test/mocktail/mockito | from `pubspec.yaml` | ✅ Working (suite exists) |

---

### 0.3 — Feature Completeness Matrix

| Feature | Status | Notes |
|---|---|---|
| User registration / login | ⚠️ Partial | Login + Google OAuth + OTP hooks exist; explicit full signup UX flow is limited. |
| Driver registration / login | ⚠️ Partial | Driver onboarding/doc upload and role switching exist, but KYC/approval ops still basic. |
| Ride booking flow (pickup + destination) | ✅ Working | Search → ride request → active ride tracking flow implemented. |
| Real-time driver tracking on map | ⚠️ Partial | Supabase streams + mock simulation exist; production-grade driver app telemetry not complete. |
| Fare calculation (fixed + dynamic) | ✅ Working | Pricing service + surge checks + promo discounts implemented and tested. |
| Payment integration (card, cash, Apple Pay, Google Pay) | ⚠️ Partial | Cash/card method selection and Stripe-related models exist; Apple/Google Pay and full Stripe checkout not completed. |
| Push notifications (ride updates, driver arrival) | ❌ Missing | Notification service is currently a stub with Firebase disabled. |
| Rating & review system | ⚠️ Partial | Review widgets/repository exist (content reviews); ride-specific rating flow is limited. |
| Ride history | ⚠️ Partial | Repository interfaces exist, but `getOrderHistory/getBookingHistory` return empty in Supabase repository. |
| Admin dashboard | ⚠️ Partial | Basic ride monitoring dashboard exists; advanced ops/KPI tooling limited. |
| Driver earnings dashboard | ✅ Working | Dedicated earnings module/pages/models/repositories present. |
| Corporate B2B accounts | ❌ Missing | No dedicated B2B account module found. |
| Airport transfer booking | ❌ Missing | No airport-specific booking/flight integration found. |
| Multi-language support | ❌ Missing | `flutter_localizations` dependency present, but no ARB/generated localization setup found. |
| Dark mode / theming | ⚠️ Partial | Light/dark themes exist, app is forced to `ThemeMode.dark`. |
| PWA manifest + service worker | ⚠️ Partial | `web/manifest.json` present; explicit custom service worker not present in repo. |
| App icons + splash screens | ⚠️ Partial | Icons configured (`flutter_launcher_icons` + web icons); explicit splash generation config not found. |

---

### 0.4 — Code Quality Assessment

#### Estimated LOC per module (repository scan)
| Module | Approx LOC |
|---|---:|
| `lib/core` | 2,567 |
| `lib/features` | 21,233 |
| `lib/models` | 1,795 |
| `lib/routes` | 288 |
| `test` | 6,204 |
| `integration_test` | 550 |
| `web` | 81 |
| `scripts` | 421 |
| `ops` | 2,691 |

#### TODO / FIXME / HACK comments found (sample)
- `android/app/build.gradle.kts` — TODO for unique Application ID and release signing config.
- `linux/flutter/CMakeLists.txt` — TODO scaffold comment (ephemeral split).
- `windows/flutter/CMakeLists.txt` — TODO scaffold comment (ephemeral split).
- `lib/features/faq/data/repositories/faq_repository.dart` — TODO on soft-delete filter (`is_active`).

#### Test suite and coverage
- Test suite is present and broad: **47 test files** across unit/widget/integration.
- CI workflows include analyze/tests and one pipeline includes integration test.
- **Coverage % is not published/configured in repository artifacts/workflows**.
- Local test execution in this environment was not possible because Flutter SDK is unavailable (`flutter: command not found`).

#### Obvious security vulnerabilities / risks
- Frontend role checks exist, but enforcement depends on backend RLS/RPC correctness (must stay strict).
- Driver documents are uploaded then exposed via public URLs from storage APIs; this can be sensitive if bucket/policies are overly permissive.
- Android release signing is still TODO in gradle comments (operational/security hardening gap).
- Positive: `.env.example` exists and runtime code includes mock-mode restrictions in production entrypoints.

#### Secrets management
- `.env.example` exists at repository root.
- Security notes and developer docs explicitly warn not to commit secrets.
- Firebase/Supabase/Maps values are expected from environment variables.

#### Git commit history summary
- Total commits visible in clone: **2**.
- Last commit date: **2026-06-18** (`6d222de`, author `NEXIFY-STUDIO`).
- Recent cadence: **2 commits in last 7/30/90 days** (very low visible history in this clone).
- Visible active author count (90 days): **1** (`NEXIFY-STUDIO`).

---

### 0.5 — Investor Readiness Score

| Dimension | Score /10 | Notes |
|---|---:|---|
| Technical maturity | 6 | Solid Flutter architecture and modularity, but mixed integration maturity. |
| Feature completeness | 5 | Core ride/demo flow exists; several business-critical features still partial/missing. |
| Code quality | 7 | Good modular structure and substantial tests; some placeholders/TODOs remain. |
| Security posture | 6 | Awareness present, but sensitive document exposure and ops hardening gaps remain. |
| Scalability architecture | 6 | Supabase + modular repos support growth; production scaling patterns not fully implemented. |
| Documentation quality | 7 | README/DEVELOPER/SECURITY docs exist and are useful; some docs reference missing files. |
| CI/CD readiness | 6 | CI workflows exist, but duplicated/overlapping pipelines and partial release automation. |
| Mobile UX completeness | 7 | Polished login and core screens; several advanced flows still incomplete. |

**OVERALL INVESTOR READINESS SCORE = 6.25 / 10**

---

## Diagnostic Conclusion
GoldTaxi has a credible technical base and a demonstrable ride flow, but it is still in a **pre-scale, MVP-hardening stage**. The strongest areas are app structure, map/ride core flow, and test surface. The main investor-risk gaps are production-grade payments, push notifications, full history/reporting flows, and expansion/business modules (B2B, airport, multilingual).
