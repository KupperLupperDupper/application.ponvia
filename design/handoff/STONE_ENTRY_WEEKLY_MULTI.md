# Ponvia — Stone (st + lb) entry & multi-weekday weekly reminders

Round 11. Frames: `Ponvia.dc.html` sections **24–26** (stone entry) and **27–29** (reminders), ids `11a`–`11f`.
Both features re-host controls that already exist. Neither changes storage.

---

## A. Split st + lb weight entry

Applies **only when the display unit is `st`** — to the log/edit sheet, the add/edit goal sheet and
onboarding's optional first weight. kg and lb keep their single field, untouched.

### Decisions (all settled)

| # | Decision |
|---|---|
| 1 | **Pounds are whole** — integer 0–13. The keypad's decimal key is dead in st mode and renders at **38% opacity** rather than silently ignoring taps. |
| 2 | **Clamp, no rollover.** A third digit, or a value that would land ≥ 14, is rejected; the field keeps its current value. `13 → +1` does nothing. Mirrors height clamping inches at ≤ 11. |
| 3 | **Two 150dp columns, 22dp gap** (322dp inside the sheet's 20dp padding). Value **48sp/800/−0.03em** tabular, suffix 20sp/600 `onSurfaceVariant`. st entry drops from the 72sp single-field hero because two 72sp fields do not fit. Goal sheet instead uses two 64dp **boxed** fields (flex 1, 12dp gap, 32sp/800 + 18sp suffix). |
| 4 | **Validation** on `stonePartsToKg(st, lb ?? 0)` against the existing **20–400 kg** (≈ 3 st 2 lb – 62 st 13 lb). Save disabled until valid. **Blank lb = 0 lb**, never an error on its own. |
| 5 | **Empty state** `0 st 0 lb`, **st** focused, auto-advance to lb (see routing). |
| 6 | **Echo line** under the fields: the range helper while invalid, otherwise `WeightFormatter` output + canonical kg — `12 st 7 lb · 79.4 kg`. Confirms entry formatting matches History/Home. |

Open question 2 (unit switched mid-sheet) is **moot**: the unit is only changeable in Settings, which is
unreachable while a modal entry sheet is open. Build the layout as a function of the unit at build time;
ship **fresh opens under `st`** as the tested path.

### Focus & key routing (st mode)

- `st`: digits append, max two, clamp 63. **Auto-advance to lb** as soon as a further digit is impossible —
  after the second digit, or after the first if it is 7–9.
- `lb`: one or two digits, reject anything ≥ 14 or a third digit. No rollover.
- decimal key: ignored, drawn at 38% opacity.
- backspace: deletes in the focused field; **at the start of lb, focus returns to st**; no-op at the start of st.
- read-back on edit: `kgToStoneParts(kg)` prefills both fields and focuses **lb** — corrections in stone are
  almost always sub-stone, and it matches the height sheet's ft/in read-back.
- focus affordance: 2dp `primary` underline on the focused column, 1dp `outline` on the other. No caret.
  Hit area is the whole 150 × 90 column.
- a11y: two `Semantics` nodes ("Stone, 12" / "Pounds, 7") announcing the focus change on auto-advance;
  the echo line is a live region for the combined value.

### Derived text

The goal sheet's read-only Direction chip speaks stone too — "1 st 13 lb at tabe". Distances under 14 lb
keep the existing single-unit rule ("9.7 lb to go"), not "0 st 9.7 lb".

### Strings

None new. `st` / `lb` are existing unit codes; the helper and formatter strings already exist.

---

## B. Multi-weekday weekly reminders

Weekly's seven 44dp circles become a **toggle set**; any subset of 1–7. Daily and monthly are unchanged.

### Decisions (all settled)

| # | Decision |
|---|---|
| 1 | **Minimum one — block.** Tapping the sole lit day is a no-op: the 120ms 12% `primary` state layer plays and the selection stays. No snackbar, no error, no disabled-looking disc. |
| 2 | **All seven stays weekly.** Lighting every day does not flip the segmented control to Daily. The two schedule identically; moving a control the user didn't touch is worse. |
| 3 | **Summary line** replaces `notifDaySelected`: short weekday names, `" · "` separator, **Mon-first circle order** (never selection order) — "Man · Ons · Fre". No "Next reminder:" prefix; the next fire lives in the master row only, as the **earliest** across the set. Wraps freely, no truncation. |
| 4 | **Affordance unchanged.** Lit = filled `primary` disc, `onPrimary` 15sp/800. Unlit = 1dp `outline` ring, `onSurfaceVariant` 15sp/700. Same `InkWell`, 120ms cross-fade, no scale. 44dp visual / 48dp hit area, row `space-between` across the 358dp content width. |
| 5 | **Mon-first order always**, independent of the device's first-day-of-week. Locale-aware ordering is a later refinement and would also reorder the summary. |

One addition beyond the brief: the circle row gains a `labelSmall` section header (**DAYS / DAGE**) to match
FREQUENCY and TIME OF DAY — as a multi-select set the row is its own field.

Switching Weekly → Daily/Monthly keeps the set in memory so switching back restores it. The conditional
block's 250ms height + 150ms cross-fade is unchanged.

a11y: each circle is `Semantics(button, checked:)` labelled with the **full** weekday name ("Onsdag, valgt");
the sole remaining day marks its clear action `enabled: false`.

### Strings — two, total

- `notifDaysHeader` → "DAYS" / "DAGE"
- `notifDaysSummary` → the joined set, no prefix (**replaces and deletes** `notifDaySelected`)

### Implementation scope (flagged, not designed)

- **Model:** `ReminderConfig.weekday: int` → `weekdays: Set<int>` (1 = Mon … 7 = Sun) across `copyWith`,
  `toJson`, `fromJson` and the backup codec.
- **Migration:** an old single `weekday` reads as a one-element set; a missing or empty set falls back to the
  stored value, then to Monday. No user ever lands on an empty set.
- **Scheduling:** one notification per selected weekday, id `1000 + weekday`, each with its own weekly
  `dayOfWeekAndTime` match; `cancelAll` before every reschedule stays (which makes the legacy 1001/Monday id
  collision safe). `nextReminderInstance` computes per weekday; the screen shows the earliest.
- **Tests:** nearest next day within the set, week-boundary wrap-around, all-seven, single-day, plus the
  existing DST cases per selected day.
- **Unchanged:** daily, monthly, the time picker, the day-of-month grid, notification copy, the `/log` deep
  link, the Android-13 permission flow.
