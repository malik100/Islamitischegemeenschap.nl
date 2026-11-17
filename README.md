# Onderzoek islam & zingeving: website + database

Twee tweetalige enquêtes (NL/EN) op één statische website (GitHub Pages), met een Supabase-database in de EU:

- **Bekeerlingen**: hoe ze de islam leerden kennen, wat hen tegenhield en wat hen eerder had kunnen bereiken.
- **Niet-moslims**: hun beeld van de islam, wat afschrikt of aanspreekt en hoe ze bereikt willen worden.
- **Vrijwilligers** (`?s=volunteer`, niet anoniem): beroep, vaardigheden, talen, beschikbaarheid en hoe iemand wil bijdragen. Geen financiële bijdragen. Bekeerlingen krijgen dit formulier ook aangeboden na het invullen van hun enquête, los van hun anonieme antwoorden.

Heb je `schema.sql` al eerder uitgevoerd? Voer de nieuwe versie gewoon opnieuw uit. Bestaande data blijft staan.

- `index.html`: de website (alles in één bestand)
- `schema.sql`: tabellen, beveiliging en analyse-query's

## 1. Database (Supabase), ca. 5 min

1. Maak een gratis account op supabase.com en klik op **New project**.
2. Kies als regio **Central EU (Frankfurt)**.
3. Ga naar **SQL Editor**, plak de inhoud van `schema.sql` en klik op **Run**.
4. Ga naar **Project Settings → API Keys** en kopieer:
   - de **Project URL** (bijv. `https://abcd1234.supabase.co`)
   - de **publishable key** (`sb_publishable_…`) of de oude **anon key**
   - Gebruik **nooit** de secret/service_role key in de website.

## 2. Website instellen

Open `index.html` en vul bovenin `CONFIG` in:

```js
const CONFIG = {
  SUPABASE_URL: "https://abcd1234.supabase.co",
  SUPABASE_KEY: "sb_publishable_...",
  RESEARCHER:   "Malik ...",
  CONTACT:      "onderzoek@jouwdomein.nl",
  DELETE_BY:    "31 december 2027"
};
```

Zolang de placeholders erin staan, draait de site in **demomodus** (niets wordt opgeslagen).

## 3. Online zetten op islamitischegemeenschap.nl

### 3a. GitHub Pages

1. Maak op GitHub een nieuwe repository, bijv. `islamitischegemeenschap`.
2. Upload alle bestanden en mappen: `index.html`, `CNAME`, en de mappen `bekeerlingen`, `niet-moslims`, `vrijwilliger`, `converts`, `non-muslims` en `volunteer`. `schema.sql` en `README.md` mogen erbij, maar hoeven niet.
3. Ga naar **Settings → Pages**, kies **Deploy from a branch**, branch `main`, map `/ (root)`, en klik op **Save**.
4. Vul bij **Custom domain** `islamitischegemeenschap.nl` in (dit staat al in het `CNAME`-bestand).

### 3b. DNS bij je domeinregistrar

Verwijder bestaande A- en AAAA-records voor het hoofddomein (`@`) en voeg deze toe:

| Type | Naam | Waarde |
|---|---|---|
| A | @ | 185.199.108.153 |
| A | @ | 185.199.109.153 |
| A | @ | 185.199.110.153 |
| A | @ | 185.199.111.153 |
| AAAA | @ | 2606:50c0:8000::153 |
| AAAA | @ | 2606:50c0:8001::153 |
| AAAA | @ | 2606:50c0:8002::153 |
| AAAA | @ | 2606:50c0:8003::153 |
| CNAME | www | `<jouw-github-gebruikersnaam>.github.io` |

Het kan tot een paar uur duren voordat DNS overal bijgewerkt is.

### 3c. Afronden

1. Zet in **Settings → Pages** het vinkje **Enforce HTTPS** aan zodra het beschikbaar is.
2. Verifieer het domein in je GitHub-account: **profielfoto → Settings → Pages → Add a domain**. GitHub geeft je een TXT-record om bij je registrar toe te voegen. Zo kan niemand anders je domein aan een eigen GitHub-site koppelen.
3. Maak een e-mailadres op je domein, bijv. `info@islamitischegemeenschap.nl` (doorsturen naar je eigen mail kan bij de meeste registrars). Zet dat bij `CONTACT` in `index.html`.

### Korte links voor werving, flyers en QR-codes

