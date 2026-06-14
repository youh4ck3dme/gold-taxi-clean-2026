# Supabase Operations Checklist & Maintenance Guide

## Overview

This document provides operational guidelines for maintaining the Supabase backend of Gold-Taxi in production. It covers verification, monitoring, backup, and emergency procedures.

## 🔐 Project Details

| **Item** | **Value** |
|----------|-----------|
| Project ID | `nscxuxhapaabtsiduxlu` |
| Project URL | `https://nscxuxhapaabtsiduxlu.supabase.co` |
| Region | (Check Supabase dashboard) |
| Plan | (Check Supabase dashboard) |

## Daily Operations Checklist

### ✅ RLS Verification

**Command:** Run in Supabase SQL Editor
```sql
-- Check all tables have RLS enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
```

**Expected Result:** All core tables (`profiles`, `drivers`, `rides`, `ride_events`, `driver_locations`) should show `rowsecurity = true`

**Tables to Verify:**
- [ ] `public.profiles` - RLS enabled
- [ ] `public.drivers` - RLS enabled
- [ ] `public.rides` - RLS enabled
- [ ] `public.ride_events` - RLS enabled
- [ ] `public.driver_locations` - RLS enabled

### ✅ Policy Verification

**Command:**
```sql
-- List all RLS policies
SELECT tablename, policyname, cmd, permissive, roles, qual, with_check
FROM pg_policies 
WHERE schemaname = 'public' 
ORDER BY tablename, policyname;
```

**Expected Policies:**
- profiles: read own, admin read all, update own
- drivers: read online, update own
- rides: customer own, driver assigned+requested, admin all, customer create
- ride_events: involved parties + admin
- driver_locations: ride-based + driver own + admin

### ✅ Realtime Verification

**Command:**
```sql
-- Check realtime publication
SELECT pubname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
ORDER BY tablename;
```

**Expected Result:**
- `rides` - ON
- `drivers` - ON
- `driver_locations` - ON

**Dashboard Check:**
1. Go to Supabase → Database → Replication
2. Verify `supabase_realtime` publication has all 3 tables toggled ON

### ✅ Trigger Verification

**Command:**
```sql
-- Check role escalation trigger exists
SELECT tgname, tgrelid::regclass, tgfoid::regproc 
FROM pg_trigger 
WHERE tgname = 'on_profile_update';
```

**Expected:** Trigger should exist on `profiles` table, calling `check_profile_update()` function.

## Table Growth Monitoring

### High-Risk Tables (Monitor Weekly)

| Table | Expected Growth | Retention Policy | Action if Large |
|-------|-----------------|------------------|-----------------|
| `ride_events` | ~100/day per user | 90 days | Archive old data |
| `driver_locations` | ~1/min per driver | 30 days | Auto-cleanup |
| `rides` | ~10/day per user | Forever (soft delete) | Monitor |
| `profiles` | ~1 per user | Forever | Low risk |
| `drivers` | ~1 per driver | Forever | Low risk |

### Growth Queries

**Ride Events Growth:**
```sql
SELECT 
  DATE(created_at) as day,
  COUNT(*) as events,
  COUNT(DISTINCT ride_id) as unique_rides
FROM ride_events 
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY day
ORDER BY day;
```

**Driver Locations Growth:**
```sql
SELECT 
  DATE(created_at) as day,
  COUNT(*) as location_updates,
  COUNT(DISTINCT driver_id) as active_drivers
FROM driver_locations 
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY day
ORDER BY day;
```

**Storage Usage:**
```sql
SELECT 
  table_name,
  pg_size_pretty(pg_total_relation_size(table_name::regclass)) as size,
  pg_total_relation_size(table_name::regclass) / 1024 / 1024 as size_mb
FROM (
  VALUES ('profiles'), ('drivers'), ('rides'), ('ride_events'), ('driver_locations')
) AS t(table_name)
ORDER BY size_mb DESC;
```

## Backup & Export Strategy

### Automated Backups (Supabase)

**Status:** Supabase provides automatic backups for paid plans.

**Check Backup Status:**
1. Go to Supabase → Project Settings → Database → Backups
2. Verify backup frequency (daily for paid, manual for free)
3. Test restore procedure

### Manual Export

**Full Database Export:**
```bash
# Using Supabase CLI
supabase db dump --db-url postgresql://postgres:nscxuxhapaabtsiduxlu@aws-1-...:5432/postgres > gold-taxi-backup-$(date +%Y%m%d).sql
```

**Table-Specific Export:**
```sql
-- Export rides data
COPY (SELECT * FROM rides) TO STDOUT WITH CSV HEADER;

-- Export to file (via Supabase dashboard)
-- Use SQL Editor → Export as CSV
```

### Backup Retention

