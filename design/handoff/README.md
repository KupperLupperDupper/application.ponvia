# Handoff: Ponvia — calm, private weight tracking (Android & iOS, Material 3)

## Overview
Ponvia is a local-first weight-tracking app. The product goal is near-zero-friction logging with the **latest weight always front and centre**, given meaning by a highlighted goal and a recent trend. Calorie tracking is explicitly out of scope for this build, but Home reserves a visual slot for a second metric so it can be added later without a redesign.

This bundle covers ten screens — Splash, Onboarding, Home, Log/Edit weight, History, Goals, Settings, Notification settings, **Privacy**, plus the **bottom navigation with universal add**, the **custom undo snackbar** and the **Goal reached moment** — in light and dark, with Home and Onboarding also shown in Danish and across kg / lb / st. Privacy is shown complete in both English and Danish.

The **Goal reached** sheet has its own spec in `GOAL_REACHED.md`.

**Read `BOTTOM_NAV_SNACKBAR_PRIVACY.md` first** if you are implementing the nav, the snackbar or the Privacy page: it is newer than the per-screen notes below and overrides them. Localised copy for all three is in `strings.en-da.json`.

## About the Design Files
The files in this bundle are **design references created in HTML**. They are prototypes that show intended look, layout and behaviour — they are **not production code to copy**. The task is to **recreate these designs in the target codebase's environment** (the stated target is **Flutter with Material 3**) using its established patterns, widgets and libraries. If no app scaffold exists yet, create a standard Flutter project and implement the designs there.

Everything visual in `Ponvia.dc.html` is inline-styled HTML at a fixed 390×844 phone frame; treat those frames as specs, not as markup to port. `DESIGN_SYSTEM.md` and `tokens.json` are the source of truth for values — where the HTML and the tokens ever disagree, **the tokens win**.

## Fidelity
**High-fidelity.** Final colours, typography, spacing, radii, elevation, motion and iconography are decided and documented. Recreate the UI faithfully using Flutter's Material 3 widgets (`FilledButton`, `Card`, `SegmentedButton`, `showModalBottomSheet`, `AlertDialog`, `ListTile`) themed from `tokens.json` — do not hand-roll widgets that M3 already provides.

---

## Global structure

**Canvas:** designed at 390×844 logical px (dp). Screen horizontal padding 16dp. Safe-area insets on top of that.

**App bar:** 56dp tall, title left-aligned, `titleLarge` (22sp/800/−0.02em). No centre titles. Trailing icon button 48dp touch target, `onSurfaceVariant`.

**Bottom navigation:** custom bar with a **universal centre add** — full spec in `BOTTOM_NAV_SNACKBAR_PRIVACY.md`, values in `tokens.json → navigation`. 84dp block (64dp bar body + a 20dp hump drawn in the same path), four **unlabelled** icon tabs in a centred row (64dp cells, 96dp centre gap), selected destination = 64×32 `primaryContainer` pill with icon FILL 1. A 64dp circular `primary` add button sits in the hump with an even 10dp collar above and below; it logs a weight from **every** tab and never takes the selected pill. This supersedes the earlier `NavigationBar` + Home-only extended FAB described for screens 1–9 below; where the two disagree, this wins.

**Add-goal:** on Goals, "New goal" / "Nyt mål" is a 40dp tonal AppBar action (`primaryContainer`, `add` 18dp + label), not a FAB.

**Snackbar:** the bespoke undo snackbar replaces Material `SnackBar` app-wide — see the spec file. Bottom inset 98dp so it clears the hump.

**Scrim:** `rgba(10,20,17,0.42)` light, `rgba(0,0,0,0.60)` dark, behind sheets and dialogs.

**Minimum touch target:** 48dp everywhere. Weekday circles are 44dp visual with 48dp hit area.

---

## Screens / Views

