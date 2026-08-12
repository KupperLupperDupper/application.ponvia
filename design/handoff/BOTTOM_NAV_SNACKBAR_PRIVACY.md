# Ponvia — Bottom nav, undo snackbar, privacy page
Handoff for the three pieces added in rounds 2–7. Source of truth: `Ponvia.dc.html` (sections 13 · Universal add — final, 11 · Custom undo snackbar, 12 · Privacy) and `tokens.json`.

Design width 390dp. All values dp unless stated. Every frame exists in light and dark; nav and snackbar are shown with Danish copy, Privacy in full in both languages.

---

## 1 · Bottom navigation with universal add

Replaces the 4-tab `NavigationBar` + Home-only extended FAB. One central add, reachable from every tab, on every route.

### Geometry
| Part | Value |
|---|---|
| Nav block height (incl. hump) | 84 |
| Bar body height | 64 |
| Hump rise above bar top | 20, over a 134 span (x 128 → 262 at 390 width) |
| Add button | 64 circle, `primary` fill, `onPrimary` glyph |
| Glyph | Material Symbols Rounded `add`, 32 |
| Collar (bar visible above / below button) | 10 / 10 — even; this is what centres the button in the bar silhouette |
| Tab cells | 4 × 64 wide × 64 tall, centred row, 96 gap for the button |
| Selected indicator | 64×32 pill, radius 16, `primaryContainer` / `onPrimaryContainer` |
| Labels | none — icons only |
| Content bottom padding | 80 |
| Elevation | button level 2 (`0 3 12 rgba(16,32,28,.20)`); bar flat with a 1dp `outline` top stroke |

Bar and hump are **one path**, drawn with the bar's fill — not a mask, not a cut:

```
M0,20 H128 C154,20 150,0 195,0 C240,0 236,20 262,20 H390 V84 H0 Z
```

In Flutter: `BottomAppBar` is not used. Draw the shape with a `CustomPainter` / `ShapeBorder` on a `SizedBox(height: 84)`, stack the centred `Row` of `IconButton`s (bottom-aligned, 64 tall) and the add button on top. Scale the path's x values by `width / 390`; keep y values fixed.

### States
- **Selected tab** — pill + `onSurface` icon, `FILL 1` axis on the Material Symbol.
- **Unselected** — `onSurfaceVariant`, `FILL 0`.
- **Add pressed** — fill steps to `#175449` (light) / `#6FC3AE` (dark), elevation 2 → 1, plus a 12dp state-layer ring at 10% primary.
- The add **never** takes the selected pill and never changes with route.

### Behaviour
- Add opens the existing log-weight modal sheet, from any tab, with the tab underneath preserved.
- **Add-goal** moves to an AppBar action on Goals: 40dp tonal button, `primaryContainer`, `add` 18 + label ("New goal" / "Nyt mål"). Labelled, not icon-only, so the two adds are never confused. Same pattern for any future per-tab create.
- Safe area: add `MediaQuery.viewPadding.bottom` under the bar body; the hump does not move.

---

## 2 · Undo snackbar

One app-wide widget replacing Material `SnackBar`. Used by single deletes (History entry, Goals card, Log/Edit sheet) and by the two bulk restores (Settings "Clear all data", "Replace" import).

| Part | Value |
|---|---|
| Side inset | 16 each side |
| Radius | 20 |
| Elevation | level 3 — `0 8 24 rgba(16,32,28,.28)` |
| Fill (light) | `#173A34`, text `#E3F3EE` |
| Fill (dark) | `surfaceContainer #1F2724`, 1dp `#333C39` outline, text `onSurface` |
| Leading tile | 36 square, radius 12, `primary` @16%; `delete` for single, `settings_backup_restore` for clear-all, `restore` for import-replace |
| Message | 15/600, line-height 1.35, wraps to 2 lines |
| Undo action | 40 tall tap target, radius 20, `#8ED8C4`, 15/800; pressed = primary @18% state layer |
| Timer | 3dp track along the bottom edge, drains left → right in `primary` |
| Duration | 4s single delete, 6s bulk restore; pauses while a sheet or dialog is open; restarts on re-show |
| **Bottom inset** | **98** = 64 bar + 20 hump + 14 gap — it clears the hump, not just the button |

Only one snackbar at a time; a new one replaces the current and commits the previous action.

---

## 3 · Privacy page

Pushed from Settings › About › Privacy. Back arrow only — no buttons, no forms, no links out.

- Hero: 96 tile, radius 30, `primaryContainer`, `lock` 44 — same silhouette as the app icon, so it reads as Ponvia, not as a warning.
- Lead line: 17/600, centred, max 3 lines.
- Five guarantee rows in one card (radius 24, `surface`, 1dp `outline`, 1dp dividers). Each row: 36 icon tile (`surfaceContainer`, `primary` glyph) + title 15/700 + description 13/400 `onSurfaceVariant`.
- Footer: `upload` 18 + 13/400 line naming the export path. The only sentence that mentions data leaving.
- Rows are height-free (padding + wrap) so Danish, which runs ~15% longer, reflows instead of clipping. At 1.3× text scale the footer moves below the fold — acceptable, nothing here is actionable.

Strings: `strings.en-da.json`.
