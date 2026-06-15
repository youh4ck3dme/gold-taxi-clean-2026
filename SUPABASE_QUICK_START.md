# 🚀 GoldTaxi - Rýchly Start s Supabase (5 minút)

**Cieľ:** Dostať sa z nuly k fungujúcemu prihláseniu v databáze

---

## ⚡ KROK 1: Inštalácia Supabase CLI (30 sekund)

```bash
# macOS
brew install supabase/tap/supabase

# Linux/Windows (npm)
npm install -g supabase

# Overte inštaláciu
supabase --version
```

---

## ⚡ KROK 2: Prihlásenie do Supabase (1 minúta)

```bash
# Spustite prihlásenie (otvorí sa prehliadač)
supabase login
```

- Prejdite na stránku, ktorú vám otvorí
- Prihláste sa cez GitHub
- V terminali uvidíte: `Logged in as your@email.com`

---

## ⚡ KROK 3: Spájanie s projektom (30 sekund)

```bash
cd /Users/erikbabcan/Gold-taxi

# Spájte s existujúcim projektom
supabase link --project-ref nscxuxhapaabtsiduxlu

# Overte spojenie
supabase status
# Mal by ste vidieť: Linked to project nscxuxhapaabtsiduxlu
```

---

## ⚡ KROK 4: Získanie kľúčov (30 sekund)

