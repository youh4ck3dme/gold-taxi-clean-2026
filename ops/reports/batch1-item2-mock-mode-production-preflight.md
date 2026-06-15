# GOLDTAXI BATCH 1 / ITEM 2 - MOCK MODE PRODUCTION KILL SWITCH PREFLIGHT

**Branch:** `audit/goldtaxi-mock-mode-production-preflight`  
**Date:** 2026-06-14  
**Status:** READ-ONLY AUDIT - NO SOURCE CODE MODIFIED  
**Auditor:** Mistral Vibe (Senior Flutter Architect, Release Engineer, Security Auditor)

---

## 1. EXECUTIVE VERDICT

### 🔴 **VERDICT: CRITICAL FAIL**

**Can mock mode accidentally run in production?** ✅ **YES - CRITICAL RISK**

**Biggest Current Risk:** 
> **AUTOMATIC FALLBACK TO MOCK MODE ON NETWORK ERRORS** - The `ApiService._onError()` method (lines 84-99, 124-136, 156-165, 184-193, 210-219, 326-367) automatically switches `_mockModeEnabled = true` and `_useMockData = true` on any connection error, meaning **production builds will silently fall back to mock data without user knowledge**. This creates a critical security vulnerability where production users could be using fake data without realizing it.

**Risk Severity:** CRITICAL - Production data integrity cannot be guaranteed.

---

## 2. MOCK MODE MAP

| # | File | Line | Symbol/Function | Current Behavior | Risk Level | Fix Recommendation |
|---|------|------|------------------|-------------------|------------|-------------------|
| 1 | `lib/main_common.dart` | 25 | `dotenv.load(fileName: ".env")` | Loads `.env` file as Flutter asset | **CRITICAL** | Remove `.env` from pubspec.yaml assets, use `--dart-define` only |
| 2 | `pubspec.yaml` | 108-110 | `assets: - .env` | `.env` bundled with app | **CRITICAL** | Remove `.env` from assets list immediately |
| 3 | `lib/main_prod.dart` | 19 | `enableMockMode: false` | Default false, but can be overridden | **HIGH** | Add assertion: `assert(!enableMockMode, 'Mock mode disabled in production')` |
| 4 | `lib/main_dev.dart` | 19 | `enableMockMode: true` | Default true for dev | **LOW** | OK for dev, but ensure prod cannot override |
| 5 | `lib/core/di/service_locator.dart` | 84 | `setupServiceLocator(mode: BackendMode.mock)` | Default to mock | **HIGH** | Change default to `BackendMode.supabase` |
| 6 | `lib/core/di/service_locator.dart` | 88 | `enableMockMode: mode == BackendMode.mock` | Passes mock flag to ApiService | **HIGH** | Validate mode before passing |
| 7 | `lib/core/services/api_service.dart` | 28-29 | `_useMockData = false`, `_mockModeEnabled = false` | Static mutable state | **CRITICAL** | Make immutable, remove auto-fallback |
| 8 | `lib/core/services/api_service.dart` | 84-99 | `_onError()` | **Auto-fallback to mock on connection error** | **CRITICAL** | Remove lines 89-96, 94-95 - NEVER auto-enable mock |
| 9 | `lib/core/services/api_service.dart` | 124-136 | `get()` method | Auto-fallback on DioException | **CRITICAL** | Remove lines 127-133 - throw error instead |
| 10 | `lib/core/services/api_service.dart` | 156-165 | `post()` method | Auto-fallback on DioException | **CRITICAL** | Remove lines 157-161 - throw error instead |
| 11 | `lib/core/services/api_service.dart` | 184-193 | `put()` method | Auto-fallback on DioException | **CRITICAL** | Remove lines 185-191 - throw error instead |
| 12 | `lib/core/services/api_service.dart` | 210-219 | `delete()` method | Auto-fallback on DioException | **CRITICAL** | Remove lines 211-215 - throw error instead |
| 13 | `lib/core/services/api_service.dart` | 373-402 | `_isEndpointAvailable()` | Auto-fallback on connection error | **CRITICAL** | Remove lines 393-398 - return false, don't enable mock |
| 14 | `lib/core/services/api_service.dart` | 430-458 | `fetchCptData()` | Auto-fallback on all errors | **CRITICAL** | Remove line 457-458 - throw error instead |
| 15 | `lib/core/services/api_service.dart` | 270-278 | JWT mock token | Returns fake JWT: `'mock_jwt_token_abc123xyz789'` | **CRITICAL** | Remove mock JWT, fail authentication |
| 16 | `lib/core/services/api_service.dart` | 295-302 | POST JWT mock token | Returns fake JWT on login | **CRITICAL** | Remove mock login response |
| 17 | `lib/core/services/api_service.dart` | 484-497 | `enableMockMode()`/`disableMockMode()`/`isMockModeEnabled()` | Static global state | **HIGH** | Make instance-based, not static |
| 18 | `lib/core/services/api_service.dart` | 36-37 | Constructor sets `_mockModeEnabled` | Instance can enable mock | **HIGH** | Add validation: `assert(!enableMockMode || kDebugMode, 'Mock mode only in debug')` |
| 19 | `lib/routes/app_router.dart` | 233 | `driverId = authState is Authenticated ? authState.user.id : 'driver_1'` | Hardcoded fallback ID | **HIGH** | Remove hardcoded `'driver_1'`, fail if not authenticated |
| 20 | `lib/features/map/presentation/cubits/ride_cubit.dart` | 222 | `driverId: 'driver_1'` | Hardcoded driver ID | **HIGH** | Remove, use authenticated driver only |
| 21 | `lib/features/map/presentation/cubits/ride_cubit.dart` | 237 | `acceptRide(rideId, 'driver_1')` | Hardcoded driver ID | **HIGH** | Remove, use real driver ID |
| 22 | `lib/features/auth/presentation/cubits/auth_cubit.dart` | 81 | `id: '0'` | Hardcoded user ID | **HIGH** | Remove, use real user ID |
| 23 | `.github/workflows/flutter-ci.yml` | 39-40 | `--dart-define=BACKEND_MODE=mock` | CI builds with mock mode | **MEDIUM** | OK for CI, but ensure prod uses supabase |
| 24 | `.github/workflows/flutter-ci.yml` | 45-47 | `--dart-define=BACKEND_MODE=supabase` | Conditional prod build | **MEDIUM** | Good, but needs explicit secrets |
| 25 | `test/**` | multiple | Mock mode in tests | Tests rely on mock behavior | **LOW** | OK for tests, but add tests for production guard |

