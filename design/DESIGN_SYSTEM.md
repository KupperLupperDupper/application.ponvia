# Ponvia — Design-Token Contract (TEMPLATE)

This is the **interface between design and code** — the *template* that defines which
tokens must exist. The Claude design step produces a **filled copy** and you drop it at
[`handoff/DESIGN_SYSTEM.md`](handoff/DESIGN_SYSTEM.md); that filled file is what the Flutter
theme (`lib/app/theme/`) is built from at M5. Keep this template as the checklist —
anything not captured here won't make it into the app. `HANDOFF.md` explains the mapping.

> Status: **DELIVERED (2026-08-08).** The filled, authoritative tokens are in
> [`handoff/DESIGN_SYSTEM.md`](handoff/DESIGN_SYSTEM.md) (+ `handoff/tokens.json` and the
> per-screen `handoff/DESIGN_SPEC.md`). This file stays as the blank contract/checklist.
> Seed `#1F6A5C`/`#8ED8C4`, Manrope type, bottom-tab nav, `st + lb` stone, neutral delta
> colors. Build the theme from the handoff copy.

## 1. Brand
- App name wordmark: `‹image/spec›`
- Logo / app-icon mark: `‹image/spec›` (needs 1024×1024 master for icon generation)
- Accent / seed color (light): `‹#RRGGBB›`
- Accent / seed color (dark): `‹#RRGGBB›`
- One-line palette rationale: `‹…›`

## 2. Color — light scheme (Material 3 ColorScheme roles)
| Role | Hex |
|------|-----|
| primary | `‹#…›` |
| onPrimary | `‹#…›` |
| primaryContainer | `‹#…›` |
| onPrimaryContainer | `‹#…›` |
| secondary | `‹#…›` |
| surface | `‹#…›` |
| onSurface | `‹#…›` |
| surfaceContainer / variant | `‹#…›` |
| outline | `‹#…›` |
| error | `‹#…›` |
| **positive** (delta down/goal-good, semantic) | `‹#…›` |
| **negative / neutral delta** | `‹#…›` |

## 3. Color — dark scheme
| Role | Hex |
|------|-----|
| primary | `‹#…›` |
| onPrimary | `‹#…›` |
| primaryContainer | `‹#…›` |
| onPrimaryContainer | `‹#…›` |
| secondary | `‹#…›` |
| surface | `‹#…›` |
| onSurface | `‹#…›` |
| surfaceContainer / variant | `‹#…›` |
| outline | `‹#…›` |
| error | `‹#…›` |
| positive | `‹#…›` |
| negative / neutral | `‹#…›` |

> Note on delta semantics: losing/gaining weight is **not** inherently good/bad. Use
> `positive`/`negative` as neutral-informative direction colors, always paired with an
> icon + text (accessibility). Confirm intent with the design.

## 4. Typography
Font family: `‹family›` (freely licensed; bundle or use Google Fonts).

| Token | Size | Weight | Line height | Usage |
|-------|------|--------|-------------|-------|
| heroWeight | `‹pt›` | `‹w›` | `‹›` | the big last-weight number on Home |
| display | `‹›` | `‹›` | `‹›` | |
| headline | `‹›` | `‹›` | `‹›` | screen titles |
| title | `‹›` | `‹›` | `‹›` | card titles, list headers |
| body | `‹›` | `‹›` | `‹›` | primary text |
| label | `‹›` | `‹›` | `‹›` | buttons, chips, captions |

## 5. Spacing scale
`‹e.g. 2, 4, 8, 12, 16, 20, 24, 32, 40›` — list the exact steps used.

## 6. Shape / radii
| Token | Radius |
|-------|--------|
| card | `‹dp›` |
| button | `‹dp›` |
| sheet | `‹dp›` |
| chip / field | `‹dp›` |

## 7. Elevation
`‹level 0/1/2/3 → dp or M3 tonal spec›`

## 8. Motion
| Transition | Duration | Easing |
|------------|----------|--------|
| page / route | `‹ms›` | `‹curve›` |
| sheet open (log weight) | `‹ms›` | `‹curve›` |
| value/number change | `‹ms›` | `‹curve›` |
| splash → app | `‹ms›` | `‹curve›` |

## 9. Iconography
- Icon set/style: `‹Material Symbols / custom / …›`
- Weight, add, history/chart, goal/flag, settings, bell/reminder: `‹names or assets›`

## 10. Charts (fl_chart styling)
- Line color(s), width, gradient fill under line: `‹…›`
- Grid/axis color, label style: `‹…›`
- Sparkline (home) vs full chart differences: `‹…›`
- Point/selection marker style: `‹…›`

## 11. Assets checklist (for the build)
- [ ] App icon master 1024×1024 (PNG, no alpha for iOS variant)
- [ ] Adaptive icon foreground + background (Android)
- [ ] Splash logo (light + dark) for `flutter_native_splash`
- [ ] Any illustration for empty states (optional)
- [ ] Font files (if self-hosted) + license
