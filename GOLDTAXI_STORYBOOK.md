# GoldTaxi Storybook
## “From Idea to Market Leader in 12 Months”

## Current State (Based on Diagnostic)
GoldTaxi already has a serious technical foundation: a multi-platform Flutter codebase, modular feature architecture, Supabase-backed repositories, map-enabled ride request flow, and a broad automated test suite footprint. The current product can demonstrate login, role-based screens, ride request simulation, map views, and driver/admin operational panels.

However, several investor-critical capabilities are still incomplete or inconsistent for production: push notifications are not implemented, payment is only partially integrated, and parts of profile/history and back-office workflows remain basic. CI/CD exists but is fragmented across overlapping workflows, and release automation still has manual placeholders.

In short, the project is no longer at idea stage, but not yet at scale-ready stage. The next 12 months should focus on converting the existing technical base into a reliable operational taxi platform with validated unit economics and expansion readiness.

---

## 📍 PHASE 1 — Foundation & MVP Hardening
**Timeline:** Weeks 1–6 (1.5 months)  
**Goal:** Make the existing code production-ready and demo-able for investors.

### Deliverables
1. Fix all critical bugs identified in diagnostic  
2. Complete the ride booking flow end-to-end  
3. Integrate Google Maps (real GPS tracking)  
4. Connect Stripe payment gateway (test mode)  
5. Build driver mobile app screen (Flutter)  
6. Set up Firebase Auth (email + Google)  
7. Deploy to Vercel (web) + TestFlight (iOS) + Play Store Internal (Android)  
8. Create investor demo environment with seed data

### Copilot Assist Tasks
- Generate complete Flutter screens for: HomeScreen, BookRideScreen, TrackRideScreen, PaymentScreen  
- Write Stripe webhook handler in Node.js / Next.js API route  
- Generate Firebase Firestore data models (User, Driver, Ride, Payment)  
- Write unit tests for fare calculation algorithm  
- Create GitHub Actions CI/CD pipeline

### Investment Required (Calculated)
- Team (1.5 months): €13,000 × 1.5 = **€19,500**
- Infrastructure (1.5 months): (€520–€1,470) × 1.5 = **€780–€2,205**
- Marketing/ops (1.5 months): €500 × 1.5 = **€750**
- **Phase 1 Total (excl. Stripe transaction fees): €21,030–€22,455**

### Success Criteria (Definition of Done)
- Investor can book a real test ride end-to-end  
- App deployed on real device  
- Payment completes in test mode  
- 0 critical bugs in core flow

---

## 📍 PHASE 2 — Driver Network & Operations
**Timeline:** Weeks 7–14 (2 months)  
**Goal:** Onboard first 50 real drivers and complete first 100 real rides.

### Deliverables
1. Build Driver Onboarding Portal (web + mobile)  
2. Build Admin Dashboard (driver approval, ride monitoring)  
3. Implement real-time ride matching algorithm  
4. Push notifications via Firebase Cloud Messaging  
5. Rating & review system  
6. Driver earnings dashboard + payout integration  
7. GDPR-compliant data handling  
8. Customer support chat integration

### Copilot Assist Tasks
- Generate Admin Dashboard with Next.js + Tailwind (driver list, ride map, KPIs)  
- Write real-time Firestore listener for driver location updates  
- Generate FCM notification service for ride events  
- Write Driver KYC document upload flow  
- Create payout integration with Stripe Connect

### Investment Required (Calculated)
- Team (2 months): €13,000 × 2 = **€26,000**
- Infrastructure (2 months): (€520–€1,470) × 2 = **€1,040–€2,940**
- Marketing/ops (2 months): €2,000 × 2 = **€4,000**
- Driver onboarding (first 50 drivers): (€45 + €20 + €100) × 50 = **€8,250**
- **Phase 2 Total (excl. Stripe transaction fees): €39,290–€41,190**

