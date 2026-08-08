# Changelog

All notable changes to Ponvia are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions follow `vMAJOR.MINOR.PATCH`.

The release workflow ([.github/workflows/release.yml](.github/workflows/release.yml)) also
auto-generates a per-release commit list, but this file is the curated, human-readable
history — update the **Unreleased** section as you work, and cut it into a version on tag.

## [Unreleased]
### Added
- M0 foundation: product spec, architecture, decision log, milestones, design handoff
  brief/system, six specialized agents, and the Android release workflow.
- Design system delivered into `design/handoff/`: filled `DESIGN_SYSTEM.md` + `tokens.json`,
  per-screen `DESIGN_SPEC.md`, mockup canvas, and brand/icon/splash assets. Seed `#1F6A5C`,
  Manrope type, bottom-tab navigation, neutral delta colors, `st + lb` stone.
- M1 scaffold + data layer: Flutter app (`io.github.kupperlupperdupper.ponvia`) with
  Riverpod, go_router bottom-tab shell + onboarding gate, Material 3 theme from tokens,
  Drift (weights + goals) + shared_preferences settings, kg/lb/st conversion, JSON+CSV
  import/export, functional Home/Log/History/Goals/Settings screens, and unit + widget
  tests. `flutter analyze` clean; 15 tests pass; debug APK builds.
- Bundled the Manrope typeface (SIL OFL 1.1 variable font) under `assets/fonts/` — the UI
  now renders in Manrope; no runtime font fetching.
- Fixed the launcher app name to “Ponvia” (was lowercase `ponvia`) on Android and iOS.
- Verified on-device (OnePlus): onboarding, navigation, DB, theme, and font all render.
- App icon (adaptive: mint mark on `#1F6A5C`) and native splash (light: green plate on
  brand green; dark: mint plate on `#0E1412`; Android-12 icon splash) generated from the
  design assets via flutter_launcher_icons + flutter_native_splash. Splash verified
  on-device; icon verified inside the built APK.
- M2 core screens: modal log/edit sheet (editable date/time), Home sparkline + goal
  progress, History trend chart with 1W/1M/3M/1Y/All range switcher + tap-to-edit, Goals
  editor + mark-achieved + distance, and JSON/CSV export (share sheet) + import (file
  picker, merge/replace). Data I/O uses file_selector + share_plus (ADR-015). 18 tests.

<!--
When cutting a release, move Unreleased items under a version heading, e.g.:

## [v0.1.0] - YYYY-MM-DD
### Added
- ...
### Changed
- ...
### Fixed
- ...
-->
