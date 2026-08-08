# Ponvia — Design Brief (prompt for the design tool)

> **How to use this file:** paste the section under "── PROMPT ──" into Claude design (or
> your design tool) as the brief. Everything above it is context for you, the human. The
> brief asks the tool to deliver **mockups** and to **write a complete `DESIGN_SYSTEM.md`
> file** (the token set, all values filled) that you then drop into
> [handoff/](handoff/) — see [handoff/README.md](handoff/README.md) and
> [HANDOFF.md](HANDOFF.md). The full file template is embedded in the prompt so the design
> session (which can't read this repo) produces a file that matches exactly.

## Context for you (not part of the prompt)
- Ponvia is a private, fully-local weight tracker (Flutter, Material 3). Calorie tracking
  is **future** — do not design calorie screens now, but leave the home layout able to
  grow a second metric later.
- The **last recorded weight is the hero** of the whole app.
- Must work in **light & dark**, **English & Danish**, and **three weight units**
  (kg, lb, st). Danish strings run ~20–30% longer than English — design must not break.
- Feed the returned tokens back into [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).

---

── PROMPT ──

You are designing **Ponvia**, a calm, private, mobile weight-tracking app (Android & iOS,
Material 3). Deliver a cohesive, modern, accessible UI as high-fidelity mockups **and** a
concrete design-token set I can hand to a Flutter developer.

### Product in one line
Track your weight with almost no friction, and always see your **latest weight** front and
center, with goals and a trend that give it meaning. (Calorie tracking comes later — don't
design it, but leave room to add a second metric on the home screen.)

### Mood & personality
Calm, trustworthy, quietly motivating — not clinical, not gamified/loud. Think "a
well-made health companion that respects you." Generous whitespace, one confident accent
color, soft geometry, restrained motion. Suggest a small brand identity: an **app name
wordmark and a simple logo/app-icon mark** for "Ponvia," plus a primary accent color (and
a dark-theme variant). Propose the palette; don't assume mine.

### Platforms & form factor
Phone-first portrait (design at 390–430pt width). Material 3 components and elevation.
Must look right in **light and dark**. Respect large-text/dynamic-type and a minimum 48dp
touch target.

### Screens to design (all states noted)
1. **Splash** — brand mark on brand background; light + dark. Must feel instant.
2. **Onboarding (first run)** — a short, friendly stepper collecting: (1) language
   (Danish/English), (2) theme (System/Light/Dark), (3) weight unit (kg/lb/st), and
   optionally (4) first weight entry and (5) reminder setup. Show a welcome step and a
   "you're all set" step. Steps must be skippable.
3. **Home (the hero screen)** — dominated by the **last recorded weight** in the chosen
   unit with its date ("Today"/"Yesterday"/date). Show: change vs previous entry
   (up/down/flat with amount and color semantics — losing weight isn't inherently
   "good/bad", keep it neutral-informative), progress toward the **highlighted goal**, a
   **compact recent-trend mini-chart (sparkline)**, and a prominent **"Log weight"**
   action (FAB or large button). Design the **empty state** (no entries yet) with an
   inviting first-log CTA. Leave a visual "slot" where a future second metric (calories)
   could sit without redesign.
4. **Log / Edit weight** — a fast entry sheet/screen: big numeric input in the chosen
   unit, date/time (defaults to now, editable), optional note, save. Show validation
   error state. This is opened many times a week — make it the fastest thing in the app.
5. **History** — reverse-chronological list of entries (date, value, delta, note) **plus**
   a **trend line chart** with range switcher (1W / 1M / 3M / 1Y / All). Design list row,
   the chart, range control, and the empty state.
6. **Goals** — a list of target-weight goals. The goal **closest to the current weight is
   visually highlighted** (elevated/accented). Each goal shows distance-to-target and
   direction (lose/gain). Include: add/edit goal form, an "achieved" goal treatment, and
   the empty state.
7. **Settings** — grouped list: Language, Theme, Weight unit, Notifications (entry point),
   Data (export/import + clear data), About (app version, privacy "all data stays on your
   device", licenses). Design the rows, selection controls, and destructive-action
   (clear data) confirm dialog.
8. **Notifications settings** — configure weigh-in reminders: enable toggle, frequency
   (Daily / Weekly / Monthly), and the conditional controls — **weekday picker** for
   Weekly, **day-of-month** for Monthly, and a **time-of-day** picker for all. Show the
   permission-needed state.

### Components / design system to define
App bar, bottom navigation (Home / History / Goals / Settings — confirm the nav model),
FAB or primary button, cards (weight hero card, goal card, list rows), segmented range
control, chips/toggles, sheets & dialogs, text fields (numeric + note), the sparkline and
full line-chart styling, empty states, and toasts/snackbars (incl. undo for delete).

### States to cover for each relevant screen
Default, **empty** (no data), loading/transition, error/validation, and the **highlighted**
/ selected variants (highlighted goal, selected range, chosen setting).

### Localization & units (critical)
Show at least the **Home** and **Onboarding** screens in **both English and Danish**, and
show the weight hero in **kg, lb, and st** so number formatting and layout are validated
against longer Danish strings and different unit widths (stone may render as `st + lb`).

### Accessibility
Contrast AA in both themes, visible focus/selection, legible type scale, color never the
sole signal (pair delta/goal direction with icon + text).

### Deliverables I need back
1. **Mockups** for every screen above, in **light and dark**, with the noted states, and
   the Home + Onboarding also in **Danish** and across the **three units** (kg/lb/st).
   Name files `<screen>.<theme>[.<lang>][.<unit>].png` (e.g. `home.dark.da.png`,
   `home.light.st.png`, `log.light.png`).
2. **A complete `DESIGN_SYSTEM.md` file** — this is the primary deliverable. Reproduce the
   exact template below and **replace every `‹fill in›` with a real value** (concrete hex
   colors, font family + sizes/weights/line-heights, spacing steps, radii in dp, elevation,
   motion durations/curves, icon set, chart styling). Output it as a single Markdown file I
   can save verbatim as `DESIGN_SYSTEM.md`. Do not change the headings or table structure —
   only fill values (you may add rows if a design element needs a token not listed).
3. **`tokens.json`** — the same values in machine-readable JSON (colors, type, spacing,
   radii, elevation, motion), for programmatic import.
4. **`rationale.md`** — one paragraph on the palette + mood.
5. The **assets**: app icon master 1024×1024 (+ Android adaptive fg/bg), splash logo
   (light + dark), and any chosen font files (freely licensed) with the license.

#### Template to fill and return as `DESIGN_SYSTEM.md`
```markdown
# Ponvia — Design Tokens (filled)

## 1. Brand
- App name wordmark: ‹describe/link›
- Logo / app-icon mark: ‹describe/link; 1024×1024 master provided in assets›
- Accent / seed color (light): ‹#RRGGBB›
- Accent / seed color (dark): ‹#RRGGBB›
- One-line palette rationale: ‹…›

## 2. Color — light scheme (Material 3 roles)
| Role | Hex |
|------|-----|
| primary | ‹#…› |
| onPrimary | ‹#…› |
| primaryContainer | ‹#…› |
| onPrimaryContainer | ‹#…› |
| secondary | ‹#…› |
| surface | ‹#…› |
| onSurface | ‹#…› |
| surfaceContainer / variant | ‹#…› |
| outline | ‹#…› |
| error | ‹#…› |
| positive (delta direction, neutral-informative) | ‹#…› |
| negative / neutral delta | ‹#…› |

## 3. Color — dark scheme
| Role | Hex |
|------|-----|
| primary | ‹#…› |
| onPrimary | ‹#…› |
| primaryContainer | ‹#…› |
| onPrimaryContainer | ‹#…› |
| secondary | ‹#…› |
| surface | ‹#…› |
| onSurface | ‹#…› |
| surfaceContainer / variant | ‹#…› |
| outline | ‹#…› |
| error | ‹#…› |
| positive | ‹#…› |
| negative / neutral | ‹#…› |

## 4. Typography
Font family: ‹family (freely licensed)›

| Token | Size | Weight | Line height | Usage |
|-------|------|--------|-------------|-------|
| heroWeight | ‹pt› | ‹w› | ‹› | big last-weight number on Home |
| display | ‹› | ‹› | ‹› | |
| headline | ‹› | ‹› | ‹› | screen titles |
| title | ‹› | ‹› | ‹› | card titles, list headers |
| body | ‹› | ‹› | ‹› | primary text |
| label | ‹› | ‹› | ‹› | buttons, chips, captions |

## 5. Spacing scale
‹exact steps, e.g. 4, 8, 12, 16, 24, 32›

## 6. Shape / radii
| Token | Radius (dp) |
|-------|-------------|
| card | ‹› |
| button | ‹› |
| sheet | ‹› |
| chip / field | ‹› |

## 7. Elevation
‹levels 0–3 → dp / M3 tonal spec›

## 8. Motion
| Transition | Duration (ms) | Easing |
|------------|---------------|--------|
| page / route | ‹› | ‹› |
| sheet open (log weight) | ‹› | ‹› |
| value/number change | ‹› | ‹› |
| splash → app | ‹› | ‹› |

## 9. Iconography
- Icon set/style: ‹Material Symbols / custom / …›
- weight, add, history/chart, goal/flag, settings, bell/reminder: ‹names or assets›

## 10. Charts (fl_chart styling)
- Line color(s), width, gradient fill under line: ‹…›
- Grid/axis color, label style: ‹…›
- Sparkline (home) vs full chart differences: ‹…›
- Point/selection marker style: ‹…›

## 11. Navigation model
- ‹bottom tabs (Home / History / Goals / Settings) vs other — state the decision›
```

Present tokens inside the file as the tables above; keep `tokens.json` in sync with them.

── END PROMPT ──
