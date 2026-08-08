# Ponvia — Design → Flutter Handoff

How the design deliverables become the app. Read this after the design step returns
mockups + tokens. Goal: a mechanical, low-ambiguity path from tokens to a themed Flutter
app.

## 1. What "done" looks like for the handoff
The design step drops its output in [`handoff/`](handoff/) (see
[handoff/README.md](handoff/README.md)). It's ready to implement when:
- [ ] [`handoff/DESIGN_SYSTEM.md`](handoff/DESIGN_SYSTEM.md) exists with **every** value
      filled (light + dark color roles, type scale incl. `heroWeight`, spacing, radii,
      elevation, motion, nav model) — it follows the template in
      [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).
- [ ] `handoff/tokens.json` present (machine-readable mirror).
- [ ] Mockups in `handoff/mockups/` for every screen in
      [DESIGN_BRIEF.md](DESIGN_BRIEF.md), in **light & dark**, with empty/error/highlighted
      states.
- [ ] Home + Onboarding shown in **English & Danish** and in **kg / lb / st**.
- [ ] Assets in `handoff/assets/` (icon master + adaptive layers, splash logos, fonts).
- [ ] The navigation model is decided (bottom nav tabs vs other).

## 2. Where each token lands in code (M5)
| Design token | Flutter target |
|--------------|----------------|
| seed / color roles (light, dark) | `ColorScheme` in `lib/app/theme/color_schemes.dart` (hand-built from the given hexes, not just `fromSeed`, so roles match the mockups) |
| `positive` / `negative` delta colors | a `ThemeExtension` (`PonviaColors`) since M3 has no built-in slot |
| type scale | `TextTheme` in `lib/app/theme/typography.dart`; `heroWeight` as a named custom style |
| spacing scale | `lib/core/ui/spacing.dart` constants (e.g. `Insets.md`) |
| radii | `lib/app/theme/shapes.dart` → `ShapeThemeData` / `CardTheme` etc. |
| elevation | component themes (`CardTheme`, `FloatingActionButtonTheme`, …) |
| motion durations/curves | `lib/core/ui/motion.dart` constants used by transitions |
| icons | Material Symbols or bundled asset set referenced from a `PonviaIcons` file |
| chart styles | applied where `fl_chart` `LineChartData` is built (history + home sparkline) |

## 3. Assets pipeline
- **App icon:** drop the 1024 master + adaptive layers into `assets/`, configure
  `flutter_launcher_icons`, run its generator. Package id
  `io.github.kupperlupperdupper.ponvia`.
- **Splash:** configure `flutter_native_splash` with the light/dark splash logos and brand
  background; run its generator. Verify no white flash on cold start.
- **Fonts:** if self-hosted, add files under `assets/fonts/` and declare in `pubspec.yaml`;
  otherwise wire Google Fonts. Keep the license file in-repo.
- **Naming:** `assets/icon/…`, `assets/splash/…`, `assets/fonts/…`, `assets/illustrations/…`.

## 4. Screen-by-screen acceptance checklist (used in M5)
For each screen, verify against the mockup in **light & dark**:
- [ ] **Splash** — brand mark centered, correct backgrounds, no flash.
- [ ] **Onboarding** — stepper matches; skippable; language/theme/unit choices apply live;
      renders in en & da without overflow.
- [ ] **Home** — hero weight uses `heroWeight` style + chosen unit + relative date; delta
      shows icon+text+color; highlighted-goal progress present; sparkline styled; primary
      log action placed as designed; empty state matches; future-metric slot preserved.
- [ ] **Log/Edit** — fast entry; numeric keyboard; validation error state; date/time
      editable; save + snackbar.
- [ ] **History** — list rows (date/value/delta/note); range switcher; chart styled per
      tokens; empty state.
- [ ] **Goals** — closest goal highlighted per design; distance + direction; add/edit form;
      achieved treatment; empty state.
- [ ] **Settings** — grouped rows; controls; About shows real version/build; clear-data
      confirm dialog matches.
- [ ] **Notifications** — enable toggle; frequency; conditional weekday/day-of-month; time
      picker; permission-needed state.

## 5. Fidelity rules
- Match spacing/radii/type **by token**, not by eyeballing pixels.
- Keep everything themable — no hard-coded colors/sizes in widgets; pull from theme +
  the spacing/motion constants.
- If a mockup implies something not captured in tokens, **add the token** to
  DESIGN_SYSTEM.md first, then implement — keep the contract complete.
- Danish is the stress test for layout: if it overflows, fix layout, don't shrink content
  arbitrarily.

## 6. Open items to confirm with the designer
- Navigation model (bottom tabs vs. hub-and-spoke).
- Stone display format (`st + lb` composite vs decimal stone).
- Delta color semantics (neutral-informative, per SPEC) — confirm palette intent.
- Whether home sparkline and history chart share one styled component.