### Metóda A: Cez Supabase Dashboard
1. Otvorte: [https://app.supabase.com/project/nscxuxhapaabtsiduxlu/settings/api](https://app.supabase.com/project/nscxuxhapaabtsiduxlu/settings/api)
2. Skopírujte:
   - **Project URL** (napr. `https://nscxuxhapaabtsiduxlu.supabase.co`)
   - **anon public key** (dlhý reťazec)

### Metóda B: Cez Supabase CLI
```bash
# Získajte konfiguráciu
supabase config

# Alebo priamo z API
curl -H "Authorization: Bearer $(supabase config --access-token)" \
  https://api.supabase.com/v1/projects/nscxuxhapaabtsiduxlu | jq
```

---

## ⚡ KROK 5: Vytvorenie .env súboru (1 minúta)

```bash
cd /Users/erikbabcan/Gold-taxi

# Vytvorte .env súbor (nahraďte hodnoty)
cat > .env << 'EOF'
# Supabase
SUPABASE_URL=https://nscxuxhapaabtsiduxlu.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsImF1ZCI6InN1cGFiYXNlIn0...  

# Google Maps (nepovinné)
GOOGLE_MAPS_API_KEY=your_google_maps_key

# Backend Mode
BACKEND_MODE=supabase
EOF

# Pridajte do .gitignore
if ! grep -q "^\.env$" .gitignore; then
    echo ".env" >> .gitignore
fi

# Ochrana súboru
ychmod 600 .env
echo "✓ .env súbor vytvorený a zabezpečený"
```

---

## ⚡ KROK 6: Nastavenie databázy (2 minúty)

### 6.1 Spustite migračný script
```bash
# OTVORTE Supabase SQL Editor
# 1. Prejdite na: https://app.supabase.com/project/nscxuxhapaabtsiduxlu/sql
# 2. Kopírujte obsah z: supabase_migration.sql
# 3. Kliknite "Run"

# Alebo cez Supabase CLI (ak máte lokálnu DB)
supabase db reset
```

### 6.2 Nastavte Realtime
```sql
-- Spustite tento SQL v Supabase SQL Editor
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.drivers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.rides;
ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
```

---

## ⚡ KROK 7: Vytvorenie testovacieho používateľa (1 minúta)

### Metóda A: Cez Supabase Dashboard (odporúčané)
1. Prejdite na: [https://app.supabase.com/project/nscxuxhapaabtsiduxlu/auth/users](https://app.supabase.com/project/nscxuxhapaabtsiduxlu/auth/users)
2. Kliknite **"Add User"**
3. Zadajte:
   - Email: `test@goldtaxi.sk`
   - Password: `Test123456!`
   - Confirm Password: `Test123456!`
4. Kliknite **"Create User"**

### Metóda B: Cez SQL (ak chcete programovo)
```sql
-- Spustite v SQL Editor
INSERT INTO public.profiles (id, email, name, role, created_at)
VALUES (
  'test-user-id',
  'test@goldtaxi.sk',
  'Test User',
  'customer',
  NOW()
);
```

---

## ⚡ KROK 8: Nastavte Google Auth (nepovinné, odporúčané)

1. Prejdite na: [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Vytvorte nový **OAuth Client ID**
3. Nastavte:
   - Authorized JavaScript origins: `http://localhost:*`
   - Authorized redirect URIs: `http://localhost:5000/auth/callback`
4. Skopírujte **Client ID** a **Client Secret**
5. V Supabase Dashboard:
   - Prejdite na: Authentication → Providers
   - Zapnite **Google**
   - Zadajte Client ID a Secret

---

## ⚡ KROK 9: Spustite aplikáciu (30 sekund)

### Pre vývoj (chrome):
```bash
cd /Users/erikbabcan/Gold-taxi

flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://nscxuxhapaabtsiduxlu.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
  --dart-define=BACKEND_MODE=supabase \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

### Pre web build:
```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://nscxuxhapaabtsiduxlu.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
  --dart-define=BACKEND_MODE=supabase \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

---

## ⚡ KROK 10: Prihlásenie a testovanie

### Prihlásenie s email/heslo:
1. Spustite aplikáciu
2. Zadajte:
   - Email: `test@goldtaxi.sk`
   - Heslo: `Test123456!`
3. Kliknite na **"Prihlásiť sa"**

### Prihlásenie cez Google:
1. Kliknite na **"Pokračovať cez Google"**
2. Vyberte svoj Google účet
3. Povolte prístup

### Overenie úspechu:
- Po prihlásení by ste mali byť presmerovaní na domovú stránku
- Mal by sa zobraziť používateľský profil
- V pravom hornom rohu by mal byť zobrazený váš email

---

## 🎯 Rýchle riešenie pre necierplivých

**Ak chcete všetko naraz, spustite tento script:**

```bash
# 1. Inštalujte Supabase CLI
brew install supabase/tap/supabase || npm install -g supabase

# 2. Prihláste sa
supabase login

# 3. Prejdite do projektu
cd /Users/erikbabcan/Gold-taxi

# 4. Spájte projekt
supabase link --project-ref nscxuxhapaabtsiduxlu

# 5. Vytvorte .env (nahraďte kľúče)
echo "SUPABASE_URL=https://nscxuxhapaabtsiduxlu.supabase.co" > .env
echo "SUPABASE_ANON_KEY=YOUR_ANON_KEY_HERE" >> .env
echo "BACKEND_MODE=supabase" >> .env
echo ".env" >> .gitignore

# 6. Spustite aplikáciu
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://nscxuxhapaabtsiduxlu.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY_HERE \
  --dart-define=BACKEND_MODE=supabase
```

**Nezabudnite:**
- Vytvorte používateľa v [Supabase Dashboard](https://app.supabase.com/project/nscxuxhapaabtsiduxlu/auth/users)
- Spustite `supabase_migration.sql` v SQL Editor

---

## 📌 Dôležité poznámky

### 1. Bezpečnosť
- **Nikdy** necommitujte `.env` do git!
- **Nikdy** nepoužívajte `service_role` kľúč v Flutter aplikácii!
- Používajte len `anon` kľúč

### 2. RLS (Row Level Security)
- Uistite sa, že máte zapnuté RLS pre všetky tabuľky
- Skontrolujte v: Authentication → Policies

### 3. Lokálny vývoj
- Pre lokálny vývoj môžete použiť:
  ```bash
  supabase start  # Spustí lokálnu databázu
  ```
- Ale pre produkciu používajte cloud Supabase

### 4. Google Maps
- Ak nepoužívate Google Maps, môžete vynechať `GOOGLE_MAPS_API_KEY`
- Ale aplikácia ho bude vyžadovať pre mapové funkcie

---

## 🆘 Riešenie problémov

### Problém: "Invalid Supabase URL"
**Riešenie:** Uistite sa, že URL nemá na konci `/`
```
✅ Správne: https://nscxuxhapaabtsiduxlu.supabase.co
❌ Nesprávne: https://nscxuxhapaabtsiduxlu.supabase.co/
```

### Problém: "Invalid API key"
**Riešenie:** Skontrolujte, či používate `anon` kľúč, nie `service_role`

### Problém: "User not found"
**Riešenie:** Vytvorte používateľa v Supabase Dashboard

### Problém: CORS errors
**Riešenie:**
```bash
# V Supabase Dashboard:
# 1. Prejdite do API → CORS
# 2. Pridajte:
#   - http://localhost:*
#   - https://your-domain.com
```

### Problém: "RLS blocked"
**Riešenie:** Skontrolujte RLS politiky:
```sql
-- Príklad pre profiles
CREATE POLICY "Enable read for authenticated users"
ON public.profiles FOR SELECT
USING (auth.uid() = id);
```

---

## ✅ Checklist

- [ ] Supabase CLI nainštalované
- [ ] Prihlásený do Supabase
- [ ] Projekt `nscxuxhapaabtsiduxlu` linked
- [ ] .env súbor vytvorený
- [ ] Databáza migrovaná
- [ ] Realtime nastavené
- [ ] Testovací používateľ vytvorený
- [ ] Google Auth nastavené (nepovinné)
- [ ] Aplikácia spustená
- [ ] Prihlásenie otestované

**Celkový čas:** ~5-10 minút

---

## 📞 Potrebujete pomoc?

- **Supabase Docs:** [https://supabase.com/docs](https://supabase.com/docs)
- **GoldTaxi Setup:** [SUPABASE_SETUP.md](SUPABASE_SETUP.md)
- **Supabase Dashboard:** [https://app.supabase.com](https://app.supabase.com)

---

**Poznámka:** Ak už máte Supabase projekt nastavený, stačí len:
1. Skopírovať `SUPABASE_URL` a `SUPABASE_ANON_KEY`
2. Vytvoriť `.env` súbor
3. Spustiť aplikáciu s `--dart-define` parametrami
4. Vytvoriť používateľa v Supabase Dashboard
5. Prihlásiť sa

**To je všetko!** 🎉
