# 🛠 Developer Documentation (DEVELOPER.md)

Welcome to the **Gold-Taxi Developer Guide**. This document details the architectural guidelines, state management strategies, routing rules, and custom integrations configured in the codebase.

---

## 🏛 Clean Architecture & Core Structure

The application is structured around a modified **Clean Architecture** framework, optimized for Flutter's widget tree lifecycle and remote API fetching.

```directory
lib/
├── core/
│   ├── constants/       # Global styles (AppColors, AppTheme) and endpoints (ApiConstants)
│   ├── di/              # Centralized service locator (GetIt configuration)
│   ├── interceptors/    # Dio interceptors for auth tokens and request logging
│   └── services/        # Platform & networking services (Api, Storage, Notifications)
├── features/            # Modular feature folders
│   ├── auth/            # Authentication presentation & repository
│   ├── blog/            # WP CPT announcements & news
│   ├── checkout/        # E-shop Cart & checkout flows
│   ├── insolvency_monitoring/ # Predikcia úpadku & payment analytics
│   ├── products/        # WooCommerce products storefront
│   └── services/        # Ride booking & scheduling
├── models/              # Shared models for serialization
└── routes/              # Centralized router configuration (GoRouter config)
```

### Key Architectural Guidelines
1.  **Strict Separation of Concerns**: No UI Widget should directly instantiate a service or repository. Use Cubit/BLoC state emitters as intermediates.
2.  **Explicit Dependency Injection**: All services, repositories, bloc instances, and data sources are registered in [service_locator.dart](file:///Users/erikbabcan/Gold-taxi/lib/core/di/service_locator.dart).
3.  **Data Isolation**: Network payloads are deserialized directly into typed models (e.g. `BaseWordPressModel` derivatives or `InvoiceModel`) and never passed as raw JSON maps to the presentation layer.

---

## 🚦 State Management and Lifecycle Rules

We employ **flutter_bloc** (BLoC for multi-event pipelines, Cubits for simple states).

### ⚠️ Factory vs. Singleton Lifecycle Warning
Understanding the difference in GetIt registrations is critical to prevent memory leaks and state errors:
*   **Lazy Singletons** (`getIt.registerLazySingleton`): Used for global, app-wide managers like `AuthCubit` (tracks user login state) and `CartCubit` (tracks items in cart). These instances are persistent and are never disposed.
*   **Factories** (`getIt.registerFactory`): Used for all page-level state management (e.g., `InsolvencyCubit`, `BlogBloc`, `SearchBloc`). 
    *   *Rule*: Since page-level widgets use `BlocProvider(create: (context) => getIt<MyCubit>())`, the provider will call `close()` on the instance when the widget is disposed.
    *   *Danger*: If a Cubit is registered as a singleton, the closed instance is cached. Re-opening the page will throw a `StateError`. Always use `registerFactory` for screen-specific Blocs/Cubits.

---

## 🛣 Smerovanie & Routovanie (GoRouter)

The routing engine is defined in [app_router.dart](file:///Users/erikbabcan/Gold-taxi/lib/routes/app_router.dart).

```mermaid
graph TD
    A[GoRouter] --> B{Auth Status?}
    B -->|Unauthenticated| C[/login]
    B -->|Authenticated| D[ShellRoute / MainShell]
    D --> E[/]
    D --> F[/services]
    D --> G[/products]
    D --> H[/events]
    D --> I[/blog]
    A --> J[/insolvency]
    A --> K[/cart]
    A --> L[/checkout]
```

*   **ShellRoute (`MainShell`)**: Keeps the `BottomNavigationBar` state active and static when switching between main tabs.
*   **FullScreen Routes**: Detail pages (like `/blog/detail` or `/checkout`) are placed outside the shell route, hiding the navigation bar and allowing a distraction-free immersive layout.
*   **Auth Redirection**: On state changes emitted by `AuthCubit`, the `GoRouterRefreshStream` notifies GoRouter to re-evaluate current paths, automatically redirecting logged-out sessions to `/login`.

---

## 📈 Predictive Insolvency Engine

The predictive model is located in [insolvency_predictor_service.dart](file:///Users/erikbabcan/Gold-taxi/lib/core/services/insolvency_predictor_service.dart).

### 1. Mathematical Scoring Formula
The predictor runs on all invoices emitted within a rolling **180-day window**. It evaluates three core risk components:

$$\text{Risk Score} = S_{\text{delay}} + S_{\text{ratio}} + S_{\text{trend}} + S_{\text{critical}}$$

1.  **Average Delay ($S_{\text{delay}}$, Max 40 pts)**:
    $$\text{Average Delay} > 60\text{ days} \implies 40\text{ pts}$$
    $$30 < \text{Average Delay} \le 60\text{ days} \implies 25\text{ pts}$$
    $$15 < \text{Average Delay} \le 30\text{ days} \implies 10\text{ pts}$$
2.  **Unpaid-to-Overdue Ratio ($S_{\text{ratio}}$, Max 45 pts)**:
    $$\text{Unpaid Ratio} = \frac{\sum \text{Amount of Overdue Unpaid Invoices}}{\sum \text{Total Invoiced Amount}}$$
    $$\text{Unpaid Ratio} > 0.6 \implies 45\text{ pts}$$
    $$0.4 < \text{Unpaid Ratio} \le 0.6 \implies 30\text{ pts}$$
    $$0.2 < \text{Unpaid Ratio} \le 0.4 \implies 15\text{ pts}$$
    $$0.05 < \text{Unpaid Ratio} \le 0.2 \implies 5\text{ pts}$$
3.  **Delay Trend ($S_{\text{trend}}$, Max 20 pts)**:
    Evaluates whether the client's payment discipline is deteriorating by comparing the average delay of the *Recent Window* (0-90 days) against the *Prior Window* (90-180 days):
    $$\text{Delay Trend} = \text{AvgDelay}_{\text{0-90}} - \text{AvgDelay}_{\text{90-180}}$$
    $$\text{Delay Trend} > 15\text{ days} \implies 20\text{ pts}$$
    $$5 < \text{Delay Trend} \le 15\text{ days} \implies 10\text{ pts}$$
    $$\text{Delay Trend} < -5\text{ days} \text{ and } \text{Unpaid Ratio} < 0.3 \implies -10\text{ pts (Risk reduction bonus)}$$
4.  **Critical Age ($S_{\text{critical}}$, Max 10 pts)**:
    If any single invoice remains unpaid and has passed its due date by **more than 90 days**, a penalty of **+10 pts** is added.

### 2. Risk Level Classifications & Preditions
*   **Low Risk (`Nízke`)**: Score $< 35$. Payment is stable.
*   **Medium Risk (`Stredné`)**: Score $35 - 69$. Generates warnings. Insolvency is predicted **if** the delay trend is deteriorating by $>20$ days and unpaid ratio exceeds $30\%$.
*   **High Risk (`Vysoké`)**: Score $\ge 70$. Triggers a high-priority warning prediction. **Predicts insolvency 3 months (90 days) in advance.**

---

## 🌐 Resilient WordPress Fallback Client

Custom Post Types (CPT) can be unpredictable on staging/production environments due to plugin configurations. To counter this, `ApiService.fetchCptData` implements a **3-tier graceful fallback strategy**:

1.  **WP CPT Native Endpoint**: Tries to fetch from standard WordPress Custom Post Type routes (e.g. `/wp-json/wp/v2/booking`).
2.  **JetEngine Elementor Route**: Fallback query directed to JetEngine elements `/wp-json/jet-engine/v1/booking`.
3.  **Posts Type Query Filter**: Fallback query requesting general WordPress posts filtered by slug parameter `/wp-json/wp/v2/posts?type=booking`.

This ensures that UI widgets never throw unexpected JSON structure exceptions even if some WP tables are missing.

---

## 🛠 ProGuard & Build Configuration

*   **Android Minification**:
    Minification and resource shrinking are enabled for production release builds in `android/app/build.gradle.kts` to minimize size and optimize startup performance.
    ```kotlin
    isMinifyEnabled = true
    isShrinkResources = true
    ```
    Custom ProGuard rules are located in [proguard-rules.pro](file:///Users/erikbabcan/Gold-taxi/android/app/proguard-rules.pro).

*   **iOS Swift Package Manager (SPM) warning**:
    Certain third-party plugins (e.g. `share_plus`, `google_maps_flutter_ios`, `connectivity_plus`) do not fully support SPM yet. CocoaPods integration via [Podfile](file:///Users/erikbabcan/Gold-taxi/ios/Podfile) must be preserved. Avoid forcing pure SPM builds on iOS modules until plugin vendors upgrade native pods.
