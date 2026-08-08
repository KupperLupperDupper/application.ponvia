# Ponvia — Design Tokens (filled)

## 1. Brand
- App name wordmark: "Ponvia" set in Manrope ExtraBold (800), letter-spacing −0.03em, sentence case. Never all-caps, never letterspaced positive. Minimum clear space around the wordmark = cap height. On dark, the wordmark is `onSurface`; on the brand plate it is `#FFFFFF`.
- Logo / app-icon mark: a **weigh-point** — a filled circle resting on a short stem above a full-width baseline, i.e. one reading marked on a scale. Geometry on a 100×100 grid: baseline `x16→84, y72→82, r5`; stem `x45→55, y40→68, r5`; point `cx50 cy28 r14`. Master `assets/icon-master-1024.png` (1024×1024, 22% corner radius). Android adaptive: `assets/android-adaptive-foreground.png` (mark at 42% scale, transparent) + `assets/android-adaptive-background.png` (solid `#1F6A5C`). Splash: `assets/splash-logo-light.png`, `assets/splash-logo-dark.png` (512×512).
- Accent / seed color (light): `#1F6A5C`
- Accent / seed color (dark): `#8ED8C4`
- One-line palette rationale: A deep, desaturated sea-green seed on warm-neutral greys — clinical enough to trust with a number, soft enough to open every morning.

## 2. Color — light scheme (Material 3 roles)
| Role | Hex |
|------|-----|
| primary | #1F6A5C |
| onPrimary | #FFFFFF |
| primaryContainer | #B3EEDD |
| onPrimaryContainer | #00201A |
| secondary | #4A635C |
| surface | #F6F8F7 |
| onSurface | #171D1B |
| surfaceContainer / variant | #EAEFEC |
| surfaceContainerHighest (cards) | #FFFFFF |
| onSurfaceVariant (secondary text) | #59635F |
| outline | #D3DBD8 |
| outlineStrong (focus ring, 2dp) | #1F6A5C |
| error | #BA1A1A |
| errorContainer / onErrorContainer | #FFDAD6 / #410002 |
| positive (delta down, neutral-informative) | #1F6A5C |
| negative / delta up (neutral-informative) | #8A6238 |
| deltaUpContainer / onDeltaUpContainer | #F3E5D3 / #3E2E17 |
| neutral delta (no change) | #59635F |
| chart line | #1F6A5C |
| chart area fill | #B3EEDD @ 45% |
| chart grid / axis | #E4EAE7 |
| scrim (sheets, dialogs) | #0A1411 @ 42% |

## 3. Color — dark scheme
| Role | Hex |
|------|-----|
| primary | #8ED8C4 |
| onPrimary | #00382F |
| primaryContainer | #005046 |
| onPrimaryContainer | #B3EEDD |
| secondary | #B1CCC4 |
| surface | #0E1412 |
| onSurface | #DEE4E1 |
| surfaceContainer / variant | #1F2724 |
| surfaceContainerHighest (cards) | #161D1B |
| onSurfaceVariant (secondary text) | #A6B0AC |
| outline | #333C39 |
| outlineStrong (focus ring, 2dp) | #8ED8C4 |
| error | #FFB4AB |
| errorContainer / onErrorContainer | #93000A / #FFDAD6 |
| positive (delta down) | #8ED8C4 |
| negative / delta up | #E0BC88 |
| deltaUpContainer / onDeltaUpContainer | #4A3A22 / #F3E5D3 |
| neutral delta (no change) | #A6B0AC |
| chart line | #8ED8C4 |
| chart area fill | #005046 @ 65% |
| chart grid / axis | #2A3431 |
| scrim (sheets, dialogs) | #000000 @ 60% |

## 4. Typography
Font family: **Manrope** (SIL Open Font License 1.1) for all UI; **JetBrains Mono** (OFL 1.1) only for developer-facing annotations and export previews — not shipped in the app UI. All numeric displays use `fontFeatures: [FontFeature.tabularFigures()]`.

| Token | Size | Weight | Line height | Usage |
|-------|------|--------|-------------|-------|
| heroWeight | 72sp | 800 | 76sp (1.05), tracking −0.04em | big last-weight number on Home; drops to 64sp when the formatted value exceeds 6 glyphs (st + lb) |
| display | 36sp | 800 | 42sp, tracking −0.02em | onboarding welcome / "all set" headings |
| headline | 28sp | 800 | 34sp, tracking −0.02em | screen titles, step titles |
| title | 20sp | 700 | 26sp | card titles, sheet titles, list headers |
| titleLarge (top app bar) | 22sp | 800 | 28sp | app bar |
| body | 16sp | 400 | 24sp (1.5) | primary text |
| bodyStrong | 16sp | 600–700 | 24sp | list row primary values |
| label | 14sp | 700 | 20sp | buttons, chips, captions |
| labelSmall (section header) | 12sp | 800 | 16sp, tracking +0.06em, uppercase | grouped-list headers |

Dynamic type: layouts are tested to `textScaleFactor 1.3`. The hero number scales but is capped at 1.15× and switches to a two-line layout above that; all other text scales freely, cards grow.

