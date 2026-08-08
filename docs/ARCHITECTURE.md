# Ponvia — Architecture

> Target architecture for M1+. Nothing here is built yet (M0 = docs only). Rationale for
> each choice lives in [DECISIONS.md](DECISIONS.md); the feature contract is
> [SPEC.md](SPEC.md).

## 1. High-level shape

Ponvia is a **single-module Flutter app** organized into clear layers with a
**feature-first** folder layout. State is managed with **Riverpod**; persistence is
**Drift (SQLite)** for domain data and **shared_preferences** for scalar settings.
Everything is **local and offline** — there is no network layer.

```
UI (screens, widgets)                 ← presentation
  │  watches/reads providers
Application (controllers, notifiers)  ← state, use-case orchestration
  │  calls repositories
Domain (models, unit conversion, goal logic)  ← pure Dart, no Flutter/DB deps
  │
Data (Drift DB, DAOs, prefs, import/export)   ← persistence & I/O
```

**Dependency rule:** dependencies point downward only. Domain is pure Dart (unit-testable
with no Flutter/DB). UI never touches the DB directly — always via
providers → repositories.

## 2. Package identity & platforms

- **Application id / bundle id:** `io.github.kupperlupperdupper.ponvia`
  (reverse-DNS from the GitHub org `github.com/KupperLupperDupper`; lowercased).
- **App display name:** Ponvia.
- **Platforms:** Android first (target device OnePlus `6eb5eb45`). iOS deferred until a
  Mac is available; Flutter keeps the iOS project scaffolded but unbuilt. Web is a
  smoke-test target only, not shipped.

## 3. Folder structure (proposed for M1)

```
lib/
  main.dart                     # bootstrap: init prefs/db, ProviderScope, run app
  app/
    app.dart                    # MaterialApp.router, theme, locale wiring
    router.dart                 # go_router routes + redirects (onboarding gate)
    theme/                      # ThemeData from design tokens (light/dark)
  core/
    units/                      # WeightUnit enum + conversion (pure, tested)
    formatting/                 # date/number/weight formatters (locale-aware)
    result/                     # error/result helpers, failures
    extensions/
  data/
    db/
      database.dart             # Drift database + connection
      tables/                   # weight_entries, goals (+ room for calories later)
      daos/                     # WeightDao, GoalDao
    prefs/                      # SettingsStore over shared_preferences
    backup/                     # JSON envelope + CSV import/export
  domain/
    models/                     # WeightEntry, Goal, AppSettings, ReminderConfig (immutable)
    goals/                      # closest-goal selection logic (pure, tested)
  features/
    home/                       # home dashboard (last-weight hero)
    logging/                    # add/edit weight entry
    history/                    # list + chart
    goals/                      # goals list & editor
    onboarding/                 # first-run flow
    settings/                   # settings + about + data mgmt
    notifications/              # reminder scheduling UI + service binding
  l10n/
    app_en.arb
    app_da.arb
test/                          # unit + widget tests mirroring lib/
```

## 4. State management (Riverpod)

- `flutter_riverpod` + `riverpod_annotation` / `riverpod_generator` for codegen providers.
- **Repositories** are providers wrapping DAOs/stores. **Controllers** are
  `AsyncNotifier`/`Notifier` that expose screen state and mutations.
- Streaming: Drift `watch` queries feed `StreamProvider`s so the home screen and history
  update reactively after a log/edit/delete — satisfies SPEC AC "reflects immediately".
- Keep rebuilds narrow: select/derive only what a widget needs; prefer `family` providers
  keyed by range/id over rebuilding large trees.

## 5. Navigation (go_router)

Routes (names indicative):
- `/splash` → decides onboarding vs home based on `hasOnboarded`.
- `/onboarding` → first-run stepper.
- `/` (home) → dashboard.
- `/log` (and `/log/:id` for edit) → weight entry form. Also the deep-link target for
  reminder taps.
- `/history` → list + chart.
- `/goals` → list; `/goals/edit/:id?` → editor.
- `/settings` → settings; nested `/settings/about`, `/settings/data`,
  `/settings/notifications`.

A router **redirect** gates onboarding: until `hasOnboarded`, all routes funnel to
`/onboarding`.

## 6. Data model & schema

Canonical unit is **kg**. Timestamps stored as UTC epoch millis (or Drift `DateTime`),
formatted to local on display.

**Drift tables**
- `weight_entries`
  - `id` INTEGER PK autoincrement
  - `timestamp` DATETIME (indexed, for range queries & "latest")
  - `weight_kg` REAL (canonical)
  - `note` TEXT nullable
- `goals`
  - `id` INTEGER PK autoincrement
  - `target_weight_kg` REAL
  - `label` TEXT nullable
  - `created_at` DATETIME
  - `achieved_at` DATETIME nullable

**Settings (shared_preferences, scalar keys)**
- `locale` ("en" | "da" | system)
- `themeMode` ("system" | "light" | "dark")
- `unit` ("kg" | "lb" | "st")
- `hasOnboarded` (bool)
- `reminder` (serialized `ReminderConfig`: enabled, frequency, weekday?, dayOfMonth?,
  timeOfDay)
