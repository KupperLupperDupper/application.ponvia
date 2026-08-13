# Skeleton loading — Home, History, Goals

Round 10. Frames live in `Ponvia.dc.html` §20–23 (ids `10a`–`10d`). Tokens in
`tokens.json → skeleton`. No new strings.

The centred `CircularProgressIndicator` is removed from Home, History and Goals. What
replaces it is a **timing rule with a skeleton attached** — on a healthy device the
skeleton is unreachable, and that is the intended outcome.

---

## 1. Lifecycle — the numbers

| Constant | Value | Scope |
|---|---|---|
| `showDelayMs` | **200** | app-wide, one constant |
| `minVisibleMs` | **400** | per skeleton instance |
| `fadeMs` | **200** | reuses `motion.splashToApp` easing |

**Sequence.** Stream subscribed → body renders **empty** (background only, live chrome
present). If the stream has not emitted by 200ms, build the skeleton. Once built, hold it
at least 400ms from its own first frame. When data has arrived *and* the floor has
elapsed, cross-fade 200ms to content.

**Why 200, not 150.** A local Drift read is a 10–40ms operation. Anything past 200ms means
the device is contending for I/O — not that the query is large. 150ms fires during ordinary
cold-start jank and shows a skeleton for a read that had already completed by the time the
first frame painted. The threshold is a statement about the storage layer, so it is a
single app-wide constant rather than three per-screen ones; a per-screen number would
imply Home is inherently slower than Goals, which is not true.

**Why a 400ms floor.** One full pulse cycle (1600ms) minus the fade would be a long hold;
400ms is the shortest window in which the pulse reads as a breath rather than a flash, and
it guarantees the skeleton can never blink out mid-descent.

**Happy path.** Blank for ~24ms, then content. No skeleton widget is ever constructed.
The show-delay must be implemented as *don't build*, not *build and hide* — an opacity-0
skeleton still costs a layout pass on every fast read.

---

## 2. Motion — pulse, not sweep

`pulse`: opacity **1 → 0.55 → 1**, **1600ms**, `cubic-bezier(0.4,0,0.6,1)`, all blocks on
**one shared clock** so the screen breathes as a single surface.

A sweep has direction, speed and a leading edge — three properties the eye tracks. That is
right for an app that wants to look like it is working hard; it is wrong for one whose
posture is "your data is already here." A sweep is also hard to keep quiet: a gradient
faint enough for Ponvia's contrast step is invisible in motion, so in practice it gets
dialled brighter until it isn't quiet any more. The pulse has one property and dialling it
down never breaks it.

`base` at 0.55 over `surface` lands on the `sheen` value (~3% lightness step). Implementations
that prefer a colour lerp can animate `base → sheen` instead; the token carries both.

**Reduced motion** (`MediaQuery.disableAnimations`): no pulse, no scale — blocks hold `base`
at full opacity; the cross-fade becomes an instant cut. Timings are unchanged, including
the 400ms floor, so the cut is not a blink.

---

## 3. Chrome stays live

Never skeletonised: status bar, app bar title and actions, bottom nav, the centre add
button, and **History's range segmented control**.

None of these are data-bound. Drawing the range control as a grey pill would hide
information the app already has (the range the pending query was built from), and
disabling it would strand a user who opened the wrong range. The user can log a weight
while Home is still resolving — the sheet opening over a skeleton is correct behaviour,
not a bug.

---

## 4. Per-screen anatomy

Screen padding, card radii, gaps and dividers are the **real** ones, so nothing changes
position when content lands.

### Home — `skeleton.home.{light,dark}.da`
- **Hero card** (radius 24, `surface`, 1dp `outline`, padding 20, gap 14): eyebrow 80×12 r6
  · hero value 180×44 r10 (the glyph's ink box, not its line box) · delta pill 64×24 r12 ·
  sparkline band fill×40 r10.
- **Goal card** (radius 24): label 110×12 r6 · progress track fill×6 r3.
- **Second-metric slot — omitted.** The brief proposed a dashed placeholder; resolved
  against. The slot only exists when a height is set, and the loader cannot know yet
  whether it will, so a placeholder would be a promise the resolved screen breaks half the
  time. BMI fades in afterwards on its own 250ms, exactly as on a warm screen.
- The sparkline band is 40dp, not the real 68dp: a full-height mass is the loudest thing on
  the screen.

### History — `skeleton.history.{light,dark}.da`
- **Range control** — live and enabled.
- **Summary card** (radius 24): 3 stat pairs, label 52×10 r5 over value 68×20 r8.
- **Chart card** (radius 16, height 170): a low, calm **area silhouette** in `base` plus a
  2dp baseline. No stroke, no grid, no axis labels, no end marker — a stroke over a fill
  starts to look like data. A flat 170dp slab reads as a broken image; this is the one
  block that must not be a rectangle.
- **Rows** — exactly **4**, on the real 64dp pitch with 1dp dividers inset 20dp. Bar widths
  vary per row (weight 88/76/92/80, date 64/58/66/60): identical widths look like a printed
  pattern, varied ones look like text. A fifth row would be a claim about how much data
  exists.

### Goals — `skeleton.goals.{light,dark}.da`
- **3 cards** on the real `cardGap` 12. First card radius **28** (the resolved list always
  highlights the closest goal in that shape — matching it means the corner does not tighten
  under the user's eye).
- Each: target value 140/124/132 × 32 r10 · label 96/112/88 × 12 r6 · progress track fill×6 r3.
- Fewer than 3 real goals: extra cards **fade out**, never collapse-and-grow. An over-count
  settling down is invisible; an under-count growing is a jump.

---

## 5. Boundaries

- **Empty state is not a skeleton.** A user with no data sees the skeleton for at most
  400ms and then the real empty state. The skeleton says "layout"; the empty state says
  "nothing here". Never blended.
- **No copy.** Zero strings — no "Indlæser…", no retry. Accessibility is one
  `Semantics(label: 'Indlæser')` live region / `aria-busy` on the scroll body; decorative
  blocks are excluded from the semantics tree so a reader hears one announcement, not eleven.
- **Out of scope:** modal sheets, Settings, Onboarding, the lock screen. Those keep their
  current behaviour this round.
- **Not a wireframe.** Only the always-present spine. No logo, no wordmark, no branded
  moment.

---

## 6. QA

Verify behind a debug delay — on a healthy device the skeleton should be unreachable, and
any sighting in normal use is a performance bug report, not a design success.

Two failures to watch for:
1. A skeleton visible for **under 400ms** (floor not applied, or applied from the request
   rather than from the skeleton's first frame).
2. A skeleton block at a **different position** than the content that replaces it — the
   transition must be a settling, never a re-layout.