---

## 3. PRODUCTION RISK FINDINGS

### 🔴 **CRITICAL RISKS**

#### 3.1 Auto Fallback to Mock on Network Error
- **Location:** `lib/core/services/api_service.dart` lines 84-99, 124-136, 156-165, 184-193, 210-219, 326-367
- **Behavior:** On ANY `DioExceptionType.connectionError` or `DioExceptionType.connectionTimeout`, the code automatically sets `_mockModeEnabled = true` and `_useMockData = true`, then returns mock data
- **Impact:** Production users experience network errors but the app silently continues with FAKE DATA
- **Severity:** **CRITICAL**
- **Fix:** Remove all auto-fallback logic. Network errors should propagate as errors, never fall back to mock.

#### 3.2 .env File Bundled as Flutter Asset
- **Location:** `pubspec.yaml` lines 108-110
- **Behavior:** `.env` file is listed in assets, meaning it gets bundled into the production app binary
- **Impact:** Production app contains development secrets and configuration
- **Severity:** **CRITICAL**
- **Fix:** Remove `.env` from pubspec.yaml assets immediately. Use `--dart-define` for runtime configuration only.

#### 3.3 Mock JWT Tokens
- **Location:** `lib/core/services/api_service.dart` lines 270-282, 295-302
- **Behavior:** Returns hardcoded fake JWT tokens: `'mock_jwt_token_abc123xyz789'`
- **Impact:** Authentication can succeed with fake tokens in mock mode
- **Severity:** **CRITICAL**
- **Fix:** Remove mock JWT generation. Authentication should fail in production without valid tokens.

