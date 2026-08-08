# Ponvia

A private, **fully-local weight-tracking app** for Android & iOS, built with Flutter.
Ponvia keeps your **most recent weight front and center**, with goals and trends to give
that number meaning. Your data never leaves your device — export and import a backup
whenever you want. Calorie tracking is planned for a later phase.

> **Status:** M0 — foundation. This repo currently contains **specs, decisions, the
> design handoff, and tooling only**. No Flutter app code exists yet; scaffolding begins
> at M1. See [docs/MILESTONES.md](docs/MILESTONES.md).

## What it does (target)

- **Weight-first home:** last recorded weight as the hero, with change vs previous and
  progress toward your closest goal.
- **Effortless logging:** add/edit/delete weight entries with an optional note; view
  history and a trend chart.
- **Goals:** keep a list of target weights; the one **closest to your current weight** is
  highlighted automatically.
- **Onboarding & splash:** a first-run intro to pick language, theme, and unit.
- **Settings:** language (Danish/English), theme (System/Light/Dark), weight unit
  (kg/lb/st), notification reminders, data import/export, and an About page (version,
  privacy, licenses).
- **Weigh-in reminders:** local notifications — daily, weekly (choose the weekday), or
  monthly.
- **Data portability:** full **JSON** backup/restore + **CSV** weight-history export.

## Documentation map

| Doc | What's in it |
|-----|--------------|
| [docs/SPEC.md](docs/SPEC.md) | Product spec: features + acceptance criteria, scope, NFRs |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers, folders, data model, deps, i18n, notifications, import/export |
| [docs/DECISIONS.md](docs/DECISIONS.md) | ADR-style rationale for every technical choice |
| [docs/MILESTONES.md](docs/MILESTONES.md) | Roadmap M0–M6 with definition-of-done |
| [design/DESIGN_BRIEF.md](design/DESIGN_BRIEF.md) | Prompt to feed the design tool (it outputs a filled `DESIGN_SYSTEM.md`) |
| [design/DESIGN_SYSTEM.md](design/DESIGN_SYSTEM.md) | Design-token contract/template the app will consume |
| [design/handoff/](design/handoff/README.md) | Drop zone for the design output (filled tokens, mockups, assets) |
| [design/HANDOFF.md](design/HANDOFF.md) | How returned designs map into Flutter |
| [CLAUDE.md](CLAUDE.md) | Build environment + conventions for future dev sessions |

## Tech stack (planned)

Flutter 3.44.9 / Dart 3.12.2 · Riverpod · Drift (SQLite) · go_router · Material 3 ·
`gen_l10n` (en/da) · fl_chart · flutter_local_notifications. Rationale in
[docs/DECISIONS.md](docs/DECISIONS.md).

## Platforms

- **Android first** — dev/test on a OnePlus (`flutter run -d <device>`).
- **iOS** — deferred until a Mac is available; the project stays iOS-capable.

## Building & running (from M1 onward)

> These commands work once the Flutter project is scaffolded (M1). Prepend the toolchain
> paths in fresh shells (see [CLAUDE.md](CLAUDE.md)).

```bash
flutter pub get
flutter run -d <android-device-id>     # debug build on a connected phone
flutter analyze
flutter test
```

## Releases (Android APK)

Pushing a `v*` tag (e.g. `v0.1.0`) triggers
[`.github/workflows/release.yml`](.github/workflows/release.yml), which builds a release
APK, generates a changelog from commits since the last tag, creates a **QR code** to the
APK download, and publishes a GitHub Release with the APK + QR attached — scan the QR
with your phone to install. (Active once M1 exists.) Keep [CHANGELOG.md](CHANGELOG.md)
updated per release.

## Privacy

Ponvia makes **no network calls**. All data is stored locally; the only way data leaves
the device is a backup you explicitly export.
