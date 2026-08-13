# Ponvia — Skeleton loading (design brief)

**Round 10 — BRIEF, pre-mockup.** This is the prompt for the Claude-design step, not a
resolved spec. Produce the frames listed at the end; the delivered handoff (frames in
`Ponvia.dc.html`, tokens under `tokens.json → skeleton`, any copy in
`strings.en-da.json`) then feeds implementation.

## The problem
Home, History and Goals each read a Drift stream and, while it resolves, show a centred
`CircularProgressIndicator`. Two things are wrong with that:

1. **A spinner says "working" — a skeleton says "your layout is about to appear here."**
   For a screen that always resolves to the same shape, the skeleton is the calmer,
   more oriented wait.
2. **This is a local-first app.** The DB reads resolve in *milliseconds*, so today's
   spinner barely flashes — and a naive skeleton would flash even more jarringly
   (appear + vanish in ~50ms reads as a flicker/blink). **Any skeleton design here is
   inseparable from its timing** (see below). A skeleton that isn't timing-guarded is a
   regression, not an improvement.

## Non-negotiable tone
Ponvia is quiet. The skeleton must be the *quietest possible* loading affordance:
- Low contrast. The placeholder fill is `surfaceContainer` sitting on `surface` — a
  barely-there step, not grey-on-white. Dark mode uses the dark `surfaceContainer`
  (`#1F2724`) on `surface` (`#0E1412`) — equally faint.
- No spinner anywhere on these three screens once this ships.
- The animation (if any) is a **slow, low-amplitude** shimmer or pulse — a breath, not a
  strobe. It must never draw the eye harder than real content would.
- Placeholder blocks mirror the **real** layout's silhouette and radii so the transition
  to content is a settling, not a swap.

## Timing (this is a design decision, spec it in the handoff)
The skeleton is governed by two thresholds; pick and justify the values:
- **Show delay** — don't render the skeleton until the load has already taken longer than
  a threshold (proposed **~150ms**). Below that, show nothing (a blank body for one or two
  frames) so a fast local read never flashes a skeleton at all.
- **Minimum on-screen** — once shown, hold it for at least a floor (proposed **~400ms**)
  so it can't blink out mid-fade.
- **Fade to content** — proposed 200ms cross-fade (reuse `motion.durationIn` = 200).
- **Reduced motion** (`MediaQuery.disableAnimations`) — no shimmer sweep and no scale;
  the skeleton is a static, faint block, cross-fade becomes an instant cut.

State clearly in the handoff whether the show-delay is per-screen or app-wide, and the
exact numbers.

## Per-screen anatomy
Mirror each screen's real success-state silhouette. Screen padding matches the live
screens (`Insets.screenH` horizontal). Every block: radius per its real sibling, fill
`surfaceContainer`, optional 1dp `outline` only where the real card has one.

### Home (`_HeroCard` + optional `_GoalCard` + second-metric slot)
- **Hero card** — the tall rounded card (radius 24). Inside, faint bars standing in for:
  eyebrow (short, ~80w × 12h), the big hero value (wide, ~180w × 44h), the delta pill
  (~64w × 24h pill), and a low sparkline band (full width × ~40h). This is the anchor of
  the screen — the one block that must feel deliberate.
- **Goal card** — a shorter rounded card (radius 24) with a label bar + a thin progress
  track bar.
- **Second-metric slot** — one dashed/quiet block matching the existing reserved slot.
- Do **not** skeletonize things that are conditional on data (BMI tile only exists when a
  height is set). The skeleton shows the *always-present* spine: hero + one secondary card.

### History (range control + summary + chart + rows)
- **Range segmented control** — a single pill-row skeleton (or keep the real control
  visible but inert; the design picks — note that the real `SegmentedButton` could show
  live since it's not data-bound, which may feel more grounded).
- **Summary card** — rounded card with 3–4 short stat bars in a row.
- **Chart card** — the largest block: a rounded card (radius 16) with a faint baseline and
  a low, calm line/area silhouette. No axis numbers.
- **List rows** — ~4 skeleton rows: each a small leading dot + a weight bar + a faint date
  bar, matching the real history row rhythm. Don't over-fill; 4 rows implies "more below".

### Goals (`_GoalCard` list)
- ~3 goal-card skeletons (radius 24; the first may take the highlighted radius 28 to hint
  the closest-goal treatment). Each: a target-value bar, a label bar, and a thin progress
  track. Stack with the real `Insets.cardGap`.

## Tokens to add (`tokens.json → skeleton`)
Propose values for:
- `base` — the placeholder fill (light + dark), i.e. `surfaceContainer` unless you refine.
- `sheen` — the shimmer highlight, a hair lighter than `base` (light + dark). Keep the
  delta small.
- `shimmer.duration`, `shimmer.easing`, and the sweep direction/angle — or, if you choose
  a pulse instead of a sweep, `pulse.duration` and the opacity range.
- `showDelayMs`, `minVisibleMs`, `fadeMs`.

## What this must not become
- Not a full-page grey wireframe of every possible widget. Only the always-present spine.
- Not a branded animation moment. No logo, no "Ponvia" wordmark, no mascot.
- Not applied to modal sheets, Settings, Onboarding, or the lock screen — those are out of
  scope for this round.
- Not a reason to slow anything down: the show-delay means the *happy path stays instant*.

## Frames to produce
`skeleton.home.light.da`, `skeleton.home.dark.da`,
`skeleton.history.light.da`, `skeleton.history.dark.da`,
`skeleton.goals.light.da`, `skeleton.goals.dark.da`,
plus one motion note frame `skeleton.shimmer-spec` showing the sweep/pulse timing and the
reduced-motion static fallback.

## Open questions for the design step
1. Shimmer **sweep** (a light band travelling across) or **pulse** (whole block breathing
   opacity)? Recommend one; sweep tends to read busier, pulse calmer — lean calm.
2. On History, real live `SegmentedButton` vs a skeleton pill-row — which grounds better?
3. Are the proposed 150 / 400 / 200ms timings right for this device class, or should the
   show-delay be higher so the skeleton is genuinely rare?
