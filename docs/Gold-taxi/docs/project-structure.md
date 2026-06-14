# Štruktúra projektu

Tento súbor určuje, kam patria nové priečinky a súbory v Gold Taxi.

## Root

| Cesta | Čo sem patrí |
| --- | --- |
| `README.md` | Rýchly štart, deploy, odkazy na docs. |
| `DEVELOPER.md` | Architektúra, pravidlá práce, technické rozhodnutia. |
| `firebase.json` | Firebase Hosting/Auth konfigurácia. |
| `.firebaserc` | Default Firebase projekt. |
| `.env.example` | Bezpečný zoznam potrebných env premenných s placeholdermi. |
| `.gitignore` | Lokálne výstupy, secrets, build artefakty. |
| `package.json` | Pomocné npm skripty pre analyze/test/build/deploy. |
| `pubspec.yaml` | Flutter dependencies a assets. |

## Flutter zdrojáky

| Cesta | Čo sem patrí |
| --- | --- |
| `lib/main.dart` | Bootstrap appky, Firebase/Supabase init, DI init. |
| `lib/firebase_options.dart` | FlutterFire generated config pre web. |
| `lib/core/constants/` | Globálne konštanty, theme hodnoty, API env accessors. |
| `lib/core/di/` | `get_it` registrácie. |
| `lib/core/services/` | Zdieľané infra služby: API, storage, notifications, deep links. |
| `lib/core/interceptors/` | HTTP interceptory. |
| `lib/core/widgets/` | Reusable UI widgets bez feature biznis logiky. |
| `lib/models/` | Zdieľané modely používané naprieč features. |
| `lib/routes/` | GoRouter konfigurácia. |
| `lib/features/<feature>/` | Feature modul so svojou data/presentation vrstvou. |

## Feature pravidlo

Nový feature modul má byť malý a čitateľný:

```text
lib/features/example/
├── data/
│   ├── datasources/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── bloc/ alebo cubits/
    ├── pages/
    └── widgets/
```

Ak feature nepotrebuje remote data source, nevytváraj prázdny priečinok iba pre symetriu. Testy dávaj do rovnakej logickej oblasti v `test/unit/<feature>/` alebo `test/widget/`.

## Aktívne feature moduly

| Feature | Hlavné súbory |
| --- | --- |
| `auth` | `AuthRepository`, `AuthCubit`, `LoginPage`. |
| `map` | `DriverPositionRepository`, `DriverProfileService`, `MapCubit`, `MapPage`, `PlatformMapWidget`. |
| `services` | Služby a booking flow. |
| `products` | WooCommerce/product storefront. |
| `checkout` | Košík a checkout. |
| `blog` | WordPress články/novinky. |
| `events` | Eventy. |
| `faq` | FAQ. |
| `profile` | Profil používateľa. |
| `search` | Vyhľadávanie. |
| `insolvency_monitoring` | Interný dashboard a predikčný servis. |

## Web a assets

| Cesta | Čo sem patrí |
| --- | --- |
| `web/index.html` | Flutter web bootstrap, Google Maps JS script, web meta tagy. |
| `web/manifest.json` | PWA manifest. |
| `web/icons/` | PWA ikony. |
| `assets/images/` | Obrázky používané aplikáciou. |

Nevkladaj do `assets/` secrety, exporty databáz ani dočasné screenshoty.

## Natívne platformy

| Cesta | Čo sem patrí |
| --- | --- |
| `android/` | Android runner, manifesty, Gradle, ProGuard. |
| `ios/` | iOS runner, Podfile, Xcode projekt. |
| `macos/`, `linux/`, `windows/` | Desktop runner súbory. |

Signing súbory a lokálne certifikáty nepatria do repozitára.

## Dokumentácia

| Cesta | Čo sem patrí |
| --- | --- |
| `docs/firebase-and-maps.md` | Firebase/Maps prevádzka, API key pravidlá, Maps API plán. |
| `docs/environment-and-secrets.md` | Env premenné, lokálne secrets, GitHub secrets. |
| `docs/woo.md` | WooCommerce credential poznámky. |
| `docs/*blueprint*` | Produktové a technické blueprinty. |

Veľké binárne súbory dávaj do `docs/` iba ak sú potrebné pre projektové rozhodnutie. Inak patria mimo repo.

## Necommitovať

- `.env`, `.env.local`, `.env.production`.
- `build/`, `.dart_tool/`, coverage a cache priečinky.
- lokálne Firebase debug logy a `.firebase/`.
- `node_modules/`.
- private keys, certificates, provisioning profiles.
- jednorazové migračné alebo SSH skripty so secretmi.

Ak je súbor potrebný v CI, ulož secret do GitHub Actions secrets a v repozitári nechaj iba bezpečnú šablónu alebo skript bez hodnoty secretu.
