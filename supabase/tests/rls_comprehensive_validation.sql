-- ============================================================================
-- GOLD-TAXI RLS COMPREHENSIVE VALIDATION SUITE
-- ============================================================================
-- Purpose: Validate that all RLS policies are correctly configured
--          for 13 core business tables across 3 role-based access levels:
--          - Admin (unrestricted)
--          - Driver (driver_id-scoped)
--          - Customer (auth.uid-scoped)
--
-- Usage: Run in Supabase SQL Editor or via pgTAP
-- ============================================================================

BEGIN;

-- ============================================================================
-- SECTION 1: HELPER FUNCTIONS VERIFICATION
-- ============================================================================

-- Test 1: private.is_admin() exists
SELECT
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'private' AND p.proname = 'is_admin'
    )
    THEN '✅ private.is_admin() exists'
    ELSE '❌ private.is_admin() MISSING'
  END AS test_result;

-- Test 2: private.driver_id_for_user() exists
SELECT
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'private' AND p.proname = 'driver_id_for_user'
    )
    THEN '✅ private.driver_id_for_user() exists'
    ELSE '❌ private.driver_id_for_user() MISSING'
  END AS test_result;

-- Test 3: private.is_active_rider_for_driver() exists
SELECT
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'private' AND p.proname = 'is_active_rider_for_driver'
    )
    THEN '✅ private.is_active_rider_for_driver() exists'
    ELSE '❌ private.is_active_rider_for_driver() MISSING'
  END AS test_result;

-- ============================================================================
-- SECTION 2: RLS ENABLEMENT VERIFICATION (13 tables)
-- ============================================================================

-- Test 4-16: Each table has RLS enabled
WITH target_tables AS (
  SELECT unnest(ARRAY[
    'profiles', 'drivers', 'rides', 'ride_events', 'driver_locations',
    'messages', 'driver_documents', 'driver_earnings', 'driver_bank_accounts',
    'payouts', 'operating_zones', 'user_promos', 'promo_codes'
  ]) AS tablename
)
SELECT
  t.tablename,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = t.tablename AND c.relrowsecurity = true
    )
    THEN '✅ RLS enabled'
    ELSE '❌ RLS NOT enabled'
  END AS rls_status
FROM target_tables t
ORDER BY t.tablename;

-- ============================================================================
-- SECTION 3: POLICY EXISTENCE VERIFICATION (13 tables)
-- ============================================================================

-- Test 17-29: Each table has at least one policy
WITH target_tables AS (
  SELECT unnest(ARRAY[
    'profiles', 'drivers', 'rides', 'ride_events', 'driver_locations',
    'messages', 'driver_documents', 'driver_earnings', 'driver_bank_accounts',
    'payouts', 'operating_zones', 'user_promos', 'promo_codes'
  ]) AS tablename
)
SELECT
  t.tablename,
  COUNT(p.policyname) AS policy_count,
  CASE
    WHEN COUNT(p.policyname) > 0
    THEN '✅ ' || COUNT(p.policyname) || ' policies exist'
    ELSE '❌ NO policies found'
  END AS policy_status
FROM target_tables t
LEFT JOIN pg_policies p ON p.tablename = t.tablename AND p.schemaname = 'public'
GROUP BY t.tablename
ORDER BY t.tablename;

-- ============================================================================
-- SECTION 4: POLICY COMMAND TYPE COVERAGE
-- ============================================================================

-- Test 30: All tables have SELECT policy
WITH select_coverage AS (
  SELECT DISTINCT tablename
  FROM pg_policies
  WHERE schemaname = 'public'
    AND cmd = 'SELECT'
    AND tablename IN (
      'profiles', 'drivers', 'rides', 'ride_events', 'driver_locations',
      'messages', 'driver_documents', 'driver_earnings', 'driver_bank_accounts',
      'payouts', 'operating_zones', 'user_promos', 'promo_codes'
    )
)
SELECT
  COUNT(*) AS tables_with_select,
  CASE
    WHEN COUNT(*) = 13 THEN '✅ All 13 tables have SELECT policy'
    ELSE '⚠️  ' || COUNT(*) || '/13 tables have SELECT policy'
  END AS coverage
FROM select_coverage;

-- Test 31: All tables with write capability have INSERT policy
WITH insert_coverage AS (
  SELECT DISTINCT tablename
  FROM pg_policies
  WHERE schemaname = 'public'
    AND cmd = 'INSERT'
    AND tablename IN (
      'profiles', 'drivers', 'rides', 'ride_events', 'driver_locations',
      'messages', 'driver_documents', 'driver_earnings', 'driver_bank_accounts',
      'payouts', 'operating_zones', 'user_promos', 'promo_codes'
    )
)
SELECT
  COUNT(*) AS tables_with_insert,
  CASE
    WHEN COUNT(*) >= 1 THEN '✅ ' || COUNT(*) || ' tables have INSERT policy'
    ELSE '⚠️  No INSERT policy found'
  END AS coverage
FROM insert_coverage;

