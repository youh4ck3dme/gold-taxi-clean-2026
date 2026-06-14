# Runtime Smoke Test Checklist

## Overview

This document provides the exact manual checks required to verify Gold-Taxi production deployment. Run this checklist after every deployment and periodically in production.

## 🎯 Quick Smoke Test (5 minutes)

### Pre-requisites
- [ ] Deployed URL: https://gold-taxi.vercel.app
- [ ] Chrome browser (Incognito mode)
- [ ] Developer Tools open (F12)
- [ ] Network tab cleared
- [ ] Console tab cleared

---

## 1️⃣ Anonymous Startup Test

**Goal:** Verify anonymous users don't trigger WordPress calls or authentication errors.

### Steps:
1. Open Chrome Incognito window
2. Navigate to https://gold-taxi.vercel.app
3. Wait for page to fully load (5 seconds)

### Verifications:
- [ ] Page loads without errors
- [ ] Login/Register CTA is visible
- [ ] No error messages displayed
- [ ] Map shows Košice fallback location

### Network Tab Checks:
- [ ] ✅ **NO** calls to `larsenevans.com`
- [ ] ✅ **NO** calls to `/wp-json/wp/v2/users/me`
- [ ] ✅ **NO** 401 errors
- [ ] ✅ **NO** 403 errors
- [ ] ✅ **NO** 500 errors

### Console Tab Checks:
- [ ] ✅ **NO** red error messages
- [ ] ✅ **NO** warnings about missing environment variables
- [ ] ✅ Supabase client initialization logged (if BACKEND_MODE=supabase)

---

## 2️⃣ Authentication Flow Test

### Customer Login Test
1. Click Login/Register
2. Login with test customer credentials
3. Verify redirect to home dashboard

**Expected:**
- [ ] Login successful
- [ ] Redirects to home page
- [ ] CustomerHomeView renders
- [ ] No console errors

### Driver Login Test
1. Logout (if logged in)
2. Login with test driver credentials
3. Verify redirect to home dashboard

**Expected:**
- [ ] Login successful
- [ ] Redirects to home page
- [ ] DriverHomeView renders (with online toggle)
- [ ] No console errors

### Admin Login Test
1. Logout (if logged in)
2. Login with test admin credentials
3. Verify redirect to home dashboard

**Expected:**
- [ ] Login successful
- [ ] Redirects to home page
- [ ] AdminHomeView renders
- [ ] No console errors

---

## 3️⃣ Core Taxi Flow Test

### Customer Ride Creation
1. Login as customer
2. Navigate to ride request flow
3. Create a new ride request

**Expected:**
- [ ] Ride creation successful
- [ ] Ride appears in CustomerHomeView
- [ ] Ride status is "requested"
- [ ] No console errors

**Network Check:**
- [ ] POST to `/rest/v1/rides` succeeds
- [ ] Response contains ride ID
- [ ] Status code: 201

### Driver Accept Ride
1. Login as driver (in separate browser/incognito)
2. Ensure driver is online
3. Refresh to see requested rides
4. Accept the ride created above

**Expected:**
- [ ] Ride appears in available rides list
- [ ] Accept button works
- [ ] Ride status changes to "accepted"
- [ ] Driver assigned to ride
- [ ] No console errors

**Race Condition Test:**
1. Open two driver accounts in separate browsers
2. Both drivers attempt to accept the same ride
3. Verify only first accept succeeds
4. Second driver sees error message

**Expected:**
- [ ] Only one driver accepts the ride
- [ ] Second driver gets "Ride not found or already taken" error
- [ ] No double-booking occurs

### Admin Overview
1. Login as admin
2. Navigate to admin dashboard
3. Verify all active rides visible

**Expected:**
- [ ] Admin sees all rides (not just own)
- [ ] Realtime updates work
- [ ] No console errors

---

## 4️⃣ Role-Based Dashboard Test

### Customer Dashboard
1. Login as customer
2. Verify CustomerHomeView renders
3. Check saved addresses display

**Expected:**
- [ ] CustomerHomeView visible
- [ ] User greeting shows customer name
- [ ] Saved addresses section renders (if addresses exist)
- [ ] Saved addresses section hidden (if no addresses)
- [ ] No errors with missing saved_addresses

### Driver Dashboard
1. Login as driver
2. Verify DriverHomeView renders
3. Test online/offline toggle

**Expected:**
- [ ] DriverHomeView visible
- [ ] Online toggle button present
- [ ] Toggle changes driver status
- [ ] Status updates in realtime
- [ ] No console errors

### Admin Dashboard
1. Login as admin
2. Verify AdminHomeView renders
3. Check all rides visible

**Expected:**
- [ ] AdminHomeView visible
- [ ] All rides displayed (not filtered by user)
- [ ] Admin-specific UI elements present
- [ ] No console errors

---

## 5️⃣ GPS Fallback Test

### Test GPS Not Available
1. Login as customer
2. Disable browser location (or deny permission)
3. Navigate to ride request