#### 3.4 Mutable Static Mock State
- **Location:** `lib/core/services/api_service.dart` lines 28-29
- **Behavior:** `_useMockData` and `_mockModeEnabled` are static mutable variables
- **Impact:** Any code can enable mock mode globally, affecting all instances
- **Severity:** **CRITICAL**
- **Fix:** Remove static variables. Use instance-based configuration or make immutable.

#### 3.5 Hardcoded User/Driver IDs
- **Locations:**
  - `lib/routes/app_router.dart:233` - fallback to `'driver_1'`
  - `lib/features/map/presentation/cubits/ride_cubit.dart:222` - `driverId: 'driver_1'`
  - `lib/features/map/presentation/cubits/ride_cubit.dart:237` - `acceptRide(rideId, 'driver_1')`
  - `lib/features/auth/presentation/cubits/auth_cubit.dart:81` - `id: '0'`
- **Behavior:** Falls back to hardcoded IDs when real IDs are not available
- **Impact:** Production code can operate with fake identities
- **Severity:** **HIGH**
- **Fix:** Remove all hardcoded IDs. Fail explicitly if authentication/user data is missing.

#### 3.6 Default BackendMode.mock in Service Locator
- **Location:** `lib/core/di/service_locator.dart:84`
- **Behavior:** Default parameter is `BackendMode.mock`
- **Impact:** If code doesn't explicitly pass mode, it defaults to mock
- **Severity:** **HIGH**
- **Fix:** Change default to `BackendMode.supabase`

---

### 🟡 **HIGH RISKS**

#### 3.7 .env Loaded via flutter_dotenv
- **Location:** `lib/main_common.dart:25`
- **Behavior:** Tries to load `.env` file at runtime
- **Impact:** Even if `.env` is removed from assets, the code tries to load it
- **Severity:** **HIGH**
- **Fix:** Remove `dotenv.load()` call. Use `const String.fromEnvironment()` only.

#### 3.8 Firebase Fallback for Analytics
- **Location:** `lib/main_common.dart:80-88`
- **Behavior:** Different error handlers for Firebase vs non-Firebase
- **Impact:** Mock mode error handling is less strict
- **Severity:** **MEDIUM**
- **Fix:** Standardize error handling, don't relax security in mock mode

#### 3.9 Dev Flavor Defaults to Mock Mode
- **Location:** `lib/main_dev.dart:19`
- **Behavior:** `enableMockMode: const bool.fromEnvironment('MOCK_MODE', defaultValue: true)`
- **Impact:** Dev builds default to mock, which is fine but should be explicit
- **Severity:** **LOW** (acceptable for dev)

---

## 4. REQUIRED PATCH PLAN

### Phase 1: Emergency Security Fixes (Do First)

#### 4.1 Remove .env from Assets
**File:** `pubspec.yaml`
```yaml
# REMOVE these lines (108-110):
assets:
  - .env
```
**Impact:** Prevents `.env` from being bundled in production builds.

#### 4.2 Remove dotenv Loading
**File:** `lib/main_common.dart`
```dart
# REMOVE lines 23-28:
// 1. Load Environment Settings
try {
  await dotenv.load(fileName: ".env");
} catch (e) {
  debugPrint('⚠️ Note: .env file not found, using environment defines if available.');
}
```
**Impact:** Forces use of `--dart-define` only.

#### 4.3 Remove Auto-Fallback in ApiService
**File:** `lib/core/services/api_service.dart`

Remove ALL instances of:
```dart
if (error.type == DioExceptionType.connectionError ||
    error.type == DioExceptionType.connectionTimeout) {
  _useMockData = true;
  _mockModeEnabled = true;
  // ... return mock data
}
```

Replace with:
```dart
throw _handleError(error);
```

**Locations:** Lines 89-96, 127-133, 157-161, 185-191, 211-215, 393-398, 457-458

**Impact:** Network errors will fail openly instead of silently using mock data.