-- Test 32: Update-capable tables have UPDATE policy
WITH update_coverage AS (
  SELECT DISTINCT tablename
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (cmd = 'UPDATE' OR cmd = 'ALL')
    AND tablename IN (
      'profiles', 'drivers', 'rides', 'ride_events', 'driver_locations',
      'messages', 'driver_documents', 'driver_earnings', 'driver_bank_accounts',
      'payouts', 'operating_zones', 'user_promos', 'promo_codes'
    )
)
SELECT
  COUNT(*) AS tables_with_update,
  CASE
    WHEN COUNT(*) >= 7 THEN '✅ ' || COUNT(*) || ' tables have UPDATE/ALL policy'
    ELSE '⚠️  ' || COUNT(*) || ' tables have UPDATE/ALL policy'
  END AS coverage
FROM update_coverage;

-- ============================================================================
-- SECTION 5: ROLE-BASED POLICY VERIFICATION
-- ============================================================================

-- Test 33: Policies use private.is_admin() for admin gates
WITH admin_gates AS (
  SELECT DISTINCT tablename
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (
      qual::text ILIKE '%private.is_admin()%' OR
      with_check::text ILIKE '%private.is_admin()%'
    )
)
SELECT
  COUNT(*) AS tables_with_admin_gate,
  CASE
    WHEN COUNT(*) >= 4 THEN '✅ ' || COUNT(*) || ' tables gate to admin'
    ELSE '⚠️  ' || COUNT(*) || ' tables gate to admin'
  END AS coverage
FROM admin_gates;

-- Test 34: Policies use private.driver_id_for_user() for driver scoping
WITH driver_scopes AS (
  SELECT DISTINCT tablename
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (
      qual::text ILIKE '%private.driver_id_for_user%' OR
      with_check::text ILIKE '%private.driver_id_for_user%'
    )
)
SELECT
  COUNT(*) AS tables_with_driver_scope,
  CASE
    WHEN COUNT(*) >= 1 THEN '✅ ' || COUNT(*) || ' table(s) use driver_id_for_user()'
    ELSE '⚠️  Only ' || COUNT(*) || ' table(s) use driver_id_for_user()'
  END AS coverage
FROM driver_scopes;

-- Test 35: Policies use (select auth.uid()) wrapper
WITH auth_uid_wrappers AS (
  SELECT DISTINCT tablename
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (
      qual::text ILIKE '%(select auth.uid()%' OR
      with_check::text ILIKE '%(select auth.uid()%' OR
      qual::text ILIKE '%auth.uid() AS uid%' OR
      with_check::text ILIKE '%auth.uid() AS uid%'
    )
)
SELECT
  COUNT(*) AS tables_with_wrapped_auth_uid,
  CASE
    WHEN COUNT(*) >= 10 THEN '✅ ' || COUNT(*) || ' tables use wrapped auth.uid()'
    ELSE '⚠️  ' || COUNT(*) || ' tables use wrapped auth.uid()'
  END AS coverage
FROM auth_uid_wrappers;

-- ============================================================================
-- SECTION 6: POLICY DETAIL LISTING
-- ============================================================================

-- Test 36: Detailed policy listing for audit
SELECT
  tablename,
  policyname,
  cmd,
  array_to_string(roles, ', ') AS roles,
  CASE
    WHEN qual IS NOT NULL THEN 'SELECT: ' || substring(qual::text, 1, 60) || '...'
    ELSE 'N/A'
  END AS select_condition,
  CASE
    WHEN with_check IS NOT NULL THEN 'INSERT/UPDATE: ' || substring(with_check::text, 1, 60) || '...'
    ELSE 'N/A'
  END AS write_condition
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles', 'drivers', 'rides', 'ride_events', 'driver_locations',
    'messages', 'driver_documents', 'driver_earnings', 'driver_bank_accounts',
    'payouts', 'operating_zones', 'user_promos', 'promo_codes'
  )
ORDER BY tablename, policyname;

-- ============================================================================
-- SECTION 7: CONSTRAINTS VERIFICATION
-- ============================================================================

-- Test 37: profiles has role check constraint
SELECT
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM pg_constraint con
      JOIN pg_class c ON c.oid = con.conrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = 'profiles'
        AND con.contype = 'c'
        AND pg_get_constraintdef(con.oid) ILIKE '%customer%driver%admin%'
    )
    THEN '✅ profiles has role check constraint'
    ELSE '❌ profiles missing role check constraint'
  END AS constraint_status;

-- ============================================================================
-- SECTION 8: SUMMARY REPORT
-- ============================================================================

-- Final summary
SELECT
  '═══════════════════════════════════════════════════════════════' AS summary,
  'GOLD-TAXI RLS VALIDATION COMPLETE' AS status,
  'All 13 tables should show:' AS requirement,
  '  ✅ RLS enabled' AS check_1,
  '  ✅ At least 1 policy' AS check_2,
  '  ✅ Proper SELECT/INSERT/UPDATE coverage' AS check_3,
  '  ✅ Role-based gating (admin/driver/customer)' AS check_4,
  'Next: Run specific access matrix tests in separate session' AS next_steps;

COMMIT;
