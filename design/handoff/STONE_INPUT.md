# Ponvia — Stone (st + lb) split weight entry (design brief)

**Round 11 — BRIEF, pre-mockup.** Prompt for the Claude-design step. Produce the frames
listed at the end; the delivered handoff (frames in `Ponvia.dc.html`, any tokens/strings)
then feeds implementation.

## The problem
Weight is stored canonically in **kg**; the display unit can be kg, lb or **st**. A stone
user thinks in **stone *and* pounds** — "12 st 7 lb", never "12.5 st". But every weight the
user *types* goes through the single custom `NumericKeypad` as one decimal value, so a
stone user today has to enter decimal stone (`12.5`), doing the /14 in their head. That is
exactly the friction that makes the stone unit feel half-supported.

Give stone users a **split st + lb entry**: two coupled fields driven by the same keypad.

## This is a solved pattern — reuse it
The optional-height feature already built this exact interaction for **ft + in**
(`lib/features/settings/height_sheet.dart`): two value fields, a focus toggle, the shared
`NumericKeypad` typing into the focused field, auto-advance from the first field to the
second, backspace at the start of the second field returning to the first, and the keypad's
decimal key ignored. **st + lb should feel identical.** The design's job is to place that
same interaction into the weight-entry surfaces and settle the stone-specific numbers
below — not to invent a new control.

## Where it applies
Every keypad-driven weight entry, **only when the display unit is `st`** (kg and lb keep
their current single field, unchanged):
- **Log / edit weight sheet** (`log_weight_screen.dart`, `LogWeightForm`).
- **Add / edit goal sheet** (`goals_screen.dart`, `_GoalForm` — the target weight).
- **Onboarding** optional first weight (same `NumericKeypad`).

## Data layer — already exists, no persistence change
`WeightConverter.kgToStoneParts(kg) → StoneParts(stone, pounds)` and
`stonePartsToKg(stone, pounds)` are in `lib/core/units/weight_unit.dart`. Storage stays
**kg**. Read-back when editing: `kg → kgToStoneParts` prefills both fields (focus the lb
field, mirroring height's ft/in read-back).

## Decisions the mockup step must settle
1. **Pounds precision.** Whole pounds (`0–13`) or one decimal (`0.0–13.x`)? Home scales
   often read half-pounds, but stone entry is usually whole lb. Recommend **whole lb**
   (keypad decimal ignored, exactly like ft/in) for a fast two-tap-per-field flow; if one
   decimal is chosen, the decimal key is live **only in the lb field**. Pick one and state it.
2. **lb range + rollover.** lb is `0 ≤ lb < 14` (14 lb = 1 st). Clamp entry so a third
   digit or a value ≥ 14 is rejected (height clamps inches at ≤ 11 the same way). Decide
   whether typing `13 → +1` rolls over into stone or simply stops; recommend **stop/clamp**,
   no rollover — matches height and avoids surprise.
3. **Stone field width.** Stone can reach ~63 st (the 400 kg cap), so the st field takes up
   to 2 digits; lb up to 2. Confirm the two fields + unit suffixes fit the sheet width at
   the hero type size (height uses 48sp values with a 120dp underline each — validate the
   two fit side by side with the `st` / `lb` suffixes).
4. **Validation.** Combined `stonePartsToKg` must land in the existing **20–400 kg**
   range; Save disabled until valid (same rule as kg/lb today). What does an empty lb mean
   — treat blank as `0 lb`? Recommend yes.
5. **Empty / initial state.** New entry shows `0 st 0 lb` with the **st** field focused
   (primary underline), advancing to lb after the first stone digit — or should lb be
   optional/skippable? Recommend auto-advance st→lb on the first digit, exactly like ft→in.
6. **Display side (confirm, likely already done).** History rows, the Home hero and goal
   text render stone as `st + lb` via the `WeightFormatter`. Confirm the entry sheet's live
   value matches that display formatting so what you type reads back the same.

## Boundaries
- No change to kg/lb entry, to storage (still kg), or to any conversion factor.
- Not a new keypad — the same `NumericKeypad`, re-hosted. Only the field layout + the
  onKey/onBackspace routing differ by unit.
- No st-only strings beyond the `st` / `lb` suffixes (already unit codes).

## Frames to produce
`stone.entry.log-empty.light.da` (0 st 0 lb, st focused),
`stone.entry.log-typing.dark.en` (e.g. 12 st, lb focused),
`stone.entry.goal.light.da` (the goal sheet variant),
`stone.entry.readback.dark.en` (editing an existing weight, both fields prefilled),
plus a note frame `stone.entry.spec` showing the two-field metrics, focus underline, and
the auto-advance / backspace-returns behaviour.

## Open questions
1. Whole lb vs one-decimal lb (question 1) — the single biggest interaction call.
2. When editing a kg/lb entry then switching the app to stone, the same sheet must reflow
   to two fields live — is that in scope for this round, or only fresh opens under `st`?
