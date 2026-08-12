# Ponvia — Goal reached moment
Handoff for round 8. Source of truth: `Ponvia.dc.html` sections **14 · Goal reached — sheet** and **15 · After confirm**, plus `tokens.json → goalReached` and `strings.en-da.json → goalReached`.

Design width 390dp. All values dp unless stated. Shown light/EN, dark/DA, and as a gain-goal variant.

---

## Trigger
After a weight entry is saved (new log **or** an edit), evaluate every active (`achievedAt == null`) goal against the new latest weight:

- **Lose goal** (`target < startWeight`): fires when `latest <= target`.
- **Gain goal** (`target > startWeight`): fires when `latest >= target`.

Rules:
- Fires **once per goal.** Record the attempt on the goal (`reachedPromptShownAt`) whichever way the user answers; a later crossing of the same target does not re-open it.
- If several goals cross on the same save, show the sheet for the **nearest** target only and mark the others silently reachable — do not queue sheets.
- Presented **after** the log sheet has finished closing (250ms out), not stacked on it.
- Undoing the weight entry reverts the achievement and clears `reachedPromptShownAt`.
- Never fires during import, restore-from-undo, or "Clear all data".

## Surface
Modal bottom sheet over the current screen — same family as *Log weight*, so `showModalBottomSheet` with the app's shared sheet shape.

| Part | Value |
|---|---|
| Height | content-hug (~compact), no fixed height |
| Top radius | 28 (top corners only) |
| Container | `surfaceContainerHighest`, elevation level 3 |
| Drag handle | 36×4, radius 2, `outline` @40%, 12 from top |
| Scrim | `rgba(10,20,17,.42)` light / `rgba(0,0,0,.60)` dark |
| Horizontal padding | 24 |
| Bottom padding | 28 + gesture inset |
| Dismissible | yes — swipe-down and scrim tap behave as **Keep it open** |

## Layout (centred column, top → bottom)
| Element | Spec |
|---|---|
| Emblem disc | 64 circle, `primaryContainer` fill, 28 below the handle |
| Emblem icon | `check_circle` (Rounded, FILL 0), 36, `primary` |
| Title | 23sp / 800 / −0.02em, `onSurface`, 24 below the emblem |
| Body | 15sp / 400, `onSurfaceVariant`, tabular figures, 8 below the title, **one line** |
| Primary button | FilledButton, full-width, height 56, radius 28, 28 below the body |
| Text button | height 48, 15sp/700, `primary`, 8 below the button |

## Copy
`strings.en-da.json → goalReached`. The weight is interpolated at `{weight}` and formatted in the user's display unit with locale decimals — Danish uses a comma ("75,0 kg"), stone renders "12 st 4 lb".

| Key | EN | DA |
|---|---|---|
| title | You reached it | Du nåede det |
| body | You've hit your {weight} goal. | Du har nået dit mål på {weight}. |
| confirm | Mark achieved | Markér som opnået |
| dismiss | Keep it open | Behold det åbne |
| confirmedSnackbar | Goal marked as reached | Målet er markeret som nået |

**Direction-agnostic:** lose and gain goals share one layout and one string set; only the number changes. Do not add "lost"/"gained" wording.

## Actions
- **Mark achieved** — sets `achievedAt = now`, closes the sheet, shows the undo snackbar (`confirmedSnackbar` + Undo, 4s). The goal switches to the existing achieved treatment on Goals: `check_circle` + "Achieved" in `primary`, full track, no strikethrough.
- **Keep it open** — closes with no state change; the goal stays active and keeps counting. Does not re-arm the trigger for that goal.

## Motion
| What | Spec |
|---|---|
| Sheet in | 350ms emphasizedDecelerate |
| Sheet out | 250ms emphasizedAccelerate |
| Emblem | fade 0→1 + scale 0.92→1.0, 250ms standardDecelerate, starting with the sheet; then **completely still** |
| Everything else | no animation — no confetti, bounce, pulse, sound or haptics |
| Reduced motion | emblem fades only (100ms), sheet translation collapses to 0 |

## Accessibility
- Sheet is announced as a dialog: title + body read together ("You reached it. You've hit your 75.0 kilogram goal.").
- Emblem is decorative (`excludeSemantics`) — the title carries the meaning.
- Both actions ≥48 tap height; focus lands on **Mark achieved**.
- Tone constraint is a product rule, not a style preference: this is an acknowledgement, not a reward.

## Frames
`goalreached.light.en`, `goalreached.dark.da`, `goalreached.light.gain`, `goalreached.confirmed.light.en`.
