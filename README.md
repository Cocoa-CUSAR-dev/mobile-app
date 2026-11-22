# Cocoa Farmer Mobile App (Flutter)

Offline-first field app for **farmers, processors, and collectors** in the Cocoa Supply Chain Databank (Is Thai Cacao). Registers farms/plots/hubs/stations and records activities, harvests, fermentation, drying, and grading. Talks to the Go mobile backend.

---

## Role in the 2026–2027 plan

Part of a system being modernized over a 10-month thesis (Jul 2026 – Apr 2027):

- **Phase I (mandatory, by Dec 2026)** — Add a **LINE OA AI chatbot** as a new farmer data-entry channel, **modernize this app's architecture**, plus SSO, reminders, and web submission history.
- **Phase II (gated, Dec 2026 – Apr 2027)** — Knowledge Base + Computer Vision.

**Where this app fits:** this is the **existing farmer app, and it stays in place** — the LINE OA chatbot is an *additive* channel, **not a replacement**, so there is **no data migration**. In Phase I the app is **refactored/modernized** (cleaner module boundaries, env-based config, secure storage, tests) rather than rewritten. The `APP-*` items in the weak-point register are the concrete refactor targets.

---

## Tech stack

Flutter 3.9+ (Dart ^3.9.2) · flutter_bloc (BLoC) · MapLibre GL · Material 3 · Thai font (NotoSansThaiLooped) · shared_preferences (local cache) · http.

## Key design decisions

- **Offline-first.** Fetches network-first; on failure (or a 10s timeout) falls back to the latest cache in `shared_preferences`. Mutations queue locally with `pending` status and sync when connectivity returns; conflicts resolve by timestamp + UUID.
- **Dynamic role-based forms.** Farmer / Processor / Collector see different form sets rendered from a schema (currently the bundled `assets/schema.json` — planned to become server-driven; `APP-4`).
- **`ServiceProvider` = single data gateway.** All HTTP + local storage go through `lib/services/service_provider.dart`.

## Code structure (`lib/`)

*(Corrected — the old README's `blocs/` and `screens/` names were wrong.)*

| Path | Purpose |
|---|---|
| `main.dart` / `route.dart` | entry point and routing |
| `bloc/` | BLoC state, one folder per feature (login, farm, plot, hub, batch, task, dynamic, …) |
| `models/` | data classes + JSON (de)serialization |
| `widgets/pages/` | full-screen pages |
| `widgets/components/` | reusable form inputs (`form_input`, `dropdown_input`, `gis_input`, `upload_input`, …) and scaffolds |
| `services/` | HTTP, GPS, files — incl. `service_provider.dart` |
| `assets/schema.json` | dynamic form definitions |

## Run & build

```bash
flutter pub get
flutter run                      # with an emulator running

flutter build apk --release      # Android APK
flutter build appbundle          # Play Store bundle
flutter build ipa                # iOS (needs macOS + Xcode)
```

## Configuration — read this before running

The backend URL is **hardcoded** in `lib/services/service_provider.dart`:

```dart
final String baseUrl = 'http://192.168.10.188:8080';
```

Change it to point at your Go backend. Moving this to env/flavor-based config is `APP-1`, an early Phase I fix — until then you must edit the source per environment.

## LINE: the account-link page (LIFF)

The LINE rich menu's "เชื่อมบัญชี LINE" button opens
`https://liff.line.me/2010930353-4bm8N7wN`. The LIFF ID is in
`lib/config/liff_config.dart` (override with `--dart-define=LIFF_ID=...`).

| Where | Value |
|---|---|
| LIFF Endpoint URL (LINE Developers Console) | `https://cocoa-cusar-dev.github.io/mobile-app/liff-link` |
| App route | `/liff-link` (`LiffLinkPage`, `lib/widgets/pages/liff_login_page.dart`) |
| Success route | `/liffLoginSuccess` (closes the LIFF window) |

What the page does (`lib/bloc/login/liff_login_bloc.dart`):

1. `liff.init()`, once per page.
2. If the person is already signed in with LINE, it tries `POST /api/v1/auth/line/login`
   with the LINE ID token. Answered with a token pair: this LINE account is
   already linked, so it goes straight to the success page. Any other answer
   (403 = not linked yet) shows the landing page, "ท่านมีบัญชีผู้ใช้อยู่แล้วหรือไม่".
3. "มีบัญชีผู้ใช้แล้ว" starts LINE login if needed and shows the form
   (`POST /api/v1/auth/line/link`); "ยังไม่มีบัญชีผู้ใช้" goes to sign-up and links
   afterwards.

Things worth knowing:

- **`/liff-link` answers 200.** GitHub Pages has no file for that path, so
  `deploy-web-test.yml` publishes a copy of `index.html` as `liff-link.html`
  (GitHub Pages serves `foo.html` at `/foo`). Without it every launch from LINE,
  and the return from LINE's login with its `code`, first got a 404 and a script
  redirect from `web/404.html`. Other deep links still use `404.html`. If the
  Endpoint URL or `--base-href` ever changes, change it in the console, here and
  in that workflow step.
- **LIFF runs `init` once per page** (`liffInit` shares the one in flight, and
  the bloc handles init and login events one at a time). Two inits at once
  write two PKCE verifiers and LINE then refuses the code of the first with
  `code_verifier does not match`.
- That error text comes from LINE, not from our backend. The error panel's
  "ลองใหม่อีกครั้ง" starts over.

## Known issues tracked for Phase I

- `APP-1` — backend URL hardcoded to a LAN IP (above).
- `APP-2` — plain HTTP + session cookie/cached data stored **unencrypted** in `shared_preferences`.
- `APP-3` — no automated tests. · `APP-4` — form schema bundled, not server-driven.

Full list and fix order: the project docs site.