| Link | Gaat naar |
|---|---|
| `islamitischegemeenschap.nl` | keuzescherm |
| `islamitischegemeenschap.nl/bekeerlingen` | vragenlijst bekeerlingen (NL) |
| `islamitischegemeenschap.nl/niet-moslims` | vragenlijst niet-moslims (NL) |
| `islamitischegemeenschap.nl/vrijwilliger` | vrijwilligersformulier (NL) |
| `islamitischegemeenschap.nl/converts` | converts survey (EN) |
| `islamitischegemeenschap.nl/non-muslims` | non-Muslim survey (EN) |
| `islamitischegemeenschap.nl/volunteer` | volunteer form (EN) |

Kanaal bijhouden? Zet `?src=` erachter, bijv. `islamitischegemeenschap.nl/bekeerlingen?src=instagram`.

### Overige parameters



| Onderdeel | Betekenis |
|---|---|
| `?s=converts` | direct naar de vragenlijst voor bekeerlingen |
| `?s=nonmuslims` | direct naar de vragenlijst voor niet-moslims |
| `?s=volunteer` | direct naar het vrijwilligersformulier |
| (geen `s`) | keuzescherm: de bezoeker kiest zelf |
| `lang=nl` / `lang=en` | taal (zonder: taal van de browser) |
| `src=reddit` | kanaal waar de link stond, zodat je ziet welke werving werkt |

Voorbeelden:

- `islamitischegemeenschap.nl/?s=converts&lang=en&src=reddit_converts`
- `islamitischegemeenschap.nl/?s=nonmuslims&lang=nl&src=instagram`
- `islamitischegemeenschap.nl/?lang=nl&src=whatsapp` (keuzescherm)

Gebruik per kanaal een eigen `src` (alleen kleine letters, cijfers, `-` en `_`).

## 4. Testen

1. Vul de enquête zelf één keer in.
2. Controleer in Supabase → **Table Editor → responses** of de rij er staat.
3. Verwijder je testrij daarna.

## 5. Resultaten bekijken en exporteren

- **Table Editor → responses → Export → CSV**
- Of gebruik de query's onderaan `schema.sql` in de SQL Editor (tellingen, gemiddelden, open antwoorden).

### Hoe antwoorden zijn opgeslagen

Elke rij heeft de kolommen `survey` (`converts` of `nonmuslims`), `lang`, `src` en `answers` (JSON). De antwoorden staan als codes in plaats van teksten, zodat NL en EN samen te analyseren zijn:

| Sleutel | Inhoud |
|---|---|
| `q1`–`q28` | bekeerlingen: antwoord per vraag (meerdere antwoorden = lijst) |
| `n1`–`n22` | niet-moslims: antwoord per vraag |
| `xN_other` | tekst bij "Anders" |
| `q19_<stelling>_before` / `_now` | bekeerlingen: score 1–5 vóór en nu |
| `n11_<stelling>` | niet-moslims: score 1–5 per stelling |

De vraagnummers die de bezoeker ziet lopen door (1, 2, 3 …) en wijken soms af van de sleutels. Zo is `q28` (wie bracht de boodschap over) vraag 12 op het scherm. Zoek de sleutels op in `index.html`.

E-mailadressen (q25 en n21) staan alleen in de tabel `contacts` en zijn niet aan de antwoorden gekoppeld.

## Vrijwilligersgegevens beheren

- De tabel `volunteers` bevat namen en contactgegevens, dus behandel die als een ledenadministratie.
- Gebruik de kolom `status` om bij te houden wie je gesproken hebt (nieuw, gesproken, actief, gestopt).
- Deel gegevens alleen met andere vrijwilligers als `share_ok = true`, en dan alleen naam, beroep en vaardigheden.
- Een verzoek om verwijdering voer je binnen een maand uit (query staat in `schema.sql`).

## Privacy (AVG)

- Religie is een bijzonder persoonsgegeven. De enquête vraagt daarom expliciete toestemming en slaat geen namen op.
- De database staat in de EU. Supabase biedt een verwerkersovereenkomst (DPA) aan in het dashboard; teken die.
- Vul de privacygegevens in `CONFIG` in en houd je aan de verwijderdatum.
- Bezoekers kunnen alleen gegevens toevoegen, niet lezen. Alleen jij ziet de data via het dashboard.

## Let op

- Gratis Supabase-projecten worden na een periode zonder activiteit gepauzeerd. Kijk tijdens de wervingsperiode af en toe in het dashboard.
- Een verborgen honeypot-veld filtert simpele spambots. Krijg je toch spam, zet dan Cloudflare Turnstile ervoor.
