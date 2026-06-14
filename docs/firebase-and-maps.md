# Firebase a Google Maps prevádzka

Tento dokument drží produkčný setup pre Firebase Hosting/Auth a Google Maps Platform.

## Firebase projekt

```text
Project ID: goldtaxi-202ff
Project number / sender ID: 1007297424308
Hosting site: goldtaxi-202ff
Live URL: https://goldtaxi-202ff.web.app
Fallback Firebase URL: https://goldtaxi-202ff.firebaseapp.com
```

Konfigurácia v repozitári:

- `.firebaserc` nastavuje default projekt `goldtaxi-202ff`.
- `firebase.json` nastavuje Hosting, Auth providery, SPA rewrite a security headers.
- `lib/firebase_options.dart` obsahuje FlutterFire web config.
- `web/index.html` načítava Google Maps JavaScript API cez `<script>`.

## Firebase CLI

Používaj vždy aktuálny Firebase CLI cez `npx`:

```bash
npx -y firebase-tools@latest --version
npx -y firebase-tools@latest login
npx -y firebase-tools@latest use goldtaxi-202ff
```

Deploy Auth providerov:

```bash
npx -y firebase-tools@latest deploy --only auth --project goldtaxi-202ff
```

Deploy Hosting:

```bash
npx -y firebase-tools@latest deploy --only hosting:goldtaxi-202ff --project goldtaxi-202ff
```

Lokálny Hosting emulator:

```bash
npx -y firebase-tools@latest emulators:start --only hosting
```

## Firebase Auth

Aktuálne povolené providery:

- Google Sign-In
- Email/Password
- Anonymous

OAuth brand:

```text
Display name: Gold Taxi
Support email: u0352652320@gmail.com
```

Authorized redirect URIs sú v `firebase.json`. Ak sa Google popup otvorí a hneď zavrie s `auth/unauthorized-domain`, skontroluj Firebase Console:

```text
https://console.firebase.google.com/project/goldtaxi-202ff/authentication/settings
```

Authorized domains musia byť domény bez protokolu a portu, napríklad `localhost`, `goldtaxi-202ff.web.app`, `goldtaxi-202ff.firebaseapp.com`.

## Google Maps Platform konzola

API a credentials spravuj tu:

```text
https://console.cloud.google.com/google/maps-apis/api-list?project=goldtaxi-202ff
https://console.cloud.google.com/google/maps-apis/credentials?project=goldtaxi-202ff
```

Produkčnú doménu pre web key pridaj ako HTTP referrer:

```text
https://goldtaxi-202ff.web.app/*
https://goldtaxi-202ff.firebaseapp.com/*
```

Pre lokálny vývoj použi samostatný development key alebo dočasne pridaj localhost referrer:

```text
http://localhost/*
http://localhost:*/*
```

## Ktoré Maps API zapnúť

Zapnúť teraz:

| API | Prečo |
| --- | --- |
| Maps JavaScript API | Webová mapa cez `<script>` v `web/index.html`. |
| Maps SDK for Android | Flutter natívna mapa na Androide cez `google_maps_flutter`. |
| Maps SDK for iOS | Flutter natívna mapa na iOS cez `google_maps_flutter`. |
| Places API (New) | Vyhľadávanie miest, autocomplete pickup/dropoff adries. |
| Geocoding API | Prevod adries na súradnice a späť. |
| Routes API | ETA, vzdialenosť, trasa vodič-zákazník-cieľ. |

Zapnúť až pri konkrétnej funkcii:

| API | Kedy ho použiť |
| --- | --- |
| Roads API | Keď bude treba snapovať GPS polohu vodiča na reálnu cestu. |
| Route Optimization API | Keď bude dispatch viac jázd alebo viac vozidiel optimalizovaný naraz. |
| Navigation SDK / Navigation for Flutter | Keď appka vodiča potrebuje turn-by-turn navigáciu priamo v aplikácii. |
| Time Zone API | Keď bude treba presný čas podľa miesta jazdy mimo lokálneho regiónu. |
| Weather API | Keď sa počasie bude používať v ETA, pricingu alebo dispečingu. |

Nezapínať zatiaľ:

| API | Dôvod |
| --- | --- |
| Solar API | Nesúvisí s taxi flow. |
| Pollen API | Nesúvisí s taxi flow. |
| Air Quality API | Iba ak vznikne konkrétny UX/use-case. |
| Aerial View API | Nie je potrebné pre objednanie jazdy. |
| Street View Publish API | Slúži na publikovanie 360 fotiek, nie na taxi mapu. |
| Map Tiles API | Použiť len pri vlastnom mapovom rendereri alebo špeciálnych tiles. |
| Maps Datasets API | Použiť až pri vlastných geodátach vo väčšom rozsahu. |
| Map Management API | Použiť až pri automatizácii cloud map stylingu. |
| Maps 3D SDK for Android/iOS | Použiť až pri 3D native map experience. |

## API key bezpečnosť

Google odporúča kľúče obmedzovať a používať samostatné API keys pre jednotlivé aplikácie. Pre Gold Taxi to znamená:

- Web browser key: HTTP referrer restrictions + iba webové API.
- Android key: Android package/SHA restrictions + iba Android SDK API.
- iOS key: iOS bundle ID restrictions + iba iOS SDK API.
- Server key: IP restrictions alebo serverové ochrany + iba serverové API; nikdy ho nedávaj do Flutter alebo web klienta.

Kľúče po zmene otestuj najprv na preview/lokálne a až potom na produkcii.

## Zdroje

- Maps JavaScript API: https://developers.google.com/maps/documentation/javascript/overview
- Maps SDK for Android: https://developers.google.com/maps/documentation/android-sdk/overview
- Maps SDK for iOS: https://developers.google.com/maps/documentation/ios-sdk/overview
- Places API (New): https://developers.google.com/maps/documentation/places/web-service/op-overview
- Geocoding API: https://developers.google.com/maps/documentation/geocoding/overview
- Routes API: https://developers.google.com/maps/documentation/routes/overview
- Roads API: https://developers.google.com/maps/documentation/roads/overview
- Route Optimization API: https://developers.google.com/maps/documentation/route-optimization/overview
- Google Maps API security: https://developers.google.com/maps/api-security-best-practices