#### 4.4 Make Static Mock State Immutable
**File:** `lib/core/services/api_service.dart`
```dart
# CHANGE lines 28-29:
// FROM:
bool _useMockData = false;
static bool _mockModeEnabled = false;

// TO:
final bool _useMockData;
static final bool _mockModeEnabled;

// In constructor (line 31-32):
ApiService(this._authInterceptor, {Dio? dio, bool enableMockMode = false})
  : _useMockData = enableMockMode,
    _mockModeEnabled = enableMockMode {
  // ...
}

# REMOVE static setters (lines 484-497):
static void enableMockMode() { ... }
static void disableMockMode() { ... }
static bool isMockModeEnabled() { ... }
```

**Impact:** Prevents runtime modification of mock state.

#### 4.5 Remove Mock JWT Tokens
**File:** `lib/core/services/api_service.dart`

Remove ALL mock JWT responses:
```dart
// Lines 270-278 - REMOVE JWT mock
if (normEndpoint.contains('/wp-json/jwt-auth/v1/token')) {
  return {
    'token': 'mock_jwt_token_abc123xyz789',
    'user_email': 'erik.babcan@example.com',
    'user_nicename': 'erik.babcan',
    'user_display_name': 'Erik Babčan',
    'expires_in': 3600,
  };
}

// Lines 280-282 - REMOVE JWT validate mock
if (normEndpoint.contains('/wp-json/jwt-auth/v1/token/validate')) {
  return {'code': 'jwt_auth_valid_token', 'data': {'status': 200}};
}

// Lines 295-302 - REMOVE POST JWT mock
if (normEndpoint.contains('/wp-json/jwt-auth/v1/token')) {
  return {
    'token': 'mock_jwt_token_abc123xyz789',
    'user_email': data['username'] ?? 'erik.babcan@example.com',
    'user_nicename': 'erik.babcan',
    'user_display_name': 'Erik Babčan',
    'expires_in': 3600,
  };
}
```

**Impact:** Prevents fake authentication in production.

#### 4.6 Remove Hardcoded IDs
**File:** `lib/routes/app_router.dart:233`
```dart
# CHANGE FROM:
final driverId = authState is Authenticated ? authState.user.id : 'driver_1';

# TO:
final driverId = authState is Authenticated ? authState.user.id : throw StateError('Driver not authenticated');
```

**File:** `lib/features/map/presentation/cubits/ride_cubit.dart:222`
```dart
# CHANGE FROM:
driverId: 'driver_1',

# TO:
driverId: throw StateError('Driver ID required'),
```

**File:** `lib/features/map/presentation/cubits/ride_cubit.dart:237`
```dart
# CHANGE FROM:
await _rideRepository.acceptRide(rideId, 'driver_1');

# TO:
final driverId = // get from auth state; 
await _rideRepository.acceptRide(rideId, driverId);
```

**File:** `lib/features/auth/presentation/cubits/auth_cubit.dart:81`
```dart
# CHANGE FROM:
id: '0',

# TO:
id: throw StateError('User ID required'),
```

**Impact:** Prevents fake identity usage.

#### 4.7 Change Default BackendMode
**File:** `lib/core/di/service_locator.dart:84`
```dart
# CHANGE FROM:
Future<void> setupServiceLocator({BackendMode mode = BackendMode.mock}) async {

# TO:
Future<void> setupServiceLocator({BackendMode mode = BackendMode.supabase}) async {
```

**Impact:** Defaults to production mode instead of mock.

#### 4.8 Add Production Guard
**File:** `lib/core/di/service_locator.dart:84-88`
```dart
Future<void> setupServiceLocator({BackendMode mode = BackendMode.supabase}) async {
  // PRODUCTION GUARD - Fail closed in production
  assert(mode != BackendMode.mock || kDebugMode, 
    'Mock mode is NOT allowed in production. Use BackendMode.supabase.');
  
  // ... rest of initialization
}
```

**Impact:** Catches accidental mock mode in production at startup.

#### 4.9 Add Production Guard in main_prod.dart
**File:** `lib/main_prod.dart:5-21`
```dart
void main() {
  // PRODUCTION GUARD - Ensure mock mode is disabled
  const mockMode = const bool.fromEnvironment('MOCK_MODE', defaultValue: false);
  assert(!mockMode, 'MOCK_MODE must be false in production builds');
  
  final prodConfig = AppConfig(
    environment: AppEnvironment.prod,
    supabaseUrl: const String.fromEnvironment(
      'SUPABASE_URL_PROD',
      defaultValue: 'https://gold-taxi.supabase.co',
    ),
    supabaseAnonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY_PROD',
      defaultValue: 'prod-supabase-anon-key',
    ),
    stripePublishableKey: const String.fromEnvironment(
      'STRIPE_KEY_PROD',
      defaultValue: 'pk_live_prod_stripe_key',
    ),
    enableMockMode: false,  // Explicitly false for production
    enableAnalytics: true,
  );

  mainCommon(prodConfig);
}
```

