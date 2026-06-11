# 🚕 Gold-Taxi Flutter Application

[![Flutter CI/CD Pipeline & Diagnostics](https://github.com/NEXIFY-STUDIO/gold-taxi/actions/workflows/ci_cd_pipeline.yml/badge.svg)](https://github.com/NEXIFY-STUDIO/gold-taxi/actions/workflows/ci_cd_pipeline.yml)
[![Flutter SDK](https://img.shields.io/badge/flutter-%3E%3D3.19.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.2.0-orange.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Gold-Taxi** is a premium, feature-rich Flutter application designed for modern passenger transport services, custom e-commerce products, events management, and corporate financial health tracking. The app utilizes a highly scalable **Clean Architecture** combined with robust state management (BLoC/Cubit) and a centralized Dependency Injection system.

---

## 🌟 Key Features

*   **🚖 Ride Booking & Services**: Real-time service selection (Odvoz, business trips, scheduled rides) with location tracking, map visualization, and pricing estimates.
*   **🛒 Gold-Taxi E-Shop**: Built-in storefront featuring customized merchandise and taxi products, complete with detailed categories, a reactive shopping cart (`CartCubit`), and checkout workflows.
*   **📈 Predictive Insolvency Monitoring**: 
    *   Predicts potential client bankruptcy **3 months in advance** based on payment discipline and billing records.
    *   Dynamic scoring algorithm (0-100%) checking average payment delay days, delay trends, and unpaid-to-overdue volume ratios.
    *   Interactive UI dashboard containing circular gauges, risk summaries, billing history, and Slovak language risk factors.
*   **📰 Corporate Blog / News Feed**: Integrates seamlessly with WordPress REST API to fetch corporate announcements and category-specific articles using resilient fallback logic.
*   **💬 Reviews & Feedback**: Client ratings and comments per taxi driver and service with local persistence.
*   **❓ Support Center & FAQs**: Expandable Frequently Asked Questions list sourced dynamically.
*   **🔒 Secure Local Storage & Authentication**: Encrypted storage for session tokens utilizing `flutter_secure_storage`.

---

## 🛠 Tech Stack

*   **Framework**: [Flutter](https://flutter.dev) (v3.19.x or higher)
*   **Language**: [Dart](https://dart.dev) (v3.2.0+)
*   **State Management**: `flutter_bloc` (v8.1.3+) & `equatable`
*   **Routing & Deep Linking**: `go_router` (v12.1.1+) & `app_links`
*   **Dependency Injection**: `get_it` (v7.5.0+)
*   **Backend & DB Integrations**: 
    *   [Supabase](https://supabase.com) (Auth & client sync)
    *   [Firebase](https://firebase.google.com) (Messaging, core, crashlytics)
    *   [WordPress / WooCommerce REST API](https://developer.wordpress.org/rest-api/) (CPT data source)
*   **HTTP Client**: `dio` (v5.4.0) with custom `AuthInterceptor` loggers

---

## 🚀 Quick Start Guide

### 1. Prerequisites
Ensure you have the Flutter SDK installed on your system:
```bash
flutter --version
```

### 2. Environment Configuration
Create a `.env` file in the root directory of the project and populate it with your environment keys:
```properties
WP_BASE_URL=https://your-wordpress-site.com
SUPABASE_URL=https://your-supabase-url.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_API_KEY=your-firebase-api-key
FIREBASE_APP_ID=your-firebase-app-id
```

### 3. Install Dependencies
Run the package getter:
```bash
flutter pub get
```

### 4. Build Code Generators
Generate serialization files (`*.g.dart`) for API communication models:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Running the Application
Launch the application on your desired target platform:
```bash
# Run on Google Chrome (web-javascript)
flutter run -d chrome

# Run on macOS Desktop
flutter run -d macos

# Run on a connected iOS/Android emulator
flutter run
```

---

## 🧪 Testing and Quality Assurance

The project maintains a zero-tolerance policy for broken features. It has a comprehensive test suite encompassing unit, widget, and integration tests.

### Running all tests locally:
```bash
flutter test
```

### Running static analysis (lint checks):
```bash
flutter analyze
```

---

## 📁 Directory Structure

```directory
Gold-taxi/
├── .github/workflows/      # CI/CD GitHub Actions pipelines
├── android/                # Android native config (ProGuard configuration included)
├── assets/                 # App icons, configuration, and .env
├── docs/                   # Blueprints, design documents, and developer specifications
├── integration_test/       # Headless app integration tests
├── ios/                    # iOS CocoaPods and build configurations
├── lib/
│   ├── core/               # Shared constants, dependency locator, widgets & services
│   ├── features/           # Clean-Architecture features (auth, products, insolvency, etc.)
│   │   └── insolvency_monitoring/
│   │       ├── data/
│   │       └── presentation/
│   │           ├── cubits/
│   │           └── pages/
│   ├── models/             # Shared data models (base WP models, invoices, cart, events)
│   ├── routes/             # Centralized routing configuration (GoRouter setup)
│   └── main.dart           # App entry point & resilient service initializations
├── macos/                  # macOS native configurations
└── test/                   # Comprehensive unit & widget tests
```

For a deeper dive into architecture, state management, and the insolvency monitoring logic, check out the [DEVELOPER.md](DEVELOPER.md).
