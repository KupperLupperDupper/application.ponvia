# Design Handoff — DELIVERED

The Claude design step delivered on 2026-08-08. This folder now holds the real design
system. The Flutter build (M5, and theme setup from M1) consumes it via
[../HANDOFF.md](../HANDOFF.md).

## Contents (as delivered)

```
design/handoff/
  DESIGN_SYSTEM.md   FILLED token set — colors (light/dark M3 roles), typography
                     (Manrope), spacing, radii, elevation, motion, icons, charts,
                     nav model. Canonical source for the Flutter theme.
  tokens.json        Machine-readable mirror of the tokens (colors, type, spacing,
                     radii, elevation, motion, icons, charts, layout, navigation).
  DESIGN_SPEC.md     Per-screen implementation spec (all 8 screens, states, exact
                     values). "Where HTML and tokens disagree, the tokens win."
  rationale.md       Palette + mood rationale.
  mockups/
    Ponvia.dc.html   High-fidelity visual reference — 8 screens at 390×844 in light &
                     dark, Home + Onboarding also in Danish and kg/lb/st. Open in a
                     browser. It is a *spec*, not code to port.
    support.js       Runtime for the canvas above (loaded via ./support.js).
  assets/
    icon-master-1024.png             app icon master (1024×1024, 22% radius)
    android-adaptive-foreground.png  Android adaptive icon foreground
    android-adaptive-background.png  Android adaptive icon background (#1F6A5C)
    splash-logo-light.png            splash mark, light (512×512)
    splash-logo-dark.png             splash mark, dark (512×512)
    FONTS-LICENSE.md                 font licensing (Manrope / JetBrains Mono, OFL 1.1)
```

## Key decisions baked in
- **Brand/seed:** sea-green `#1F6A5C` (light) / `#8ED8C4` (dark). Warm-neutral greys.
- **Type:** Manrope (OFL) for all UI; tabular figures for numbers; `heroWeight` 72sp/800.
- **Navigation:** M3 bottom `NavigationBar`, 4 tabs — Home / History / Goals / Settings.
  Logging is a **modal bottom sheet** from an extended FAB on Home (plain FAB on Goals),
  never a tab. Notifications is a pushed route under Settings.
- **Delta semantics (neutral-informative):** down = brand green, up = muted ochre
  (`#8A6238` / `#E0BC88`), always paired with an arrow icon + word. No good/bad coloring.
- **Stone** renders as composite `st + lb` (hero drops to 64sp past 6 glyphs).

## ⚠️ Fonts are NOT bundled as binaries
Only `FONTS-LICENSE.md` shipped — no `.ttf` files. The mockups load Manrope + Material
Symbols Rounded + JetBrains Mono from Google Fonts. For the app (M1), bundle **Manrope**
locally (download the OFL TTFs into `assets/fonts/`) or use the `google_fonts` package, and
use the `material_symbols_icons` package (or bundle the variable font) for the icons.
Keep `FONTS-LICENSE.md` with whatever is shipped.

## Relationship to `../DESIGN_SYSTEM.md`
`../DESIGN_SYSTEM.md` is the blank **template/contract** (the checklist of required
tokens). The filled, authoritative version is **this folder's `DESIGN_SYSTEM.md`** — build
the theme from it. `DESIGN_SPEC.md` is the screen-by-screen detail on top of the tokens.