**Impact:** Fails fast if MOCK_MODE is enabled in production.

#### 4.10 Remove MockApiService Import
**File:** `lib/core/services/api_service.dart:10`
```dart
# REMOVE:
import 'mock_api_service.dart';
```

**Impact:** Removes dependency on mock service.

#### 4.11 Remove MockApiService References
**File:** `lib/core/services/api_service.dart`
Remove all references to `MockApiService.getMock...()`:
- Lines 230-231, 234-235, 238-239, 242-246, 250-254, 258-262, 266-268, 412
- Lines 266-268

---

## 5. PROPOSED CODE CHANGES SUMMARY

### Summary by File

#### `pubspec.yaml`
- **Remove:** `.env` from assets list (lines 108-110)
- **Impact:** Prevents secrets from being bundled

#### `lib/main_common.dart`
- **Remove:** `dotenv.load()` call (lines 23-28)
- **Impact:** Forces use of `--dart-define`

#### `lib/main_prod.dart`
- **Add:** Assertion to guard against MOCK_MODE
- **Change:** Make `enableMockMode` explicitly false
- **Impact:** Production cannot accidentally use mock

#### `lib/main_dev.dart`
- **No changes needed** - OK for dev to use mock

#### `lib/core/di/service_locator.dart`
- **Change:** Default `BackendMode` to `supabase`
- **Add:** Assertion guard against mock mode in production
- **Impact:** Defaults to production, fails on mock

#### `lib/core/services/api_service.dart`
- **Remove:** All auto-fallback logic (7 locations)
- **Remove:** Static mutable state `_useMockData`, `_mockModeEnabled`
- **Remove:** Static methods `enableMockMode()`, `disableMockMode()`, `isMockModeEnabled()`
- **Remove:** Mock JWT token generation (3 locations)
- **Remove:** MockApiService import and references
- **Change:** Make mock state instance-based and immutable
- **Impact:** Prevents silent fallback and fake authentication

#### `lib/routes/app_router.dart`
- **Remove:** Hardcoded `'driver_1'` fallback (line 233)
- **Change:** Throw error if driver not authenticated
- **Impact:** Prevents fake driver identity

#### `lib/features/map/presentation/cubits/ride_cubit.dart`
- **Remove:** Hardcoded `'driver_1'` (lines 222, 237)
- **Change:** Use authenticated driver ID or throw error
- **Impact:** Prevents fake driver identity

#### `lib/features/auth/presentation/cubits/auth_cubit.dart`
- **Remove:** Hardcoded `id: '0'` (line 81)
- **Change:** Use real user ID or throw error
- **Impact:** Prevents fake user identity

---

## 6. TEST PLAN

### New Tests to Create

#### Test 1: Production Config Rejects BackendMode.mock
```dart
// File: test/unit/mock_mode_production_guard_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/config/app_config.dart';
import 'package:gold_taxi/core/di/service_locator.dart';

void main() {
  test('Production config must reject BackendMode.mock', () {
    final prodConfig = AppConfig(
      environment: AppEnvironment.prod,
      supabaseUrl: 'https://test.supabase.co',
      supabaseAnonKey: 'test-key',
      stripePublishableKey: 'test-stripe',
      enableMockMode: true, // Try to enable mock in prod
      enableAnalytics: true,
    );
    
    expect(() => setupServiceLocator(mode: BackendMode.mock),
      throwsAssertion);
  });
  
  test('Production main_prod.dart rejects MOCK_MODE env var', () {
    // This should be tested via integration test with --dart-define=MOCK_MODE=true
    // Expected: App fails to start with assertion error
  });
}
```

