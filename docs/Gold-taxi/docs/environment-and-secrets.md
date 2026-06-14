# Environment a secrets

Tento projekt používa viac verejných client configov aj skutočných secretov. Rozlišuj ich pred commitom.

## Lokálny `.env`

Vytvor lokálny `.env` z `.env.example`:

```bash
cp .env.example .env
```

`.env` je ignorovaný gitom. Hodnoty v ňom sa načítavajú cez `flutter_dotenv`.

Aktuálne používané premenné:

| Premenná | Typ | Poznámka |
| --- | --- | --- |
| `WP_BASE_URL` | config | URL WordPress backendu. |
| `SUPABASE_URL` | public client config | Supabase project URL. |
| `SUPABASE_ANON_KEY` | public client key | Musí byť krytý RLS policy na Supabase strane. |
| `FIREBASE_PROJECT_ID` | public client config | Firebase project ID. |
| `FIREBASE_API_KEY` | public client config | Firebase web API key; obmedzuj použitím Firebase pravidiel a domén. |
| `FIREBASE_APP_ID` | public client config | Firebase app ID. |
| `WOO_CONSUMER_KEY` | secret | Používaj iba lokálne/CI secret store. |
| `WOO_CONSUMER_SECRET` | secret | Nikdy necommitovať. |
| `GOOGLE_MAPS_API_KEY` | restricted client key | Web key musí mať HTTP referrer restrictions; Android/iOS používajú vlastné platformové restrictions. |

## Čo je secret

Za secret považuj všetko, čo umožní zápis, administráciu, billing abuse alebo server-side prístup:

- WooCommerce consumer secret.
- Google Maps server key.
- Firebase service account JSON.
- Supabase service role key.
- signing certifikáty a privátne kľúče.
- SSH/FTP/SFTP heslá a deploy tokeny.

## Čo je public client config

Firebase web API key, Firebase app ID, Supabase anon key a Google Maps browser key sú viditeľné v klientovi. Nie sú to serverové secrety, ale musia byť obmedzené:

- Firebase Auth musí mať správne authorized domains.
- Supabase musí mať zapnuté RLS a least-privilege policies.
- Google Maps key musí mať application restrictions a API restrictions.
- Google Maps key nevkladaj priamo do `web/index.html`, `AndroidManifest.xml` ani Swift súborov; používaj build-time premenné.

## GitHub Actions

`setup_github_secrets.sh` je bezpečný helper, ktorý hodnoty pýta interaktívne a neposiela ich do repozitára. Používaj ho iba s `gh` CLI v autentifikovanom repozitári.

## Rotácia

Ak sa secret objavil v git histórii, nepovažuj samotné vymazanie zo súboru za riešenie. Kľúč treba zrotovať v príslušnej službe a až potom upratať históriu, ak je to potrebné.
