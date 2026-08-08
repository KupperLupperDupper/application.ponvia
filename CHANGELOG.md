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