- `schemaVersion` for migrations

**Calorie future-proofing:** no calorie tables now, but the DB migration strategy and
folder layout leave room to add `food_entries` / `calorie_*` tables without reworking
existing ones.

**Derived logic (domain, pure):**
- *Latest weight* = entry with max timestamp.
- *Delta* = latest − previous.
- *Closest goal* = `argmin(|current_kg − target_kg|)` over non-achieved goals; documented
  tie-break (smaller required change, then most recent `created_at`). Suppressed when no
  entries exist.

## 7. Units & formatting

- `WeightUnit { kg, lb, st }` with pure conversion to/from kg and a display formatter.
- Locale-aware number/date formatting via `intl`. Stone renders as composite `st + lb`
  by default (final format confirmed in design).
- All conversions covered by unit tests including round-trip stability.

## 8. Theming & i18n

- **Material 3.** `ThemeData` for light and dark built from **design tokens** (seed color,
  type scale, radii, spacing) delivered by the design step —
  see [../design/DESIGN_SYSTEM.md](../design/DESIGN_SYSTEM.md).
- `themeMode` from settings drives light/dark/system.
- **i18n** via Flutter `gen_l10n`: `app_en.arb` (template) + `app_da.arb`, generated
  `AppLocalizations`. Locale from settings, overriding system when set. No hard-coded UI
  strings. Danish and English kept at parity by the i18n agent.

## 9. Notifications architecture

- `flutter_local_notifications` + `timezone` (+ `flutter_timezone` to resolve the device
  zone) for zoned scheduled reminders.
- A `ReminderService` translates a `ReminderConfig` into scheduled notifications:
  - Daily → one repeating daily trigger at `timeOfDay`.
  - Weekly → next occurrence of `weekday` at `timeOfDay`, repeating weekly.
  - Monthly → `dayOfMonth` at `timeOfDay`, clamped to the last day in short months.
- **Android specifics:** request `POST_NOTIFICATIONS` (API 33+) contextually; handle
  exact-alarm constraints per Android version; reschedule on `BOOT_COMPLETED` if the
  chosen mechanism requires it. Denied permission degrades to "reminders off" with an
  explanatory state.
- Reminder tap opens `/log` (deep link).
- iOS scheduling paths written now, verified when a Mac exists.

## 10. Import / export

- **JSON backup (full fidelity).** Versioned envelope:
  ```json
  {
    "schemaVersion": 1,
    "app": "ponvia",
    "exportedAt": "<ISO-8601 UTC>",
    "weights": [ { "timestamp": "<ISO>", "weightKg": 82.4, "note": null } ],
    "goals":   [ { "targetWeightKg": 78.0, "label": "Summer", "createdAt": "<ISO>", "achievedAt": null } ],
    "settings": { "locale": "da", "themeMode": "system", "unit": "kg", "reminder": { } }
  }
  ```
  Restore offers **merge** or **replace**; timestamp collisions de-duped deterministically;
  schema version checked (migrate or reject with a message).
- **CSV (weight history only).** Columns: `timestamp,weight_kg,weight_display,unit,note`.
  Import appends, validates each row, and reports imported/skipped counts.
- Uses OS file/share pickers (e.g. `file_picker`/`share_plus`); no network.

## 11. Performance practices

- Defer heavy init off the first frame; show splash while warming DB/prefs.
- Prefer streaming providers + `const` widgets; avoid rebuilding lists/charts wholesale.
- Cap chart point density per range; downsample "All" range.
- Use `flutter_native_splash` to eliminate the white-flash and keep perceived start fast.

## 12. Testing strategy

- **Unit:** unit conversion (round-trip), closest-goal selection & tie-breaks, reminder
  date math (weekly/monthly/DST/short months), JSON/CSV serialize↔deserialize.
- **Widget:** home hero renders latest + delta; goals list highlights the closest; log
  form validation; settings toggles apply.
- **Golden (optional):** key screens in light/dark once design lands.
- CI-lite: a `scripts/check` running `flutter analyze` + `flutter test` (added in M1).

## 13. Tooling & dependencies (recommended, added in M1)

| Concern            | Package |
|--------------------|---------|
| State              | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner` |
| Database           | `drift`, `sqlite3_flutter_libs`, `drift_dev` |
| Prefs              | `shared_preferences` |
| Navigation         | `go_router` |
| i18n               | `flutter_localizations` (SDK), `intl`, gen_l10n |
| Charts             | `fl_chart` |
| Notifications      | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Files/share        | `file_picker`, `share_plus`, `path_provider` |
| Splash/icons       | `flutter_native_splash`, `flutter_launcher_icons` |
| Lint               | `flutter_lints` (or `very_good_analysis`) |
| Utility (optional) | `freezed`/`json_serializable` for models if warranted |

Exact versions pinned at scaffold time against Flutter 3.44.9 / Dart 3.12.2.