#### Test 2: Network Error Does Not Enable Mock
```dart
// File: test/unit/api_service_no_mock_fallback_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/core/interceptors/auth_interceptor.dart';

class MockAuthInterceptor extends Mock implements AuthInterceptor {}

void main() {
  late ApiService apiService;
  late MockAuthInterceptor mockAuthInterceptor;
  
  setUp(() {
    mockAuthInterceptor = MockAuthInterceptor();
    apiService = ApiService(mockAuthInterceptor, enableMockMode: false);
  });
  
  test('Connection error throws exception, does NOT enable mock', () async {
    final dioException = DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionError,
    );
    
    expect(() => apiService._onError(dioException, any()), 
      throwsA(isA<ApiException>()));
    
    // Verify mock mode was NOT enabled
    expect(ApiService.isMockModeEnabled(), false);
  });
  
  test('Timeout error throws exception, does NOT enable mock', () async {
    final dioException = DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionTimeout,
    );
    
    expect(() => apiService._onError(dioException, any()), 
      throwsA(isA<ApiException>()));
    
    expect(ApiService.isMockModeEnabled(), false);
  });
}
```

#### Test 3: Mock JWT Cannot Authenticate in Production
```dart
// File: test/unit/mock_jwt_production_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/services/api_service.dart';

void main() {
  test('JWT endpoint returns real error in production, not mock token', () async {
    final apiService = ApiService(MockAuthInterceptor(), enableMockMode: false);
    
    // In production mode, JWT endpoint should NOT return mock token
    final result = await apiService.get('/wp-json/jwt-auth/v1/token');
    
    // Should be real API response or throw, NOT mock token
    expect(result, isNot(contains('mock_jwt_token_abc123xyz789')));
  });
}
```

#### Test 4: .env Not Listed as Flutter Asset
```dart
// File: test/unit/env_not_bundled_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

void main() {
  test('.env must NOT be listed in pubspec.yaml assets', () async {
    final pubspecPath = path.join('..', '..', 'pubspec.yaml');
    final yaml = YamlMap.loadYaml(await File(pubspecPath).readAsString());
    final assets = yaml['flutter']?['assets'] as YamlList?;
    
    if (assets != null) {
      for (final asset in assets) {
        expect(asset.toString(), isNot(contains('.env')));
      }
    }
  });
}
```

#### Test 5: Dev Mock Mode Still Works
```dart
// File: test/unit/dev_mock_mode_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/config/app_config.dart';
import 'package:gold_taxi/core/di/service_locator.dart';

void main() {
  test('Dev config allows mock mode', () {
    final devConfig = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: 'https://dev.supabase.co',
      supabaseAnonKey: 'dev-key',
      stripePublishableKey: 'dev-stripe',
      enableMockMode: true,
      enableAnalytics: false,
    );
    
    // In debug mode, this should work
    expect(() => setupServiceLocator(mode: BackendMode.mock),
      returnsNormally);
  });
}
```

---

## 7. MERGE SAFETY

### Coordination with Batch 1 / Item 1 (Auth Unification)

| File | This Task (Mock Mode) | Auth Unification | Coordination Needed |
|------|------------------------|-------------------|---------------------|
| `lib/core/di/service_locator.dart` | Change default BackendMode, add guards | Likely modifies auth setup | **MUST COORDINATE** - Both touch service locator |
| `lib/features/auth/presentation/cubits/auth_cubit.dart` | Remove hardcoded ID | Likely modifies auth state | **SAFE** - Our changes are additive (removing hardcoded values) |
| `lib/features/auth/data/repositories/auth_repository.dart` | No changes | Will modify | **SAFE** - We don't touch auth repo |
| `lib/main_common.dart` | Remove dotenv | May modify | **WAIT** - Auth unification may also touch main files |
| `lib/main_prod.dart` | Add guard assertion | May modify | **WAIT** - Auth unification may also touch main files |
| `lib/main_dev.dart` | No changes | May modify | **SAFE** - We don't change dev main |
| `pubspec.yaml` | Remove .env asset | No changes expected | **SAFE** - Independent change |
| `lib/core/services/api_service.dart` | Major refactor | No changes expected | **SAFE** - Independent change |
| `lib/routes/app_router.dart` | Remove hardcoded driver_1 | May modify router | **SAFE** - Our change is small and compatible |
| `lib/features/map/presentation/cubits/ride_cubit.dart` | Remove hardcoded driver_1 | No changes expected | **SAFE** - Independent change |

