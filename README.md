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

## Known issues tracked for Phase I

- `APP-1` — backend URL hardcoded to a LAN IP (above).
- `APP-2` — plain HTTP + session cookie/cached data stored **unencrypted** in `shared_preferences`.
- `APP-3` — no automated tests. · `APP-4` — form schema bundled, not server-driven.

Full list and fix order: the project docs site.
