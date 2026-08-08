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

## M1 — Scaffold + data layer ☑
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

**DoD:** ☑ `flutter analyze` clean · ☑ tests green (15) · ☑ debug APK builds · ☑ on-device
smoke test on the OnePlus (`6eb5eb45`): cold start ~2.0s, onboarding → home → DB open →
empty state, theme tokens applied in dark mode, no runtime errors. Release workflow can now
produce an APK on a tag. **M1 complete.**

## M2 — Core screens (functional, pre-design styling) ☑
**Deliverables:**
- ☑ Log/Edit as a modal bottom sheet (add + edit, editable date/time, note).
- ☑ Home: last-weight hero + delta chip + recent-trend sparkline (fl_chart) + progress
  toward the highlighted goal.
- ☑ History: list (tap-to-edit, swipe-delete) + trend chart with 1W/1M/3M/1Y/All switcher.
- ☑ Goals: add/edit dialog, mark achieved (with achieved treatment), distance-to-target.
- ☑ Settings: JSON + CSV export via the share sheet, import (JSON/CSV) via file picker
  with merge/replace, clear data.

**Deps note:** `file_picker` couldn't build under Flutter's Built-in-Kotlin Android setup
(it applies KGP); swapped to `file_selector` (import) + `share_plus` (export). See
DECISIONS ADR-015.

**DoD:** ☑ `flutter analyze` clean · ☑ 18 tests pass (incl. hero, goal-highlight+distance,
log validation) · ☑ debug APK builds · ☑ on-device: modal log sheet + save → Home hero
updates. **M2 complete.**

## M3 — Onboarding + i18n ☑
**Deliverables:**
- ☑ Full **en/da localization** via gen_l10n (`lib/l10n/*.arb`, ~75 keys); every screen
  localized (no hard-coded user-facing strings). Locale from settings, overriding system.
- ☑ Locale / theme / unit apply **live** across the app (incl. during onboarding).
- ☑ First-run **onboarding stepper** (PageView): welcome → language → unit → theme →
  optional first weight → all set; dots indicator; full-width nav buttons.
- ☑ Native splash + router onboarding gate (from M1) intact.
- Reminder setup in onboarding deferred to **M4** (built with the notification engine).

**DoD:** ☑ analyze clean · ☑ 19 tests pass (incl. onboarding render) · ☑ debug APK builds ·
☑ on-device: fresh install lands in onboarding, renders in **Danish** (system locale),
stepper advances, choices apply live. **M3 complete.**

**Bug fixed:** the theme's `FilledButton.minimumSize = Size.fromHeight(56)` is
infinite-width; placing such a button beside a `Spacer` in a `Row` crashed onboarding
layout. Nav buttons are now full-width (stretch), matching the design's pill buttons.

## M4 — Notifications ☐
**Deliverables:** Reminder settings UI (daily/weekly+weekday/monthly+day, time-of-day);
`ReminderService` scheduling; Android 13+ permission flow + exact-alarm handling; reboot
reschedule; tap → `/log` deep link.

**DoD:** Each frequency schedules and fires correctly on-device (incl. weekday/monthly
edge cases); disabling cancels everything; denied permission degrades gracefully.

## M5 — Design integration ☐
**This is the high-fidelity pass** — M1–M4 built function with token-only styling; M5 makes
every screen actually match `design/handoff/DESIGN_SPEC.md` + the mockup canvas. It is
craft work (bespoke components, spacing rhythm, elevation, motion), not a token tweak, done
screen-by-screen with on-device before/after review.

**Deliverables:**
- Rebuild each screen to the mockups: hero card, styled trend chart (gradient, markers,
  custom range control), goal cards, list rows, settings rows, empty states, dialogs/sheets.
- Elevation, radii, spacing scale, and motion/transitions per the tokens; splash→app
  transition; no white flash.
- **Custom in-app number pad** for weight/goal entry (0–9, decimal, backspace), styled to
  the tokens, replacing the OS numeric keyboard. Used in the log sheet, onboarding
  first-weight, and goal target. (User-requested.)
- Performance pass (startup, scroll, chart).

**DoD:** Screens match the approved designs in light & dark, en & da, and all three units;
custom keypad works for all numeric entry; no frame drops on hot paths; splash has no
white flash.

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