## 5. Spacing scale
`4, 8, 12, 16, 20, 24, 32, 48` (dp). Screen horizontal padding 16; card inner padding 20; sheet inner padding 20; gap between stacked cards 12; section gap 20–24.

## 6. Shape / radii
| Token | Radius (dp) |
|-------|-------------|
| card | 24 (hero card 28) |
| button | 28 (full-height pill, 56dp tall) |
| sheet | 28 top corners only, 0 bottom |
| chip / field | 16 (field), 20 full-pill (chip, segmented control) |
| FAB | 18 (56dp square) / 20 (extended) |
| dialog | 28 |
| app icon | 22% of icon size |

## 7. Elevation
| Level | Use | Light | Dark (tonal) |
|---|---|---|---|
| 0 | screen background, flat rows | none, 1dp `outline` hairline on cards | none, 1dp `outline` hairline |
| 1 | resting cards, bottom nav | `0 1 3 rgba(16,32,28,.12)` | surface + 5% primary tonal overlay (#161D1B) |
| 2 | highlighted goal card, snackbar | `0 4 14 rgba(16,32,28,.16)` | surface + 8% overlay + `0 4 14 rgba(0,0,0,.45)` |
| 3 | FAB, bottom sheet, dialog | `0 8 24 rgba(16,32,28,.20)` | surface + 11% overlay + `0 8 24 rgba(0,0,0,.55)` |

Dark theme leads with tonal overlay, not shadow; shadows only carry the scrim-backed surfaces (sheet, dialog, FAB).

## 8. Motion
| Transition | Duration (ms) | Easing |
|------------|---------------|--------|
| page / route | 300 | M3 emphasized — `cubic-bezier(0.2, 0.0, 0.0, 1.0)` |
| sheet open (log weight) | 350 open / 250 close | emphasizedDecelerate `cubic-bezier(0.05, 0.7, 0.1, 1.0)` / emphasizedAccelerate `cubic-bezier(0.3, 0.0, 0.8, 0.15)` |
| value/number change (hero, delta, progress) | 250 | standard `cubic-bezier(0.2, 0.0, 0.0, 1.0)`, animated digit roll + progress tween |
| splash → app | 200 fade + 1.0→1.04 mark scale | standardDecelerate `cubic-bezier(0.0, 0.0, 0.0, 1.0)` |
| conditional block (weekday ↔ day-of-month) | 250 height + 150 cross-fade | standard |
| chip / segment selection | 120 | standard, plus M3 state-layer ripple |
| snackbar in/out | 200 / 150 | standardDecelerate / standardAccelerate |

Reduced-motion: durations → 0 for translation, cross-fades kept at 100ms.

## 9. Iconography
- Icon set/style: **Material Symbols Rounded**, optical size 24, weight 400, grade 0, FILL 0 — except the selected bottom-nav destination, which uses FILL 1. Standard size 24dp; 20dp inside chips and list-row leading; 44–48dp touch target minimum.
- weight → `scale`; add → `add`; history/chart → `show_chart`; goal/flag → `flag`; achieved → `check_circle`; settings → `settings`; bell/reminder → `notifications` (`notifications_off` for the permission state); delta → `arrow_downward` / `arrow_upward` / `remove`; date → `event`; time → `schedule`; note → `edit_note`; export → `upload`; import → `download`; destructive → `delete_forever`; privacy → `lock`; language → `language`; theme → `contrast`.

## 10. Charts (fl_chart styling)
- Line color(s), width, gradient fill under line: single series, `chart line` role, **2.5dp** on the Home sparkline and **3dp** on the full chart, `isCurved: true, curveSmoothness: 0.25`, round caps/joins. Below-line `BelowBarData` gradient from `#B3EEDD` @45% (dark: `#005046` @65%) to fully transparent at the baseline.
- Grid/axis color, label style: horizontal grid only, 1dp `chart grid`, 4 lines max; no vertical grid, no border. Axis labels `label` token at 10–12sp in `onSurfaceVariant`, left axis every other gridline, bottom axis max 5 date labels.
- Sparkline (home) vs full chart differences: sparkline has no axes, no grid, no touch handling, fixed 68dp height, and a 4.5dp filled dot on the newest point; the full chart is 170dp tall, has axes/grid, a dashed 1dp vertical indicator on touch, and pinch-free horizontal pan within the selected range.
- Point/selection marker style: 6dp radius, `surface` fill with a 3dp `chart line` stroke; tooltip is an 8dp-radius `primary` pill with `onPrimary` 12sp/700 text showing `value · date`.

## 11. Navigation model
- **Bottom navigation with four destinations — Home / History / Goals / Settings** (M3 `NavigationBar`, 88dp incl. system inset, active destination gets the pill-shaped `primaryContainer` indicator + FILL 1 icon + 700 label). Decision: logging is the only frequent write action and it is a modal bottom sheet launched from an extended FAB on Home (and a plain 56dp FAB on Goals), so it never occupies a tab. Notifications is a pushed detail route under Settings, not a destination. Four tabs keep every label legible in Danish ("Indstillinger") without truncation.
