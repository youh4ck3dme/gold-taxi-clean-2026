# Error Monitoring & Observability Plan

## Overview

This document outlines the recommended monitoring strategy for Gold-Taxi production deployment. Monitoring should be implemented **before** adding complex features like payments (Stripe) to ensure visibility into runtime issues.

## 🎯 Current Status

- ✅ **No monitoring SDK integrated** (intentional - keeping launch minimal)
- ✅ **Zero critical runtime errors** in current deployment
- ✅ **Manual verification** passing (see DEPLOYMENT.md)

## Recommended Tools

### Tier 1: Error Tracking (Immediate)

#### Sentry (Recommended)
- **Type:** Error tracking + performance monitoring
- **Risk:** Low - SDK is well-tested, no secrets required for basic setup
- **Privacy:** Can be configured to respect GDPR

#### LogRocket (Alternative)
- **Type:** Session replay + error tracking
- **Risk:** Medium - More invasive, captures user sessions
- **Privacy:** Requires careful configuration for PII

### Tier 2: Analytics (Post-Launch)

- **Vercel Analytics** - Built-in, zero config
- **Google Analytics** - For user behavior tracking
- **Supabase Analytics** - For database insights

## Sentry Setup Guide (Low-Risk)

### 1. Add Dependency
```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.15.0
```

### 2. Initialize in main.dart
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0; // Performance monitoring
      options.debug = kDebugMode;
      // Privacy: Disable automatic breadcrumb collection for sensitive data
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(const MyApp()),
  );
  
  // Rest of your app initialization...
}
```

### 3. Configure Environment
```bash
# .env
type=production
SENTRY_DSN=your-dsn-from-sentry.io
```

### 4. What to Capture
- ✅ **Dart errors** (all unhandled exceptions)
- ✅ **Flutter errors** (widget build errors, etc.)
- ✅ **HTTP errors** (4xx/5xx from Supabase API)
- ✅ **Performance traces** (slow renders, API calls)
- ❌ **User PII** (names, emails, addresses - use `sendDefaultPii: false`)
- ❌ **Payment data** (never capture)
- ❌ **Location data** (GDPR - require explicit consent)

### 5. Privacy Configuration
```dart
options.beforeSend = (event) {
  // Strip sensitive data
  event.user?.clear();
  event.extra?.removeWhere((key, value) => key.contains('token') || key.contains('password'));
  return event;
};
```

## LogRocket Setup Guide

**Use only if:** You need session replay for debugging complex UX issues.

### Privacy Considerations
- Session replay captures **everything** user sees/types
- Must have **explicit user consent** in EU (GDPR)
- Consider **masking** sensitive fields

### Recommended: Start with Sentry First
LogRocket is more invasive. Begin with Sentry error tracking, add LogRocket only if replay is essential.

## Supabase Monitoring

### Built-in Tools
- **Supabase Dashboard** → Database → Logs
- **Query monitoring** → Performance insights
- **Realtime monitoring** → Connection stats

### Recommended Alerts
1. **Failed RLS queries** - Indicates policy issues
2. **High latency queries** - Performance degradation
3. **Connection spikes** - DDoS or misuse
4. **Storage growth** - Uncontrolled data accumulation

## Vercel Monitoring

### Built-in Analytics
- Automatic for all deployments
- Shows: requests, errors, latency
- Dashboard: https://vercel.com/nexify-studio/gold-taxi/analytics

### Custom Checks
- **Deployment health** - Green/Red status
- **Error rate** - 4xx/5xx monitoring
- **Cold start time** - PWA performance

## What NOT to Monitor

- ❌ **User credentials** - Never log passwords, tokens
- ❌ **Payment data** - PCI compliance
- ❌ **Exact GPS coordinates** - GDPR sensitivity
- ❌ **Personal data** without consent
- ❌ **Business logic** that reveals competitive advantage

## Monitoring Checklist (Pre-Phase 5C)

- [ ] Sentry SDK added to pubspec.yaml
- [ ] Sentry initialized in main.dart
- [ ] Privacy filters configured
- [ ] SENTRY_DSN added to Vercel environment variables
- [ ] SENTRY_DSN added to GitHub Secrets (for CI)
- [ ] Supabase monitoring dashboard reviewed
- [ ] Vercel analytics enabled
- [ ] Error handling in catch blocks verified

## Error Boundaries (Flutter Web)

### Current Status
Check if error boundaries exist in `main.dart`:

```dart
// Recommended pattern for Flutter web
errunApp(
  ErrorWidget.builder((FlutterErrorDetails details) {
    // Send to Sentry
    Sentry.captureException(details.exception, stackTrace: details.stack);
    return MaterialApp(
      // Your error widget
    );
  }),
);
```

### Implementation Priority
1. **High:** Main app error boundary
2. **Medium:** Route-level error boundaries
3. **Low:** Widget-level error boundaries

## Future Implementation Checklist

| Task | Priority | Effort | Status |
|------|----------|--------|--------|
| Add Sentry SDK | High | 1 hour | ⏳ Pending |
| Configure privacy filters | High | 30 min | ⏳ Pending |
| Add SENTRY_DSN to Vercel | High | 5 min | ⏳ Pending |
| Add SENTRY_DSN to GitHub | Medium | 5 min | ⏳ Pending |
| Review Supabase alerts | Medium | 30 min | ⏳ Pending |
| Configure error boundaries | Medium | 1 hour | ⏳ Pending |
| Add LogRocket (if needed) | Low | 2 hours | ⏳ Backlog |

## Contacts & Escalation

- **Primary:** Project maintainer (u0352652320@gmail.com)
- **Supabase Support:** support@supabase.com
- **Vercel Support:** support@vercel.com
- **Emergency Rollback:** See DEPLOYMENT.md - Release Baseline Protection

## References

- [Sentry Flutter Docs](https://docs.sentry.io/platforms/flutter/)
- [LogRocket Flutter Docs](https://docs.logrocket.com/docs/flutter)
- [Supabase Monitoring](https://supabase.com/docs/guides/observability)
- [Vercel Analytics](https://vercel.com/docs/analytics)
