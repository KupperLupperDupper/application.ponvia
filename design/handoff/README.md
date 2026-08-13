# Handoff: Ponvia — Skeleton loading (Round 10)

Replaces the centred `CircularProgressIndicator` on **Home, History and Goals** with a
timing-guarded skeleton. Target: **Flutter + Material 3**, local-first (Drift).

## Read first
**`SKELETON_LOADING.md`** is the spec. It is newer than anything in the other markdown
files and overrides them on loading behaviour. `tokens.json → skeleton` holds every value;
where the HTML and the tokens disagree, **the tokens win**.

## The one-paragraph version
On a healthy device this feature is **invisible**. A local Drift read is 10–40ms, so the
body renders blank for 200ms and the real layout appears — no skeleton widget is ever
constructed. The skeleton exists only for the rare read that stalls, and when it appears it
must look like the layout settling, not a different screen loading. Implement the show
delay as *don't build*, not *build and hide*.

**200ms blank → skeleton (held ≥ 400ms) → 200ms cross-fade to content.**

## Decisions that are settled (do not re-open in implementation)
- **Pulse, not sweep.** 1600ms, `cubic-bezier(0.4,0,0.6,1)`, opacity 1 → 0.55 → 1, **one
  shared clock** for all blocks on a screen.
- **200ms show delay, app-wide** — one constant, not per-screen. 150ms was proposed and
  rejected: it fires during ordinary cold-start jank.
- **Chrome that is not data-bound stays live and tappable** — status bar, app bar title and
  actions, bottom nav, centre add button, and History's range segmented control.
- **No placeholder for Home's second-metric slot.** It is conditional on a height being
  set, which the loader cannot know yet.
- **Zero strings.** No "Indlæser…", no retry. One `Semantics(label: 'Indlæser')` live
  region on the scroll body; decorative blocks excluded from the semantics tree.
- **Reduced motion** (`MediaQuery.disableAnimations`): no pulse, cross-fade becomes an
  instant cut, timings unchanged — the 400ms floor still applies.

## Frames
Open `Ponvia.dc.html` in a browser and pan/zoom. Round 10 is the **topmost section**,
badged `10`, sections 20–23:

| Frame | id |
|---|---|
| `skeleton.home.light.da` · `skeleton.home.dark.da` | `10a` |
| `skeleton.history.light.da` · `skeleton.history.dark.da` | `10b` |
| `skeleton.goals.light.da` · `skeleton.goals.dark.da` | `10c` |
| `skeleton.shimmer-spec` (pulse frames, lifecycle diagram, reduced-motion fallback) | `10d` |

The frames are **design references in HTML**, not code to port — recreate them with Flutter
M3 widgets themed from `tokens.json`. Everything below the `10` badge in that file is
earlier rounds, kept for context.

## Out of scope this round
Modal sheets, Settings, Onboarding and the lock screen keep their current loading
behaviour.

## QA
Verify behind a debug delay. Any skeleton sighting in normal use is a performance bug
report, not a design success. Two failures to watch for:
1. Skeleton visible for **under 400ms** — the floor must run from the skeleton's first
   frame, not from the request.
2. A block at a **different position** than the content replacing it — the transition is a
   dissolve in place, never a re-layout.

## Files
- `SKELETON_LOADING.md` — the spec: timings and their justification, motion, per-screen
  anatomy, boundaries, QA.
- `Ponvia.dc.html` + `support.js` — the frame canvas. Both files must sit side by side.
- `tokens.json` — v1.5.0, adds the `skeleton` block (base/sheen, pulse, thresholds,
  per-screen block geometry, live-chrome list).
- `DESIGN_SYSTEM.md` — the full token spec for context (colour, type, radii, motion).
- `strings.en-da.json` — unchanged; included because the frames are Danish. **No new
  strings this round.**
- `assets/` — app icon, adaptive pair, splash logos, font licenses (font binaries are not
  bundled; download from the sources in `assets/FONTS-LICENSE.md`).
