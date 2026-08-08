# Ponvia — Decision Log (ADRs)

Lightweight architecture decision records. Each: **context → decision → rationale →
alternatives rejected**. Newest decisions can be appended over time.

---

## ADR-001 — Framework: Flutter
- **Decision:** Build Ponvia in Flutter (Dart), single codebase for Android + iOS.
- **Rationale:** One codebase for both stores; excellent performance; strong local-DB and
  charting ecosystem; developer targeting Android now, iOS later without a rewrite.
- **Rejected:** Native Kotlin/Swift (two codebases), React Native (weaker for smooth
  charts/perf here), KMP+Compose (iOS UI still bespoke).

## ADR-002 — State management: Riverpod
- **Decision:** `flutter_riverpod` with code-gen (`riverpod_generator`).
- **Rationale:** Compile-safe, testable without a widget tree, fine-grained rebuilds
  (matters for the performance goal), first-class async/stream providers that pair well
  with Drift's reactive queries.
- **Rejected:** Bloc (more boilerplate for this scale), `provider` (less safety),
  setState-only (won't scale across features).

## ADR-003 — Local database: Drift (SQLite)
- **Decision:** Drift over SQLite for domain data (weights, goals).
- **Rationale:** Robust time-series queries and indexing for history/charts; reactive
  `watch` streams for live UI; first-class migrations; trivial to serialize the whole DB
  to a JSON backup and to emit CSV; leaves a clean path to add calorie tables later.
- **Rejected:** Isar (fast but maintenance/roadmap uncertainty), Hive (weak querying for
  time-series + goals), raw sqflite (more manual, less type-safety).

## ADR-004 — Settings storage: shared_preferences
- **Decision:** Scalar settings (locale, theme, unit, onboarding flag, reminder config)
  in `shared_preferences`; domain data in Drift.
- **Rationale:** Settings are small key/values read at startup; no need for a DB round-trip
  or schema. Keeps the DB focused on records.
- **Rejected:** Storing settings in Drift (heavier for scalars), platform-specific stores.

## ADR-005 — Navigation: go_router
- **Decision:** `go_router` for declarative, deep-link-capable routing.
- **Rationale:** Clean onboarding redirect gate; notification taps deep-link to `/log`;
  URL-style routes ease testing and future web smoke tests.
- **Rejected:** Navigator 1.0 (imperative, awkward for redirect gating), auto_route
  (extra codegen without clear benefit here).

## ADR-006 — Internationalization: gen_l10n + ARB (en, da)
- **Decision:** Flutter's built-in `gen_l10n` with `app_en.arb` (template) + `app_da.arb`.
- **Rationale:** Official, no runtime dependency, compile-checked keys; Danish + English
  are the launch languages; locale overrides system when the user chooses.
- **Rejected:** `easy_localization`/`slang` (extra deps; built-in is sufficient here).

## ADR-007 — Charts: fl_chart
- **Decision:** `fl_chart` for the weight trend (mini + full).
- **Rationale:** Flexible, performant line charts; themeable to match design tokens;
  widely used and maintained.
- **Rejected:** `syncfusion_flutter_charts` (heavier/licensing), hand-rolled `CustomPainter`
  (more effort; revisit only if fl_chart limits us).

## ADR-008 — Notifications: flutter_local_notifications + timezone
- **Decision:** `flutter_local_notifications` with `timezone` + `flutter_timezone` for
  zoned, scheduled local reminders.
- **Rationale:** Purely local (no push server needed), supports daily/weekly/monthly
  scheduling in the device timezone, handles Android 13+ permission and exact alarms.
- **Rejected:** Firebase Cloud Messaging (requires network/cloud; violates local-only),
  workmanager-only (less suited to precise user-facing reminders).

## ADR-009 — Canonical unit: kilograms
- **Decision:** Store all weights in **kg**; convert for display to kg/lb/st.
- **Rationale:** One canonical unit avoids drift/rounding bugs; switching display units
  never mutates stored data; conversions are pure and unit-tested.
- **Rejected:** Storing in the user's current display unit (fragile on unit change).

## ADR-010 — Data portability: JSON (full) + CSV (weights)
- **Decision:** Export/import a versioned JSON backup (weights + goals + settings) and a
  CSV of weight history.
- **Rationale:** JSON gives lossless backup/restore; CSV gives spreadsheet
  interoperability. Versioned envelope enables safe migration. Matches user choice.
- **Rejected:** JSON-only (no spreadsheet path), CSV-only (loses goals/settings fidelity),
  proprietary/binary formats (not portable).

## ADR-011 — Application id: io.github.kupperlupperdupper.ponvia
- **Decision:** Package/bundle id `io.github.kupperlupperdupper.ponvia`.
- **Rationale:** The developer owns no domain; the community convention for a
  GitHub-hosted project is reverse-DNS on `github.com/<user>` → `io.github.<user>`.
  Lowercased per Android/iOS id rules. Stable and unlikely to collide.
- **Rejected:** `com.littlebeacon.*` (explicitly declined by the user), `com.github.*`
  (discouraged; `github.com` isn't the publisher), a made-up domain.

## ADR-012 — Release delivery: GitHub Actions → APK + changelog + QR
- **Decision:** A GitHub Actions workflow triggered on `v*` tags (and manual dispatch)
  builds a **release APK**, generates a **changelog** from commits since the previous
  tag (augmented by `CHANGELOG.md` when present), generates a **QR code** encoding the
  APK's release-asset download URL, and publishes a **GitHub Release** with the APK + QR
  attached and the QR inlined in the notes for phone scanning.
- **Rationale:** The developer installs directly on their own Android device; a scannable
  QR to a hosted APK is the lowest-friction sideload path. Deterministic asset URLs let
  the QR be generated in the same run. A single universal APK (not split-per-ABI) means
  one file and one QR to scan.
- **Signing:** v1 uses Flutter's default release signing (debug keystore) so the APK
  installs without extra setup. A real upload keystore via repo secrets can be added
  later without changing the workflow's shape.
- **Rejected:** Split-per-ABI APKs (multiple files/QRs), Play Internal Testing (heavier,
  account/setup overhead for a personal app), third-party QR web services (network +
  privacy; QR is generated on the runner instead).
- **Dependency note:** The workflow references `flutter build apk`, so it only succeeds
  once the M1 scaffold (`pubspec.yaml` + Android project) exists and a `v*` tag is pushed.
  Until then it is inert.

## ADR-013 — Riverpod without code generation (M1)
- **Decision:** Use hand-written Riverpod providers (`Provider`, `NotifierProvider`,
  `StreamProvider`) instead of `riverpod_generator`.
- **Rationale:** At M1, `riverpod_generator` (analyzer ^13) could not co-resolve with
  `drift_dev` (analyzer <3 transitively via the test toolchain) — version solving failed.
  Drift's codegen is mandatory; Riverpod's is optional. The non-codegen API is fully
  supported in Riverpod 3.x and providers are an implementation detail, so this is
  reversible later without reworking call sites. Supersedes the codegen mention in
  ARCHITECTURE §4 / ADR-002.
- **Rejected:** Pinning older Riverpod/analyzer (would hold back Drift), dropping Drift
  codegen (impossible).

## ADR-014 — Disable Kotlin incremental compilation on this machine
- **Decision:** Set `kotlin.incremental=false` in `android/gradle.properties`.
- **Rationale:** `compileDebugKotlin` repeatedly crashed with "Could not close incremental
  caches … *.tab" on this Windows dev box (file-locking on `build/`, likely AV). Disabling
  incremental compilation is slightly slower but builds reliably. Harmless on CI.
- **Rejected:** Excluding `build/` from AV (not always possible), retрy loops (didn't help).

## ADR-015 — File I/O plugins: file_selector + share_plus (not file_picker)
- **Decision:** Use `file_selector` (import/open) and `share_plus` (export via the OS share
  sheet) for data portability. Not `file_picker`.
- **Rationale:** `file_picker` applies the Kotlin Gradle Plugin, which fails to compile
  under Flutter's new Built-in-Kotlin Android setup used by this project (`compileDebugKotlin
  not found in project ':file_picker'` → `GeneratedPluginRegistrant` can't resolve
  `FilePickerPlugin`). `file_selector` (Flutter-team, Java-based) and `share_plus` don't
  apply KGP and build cleanly. Export as a share also gives a nicer "save to…/send"
  flow than a bare save dialog. `file_picker` also conflicted with `share_plus` on win32.
- **Rejected:** `file_picker` (build failure), keeping `share_plus`+`file_picker` (win32
  conflict), writing exports only to app storage (poor discoverability).