### Recommendation:
**Option B: Needs manual merge coordination**

The changes to `lib/core/di/service_locator.dart` and potentially the main entry files (`main_common.dart`, `main_prod.dart`) will likely overlap with Auth Unification changes. These files should be merged manually to ensure both security guards and auth changes are properly integrated.

---

## 8. COMMAND RESULTS

### pwd
```
/Users/erikbabcan/Gold-taxi
```

### git status --short
```
M  lib/core/di/service_locator.dart
M  lib/features/auth/data/repositories/auth_repository.dart
M  lib/features/auth/presentation/cubits/auth_cubit.dart
M  lib/routes/app_router.dart
audit/goldtaxi-mock-mode-production-preflight
```

### git branch --show-current
```
audit/goldtaxi-mock-mode-production-preflight
```

### rg -n "BackendMode\|mock\|MockApiService\|mock_jwt\|_mockModeEnabled\|fallback\|dotenv\|\\.env\|AppConfig\|main_dev\|main_prod\|dart-define\|driver_1\|id: '0'\|id: \"0\""
**Key Findings:**
- `lib/main_prod.dart:19` - `enableMockMode: const bool.fromEnvironment('MOCK_MODE', defaultValue: false)`
- `lib/main_dev.dart:19` - `enableMockMode: const bool.fromEnvironment('MOCK_MODE', defaultValue: true)`
- `lib/main_common.dart:25` - `dotenv.load(fileName: ".env")`
- `lib/main_common.dart:31` - `backendMode = config.enableMockMode ? BackendMode.mock : BackendMode.supabase`
- `lib/main_common.dart:36-38` - `ApiService.enableMockMode()`
- `pubspec.yaml:108-110` - `.env` listed as asset
- `lib/core/services/api_service.dart:28-29` - Static mutable mock state
- `lib/core/services/api_service.dart:84-99` - Auto-fallback on error
- `lib/core/services/api_service.dart:124-136` - Auto-fallback on error
- `lib/core/services/api_service.dart:270-282` - Mock JWT token
- `lib/core/services/api_service.dart:295-302` - Mock JWT POST
- `lib/routes/app_router.dart:233` - Hardcoded `'driver_1'`
- `lib/features/map/presentation/cubits/ride_cubit.dart:222,237` - Hardcoded `'driver_1'`
- `lib/features/auth/presentation/cubits/auth_cubit.dart:81` - Hardcoded `id: '0'`
- `.github/workflows/flutter-ci.yml:39-40` - Builds with `BACKEND_MODE=mock`
- `.github/workflows/flutter-ci.yml:45-47` - Builds with `BACKEND_MODE=supabase`

### rg -n "assets:\|\\.env" pubspec.yaml
```
pubspec.yaml:108:  assets:
pubspec.yaml:110:    - .env
```

### rg -n "flutter build\|dart-define\|BACKEND_MODE\|ENV\|SUPABASE" .github/
```
.github/workflows/flutter-ci.yml:39: flutter build web --release --no-tree-shake-icons \
.github/workflows/flutter-ci.yml:40:   --dart-define=BACKEND_MODE=mock
.github/workflows/flutter-ci.yml:45: flutter build web --release --no-tree-shake-icons \
.github/workflows/flutter-ci.yml:46:   --dart-define=BACKEND_MODE=supabase \
.github/workflows/flutter-ci.yml:47:   --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
.github/workflows/flutter-ci.yml:48:   --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
.github/workflows/firebase-hosting-merge.yml:34: flutter build web --release --no-tree-shake-icons \
.github/workflows/firebase-hosting-merge.yml:35:   --dart-define=BACKEND_MODE=supabase \
.github/workflows/firebase-hosting-merge.yml:36:   --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
.github/workflows/firebase-hosting-merge.yml:37:   --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} \
.github/workflows/firebase-hosting-merge.yml:38:   --dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}
```

