# Ponvia — Multi-weekday weekly reminders (design brief)

**Round 11 — BRIEF, pre-mockup.** Prompt for the Claude-design step. Produce the frames
listed at the end; the delivered handoff then feeds implementation.

## The problem
Weigh-in reminders support **daily / weekly / monthly**. Weekly lets the user pick exactly
**one** weekday via a row of seven 44dp circles (`_WeekdayCircles` in
`notifications_screen.dart`, single-select). But a common cadence is "remind me **Mon, Wed,
Fri**" — several days a week without being daily. Let weekly select **one or more** weekdays.

The UI change is small (single-select → multi-select on the existing circles). The work
behind it — model, scheduling, backup, migration — is real; this brief must scope both.

## The visible change
The seven weekday circles become a **toggle set**: tap to light a day (`primary` fill),
tap again to clear it (outline). Any subset of 1–7 can be lit. Everything else on the
Reminders screen (frequency segmented control, time card, monthly day grid) is unchanged.

## Decisions the mockup step must settle
1. **Minimum selection.** Weekly with **zero** days is meaningless. When the user clears
   the last lit day, what happens? Options: (a) block it — the last day can't be cleared;
   (b) allow zero but disable/annotate the reminder until a day is picked. Recommend **(a)
   block** — one day always stays lit, so the reminder is never silently dead.
2. **All-seven = daily?** If the user lights all seven, is that just "every day"? Options:
   keep it as weekly-with-7 (simplest, no cross-talk with the Daily segment), or collapse
   to the Daily frequency. Recommend **keep as weekly-with-7** — do not auto-switch the
   segmented control under the user; the two states scheduling identically is fine.
3. **The summary line.** Today a helper reads "Next reminder: <weekday>"
   (`notifDaySelected`). With several days it should read the **selected set** and/or the
   **next fire**. Recommend a compact set summary — "Man · Ons · Fre" — plus the existing
   next-fire line if one is shown. Define the separator and ordering (Mon-first, following
   the circle order, not selection order).
4. **Selected-state affordance.** Confirm the lit circle stays the filled `primary` disc
   with on-primary text, and the unlit is the 1dp `outline` ring — same tokens as today,
   just now several can be lit at once. Any pressed/ripple treatment stays as the current
   `InkWell` circle.
5. **Order of the week.** Circles are Mon…Sun today (locale narrow names). Keep that order
   regardless of the device's first-day-of-week? Recommend keeping Mon-first for now (state
   it, since locale-aware first-day is a possible later refinement).

## Behind the UI (implementation scope — flag, don't design)
State so the design understands the blast radius; none of this needs a mockup:
- **Model:** `ReminderConfig.weekday` (single `int`) becomes a **set of weekdays**
  (`Set<int>`, 1=Mon…7=Sun). `copyWith` / `toJson` / `fromJson` and the backup codec gain
  the new field; a **migration** must read an old single `weekday` as a one-element set so
  existing users' reminders survive an update.
- **Scheduling:** `notification_service.dart` schedules **one** notification today
  (`_notificationId = 1001`, `matchDateTimeComponents: dayOfWeekAndTime`). Multi-weekday =
  **one scheduled notification per selected weekday**, each with a **distinct id** (e.g.
  `1000 + weekday`) and its own weekly `dayOfWeekAndTime` match; `cancelAll` before
  rescheduling stays. `nextReminderInstance` (`reminder_schedule.dart`) computes per
  weekday; the screen's "next fire" is the **earliest** across the selected set.
- **Tests:** extend the reminder date-math tests for a multi-day set (nearest next day,
  wrap-around across the week, DST-safe like the current cases).

## Boundaries
- Daily and monthly are unchanged. Multi-select applies **only** to the weekly frequency.
- No new notification content or channel; same reminder copy and deep-link to `/log`.
- Not touching the time picker, the monthly day grid, or the Android-13 permission flow.

## Frames to produce
`reminders.weekly-multi.light.da` (Mon/Wed/Fri lit, summary line shown),
`reminders.weekly-multi.dark.en` (a different subset),
`reminders.weekly-one-left.light.da` (a single day lit, showing the "can't clear the last
one" state per decision 1),
plus a note frame `reminders.weekly-multi.spec` for the toggle interaction and the summary
formatting.

## Open questions
1. Minimum-selection behaviour (decision 1) and the all-seven question (decision 2).
2. Summary-line format and whether a "next fire" line accompanies it.
