# Ponvia — Milestones

Sequenced roadmap. **Only M0 is being built in the current pass** (docs, decisions,
agents, design handoff). Each milestone lists deliverables and a definition-of-done (DoD).
Do not work ahead of the current milestone without the user's go-ahead.

Legend: ☐ not started · ◐ in progress · ☑ done

---

## M0 — Foundation (docs & design handoff) ◐
**Deliverables**
- `docs/SPEC.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/MILESTONES.md`
- `README.md`, `CLAUDE.md`
- `design/DESIGN_BRIEF.md`, `design/DESIGN_SYSTEM.md`, `design/HANDOFF.md`
- `.claude/agents/*.md` (6 specialized agents)
- `.github/workflows/release.yml` + `CHANGELOG.md` (prepared; inert until M1)

**DoD:** All docs exist and cross-link; SPEC covers every feature in the brief; the design
brief is self-contained enough to paste into the design tool; agents load without errors.
No Dart code yet.

## M1 — Scaffold + data layer ◐ (on-device run pending)
**Deliverables**
- ☑ `flutter create` project (id `io.github.kupperlupperdupper.ponvia`), folder structure
  per ARCHITECTURE, analysis options (excludes generated files).
- ☑ Riverpod (no codegen — ADR-013) + go_router (bottom-tab shell + onboarding gate) wired;
  Material 3 theme built from `design/handoff/tokens.json` (light/dark + `PonviaColors`
  extension). Native splash deferred to M3 with onboarding.
- ☑ Drift schema (`weight_entries`, `goals`) + repositories; `SettingsStore` over
  shared_preferences.
- ☑ Unit conversion (kg/lb/st) + formatters; closest-goal logic.
- ☑ JSON + CSV import/export (codec + service).
- ☑ Functional screens: Home (hero + delta + goal), Log, History (list + swipe-delete),
  Goals (add/highlight/delete), Settings (theme/unit/language, export, clear).
- ☑ Unit tests (conversion, goal selection, backup round-trip) + Home widget test;
  `scripts/check.sh`.

**DoD:** ☑ `flutter analyze` clean · ☑ tests green (15) · ☑ debug APK builds. ☐ On-device
smoke test on the OnePlus (`flutter run -d 6eb5eb45`) — pending phone connection. Release
workflow can now produce an APK on a tag.

## M2 — Core screens (functional, pre-design styling) ☐
**Deliverables:** Home (last-weight hero + delta + mini-trend), Log/Edit weight, History
(list + fl_chart with range switch), Goals (list with closest highlighted + editor),
Settings shell. All backed by live Drift streams.

**DoD:** Every SPEC §3.3–3.6 acceptance criterion demonstrably works on-device with
placeholder styling; widget tests for hero, goal-highlight, and log validation pass.

## M3 — Onboarding + i18n ☐
**Deliverables:** Splash → onboarding gate; first-run stepper (language, theme, unit,
optional first weight + reminder); full en/da localization; locale/theme/unit apply live.

**DoD:** Fresh install lands in onboarding; choices persist and apply app-wide; switching
language/theme/unit in Settings updates the UI immediately; no hard-coded strings
(analyzer/l10n checks pass).

## M4 — Notifications ☐
**Deliverables:** Reminder settings UI (daily/weekly+weekday/monthly+day, time-of-day);
`ReminderService` scheduling; Android 13+ permission flow + exact-alarm handling; reboot
reschedule; tap → `/log` deep link.

**DoD:** Each frequency schedules and fires correctly on-device (incl. weekday/monthly
edge cases); disabling cancels everything; denied permission degrades gracefully.

## M5 — Design integration ☐
**Deliverables:** Apply returned design tokens + mockups (theme, type, spacing, motion,
icons/splash assets); polish transitions; performance pass (startup, scroll, chart).

**DoD:** Screens match the approved designs in light & dark, en & da, and all three units;
no frame drops on hot paths; splash has no white flash.

## M6 — Device QA + release prep ☐
**Deliverables:** On-device QA pass; version bump + `CHANGELOG.md` entry; tag `v0.x.0` to
exercise the release workflow (APK + QR + notes). iOS build/run deferred until a Mac is
available.

**DoD:** A tagged release produces an installable APK with a scannable QR and an accurate
changelog; core flows verified on the OnePlus.

---

### Future (post-v1, not scheduled)
Calorie/food tracking, health-platform integration, home-screen widgets, cloud
sync/multi-device, multi-profile, watch app. The data model and folders leave room for
these without reworking existing code.
