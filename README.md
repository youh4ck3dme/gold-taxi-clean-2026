# Gold Taxi

Flutter aplikácia pre taxi službu Gold Taxi. Aktuálny stav pokrýva prihlásenie, mapu vodičov, objednávkový tok, produkty, blog/novinky, recenzie, FAQ a interný insolvency monitoring.

Produkčná web adresa:

```text
https://goldtaxi-202ff.web.app
```

Firebase projekt:

```text
goldtaxi-202ff
```

## Hlavné časti

- Firebase Hosting pre Flutter web build z `build/web`.
- Firebase Auth s povolenými providermi Google Sign-In, Email/Password a Anonymous.
- Google Sign-In na webe cez `FirebaseAuth.signInWithPopup(GoogleAuthProvider())`.
- Google Maps na webe cez `<script>` v `web/index.html`.
- Platformová mapa v `PlatformMapWidget`: Google Maps pre web/Android/iOS, `flutter_map` fallback pre desktop platformy bez Google Maps pluginu.
- Demo profil vodiča `Ján Novák` a ďalší vodiči v `DriverPositionRepository`; Supabase CRUD servis je pripravený v `DriverProfileService`.
- WordPress/WooCommerce dátové zdroje cez `ApiService` a feature repositories.
- Supabase inicializácia pre budúce realtime a profilové dáta vodičov.

## Rýchly štart

1. Priprav lokálny environment:

```bash
cp .env.example .env
```

2. Doplň hodnoty v `.env`. Skutočné secrety nepatria do gitu.

3. Nainštaluj Flutter balíky:

```bash
flutter pub get
```

4. Spusti web lokálne:

```bash
flutter run -d chrome
```

5. Spusti kontroly:

```bash
npm run analyze
npm test
```

## Firebase deploy cez npm/npx

Firebase CLI používaj cez `npx -y firebase-tools@latest`, aby sa nepoužívala zastaraná globálna verzia.

```bash
npm run firebase:deploy
```

Tento príkaz nasadí Hosting site `goldtaxi-202ff`. Auth konfigurácia sa nasadzuje samostatne:

```bash
npm run firebase:deploy:auth
```

Priamy ekvivalent bez npm skriptu:

```bash
npx -y firebase-tools@latest deploy --only hosting:goldtaxi-202ff --project goldtaxi-202ff
```

## Environment premenné

Lokálny `.env` vychádza z `.env.example`:

```properties
WP_BASE_URL=https://your-wordpress-site.com
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
FIREBASE_PROJECT_ID=goldtaxi-202ff
FIREBASE_API_KEY=your-firebase-web-api-key
FIREBASE_APP_ID=your-firebase-web-app-id
WOO_CONSUMER_KEY=your-local-woo-key
WOO_CONSUMER_SECRET=your-local-woo-secret
GOOGLE_MAPS_API_KEY=your-restricted-google-maps-browser-key
```

Firebase web konfigurácia pre aktuálnu aplikáciu je v `lib/firebase_options.dart`. Google Maps web key je zatiaľ vložený v `web/index.html`; musí byť obmedzený v Google Cloud Console na produkčné domény.

## Dôležité súbory

- `firebase.json` - Hosting, Auth provideri, SPA rewrite a bezpečnostné headers.
- `.firebaserc` - predvolený Firebase projekt `goldtaxi-202ff`.
- `lib/firebase_options.dart` - FlutterFire web konfigurácia.
- `web/index.html` - Flutter bootstrap a Google Maps JavaScript `<script>`.
- `lib/features/auth/` - Firebase/WordPress auth flow.
- `lib/features/map/` - mapa vodičov, markery, driver repository a Supabase driver profil servis.
- `docs/firebase-and-maps.md` - Firebase Hosting/Auth a Google Maps API plán.
- `docs/project-structure.md` - kam patria priečinky a súbory v projekte.
- `docs/environment-and-secrets.md` - pravidlá pre `.env`, API kľúče a secrety.

## Kvalita

Pred dokončením zmeny spusti:

```bash
npm run analyze
npm test
flutter build web --release
```

Pre Firebase Hosting deploy:

```bash
npm run firebase:deploy
```

Viac technických pravidiel je v `DEVELOPER.md`.