| Backup Type | Frequency | Retention | Storage |
|-------------|-----------|-----------|---------|
| Automated (Supabase) | Daily | 7 days | Supabase |
| Manual Export | Weekly | 30 days | Local/Cloud |
| Before Major Release | On-demand | Forever | Local/Cloud |

## Emergency Procedures

### 1. Database Corruption

**Symptoms:**
- 500 errors on all API calls
- "relation does not exist" errors
- Data inconsistencies

**Response:**
```bash
# Restore from latest backup
supabase db reset --db-url postgresql://... 
# Then re-run migrations
```

### 2. RLS Policy Failure

**Symptoms:**
- 403 errors on legitimate requests
- Users cannot access their data

**Diagnose:**
```sql
-- Check recent policy changes
SELECT * FROM pg_policies 
WHERE schemaname = 'public' 
ORDER BY seq DESC;
```

**Fix:**
- Re-apply migration files
- Check for missing policies
- Verify USING/WITH CHECK clauses

### 3. Realtime Connection Issues

**Symptoms:**
- No live updates in UI
- "connection failed" in browser console

**Diagnose:**
1. Check Supabase → Database → Realtime → Connections
2. Verify publication includes all tables
3. Check browser console for WebSocket errors

**Fix:**
```sql
-- Re-enable realtime for tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.rides;
ALTER PUBLICATION supabase_realtime ADD TABLE public.drivers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_locations;
```

### 4. Performance Degradation

**Symptoms:**
- Slow API responses (>1s)
- Timeouts on complex queries

**Diagnose:**
```sql
-- Check slow queries
SELECT query, total_time, calls 
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;

-- Check table sizes
SELECT tablename, n_live_tup 
FROM pg_stat_user_tables 
ORDER BY n_live_tup DESC;
```

**Fix:**
- Add missing indexes
- Optimize slow queries
- Archive old data
- Consider table partitioning

## Index Maintenance

### Current Indexes (Verify)

```sql
-- List all indexes
SELECT tablename, indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;
```

**Expected Indexes:**
- `rides_customer_id_idx` - Customer ride lookups
- `rides_driver_id_idx` - Driver ride lookups
- `rides_status_idx` - Status filtering
- `rides_created_at_desc_idx` - Recent rides
- `drivers_user_id_idx` - Driver profile lookups
- `drivers_is_online_idx` - Online driver filtering
- `driver_locations_driver_id_created_at_idx` - Driver location history
- `ride_events_ride_id_created_at_idx` - Ride event history

### Missing Indexes (Add if Needed)

**If querying by multiple fields:**
```sql
-- Example: Composite index for common query
CREATE INDEX IF NOT EXISTS rides_customer_status_idx 
ON public.rides(customer_id, status);
```

**If ordering by date frequently:**
```sql
CREATE INDEX IF NOT EXISTS rides_status_created_idx 
ON public.rides(status, created_at DESC);
```

## Security Checklist

### ✅ Quarterly Review

- [ ] Review all RLS policies for correctness
- [ ] Audit all RPC functions for SQL injection
- [ ] Verify no service_role usage in client code
- [ ] Check for exposed API keys in frontend
- [ ] Review authentication redirect URLs
- [ ] Test role escalation prevention

### 🔒 Immediate Actions if Breach Detected

1. **Rotate Supabase anon key**
   - Go to Supabase → Settings → API
   - Generate new anon key
   - Update Vercel environment variables
   - Redeploy

2. **Disable compromised auth providers**
   - Go to Supabase → Authentication → Providers
   - Disable suspicious providers

3. **Review database logs**
   - Go to Supabase → Database → Logs
   - Look for unusual query patterns

## Monitoring Alerts Setup

### Recommended Supabase Alerts

1. **Failed Login Attempts**
   - Threshold: 10 failed attempts per minute
   - Action: Notify security team

2. **High Query Latency**
   - Threshold: >1s average response time
   - Duration: 5 minutes

3. **Storage Threshold**
   - Threshold: >80% of plan limit
   - Action: Archive old data

4. **Connection Count**
   - Threshold: >1000 concurrent connections
   - Action: Investigate traffic spike

## Maintenance Schedule

| Task | Frequency | Owner | Notes |
|------|-----------|-------|-------|
| RLS verification | Weekly | DevOps | Automate via CI |
| Backup verification | Monthly | DevOps | Test restore |
| Performance review | Quarterly | Backend | Optimize queries |
| Security audit | Quarterly | Security | Review access |
| Index review | Quarterly | Backend | Add missing indexes |

## Contacts

- **Supabase Support:** support@supabase.com
- **Emergency:** Use rollback tag `gold-taxi-production-pass-2026-06-14`
- **Project Owner:** u0352652320@gmail.com

## References

- [Supabase Observability](https://supabase.com/docs/guides/observability)
- [PostgreSQL Monitoring](https://www.postgresql.org/docs/current/monitoring-stats.html)
- [Supabase Backups](https://supabase.com/docs/guides/database/backups)