### 1. Splash
- **Purpose:** brand moment while the local DB opens. Must feel instant — target < 400 ms visible.
- **Layout:** full-bleed `primary` (#1F6A5C) in light; `surface` (#0E1412) in dark. Mark centred, optically at ~45% of screen height; wordmark 38sp/800/−0.03em, 28dp below the mark. A single line of reassurance pinned 38dp from the bottom, 13sp/500, `primaryContainer` colour.
- **Mark:** 112×112, radius 34dp. Light: plate `#175449`, baseline+stem `#8ED8C4`, point `#B3EEDD`. Dark: plate `#8ED8C4`, baseline+stem `#14544A`, point `#0E3B33`.
- **Copy:** "Ponvia" / "All data stays on your device" (da: "Alle data bliver på din telefon").
- **Exit:** 200 ms fade with the mark scaling 1.0 → 1.04, standardDecelerate.

### 2. Onboarding (first run)
Five steps plus a welcome and a completion screen. **Every step is skippable** — "Skip" text button top-right (48dp tall), plus a text "Back" bottom-left from step 2 on.

- **Chrome per step:** back arrow (48dp) + "Skip" in a 56dp row; then a 4dp linear progress bar (`primary` on `surfaceContainer`, radius 2) and a `labelSmall` counter ("STEP 3 OF 5", optional steps append " · OPTIONAL"; da: "TRIN 3 AF 5").
- **Title block:** `headline` 28sp/800/−0.02em, then a 15sp/1.5 `onSurfaceVariant` subtitle. 28dp above, 8dp between.
- **Primary action:** filled pill, 56dp tall, 32dp horizontal padding, bottom-right, 36dp from the bottom.

**Welcome** — mark 96×96 (radius 30dp), 32dp gap, centred title 32sp/800 + 16sp/1.55 body; stacked full-width "Get started" (filled) and "I'll set this up later" (text, 48dp).
**Step 1 Language** — radio rows, 64dp tall, radius 20dp, leading `radio_button_checked`/`radio_button_unchecked` 24dp; the selected row is filled `primaryContainer` with 16sp/700 primary text and a 13sp secondary line. Options: English (United States), Dansk (Danish (Denmark)).
**Step 2 Theme** — three-column grid, 12dp gap, each cell radius 20dp with a 52×80 preview swatch (radius 12): System = a 105° split of #FFFFFF/#0E1412, Light = #FFFFFF, Dark = #0E1412. Selected cell: `primaryContainer` fill + 2dp `primary` border.
**Step 3 Weight unit** — 48dp segmented control (radius 24, 1dp `outline`, 1dp dividers). Selected segment: `primaryContainer` + `check` 18dp + 15sp/700. Below it a preview card (radius 24, `surfaceContainerHighest`, 24dp padding) showing "82.4" at 56sp/800 with a 22sp unit. Subtitle promises conversion, not rewriting.
**Step 4 First weight (optional)** — hero number 76sp/800 with a 200×2dp `primary` underline and "Today · 08:14" below; a 3×4 numeric keypad (52–56dp rows, 24sp/600, `backspace` glyph last). Actions: "Skip for now" (text) / "Save" (filled).
**Step 5 Reminder (optional)** — a 64dp switch row (radius 20, 1dp outline, leading `notifications` in `primary`), a row of 40dp frequency chips (Daily selected = `primaryContainer`/700; others 1dp outline), and a 64dp time row showing "07:30" in 16sp/700 `primary`. Actions: "Not now" / "Continue".
**All set** — 96dp `primaryContainer` circle with a 48dp `check`, title 32sp/800, then a summary card (radius 24, 20dp padding, 14dp row gap) listing Language / Theme / Unit / Reminder as label(`onSurfaceVariant`) + value(700). Full-width "Start tracking".

**Danish strings shown:** Velkommen til Ponvia · Kom i gang · Jeg opsætter det senere · Spring over · Hvilken vægtenhed bruger du? · Forhåndsvisning · Tilbage · Fortsæt · Du er klar · Begynd at registrere. Note the comma decimal separator ("82,4") and dot time separator ("07.30").

### 3. Home (hero screen)
- **Purpose:** answer "what do I weigh, and is it moving?" in under a second.
- **Layout (top to bottom):** status bar 44 → app bar 56 ("Ponvia" + `settings` icon) → 8dp → cards column, 16dp side padding, 12dp gaps.
- **Hero card:** radius 28, `surfaceContainerHighest`, 1dp `outline`, padding 24/20/16, 16dp internal gaps.
  - Eyebrow "LATEST WEIGHT" `labelSmall` (12sp/800/+0.06em) in `onSurfaceVariant`.
  - Value `heroWeight` 72–76sp/800/−0.04em, line-height 0.95, **tabular figures**, with the unit at 26sp/600 `onSurfaceVariant` on the same baseline.
  - Meta row: "Today · 08:14" 15sp/600 `onSurfaceVariant` + a delta chip — 32dp tall, radius 16, `primaryContainer`/`onPrimaryContainer` for a decrease, `deltaUpContainer`/`onDeltaUpContainer` (#F3E5D3/#3E2E17) for an increase, `surfaceContainer`/`onSurfaceVariant` for no change. Always icon + word + amount: ↓ "Down 0.6 kg" / ↑ "Up 0.2 kg" / — "No change". **Colour is never the only signal.**
  - Sparkline 68dp (see Charts) with a footer row: "Last 14 days" / signed total, both 12sp/600 `onSurfaceVariant`.
- **Goal card:** radius 24, 18/20 padding. Row 1: `flag` 20dp `primary` + "Goal · 78.0 kg" 15sp/700, right-aligned "4.4 kg to go" 15sp/700 `primary`. Row 2: 10dp progress track (radius 5, `surfaceContainer`) with a `primary` fill. Row 3: "62% of the way from 89.9 kg" 13sp `onSurfaceVariant`.
- **Second-metric slot:** 76dp, radius 24, **1.5dp dashed `outline`**, centred `add_circle` + caption. In production this is simply an empty `SizedBox`/placeholder card that a future calories card drops into — keep the height and gap so nothing reflows.
- **Empty state:** 180dp `surfaceContainer` panel with a minimal baseline-and-dots graphic, "No entries yet" 24sp/800, 16sp body, then a filled "Log your first weight" pill with a leading `add`. The reserved slot stays visible. No hero card, no goal card, no FAB (the CTA is the FAB's stand-in).
- **Loading state:** card skeleton in `surfaceContainer` blocks — **no ring, no copy** (see `SKELETON_LOADING.md`, which supersedes this line).
- **Unit variants:** kg "82.4" 76sp; lb "181.7" 72sp; **st renders as two value/unit pairs — "12 st 13.7 lb" — at 64sp/800 with 24sp units, wrapping allowed**. Goal in st reads "12 st 4 lb" while the distance stays in lb ("9.7 lb to go").
- **Danish:** SENESTE VÆGT · I dag · 08.14 · "Ned 0,6 kg" · Mål · "4,4 kg tilbage" · "62 % af vejen fra 89,9 kg" · FAB "Registrér vægt" · tabs Hjem / Historik / Mål / Indstillinger. Danish is materially longer — the goal row must allow the distance label to keep `white-space: nowrap` while the title truncates.

### 4. Log / Edit weight
- **Purpose:** the most-used flow in the app. Opened from the FAB as a **modal bottom sheet** over Home; no route change.
- **Sheet:** 660dp tall, top radius 28, `surfaceContainerHighest`, elevation 3. Drag handle 36×4 (`outline`) at 12dp. Header row 56dp: "Log weight" 20sp/800 + `close` (48dp).
- **Value:** 72sp/800 tabular with a 26sp unit, centred, over a 220×2dp `primary` underline. The keypad is always visible on open — **the field is focused and the sheet opens above the keypad; no extra tap to start typing.**
- **Date / time:** two equal 56dp fields, radius 16, `surfaceContainer`, each with a 20dp icon and a stacked label(11sp/700/+0.04em)/value(15sp/700). Defaults to now; taps open the M3 date and time pickers.
- **Note:** 56dp outlined field, radius 16, leading `edit_note`, placeholder "Add a note (optional)". Focused/filled state uses a 1dp `primary` border and `primary` icon.
- **Keypad:** 3×4 grid, 52dp rows, 26sp/600, digits + "." + `backspace`.
- **Save:** full-width filled pill 56dp, 16dp side padding, 28dp bottom.
- **Validation / error state:** value, underline and helper all switch to `error`; helper row = `error` 18dp icon + 13sp/600 "Enter a weight between 20 and 400 kg". Save becomes disabled (`surfaceContainer` fill, `onSurfaceVariant` label). Rules: numeric only, one decimal separator, max one decimal place for kg/lb (st accepts st+lb), range 20–400 kg (44–880 lb), date not in the future.
- **Edit variant:** title "Edit entry", a `delete` icon added to the header, "Save changes" label, values pre-filled. Deleting closes the sheet and shows the undo snackbar.

### 5. History
- **Purpose:** scan the trend, then the individual entries, in one scroll.
- **Range control:** 40dp segmented button, radius 20, 1dp outline and dividers; segments 1W / 1M / 3M / 1Y / All. Selected: `primaryContainer` + `check` 16dp + 700 weight (the selected segment is wider to fit the check).
- **Chart card:** radius 24, `surfaceContainerHighest`, 1dp outline, 16/12/12 padding, chart 170dp. See Charts.
- **List:** month header `labelSmall` "AUGUST 2026" with 6/8 padding, then rows: 12/8 padding, 1dp `outline` bottom divider, 16dp gaps. Row = title 16sp/700 ("Today · 08:14", "Yesterday · 07:58", "5 Aug · 07:52") over an optional 13sp `onSurfaceVariant` note; then the value 18sp/800 tabular; then a fixed 62dp-wide delta cell, right-aligned, icon 18dp + 14sp/700 amount, coloured `deltaDown`/`deltaUp`/`deltaFlat`.
- **Undo snackbar:** 56dp, radius 12, inverse surface (#E2E6E4 light-on-dark), "Entry deleted" 14sp/600 + "UNDO" 14sp/800 `primary`, sitting 104dp from the bottom (above the nav bar). 5 s timeout.
- **Empty state:** the range control renders disabled (`#A9B3AF` labels), then a 96dp `surfaceContainer` circle with `show_chart`, "Nothing to show yet" 22sp/800, a 15sp explainer, and an **outlined** "Log a weight" pill (48dp).

### 6. Goals
- **Purpose:** several targets, with the one nearest the current weight doing the emotional work.
- **Highlighted goal card:** radius 28, `primaryContainer` fill, elevation 2, 20dp padding, 14dp gaps. Chip "CLOSEST GOAL" — 28dp, radius 14, `primary`/`onPrimary`, `star` 16dp + 12sp/800. Value 44sp/800 + 18sp unit; right-aligned direction "↓ 4.4 kg to lose" 15sp/700. Progress track 10dp on `rgba(0,32,26,.16)` (dark: `rgba(0,0,0,.28)`) with a `primary` fill. Footer "Started 89.9 kg · 12 May" / "62%" 13sp/600 at 85% opacity.
- **Regular goal card:** radius 24, `surfaceContainerHighest`, 1dp outline. Value 32sp/800, direction in `onSurfaceVariant`, 8dp track with a 60%-opacity `primary` fill, optional 13sp label ("Long-term goal").
- **Achieved treatment:** direction is replaced by `check_circle` + "Achieved" in `primary`; track is full-width `primary` on `primaryContainer`; footer "Reached 12 Jul · kept for 27 days". No strikethrough — the goal is still meaningful.
- **Gain direction:** `arrow_upward` + "5.6 kg to gain" in `deltaUp`; no progress bar until there is movement.
- **Add / edit goal sheet:** 520dp, top radius 28. "TARGET WEIGHT" label in `primary`; a 64dp field with a **2dp `primary` border** on `surfaceContainer` showing 32sp/800 value + 18sp unit. Optional label field (56dp outlined, placeholder "e.g. Summer goal"). A read-only "Direction" row that derives lose/gain from the latest weight and shows it as a chip. A "Highlight on Home" switch row separated by a 1dp divider. Footer: outlined "Cancel" (flex 1) + filled "Save goal" (flex 1.4), 56dp, 12dp gap.
- **Empty state:** 96dp `surfaceContainer` circle with `flag`, "No goals yet" 22sp/800, explainer, filled "Add a goal" with leading `add`.

### 7. Settings
- **Layout:** grouped list, 8dp outer padding, **96dp bottom inset so the last row clears the nav bar**. Section headers `labelSmall` in `primary`, padding 8/16/4.
- **Rows:** 56–64dp, 16dp padding, 16dp gaps, leading 24dp `onSurfaceVariant` icon, label 16sp/600, trailing value 15sp `onSurfaceVariant` + `chevron_right` 20dp where the row pushes a route.
- **PREFERENCES:** Language (`language` → English/Dansk), Theme (`contrast` → System/Light/Dark), Weight unit (`scale`, 76dp row with an **inline 40dp segmented kg/lb/st control**, selected segment `primaryContainer`/800), Notifications (`notifications` → "Daily · 07:30").
- **DATA:** Export data (`upload`, trailing "CSV / JSON"), Import data (`download`), **Clear all data** (`delete_forever`, whole row in `error`, label 700).
- **ABOUT:** a 52dp `lock` row reading "All data stays on your device" in `onSurfaceVariant`, and an `info` row "Ponvia" with the version "1.0.0 (14)" tabular. Licenses open Flutter's `showLicensePage`.
- **Clear-data dialog:** radius 28, 24dp padding, 16dp gaps, centred `delete_forever` in `error`, title 22sp/800 "Clear all data?", body 15sp/1.55 `onSurfaceVariant` explaining it is per-device and irreversible and suggesting export first. Actions right-aligned: text "Cancel" (`primary`) then a filled destructive "Clear data" (`error` fill, `#690005` label in dark; `error`/`onError` in light), both 48dp.

### 8. Notification settings
Pushed route from Settings; app bar with a back arrow and "Reminders" (da: "Påmindelser") at 20sp/800.
- **Master row:** 72dp, radius 24, `primaryContainer`, "Weigh-in reminder" 16sp/700 over a 13sp next-fire line ("Next: Wed 12 Aug, 07:30"). M3 Switch, 52×32, thumb 24dp with a `check` glyph when on.
- **FREQUENCY:** 48dp segmented control, radius 24 — Daily / Weekly / Monthly, selected gets `check` + `primaryContainer` + 800.
- **Conditional block (animates height 250 ms + 150 ms cross-fade):**
  - *Weekly* → seven 44dp circles M T W T F S S (Danish M T O T F L S) under a `labelSmall` DAYS / DAGE header, **multi-select** (any subset of 1–7, the last lit day can't be cleared): lit = `primary`/`onPrimary`/800, unlit = 1dp outline; beneath them a 13sp Mon-first set summary ("Man · Ons · Fre"). Full spec in `STONE_ENTRY_WEEKLY_MULTI.md`, which supersedes this line.
  - *Monthly* → 7-column grid of 42dp day cells (radius 12), selected = `primary`/`onPrimary`, plus an info strip (radius 12, `surfaceContainer`, `info` 18dp + 13sp) explaining the short-month fallback.
- **TIME OF DAY:** always shown. 72–88dp card, radius 24, with two 52–60dp digit blocks (radius 14) — the focused unit is `primaryContainer`, the other `surfaceContainer` — separated by a 28–30sp colon (Danish uses a full stop).
- **Permission-needed state:** an `errorContainer` panel (radius 24, 20dp padding) with `notifications_off`, "Notifications are off" 16sp/800, a 14sp explanation that the schedule is local, and a filled `error` "Allow notifications" button. **Everything below is rendered at 38% opacity and is non-interactive** until permission is granted.
- **Save:** full-width filled pill pinned 32dp from the bottom.

---

## Interactions & Behavior
- **Nav:** bottom tabs swap the root route with no transition (M3 `NavigationBar` default). Detail routes (Notifications, goal edit) push with the 300 ms emphasized route transition.
- **Logging:** FAB → modal sheet (350 ms emphasizedDecelerate in, 250 ms emphasizedAccelerate out). Save writes locally, closes the sheet, and Home's hero number + delta chip + sparkline + goal progress animate to the new values over 250 ms (digit roll + tween).
- **Delete:** swipe or the edit sheet's delete icon removes the row optimistically and shows the undo snackbar for 5 s; undo restores in place.
- **Range switch:** 120 ms selection ripple, then the chart re-tweens its line/area over 250 ms.
- **Frequency switch:** the conditional block animates height 250 ms with a 150 ms cross-fade.
- **Validation:** live as the user types; the error state only appears after the value leaves the valid range or on a save attempt with an empty field.
- **Loading:** local DB reads are fast — **blank for 200 ms, then a pulsing skeleton held ≥ 400 ms, cross-faded 200 ms to content.** No spinner on Home, History or Goals. Full spec in `SKELETON_LOADING.md`; supersedes the 150 ms figure.
- **Reduced motion:** translation durations collapse to 0, cross-fades to 100 ms.
- **Responsive:** phone-first portrait, 390–430dp. Above 430dp, cap the content column at 430dp and centre it. Tested to `textScaleFactor` 1.3 — the hero number caps at 1.15× and goes two-line above that; all other text scales and cards grow.

## State Management
- `entries: List<WeightEntry{ id, valueKg (canonical), recordedAt, note? }>` — always stored in **kg**; display units convert at the edge, so switching units never rewrites data.
- `goals: List<Goal{ id, targetKg, label?, createdAt, startWeightKg, achievedAt? }>` — the highlighted goal is **derived**, not stored: the unachieved goal with the smallest `|targetKg − latest.valueKg|`, with a manual "Highlight on Home" override flag.
- `settings: { locale (da|en), themeMode (system|light|dark), unit (kg|lb|st) }`.
- `reminder: { enabled, frequency (daily|weekly|monthly), weekdays: Set<int>, dayOfMonth: int, timeOfDay, permissionGranted }`.
- `historyRange: enum { w1, m1, m3, y1, all }` — view state only.
- Derived: `latestEntry`, `delta = latest − previous` (direction + absolute amount), `trendSeries(range)`, `goalProgress = (start − current) / (start − target)` clamped 0–1.
- Data fetching: none — local persistence only (sqflite/drift or Isar). Export writes CSV/JSON to a user-chosen file; import validates and merges by timestamp. "Clear all data" wipes the store and resets settings to onboarding defaults.

## Design Tokens
Full, authoritative values are in **`DESIGN_SYSTEM.md`** (human-readable tables) and **`tokens.json`** (machine-readable). Summary:

- **Seed:** `#1F6A5C` light / `#8ED8C4` dark.
- **Light:** primary #1F6A5C · onPrimary #FFFFFF · primaryContainer #B3EEDD · onPrimaryContainer #00201A · secondary #4A635C · surface #F6F8F7 · onSurface #171D1B · surfaceContainer #EAEFEC · surfaceContainerHighest #FFFFFF · onSurfaceVariant #59635F · outline #D3DBD8 · error #BA1A1A · deltaDown #1F6A5C · deltaUp #8A6238 · deltaFlat #59635F.
- **Dark:** primary #8ED8C4 · onPrimary #00382F · primaryContainer #005046 · onPrimaryContainer #B3EEDD · secondary #B1CCC4 · surface #0E1412 · onSurface #DEE4E1 · surfaceContainer #1F2724 · surfaceContainerHighest #161D1B · onSurfaceVariant #A6B0AC · outline #333C39 · error #FFB4AB · deltaDown #8ED8C4 · deltaUp #E0BC88 · deltaFlat #A6B0AC.
- **Type — Manrope (OFL 1.1), tabular figures on all numbers:** heroWeight 72/800/76/−0.04em · display 36/800/42 · headline 28/800/34 · titleLarge 22/800/28 · title 20/700/26 · body 16/400/24 · bodyStrong 16/700/24 · label 14/700/20 · labelSmall 12/800/16/+0.06em/uppercase.
- **Spacing:** 4, 8, 12, 16, 20, 24, 32, 48.
- **Radii:** chip 20 · field 16 · card 24 (hero 28) · button 28 · sheet 28 (top only) · dialog 28 · FAB 18 / extended 20.
- **Elevation:** 0 hairline · 1 `0 1 3 rgba(16,32,28,.12)` · 2 `0 4 14 rgba(16,32,28,.16)` · 3 `0 8 24 rgba(16,32,28,.20)`. Dark leads with tonal overlay (5/8/11%), shadows only under the scrim.
- **Motion:** route 300 emphasized · sheet 350/250 · value change 250 standard · splash 200 · conditional block 250 · selection 120 · snackbar 200/150.

**Charts (fl_chart):** single series, curved (`curveSmoothness 0.25`), round caps. Sparkline: 68dp, 2.5dp stroke, no axes/grid/touch, 4.5dp end dot, below-bar gradient from `#B3EEDD` @45% (dark `#005046` @65%) to transparent. Full chart: 170dp, 3dp stroke, horizontal grid only (max 4 lines, 1dp `chartGrid`), left labels every other line and max 5 bottom date labels at 10–12sp `onSurfaceVariant`, dashed 1dp vertical indicator on touch, 6dp marker (`surface` fill, 3dp `chartLine` stroke), tooltip = 8dp-radius `primary` pill with 12sp/700 `onPrimary` "value · date".

## Accessibility
- AA contrast verified in both themes for text, icons and the delta chips.
- **Colour is never the sole signal:** every delta pairs a hue with an arrow icon and a word; the highlighted goal pairs its fill with a "CLOSEST GOAL" chip and elevation; every selected segment/chip carries a `check`.
- Focus/selection: 2dp `primary` (light) / `primary` (dark) ring on focusable controls; M3 state layers on press.
- Minimum 48dp targets; the numeric keypad keys are 52dp.
- Semantics: the hero card is one live region announcing "Latest weight, 82.4 kilograms, today at 08:14, down 0.6 kilograms since 5 August". Charts get a text summary alternative ("14-day trend, down 1.8 kg").
- Tested to `textScaleFactor` 1.3; Danish is the long-string reference locale.

## Assets
All in `assets/`:
- `icon-master-1024.png` — 1024×1024 app-icon master, 22% corner radius, `#1F6A5C` plate.
- `android-adaptive-foreground.png` / `android-adaptive-background.png` — 1024×1024 adaptive pair (mark at 42% scale on transparent; solid `#1F6A5C`).
- `splash-logo-light.png` / `splash-logo-dark.png` — 512×512.
- `FONTS-LICENSE.md` — Manrope (SIL OFL 1.1) and Material Symbols Rounded (Apache 2.0) sources, plus the `pubspec.yaml` font declaration. **Font binaries are not bundled** — download from the linked canonical sources.
- The logo mark is pure geometry (baseline bar, stem, circle) on a 100×100 grid — exact coordinates are in `DESIGN_SYSTEM.md` §1, so it can be redrawn as vector at any size.
- Icons are Material Symbols Rounded; no custom icon assets exist.

## Files
- `Ponvia.dc.html` — **the design reference.** All 30+ frames on one canvas, grouped by screen, each captioned with its intended export name (`home.dark.kg.png`, `log-error.light.png`, …). Open it in a browser and pan/zoom.
- `DESIGN_SYSTEM.md` — filled token spec (brand, both colour schemes, type, spacing, shape, elevation, motion, iconography, charts, navigation decision).
- `tokens.json` — the same values, machine-readable, for generating a Flutter `ThemeData`.
- `GOAL_REACHED.md` — the goal-reached sheet: trigger rules, geometry, copy, motion.
- `HEIGHT_BMI_APPLOCK.md` — the two opt-in features: height entry + BMI slot, and biometric/PIN app lock.
- `STONE_ENTRY_WEEKLY_MULTI.md` — split st + lb weight entry, and multi-weekday weekly reminders: decisions, key routing, strings, implementation scope.
- `SKELETON_LOADING.md` — skeleton loading for Home, History and Goals: timing thresholds, pulse motion, per-screen anatomy.
- `rationale.md` — one paragraph on palette and mood.
- `assets/` — icon, adaptive pair, splash logos, font licenses.

## Open decisions worth confirming with the designer
1. **Navigation model is settled as four bottom tabs** with logging as a FAB-launched sheet (rationale in `DESIGN_SYSTEM.md` §11) — do not promote logging to a tab.
2. **Settled in `STONE_ENTRY_WEEKLY_MULTI.md`:** stone input is two coupled fields (st + lb, whole pounds). Decimal stone is no longer accepted anywhere.
3. The second-metric slot on Home is intentionally empty in this build. Keep its height and gap reserved.

---

### 10. Privacy — Settings › About › Privacy
- **Purpose:** state plainly that Ponvia is fully local. No account, no cloud, no tracking, no network; data leaves only via a user-started export.
- **Layout:** back arrow + title, then a 96dp primaryContainer lock tile, a centred lead line (17sp/600), five guarantee rows in one 24dp-radius card with 1dp dividers, and a footer line naming the export path. No buttons, no forms, no outbound links.
- **Copy:** strings.en-da.json → privacy. Danish runs ~15% longer; rows are height-free so they reflow.
- **Frames:** privacy.light.en, privacy.dark.en, privacy.light.da, privacy.dark.da.

### 11. Bottom nav + undo snackbar
See BOTTOM_NAV_SNACKBAR_PRIVACY.md. Frames: nav.* and snackbar.* in Ponvia.dc.html sections 13 and 11. The sections badged 2–6 in that file are **superseded exploration** kept for provenance — build from the one badged 7 · Settled.


### 12. Goal reached — modal sheet
See `GOAL_REACHED.md`. Frames: `goalreached.*` in `Ponvia.dc.html` sections 14 and 15.
- **Purpose:** close the loop that today requires manually tapping "Mark achieved" in the goal editor. Fires after a log whose weight crosses an active goal's target, lose or gain.
- **Tone is a hard constraint:** the app gently notices; it does not congratulate. No confetti, streaks, badges, sound, celebratory haptics, bounce or emoji. Only the 64dp `check_circle` emblem moves, once, for 250ms.
- **Layout:** content-hug sheet, 28 top radius, `surfaceContainerHighest`, elevation 3 — the same family as the log sheet. Emblem → title → one body line → full-width filled "Mark achieved" → text "Keep it open".
- **After confirm:** sheet out (250ms), then the existing undo snackbar at the 98dp inset — "Goal marked as reached · Undo". No second confirmation, no route change.
- **Copy:** `strings.en-da.json → goalReached`; the weight is interpolated in the display unit with locale decimals.


### 13. Height → BMI (opt-in)
See `HEIGHT_BMI_APPLOCK.md`. Frames: sections 16–17.
- One optional **Højde** row in Preferences, entered on the existing NumericKeypad. Stored in cm; **imperial users enter ft/in** (they don't know their cm) with a quiet "Stored as 178 cm" line.
- Setting a height adds a BMI tile to Home: value, one decimal, tabular, plus one neutral band word. **With no height there is no tile and no placeholder** — Home never advertises BMI; the 7-day average takes the full width.
- Tone is a hard rule: no colour coding, no gauge, no advice, no "overweight"/"obese". Nothing else in the app is gated on height.

### 14. App lock (opt-in)
See `HEIGHT_BMI_APPLOCK.md`. Frames: sections 18–19.
- New **Sikkerhed** group in Settings (not Preferences — a launch lock isn't a cosmetic choice), placed between Preferences and Data, with the on-device promise as supporting text.
- **Two switches, no timer:** App-lås (parent, sets a 4-digit Ponvia PIN in a two-step flow) and Fingeraftryk (nested, requires one successful fingerprint to enable). Valid states: nothing / PIN only / PIN + fingerprint.
- **Launch is the PIN view**, always — 72dp lock disc, wordmark, 4 dots, keypad, no submit button. With fingerprint on, the OS prompt fires automatically over it. A correct PIN or accepted fingerprint goes straight to Home.
- States: idle, fingerprint-waiting, wrong PIN (dots shake + clear), accepted (lock→lock_open, fade-through). Micro-animations specced per element; reduced motion is fades only.
- PIN stored only as a salted hash on device; no account, no recovery, no Ponvia-side lockout timer; `FLAG_SECURE` while enabled.

### 16. Stone entry + multi-weekday reminders
See `STONE_ENTRY_WEEKLY_MULTI.md`. Frames: sections 24–29.
- In `st`, every keypad-driven weight entry splits into **two coupled fields** (st + lb) in the height sheet's ft/in pattern: 48sp values in 150dp columns, 2dp `primary` underline on the focused one, auto-advance st→lb, backspace at the start of lb returns to st. **Whole pounds only** (0–13); the decimal key renders at 38% opacity. lb clamps, never rolls over. Blank lb = 0 lb. Storage stays kg.
- Weekly reminders become **multi-select**: any 1–7 days lit, the last one can't be cleared, all seven stays weekly (never auto-switches to Daily), and the helper is a Mon-first middot set summary. Two new strings; `notifDaySelected` is deleted.

### 15. Skeleton loading
See `SKELETON_LOADING.md`. Frames: sections 20–23.
- The spinner is removed from Home, History and Goals. **200 ms blank → skeleton → ≥ 400 ms floor → 200 ms cross-fade.** One app-wide show delay; on a healthy device the skeleton is unreachable, and any sighting in normal use is a performance bug.
- **Pulse, not sweep:** all blocks share one clock, opacity 1 → 0.55 → 1 over 1600 ms. Reduced motion drops the pulse and cuts instead of fading; the 400 ms floor still applies.
- Only the always-present spine is drawn — Home's conditional BMI slot gets **no placeholder**. Chrome that isn't data-bound (app bar, nav, add button, History's range control) stays live and tappable.
- Zero strings; one `Semantics(label: 'Indlæser')` live region on the scroll body. Sheets, Settings, Onboarding and the lock screen are out of scope.
