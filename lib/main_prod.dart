import 'package:flutter/foundation.dart';

import 'core/config/app_config.dart';
import 'main_common.dart';

void main() {
  // ── MOCK MODE GUARD ────────────────────────────────────────────────────────
  // Production builds must never run in mock mode.
  // These guards are evaluated at *compile time* (const) so tree-shaking
  // removes any unreachable mock-mode branches from release binaries.
  const mockMode = bool.fromEnvironment('MOCK_MODE', defaultValue: false) ||
      String.fromEnvironment('BACKEND_MODE') == 'mock';
  assert(!mockMode, 'MOCK_MODE must be false in production builds.');
  if (mockMode) {
    throw StateError(
      'Security violation: MOCK_MODE / BACKEND_MODE=mock cannot be set in production.',
    );
  }

  // ── REQUIRED BUILD-TIME DEFINES ───────────────────────────────────────────
  // Both values MUST be supplied via --dart-define at build time.
  // There are intentionally NO default values so that a missing define causes
  // an immediate, visible startup failure rather than silently using stale
  // or empty credentials.
  //
  //   flutter build web --release \
  //     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  //     --dart-define=SUPABASE_ANON_KEY=your-publishable-key
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty) {
    throw StateError(
      'Production misconfiguration: SUPABASE_URL is not set. '
      'Pass --dart-define=SUPABASE_URL=https://your-project.supabase.co '
      'when building the production target.',
    );
  }
  if (supabaseAnonKey.isEmpty) {
    throw StateError(
      'Production misconfiguration: SUPABASE_ANON_KEY is not set. '
      'Pass --dart-define=SUPABASE_ANON_KEY=your-publishable-key '
      'when building the production target.',
    );
  }

  // Stripe key is optional in CI/test builds; log a warning if absent.
  const stripeKey = String.fromEnvironment('STRIPE_KEY_PROD');
  if (stripeKey.isEmpty) {
    debugPrint(
      '⚠️  STRIPE_KEY_PROD is not set. Stripe features will be unavailable.',
    );
  }

  final prodConfig = AppConfig(
    environment: AppEnvironment.prod,
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
    stripePublishableKey: stripeKey,
    enableMockMode: false,
    enableAnalytics: true,
  );

  mainCommon(prodConfig);
}