### Success Criteria (Definition of Done)
- 50 verified drivers in system  
- 100 completed real rides  
- Admin can approve/reject drivers  
- Drivers receive weekly payouts

---

## 📍 PHASE 3 — Product-Market Fit & Revenue
**Timeline:** Weeks 15–26 (3 months)  
**Goal:** Reach €10,000 MRR and validate unit economics.

### Deliverables
1. Launch B2B Corporate Accounts module  
2. Airport Transfer product with flight tracking  
3. Loyalty program for repeat customers  
4. Multi-language (SK, EN, DE, HU)  
5. Advanced fare engine (surge + fixed + subscription)  
6. iOS App Store + Google Play Store public launch  
7. Marketing landing page with SEO  
8. Analytics dashboard (Mixpanel / PostHog)

### Copilot Assist Tasks
- Generate B2B company account flow with invoice generation  
- Write Skyscanner / FlightAware API integration for flight tracking  
- Build loyalty points system in Firestore  
- Generate i18n strings for 4 languages  
- Create SEO-optimized Next.js landing pages  
- Write PostHog event tracking hooks

### Investment Required (Calculated)
- Team (3 months): €13,000 × 3 = **€39,000**
- Infrastructure (3 months): (€520–€1,470) × 3 = **€1,560–€4,410**
- Marketing/ops (3 months): €5,000 × 3 = **€15,000**
- **Phase 3 Total (excl. Stripe transaction fees): €55,560–€58,410**

### Success Criteria (Definition of Done)
- 5 B2B corporate clients signed  
- App live in App Store + Play Store  
- €10,000 Monthly Recurring Revenue  
- NPS score ≥ 50

---

## 📍 PHASE 4 — Scale & Expansion
**Timeline:** Weeks 27–52 (6.5 months)  
**Goal:** Expand to 4 countries, raise Series A.

### Deliverables
1. Launch in Vienna, Prague, Budapest  
2. White-label platform for partner cities  
3. Machine learning fare prediction model  
4. Driver performance AI scoring  
5. Automated compliance per country (VAT, receipts)  
6. Series A fundraising materials + data room  
7. PR and brand awareness campaigns  
8. API for enterprise integration

### Copilot Assist Tasks
- Generate multi-region Firestore architecture  
- Write automated VAT invoice generation per country  
- Create ML model training pipeline for demand forecasting  
- Build public REST API with Swagger documentation  
- Generate comprehensive test suite (unit + integration + E2E)

### Investment Required (Calculated)
- Team (6.5 months): €13,000 × 6.5 = **€84,500**
- Infrastructure (6.5 months): (€520–€1,470) × 6.5 = **€3,380–€9,555**
- Marketing/ops (6.5 months): €15,000 × 6.5 = **€97,500**
- **Phase 4 Total (excl. Stripe transaction fees): €185,380–€191,555**

### Success Criteria (Definition of Done)
- Operational in 4 countries  
- 500+ active drivers  
- Series A term sheet signed  
- €50,000+ MRR

---

## INVESTMENT CALCULATOR SUMMARY

### Cost assumptions used
- Team/month: **€13,000** (Flutter €4,500 + Backend €4,000 + UI/UX €3,000 + QA PT €1,500)
- Infrastructure/month (excl. Stripe variable fees): **€520–€1,470**
  - Firebase: €200–€800
  - Vercel Pro: €20
  - Google Maps: €150–€500
  - Expo/TestFlight: €100
  - Domain/SSL/misc: €50
- Stripe fees: **2.9% + €0.30 per transaction** (variable, excluded from fixed totals)

### Phase totals (fixed costs, excl. Stripe variable fees)
| Phase | Total Investment |
|---|---:|
| Phase 1 | €21,030–€22,455 |
| Phase 2 | €39,290–€41,190 |
| Phase 3 | €55,560–€58,410 |
| Phase 4 | €185,380–€191,555 |

### Total 12-month program budget envelope
**€301,260–€313,610** (excluding Stripe transaction fees tied to ride volume)
