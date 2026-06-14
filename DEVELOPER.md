# Developer Guide

Tento dokument je hlavný technický prehľad pre Gold Taxi. README drží rýchly štart; tento súbor drží architektúru, pravidlá práce a prevádzkové poznámky.

## Stav projektu

- Framework: Flutter / Dart.
- Stav management: `flutter_bloc`, Cubit/Bloc podľa zložitosti flow.
- DI: `get_it` v `lib/core/di/service_locator.dart`.
- Routing: `go_router` v `lib/routes/app_router.dart`.
- Hosting: Firebase Hosting site `goldtaxi-202ff`, public dir `build/web`.
- Auth: Firebase Auth pre web Google Sign-In, Email/Password a Anonymous; WordPress JWT login ostáva ako existujúca cesta.
- Maps: `google_maps_flutter` pre web/Android/iOS, `flutter_map` fallback pre desktop.
- Backend zdroje: WordPress/WooCommerce, Supabase, Firebase.

## Architektúra

Feature kód patrí pod `lib/features/<feature>/`:

```text
lib/features/<feature>/
├── data/
│   ├── datasources/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── bloc/ alebo cubits/
    ├── pages/
    └── widgets/
```

Zdieľané služby, konštanty, theme, DI a widgety patria do `lib/core/`. Zdieľané modely patria do `lib/models/`. Nové routy sa registrujú v `lib/routes/app_router.dart`.

Pravidlá:

- UI nevytvára repository alebo service priamo; používa Cubit/Bloc z DI.
- Page-level Bloc/Cubit registruj ako `registerFactory`, aby sa bezpečne zatváral cez `BlocProvider`.
- App-wide stav ako `AuthCubit` alebo `CartCubit` môže byť lazy singleton.
- Network a storage hranice musia validovať dáta a neprepúšťať raw JSON do presentation vrstvy.

## Firebase

Firebase skill pravidlá pre tento projekt:

- CLI príkazy používaj ako `npx -y firebase-tools@latest ...`.
- Hosting konfigurácia je v `firebase.json`.
- Predvolený projekt je v `.firebaserc`: `goldtaxi-202ff`.
- Auth provideri sú deklarovaní v `firebase.json` a po zmene sa musia nasadiť:

```bash
npx -y firebase-tools@latest deploy --only auth --project goldtaxi-202ff
```

Hosting deploy:

```bash
npx -y firebase-tools@latest deploy --only hosting:goldtaxi-202ff --project goldtaxi-202ff
```

FlutterFire web config je v `lib/firebase_options.dart`. Android/iOS Firebase config zatiaľ nie je nastavený v `DefaultFirebaseOptions`; pri natívnej Firebase podpore použi FlutterFire/Firebase CLI a vedome rozhodni, či sa platformové config súbory budú commitovať.

## Authentication

Aktívny auth modul je `lib/features/auth/`.

- `AuthRepository.login()` používa WordPress JWT endpoint a voliteľný Firebase Email/Password fallback.
- `AuthRepository.signInWithGoogle()` používa na webe `FirebaseAuth.signInWithPopup(GoogleAuthProvider())`.
- `AuthCubit` drží auth stav pre routing.
- `LoginPage` obsahuje Google Sign-In tlačidlo.

Na Flutter Web nepoužívaj webový `google_sign_in` flow, ak nie je explicitne potrebný. Súčasný web flow ide cez Firebase popup a vyhýba sa problémom s klientskym ID v `google_sign_in` 7.x.

## Mapy a vodiči

Aktuálne súborové vlastníctvo:

- `lib/features/map/data/repositories/driver_position_repository.dart` - aktuálny in-memory zdroj polôh vodičov a demo data.
- `lib/features/map/data/services/driver_profile_service.dart` - Supabase CRUD servis pre tabuľku `driver_profiles`.
- `lib/models/driver_position_model.dart` - spoločný model vodiča, auta a polohy.
- `lib/features/map/presentation/cubits/map_cubit.dart` - map state, markery, výber vodiča, camera actions.
- `lib/features/map/presentation/pages/map_page.dart` - obrazovka mapy, zoznam vodičov, call/order akcie.
- `lib/features/map/presentation/widgets/platform_map_widget.dart` - Google Maps alebo OpenStreetMap fallback.

Demo vodič:

```text
driverId: demo_driver_jan_novak
name: Ján Novák
car: Škoda Octavia, BA-123GT
location: 48.1486, 17.1077
```

Keď bude pripravený realtime backend, nahraď `_mockDrivers` v `DriverPositionRepository` Supabase Realtime streamom alebo Firestore streamom. Presentation vrstva by sa nemala meniť, ak zachováš `Stream<List<DriverPositionModel>>`.

## Google Maps Platform

Pre aktuálnu aplikáciu sú najdôležitejšie:

- Maps JavaScript API - web mapa načítaná dynamicky cez `GOOGLE_MAPS_API_KEY`.
- Maps SDK for Android - natívna Android mapa cez Flutter plugin.
- Maps SDK for iOS - natívna iOS mapa cez Flutter plugin.
- Places API (New) - autocomplete a výber adries.
- Geocoding API - prevod adresa/súradnice.
- Routes API - ETA, vzdialenosť a trasa zákazník/vodič.

Roads API, Route Optimization API a Navigation SDK zapínaj až pri konkrétnom use-case. Viac je v `docs/firebase-and-maps.md`.

Google Maps browser key musí byť obmedzený na:

```text
https://goldtaxi-202ff.web.app/*
https://goldtaxi-202ff.firebaseapp.com/*
```

Lokálne referrery pridaj iba pre vývoj a nikdy nepoužívaj rovnaký key pre server-side API.

## Secrets

Nikdy necommituj:

- `.env` ani produkčné env súbory.
- WooCommerce consumer secret.
- súkromné certifikáty, signing keys, `.pem`, `.p12`, `.jks`, `.keystore`.
- server-side Google Maps API key.

Firebase web config a browser Google Maps key nie sú klasické serverové secrety, ale musia byť obmedzené v konzole. Detaily sú v `docs/environment-and-secrets.md`.

## Testy a kontroly

Používaj npm skripty alebo priame Flutter príkazy:

```bash
npm run analyze
npm test
flutter build web --release
npm run maps:smoke
```

Mapové testy sú pod `test/unit/map/`. Auth testy sú pod `test/unit/auth_*` a `test/widget/login_page_test.dart`.

## Git a priečinky

Pred širokými refaktormi vytvor checkpoint/commit. Nevracaj cudzie zmeny. Dokumentáciu k tomu, čo patrí do ktorého priečinka, drží `docs/project-structure.md`.
