# 🎯 Complete Blueprint: 100% Completion of Gold Taxi (WordPress JetEngine & Flutter)

This blueprint outlines the remaining development phases to complete the Flutter mobile application integrated with WordPress JetEngine. The current codebase has the directory structure and skeletons in place, but many modules need deep logic implementation, state management wiring, and edge-case handling.

---

## 🛠️ One-Command Reinstallation, Fix, and Analysis Tool

To easily maintain and verify the codebase at any point, use the helper script created at [clean_check.sh](file:///Users/erikbabcan/Gold-taxi/clean_check.sh):

```bash
./clean_check.sh
```

This script performs the following tasks sequentially:
1. **Clean Cache**: Runs `flutter clean` to remove build artifacts.
2. **Resolve Dependencies**: Runs `flutter pub get` to download and align packages.
3. **Generate Code**: Runs `build_runner` to generate any JSON serializable or Retrofit clients.
4. **Static Analysis**: Runs `flutter analyze` to check for compilation/lint issues.

---

## 🚀 Phased Blueprint for 100% Project Completion

### Phase 1: Dependency Injection (DI) & Networking Validation
*   **Goal**: Ensure all features are registered in the service locator and communication with the WordPress REST API is configured.
*   **Key Files**:
    *   [service_locator.dart](file:///Users/erikbabcan/Gold-taxi/lib/core/di/service_locator.dart)
    *   [api_service.dart](file:///Users/erikbabcan/Gold-taxi/lib/core/services/api_service.dart)
*   **Tasks**:
    1. Verify all new BLoCs/Cubits, Repositories, and DataSources are registered in `service_locator.dart`.
    2. Test [auth_interceptor.dart](file:///Users/erikbabcan/Gold-taxi/lib/core/interceptors/auth_interceptor.dart) to automatically append the JWT token to outgoing API requests and handle `401 Unauthorized` token refreshing.
    3. Configure API base URL and timeouts in [api_constants.dart](file:///Users/erikbabcan/Gold-taxi/lib/core/constants/api_constants.dart).

---

### Phase 2: Authentication & Secure Session Module
*   **Goal**: Establish a secure registration, login, and token storage pipeline.
*   **Key Files**:
    *   `lib/features/auth/presentation/pages/login_page.dart`
    *   `lib/features/auth/presentation/cubits/auth_cubit.dart`
    *   [secure_storage_service.dart](file:///Users/erikbabcan/Gold-taxi/lib/core/services/secure_storage_service.dart)
*   **Tasks**:
    1. Implement JWT Token requests from the WordPress Authentication endpoints.
    2. Store the JWT token securely using [secure_storage_service.dart](file:///Users/erikbabcan/Gold-taxi/lib/core/services/secure_storage_service.dart) (`flutter_secure_storage`).
    3. Create form validation for the login/register fields using `FormState` and validators.
    4. Connect Firebase Auth to enable Google/Apple logins.

---

### Phase 3: WordPress Custom Post Types (CPT) Modules
*   **Goal**: Connect dynamic content (Products, Services, Events, Blog) to remote and local data sources.
*   **Tasks**:
    1. **Products Module**:
        *   Implement grid and list layouts in `products_page.dart`.
        *   Wire up `products_bloc.dart` to fetch products using pagination parameters.
        *   Create filter panels for price range, availability, and WooCommerce categories.
    2. **Services & Bookings Module**:
        *   Display active services in `services_page.dart`.
        *   Build an interactive date/time calendar selector in `booking_page.dart` referencing provider availability.
        *   Set up booking request payloads sent to JetEngine Bookings endpoints.
    3. **Events Module**:
        *   Build calendar grid layouts showing future events in `events_page.dart`.
        *   Implement registration forms for events with capacity validation.
    4. **Blog Module**:
        *   Format rich text posts using `flutter_html` in `blog_detail_page.dart`.
        *   Add pagination and pull-to-refresh to `blog_page.dart`.

---

### Phase 4: Shared Interactive Features
*   **Goal**: Build components for user reviews, search, and frequently asked questions.
*   **Tasks**:
    1. **Review & Rating System**:
        *   Wire up `reviews_bloc.dart` to display average stars and list reviews for products/services.
        *   Create `review_form.dart` to submit reviews with ratings (1-5), pros, cons, and text.
    2. **Unified Search Module**:
        *   Implement search term autocomplete in `search_page.dart`.
        *   Integrate multi-entity search results (Posts, Products, Services, Events).
    3. **FAQ Accordion**:
        *   Create expanding lists using `ExpansionPanelList` in `faq_page.dart` sorted by categories.

---

### Phase 5: E-Commerce & Checkout Flow
*   **Goal**: Build a persistent local shopping cart and a multi-step checkout form.
*   **Key Files**:
    *   `lib/features/checkout/presentation/cubits/cart_cubit.dart`
    *   `lib/features/checkout/presentation/pages/cart_page.dart`
    *   `lib/features/checkout/presentation/pages/checkout_page.dart`
*   **Tasks**:
    1. Save cart items in a local Hive box using `LocalStorageService` to retain items between sessions.
    2. Develop a multi-step Checkout Wizard:
        *   *Step 1*: Billing/Shipping details.
        *   *Step 2*: Payment method selector (Stripe / Bank Transfer / Cash on Delivery).
        *   *Step 3*: Summary & confirmation.
    3. Push finalized order payloads to WooCommerce endpoints.

---

### Phase 6: Offline-First Capabilities & Syncing Engine
*   **Goal**: Make the app operational without internet access using caching and connectivity checks.
*   **Key Files**:
    *   `lib/core/services/local_storage_service.dart`
    *   `lib/core/services/connectivity_service.dart`
*   **Tasks**:
    1. Implement caching in all Remote Data Sources so they write/retrieve from local Hive boxes when network calls fail.
    2. Listen to network changes. If the user comes online, trigger any pending write operations (like reviews or booking registrations).
    3. Add subtle offline banners in the app UI when connection is lost.

---

### Phase 7: Polish, Transitions, & Deep Linking
*   **Goal**: Make the user experience premium and integrate SEO deep-linking.
*   **Tasks**:
    1. **Animations**: Add subtle micro-animations (Lottie for success screens, shimmers for loading states, smooth page transitions).
    2. **Deep Links**: Setup `app_links` to handle paths like `goldtaxi://products/{id}` or `https://goldtaxi.com/services/{slug}`.
    3. **Theme Modes**: Verify high-contrast accessibility and clean Light/Dark modes in `app_theme.dart`.

---

## 📋 Pre-Launch Production Checklist

- [ ] **WordPress REST API**: Configure Redis object caching to minimize database query latency.
- [ ] **Security**: Enable ProGuard obfuscation for Android and compile iOS in Release mode.
- [ ] **Firebase Settings**: Deploy firestore and storage rules restricting anonymous writes.
- [ ] **Testing**: Ensure all models have unit tests covering JSON serialization.