**Expected:**
- [ ] App falls back to Košice map
- [ ] User can still request ride
- [ ] Ride uses Košice as pickup location
- [ ] No errors or crashes

### Test GPS Available
1. Enable browser location
2. Allow location permission
3. Navigate to ride request

**Expected:**
- [ ] App shows user's actual location
- [ ] Pickup location set to current position
- [ ] No errors or crashes

---

## 6️⃣ PWA Test

### Installability
1. Open in Chrome
2. Click install icon in address bar (or "Add to Home Screen")

**Expected:**
- [ ] Install prompt appears
- [ ] App installs successfully
- [ ] App icon appears on desktop/home screen

### Offline Behavior
1. Install PWA
2. Disable internet connection
3. Open installed app

**Expected:**
- [ ] App loads (shows cached UI)
- [ ] Error message: "Offline - Please check your connection"
- [ ] No crashes
- [ ] Reconnects when internet returns

### Manifest Check
1. Open DevTools → Application → Manifest

**Expected:**
- [ ] Name: Gold Taxi
- [ ] Short name: Gold Taxi
- [ ] Theme color: #FFB81C
- [ ] Background color: #1A1A1A
- [ ] Icons: 192x192, 512x512 present

---

## 7️⃣ Logout Test

### Steps:
1. Login as any user
2. Click logout
3. Verify redirect

**Expected:**
- [ ] User logged out successfully
- [ ] Redirects to login/landing page
- [ ] No error messages
- [ ] No cached user data visible

---

## 8️⃣ Realtime Updates Test

### Customer Ride Status
1. Login as customer on Device A
2. Create a ride request
3. Login as driver on Device B
4. Driver accepts the ride

**Expected:**
- [ ] Device A (customer) shows status change to "accepted" within 2 seconds
- [ ] No manual refresh needed
- [ ] Console shows realtime subscription event

### Driver Location Updates
1. Login as driver
2. Move driver location (or simulate via UI)
3. Login as customer with active ride

**Expected:**
- [ ] Customer sees driver location update in realtime
- [ ] Location marker moves smoothly
- [ ] No console errors

---

## 🚨 Critical Failure Indicators

**IMMEDIATE ROLLBACK REQUIRED if any of these occur:**

- [ ] ❌ **500 errors** on any core API call
- [ ] ❌ **403 errors** from Supabase RLS
- [ ] ❌ **WordPress calls** on anonymous startup
- [ ] ❌ **service_role key** in client code
- [ ] ❌ **Double-booking** allowed (two drivers accept same ride)
- [ ] ❌ **Authentication bypass** (can access without login)
- [ ] ❌ **PII leakage** in console/network logs
- [ ] ❌ **Database connection failures**

---

## 📋 Full Test Results Template

```
SMOKE TEST RESULTS
=================
Date: ___________
Tester: __________
Deployed Commit: __________

1. ANONYMOUS STARTUP
   [ ] Page loads
   [ ] Login CTA visible
   [ ] No WP calls
   [ ] No console errors
   Result: PASS/FAIL

2. AUTHENTICATION
   [ ] Customer login
   [ ] Driver login
   [ ] Admin login
   [ ] Logout
   Result: PASS/FAIL

3. CORE FLOW
   [ ] Customer creates ride
   [ ] Driver accepts ride
   [ ] Double accept blocked
   [ ] Admin sees all rides
   Result: PASS/FAIL

4. ROLE DASHBOARDS
   [ ] Customer view
   [ ] Driver view
   [ ] Admin view
   Result: PASS/FAIL

5. GPS FALLBACK
   [ ] No GPS fallback
   [ ] GPS available
   Result: PASS/FAIL

6. PWA
   [ ] Installable
   [ ] Offline mode
   [ ] Manifest valid
   Result: PASS/FAIL

7. REALTIME
   [ ] Ride status updates
   [ ] Location updates
   Result: PASS/FAIL

OVERALL: PASS/FAIL
Notes: ________________________
```

---

## 🔄 Automated Testing (Future)

**Recommended:** Convert these manual checks to automated tests using:
- Playwright for browser automation
- GitHub Actions for CI/CD integration
- Supabase test utilities for backend verification

**Priority:**
1. Anonymous startup test (critical)
2. Authentication flow test
3. Core ride flow test
4. Double-accept race condition

---

## 📞 Emergency Contacts

- **Primary:** u0352652320@gmail.com
- **Supabase Status:** https://status.supabase.com
- **Vercel Status:** https://www.vercel-status.com
- **Rollback Tag:** `gold-taxi-production-pass-2026-06-14`

---

## 🎯 Pass Criteria

**Production Deployment is CONSIDERED STABLE when:**

- ✅ All anonymous startup checks pass
- ✅ All authentication checks pass
- ✅ All core flow checks pass
- ✅ All role dashboard checks pass
- ✅ GPS fallback works
- ✅ PWA installable
- ✅ Realtime updates work
- ✅ No critical failure indicators

**Minimum for Controlled Launch:** 7/7 sections PASS
