# Changelog

All notable changes to Ponvia are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions follow `vMAJOR.MINOR.PATCH`.

The release workflow ([.github/workflows/release.yml](.github/workflows/release.yml)) also
auto-generates a per-release commit list, but this file is the curated, human-readable
history — update the **Unreleased** section as you work, and cut it into a version on tag.

## [Unreleased]

## [0.2.0] - 2026-08-12
### Added
- **Universal add button** in the bottom navigation — log a weight from any tab, not just
  Home. The nav bar now has a central add action; "New goal" moved to an app-bar button on
  the Goals screen.
- **Undo on every delete** — a custom, themed snackbar with an Undo action now appears when
  you delete a weight entry (in History or the edit sheet) or a goal. **Clear all data** and
  a **Replace** import are undoable too: they snapshot your data first so the wipe can be
  reversed.
- **Privacy page** (Settings › Privacy) — a plain-language, fully-local summary in English
  and Danish: no accounts, no cloud, no tracking; your data only leaves the device via an
  export you start yourself.

## [0.1.1] - 2026-08-09
### Fixed
- Goals swipe-to-delete: the red delete surface now sits flush behind the card as you
  swipe, instead of appearing as a separate rounded block with a gap ("hard cut").

## [0.1.0] - 2026-08-08
First release — a private, offline weight tracker for Android (iOS-capable; not yet
built). Everything stays on your device: no accounts, no cloud, no network.

### Added
- **Weight tracking** — log/edit entries with a custom in-app number pad, editable date
  & time, and notes; history list plus an interactive trend chart (1W / 1M / 3M / 1Y / All).
- **Home dashboard** focused on your latest weight, with change vs the previous entry, a
  recent-trend sparkline, and progress toward the highlighted (closest) goal.
- **Goals** — keep several targets; the one closest to your current weight is highlighted;
  add/edit, mark achieved, and see distance-to-target.
- **Weigh-in reminders** — local notifications: daily, weekly (choose the weekday), or
  monthly (choose the day), at a time you pick. Android 13 permission flow; reschedules
  after reboot; tapping a reminder opens the log sheet.
- **Localization** — full English & Danish; light / dark / system theme; kg / lb / st units.
- **Data portability** — JSON backup (weights, goals, settings) and CSV export; import with
  merge or replace.
- **Onboarding** — welcome, language, theme, unit, and an optional first weight.
- **Design** — matched to the Ponvia design system (Manrope, sea-green palette, bottom-tab
  navigation), with a generated app icon and native splash.

### Tech
- Flutter 3.44 · Riverpod · Drift (SQLite) · go_router · Material 3 · fl_chart ·
  flutter_local_notifications. Application id `io.github.kupperlupperdupper.ponvia`.
- Release APKs are signed with a stable upload key (via CI secrets), so updates install
  in place. Portrait-only.
