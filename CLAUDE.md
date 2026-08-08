# CLAUDE.md — Ponvia working notes

Instructions for any Claude Code session working in this repo. Read this first, then the
docs it points to.

## What this project is
Ponvia — a private, fully-local Flutter weight-tracking app (calories later). Android
first, iOS deferred until a Mac exists. Source of truth:
- Product: [docs/SPEC.md](docs/SPEC.md)
- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Decisions/rationale: [docs/DECISIONS.md](docs/DECISIONS.md)
- Roadmap + current milestone: [docs/MILESTONES.md](docs/MILESTONES.md)
- Design handoff: [design/](design/)

## Current state
**M0 — foundation.** Docs, design handoff, agents, and the release workflow exist; there
is **no Dart code yet**. Scaffolding starts at M1. Do not build ahead of the current
milestone without the user's go-ahead.

## Build environment (this Windows machine)
Hand-installed toolchain (no Android Studio):
- **Flutter 3.44.9 / Dart 3.12.2** at `C:\src\flutter`.
- **Android SDK** at `C:\Android\Sdk` (`ANDROID_HOME` set; platform-tools, android-36,
  build-tools 36).
- **JDK 17 (Temurin)** at `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot`
  (`JAVA_HOME` set). An old Oracle JDK 8 also exists — **never** use it for Gradle.
- **Test device:** OnePlus LE2123, adb id `6eb5eb45`, USB debugging authorized →
  `flutter run -d 6eb5eb45`.
- iOS: not buildable here (no Mac). Web: smoke-test only.

### ⚠️ Shell PATH quirk (important)
Claude tool-shells inherit a fixed env snapshot and do **not** pick up the persisted user
PATH mid-session. Prepend the paths yourself in every flutter/adb call:
- **Bash:** `export PATH="$PATH:/c/src/flutter/bin:/c/Android/Sdk/platform-tools"`
- **PowerShell:** `$env:Path += ';C:\src\flutter\bin;C:\Android\Sdk\platform-tools'`

## Common commands (M1+)
```bash
export PATH="$PATH:/c/src/flutter/bin:/c/Android/Sdk/platform-tools"
flutter pub get
flutter run -d 6eb5eb45      # debug on the phone (must be connected + authorized)
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # Riverpod/Drift codegen
```
Check the device is visible first: `adb devices`.

## Conventions
- **Layers:** UI → application (Riverpod) → domain (pure Dart) → data (Drift/prefs).
  UI never touches the DB directly. Domain has no Flutter/DB imports and is unit-tested.
- **State:** Riverpod with codegen; prefer streaming providers off Drift `watch`.
- **Units:** store **kg**; convert for display. Never persist display units.
- **i18n:** no hard-coded user-facing strings; add keys to `app_en.arb` + `app_da.arb`
  and keep both at parity.
- **Package id:** `io.github.kupperlupperdupper.ponvia` (do not change casually).
- **Tests:** cover conversions, closest-goal logic, reminder date math, backup round-trip.
- Match surrounding code style; keep changes scoped to the active milestone.

## Releases
Tagging `v*` runs [.github/workflows/release.yml](.github/workflows/release.yml): builds a
release APK, changelog from commits since the last tag, a QR to the APK, and a GitHub
Release. Update [CHANGELOG.md](CHANGELOG.md) before tagging. The workflow only works once
M1 has produced a `pubspec.yaml` + Android project.

## Specialized agents
`.claude/agents/` holds focused subagents (architect, data, UI, i18n, notifications,
device-QA). Use the matching agent for milestone work.

## Memory
Cross-session memory lives in the user's memory store (`ponvia-milestone-status`,
`build-environment`). Keep `ponvia-milestone-status` current when the milestone advances.