### flutter analyze
```
No issues found!
```
(Note: Previous run showed 0 issues, but there may be warnings from plugin dependencies)

### flutter test
```
All tests passed! (191 tests)
```
(Note: Tests pass, but mock mode vulnerabilities exist in production)

---

## 9. FINAL DECISION

### 🔴 **FINAL DECISION: C) Too risky, requires broader refactor**

**Rationale:**

While the fixes are well-defined and localized, the **CRITICAL** nature of the vulnerabilities (automatic mock fallback, .env in assets, mock JWT tokens) means that:

1. **Immediate action is required** - These vulnerabilities could allow production users to operate with fake data
2. **Broader refactor needed** - The mock fallback logic is deeply embedded in `ApiService` and needs architectural changes
3. **Coordination required** - Changes overlap with Auth Unification (Batch 1 / Item 1)
4. **Production impact** - Must ensure zero downtime and complete testing

**Recommended Approach:**

1. **IMMEDIATE (Today):** Remove `.env` from pubspec.yaml assets and remove dotenv.load() - This is a 2-line fix that prevents the most critical security issue
2. **PHASE 1:** Create the production guard assertions and remove auto-fallback logic
3. **PHASE 2:** Remove mock JWT tokens and hardcoded IDs
4. **PHASE 3:** Coordinate with Auth Unification team for service_locator.dart changes

**Security Priority:** The `.env` in assets and auto-fallback to mock are **CRITICAL** and should be fixed immediately, even if it requires a hotfix release.

---

## 10. PRIORITY ACTION ITEMS

| # | Action | File | Risk Level | ETA |
|---|--------|------|------------|-----|
| 1 | Remove .env from pubspec.yaml assets | pubspec.yaml | CRITICAL | 5 min |
| 2 | Remove dotenv.load() call | lib/main_common.dart | CRITICAL | 5 min |
| 3 | Remove auto-fallback in ApiService._onError() | lib/core/services/api_service.dart | CRITICAL | 30 min |
| 4 | Remove auto-fallback in ApiService.get() | lib/core/services/api_service.dart | CRITICAL | 30 min |
| 5 | Remove auto-fallback in ApiService.post() | lib/core/services/api_service.dart | CRITICAL | 30 min |
| 6 | Remove auto-fallback in ApiService.put() | lib/core/services/api_service.dart | CRITICAL | 30 min |
| 7 | Remove auto-fallback in ApiService.delete() | lib/core/services/api_service.dart | CRITICAL | 30 min |
| 8 | Remove auto-fallback in ApiService._isEndpointAvailable() | lib/core/services/api_service.dart | CRITICAL | 30 min |
| 9 | Remove auto-fallback in ApiService.fetchCptData() | lib/core/services/api_service.dart | CRITICAL | 30 min |
| 10 | Remove mock JWT tokens | lib/core/services/api_service.dart | CRITICAL | 30 min |
| 11 | Remove static mutable mock state | lib/core/services/api_service.dart | HIGH | 30 min |
| 12 | Add production guard in service_locator.dart | lib/core/di/service_locator.dart | HIGH | 15 min |
| 13 | Add production guard in main_prod.dart | lib/main_prod.dart | HIGH | 10 min |
| 14 | Change default BackendMode to supabase | lib/core/di/service_locator.dart | HIGH | 5 min |
| 15 | Remove hardcoded IDs | lib/routes/app_router.dart, lib/features/map/..., lib/features/auth/... | HIGH | 20 min |
| 16 | Create production guard tests | test/unit/ | HIGH | 60 min |

---

**Report Path:** `ops/reports/batch1-item2-mock-mode-production-preflight.md`  
**Summary:** CRITICAL security vulnerabilities found - mock mode can auto-enable in production, .env bundled as asset, mock JWT tokens accepted, hardcoded IDs used.  
**Verdict:** **FAIL** - Immediate action required before production deployment.  
**Coordination:** Must coordinate with Batch 1 / Item 1 (Auth Unification) for service_locator.dart changes.  
**Recommendation:** Fix CRITICAL issues (items 1-2) immediately, then proceed with Phase 1-3 in coordination with Auth team.
