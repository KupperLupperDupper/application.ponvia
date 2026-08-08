# Ponvia — Product Specification

> Status: **M0 (foundation)**. This spec is the source of truth for what Ponvia does.
> Code does not exist yet; this describes the target for M1–M6. See
> [MILESTONES.md](MILESTONES.md) for sequencing and [DECISIONS.md](DECISIONS.md) for
> the "why" behind technical choices.

## 1. Product summary

Ponvia is a **private, fully-local weight-tracking app** for iOS and Android, built with
Flutter. Its primary job is to make logging your weight effortless and to keep your
**most recent weight front and center**, with goals and trends to give that number
meaning. Calorie intake tracking is planned but **out of scope until a later phase**.

- **No accounts, no cloud, no network.** All data lives on the device.
- **Ownership of data:** the user can export a full backup and import it back.
- **Android first** (the developer's device), iOS parity later once a Mac is available.

### Design values
1. **Weight-first.** The last recorded weight is the hero of the app.
2. **Low-friction logging.** Adding a weight is a few taps from launch.
3. **Performance & polish.** Fast cold start, smooth 60/120fps, no jank.
4. **Privacy by construction.** Nothing leaves the device unless the user exports it.
5. **Bilingual from day one.** Danish and English, first-class.

---

## 2. Personas & scope

- **Primary user (v1):** the developer — a single person tracking their own weight on
  Android. No multi-user, no sharing, no sync in v1.
- The architecture must not *preclude* future multi-profile or sync, but v1 builds none
  of it.

**In scope (v1):** weight logging & history, goals, home dashboard, onboarding, splash,
settings (language / theme / unit / notifications / about), local notifications for
weigh-in reminders, JSON + CSV import/export.

**Explicitly out of scope (v1):** calorie/food tracking (data model leaves room; no UI),
cloud sync, accounts, social features, health-platform integration (Apple Health / Google
Fit / Health Connect), widgets, watch apps. These are candidates for later phases.

---

## 3. Feature requirements

Each feature lists **acceptance criteria (AC)**. "The app" = Ponvia.

### 3.1 Splash screen
- **AC1** On launch the app shows a native splash (brand mark on brand background) with
  no white flash, in both light and dark themes.
- **AC2** The splash transitions into either onboarding (first run) or the home screen
  (returning user) once initial data (settings, last weight) is loaded.
- **AC3** Perceived cold-start to first meaningful screen ≤ ~2s on the target device.

### 3.2 Onboarding / introduction (first-run only)
- **AC1** Shown only on first launch (a "seen onboarding" flag persists).
- **AC2** Collects, with sensible defaults, in this order: **language** (Danish/English),
  **theme** (System/Light/Dark), **weight unit** (kg / lb / st), and optionally a **first
  weight entry** and **reminder setup** (can be skipped).
- **AC3** A user can skip optional steps and still reach a usable home screen.
- **AC4** Choices made in onboarding are immediately reflected app-wide and editable later
  in Settings.
- **AC5** Onboarding is re-runnable via a hidden/dev affordance is NOT required, but the
  underlying flag must be resettable via "clear data".

### 3.3 Home screen (weight-first dashboard)
- **AC1** The **last recorded weight** is the dominant visual element, shown in the
  user's chosen unit with its date ("today", "yesterday", or a formatted date).
- **AC2** Shows change vs the previous entry (delta + direction, e.g. ▼ 0.4 kg) and,
  if any goals exist, progress toward the **currently highlighted goal** (see 3.5).
- **AC3** A compact recent-trend visualization (e.g. last N entries sparkline/mini-chart).
- **AC4** A primary, always-reachable **"Log weight"** action.
- **AC5** Empty state (no entries yet) invites the first log with a clear call to action.
- **AC6** Home reflects new entries immediately after logging (no manual refresh).

### 3.4 Weight logging & history
- **AC1** Logging captures: **weight value** (in the display unit, stored canonically in
  kg), **timestamp** (defaults to now, editable), and an **optional note**.
- **AC2** Input validates range and precision sensibly per unit and rejects nonsense
  (empty, non-numeric, absurd values).
- **AC3** Entries can be **edited** and **deleted** (delete is reversible via an undo
  affordance or a confirm; hard-delete only through explicit action).
- **AC4** History lists entries reverse-chronologically with date, value, delta, note.
- **AC5** A **weight chart** shows the trend over selectable ranges (e.g. 1W / 1M / 3M /
  1Y / All). Chart respects the chosen unit.
- **AC6** Multiple entries on the same day are allowed; the "last" entry is the most
  recent by timestamp.

### 3.5 Goals
- **AC1** The user maintains a **list of weight goals** (target weight, optional label).
- **AC2** The goal **closest to the current weight** is automatically **highlighted**
  (minimum absolute difference between current weight and each target). Ties resolve
  deterministically (e.g. the goal requiring the smaller change, then most recently
  created).
- **AC3** Each goal shows distance-to-target and directional intent (lose/gain) derived
  from current vs target.
- **AC4** Goals can be added, edited, deleted, and marked achieved (achieved goals are
  visually distinct and excluded from "closest" highlighting unless none remain).
- **AC5** If there are no entries yet, goals still display but "closest" highlighting is
  suppressed until a current weight exists.

### 3.6 Settings
- **AC1 Language:** switch between **Danish** and **English**; applies immediately without
  restart.
- **AC2 Theme:** **System / Light / Dark**; applies immediately.
- **AC3 Weight unit:** **kg / lb / st (stone)**; all displayed weights convert
  immediately; stored data is unchanged (canonical kg).
- **AC4 Notifications:** enable/disable weigh-in reminders and configure them (see 3.7).
- **AC5 Data:** **Export** (JSON full backup, CSV weight history) and **Import** (JSON
  restore, CSV weight append). Includes a **clear all data** action with strong confirm.
- **AC6 About:** app **version + build number**, a short app description, licenses/credits
  (open-source licenses page), and privacy statement ("all data stays on your device").
- **AC7** Any other low-risk, sensible settings live here (e.g. default note behavior,
  first-day-of-week if relevant to reminders/charts).

### 3.7 Notifications (weigh-in reminders)
- **AC1** User can enable reminders to weigh themselves again.
- **AC2** Frequency options: **Daily**, **Weekly**, **Monthly**.
- **AC3** For **Weekly**, the user chooses **which day of the week**. For **Monthly**, the
  user chooses a day-of-month (with graceful handling of 29–31 in short months). All
  frequencies let the user choose the **time of day**.
- **AC4** Reminders fire locally at the scheduled time in the device's local timezone,
  even across reboots (rescheduled on boot where the platform requires).
- **AC5** On Android 13+ the app requests the notification permission at the right moment
  (not abruptly on first launch) and degrades gracefully if denied. Exact-alarm behavior
  is handled per Android version.
- **AC6** Tapping a reminder deep-links to the log-weight flow.
- **AC7** Disabling reminders cancels all scheduled notifications.

### 3.8 Import / export (data portability)
- **AC1 Export JSON:** a single versioned file containing **all** weights, goals, and
  settings — a complete, restorable backup.
- **AC2 Export CSV:** weight history as CSV (`timestamp,weight_kg,weight_display,unit,
  note`) for spreadsheets.
- **AC3 Import JSON:** restores a backup. The user chooses **merge** or **replace**;
  conflicts (same timestamp) are de-duplicated deterministically. Schema version is
  checked and migrated or rejected with a clear message.
- **AC4 Import CSV:** appends weight entries; validates rows and reports how many were
  imported/skipped.
- **AC5** Export/import use the OS share/file pickers; no network involved.

---

## 4. Non-functional requirements

- **Performance:** cold start to first meaningful paint ≤ ~2s on the OnePlus target;
  scrolling and chart interaction stay at the device's native refresh rate; no dropped
  frames on the hot paths (home, log, history). Startup work is deferred/async where
  possible.
- **Offline & private:** zero network calls in v1. No analytics, no crash-reporting SDKs
  that phone home, no ads. (Any future telemetry is opt-in and out of scope now.)
- **Data safety:** logging, editing, and deleting are transactional; import never
  silently destroys data (replace requires explicit confirm; a pre-import auto-backup is
  a nice-to-have).
- **Accessibility:** supports large text/dynamic type, sufficient contrast in both themes,
  semantic labels for screen readers, and hit targets ≥ 48dp.
- **Internationalization:** all user-facing strings localized (en, da); numbers, dates,
  and units formatted per locale; no hard-coded strings.
- **Resilience:** survives process death/restore; handles timezone and DST changes for
  reminders; handles empty/edge datasets.
- **Maintainability:** layered architecture, typed models, tested converters and
  repositories. See [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 5. Units & conversions

- Canonical storage unit: **kilograms (kg)** as a floating value.
- Display units: **kg**, **lb** (pounds), **st** (stone; UK style `x st y lb` or decimal
  stone — decide in design, default to `st + lb` composite for readability).
- Conversion factors: 1 kg = 2.2046226218 lb; 1 st = 6.35029318 kg (14 lb).
- Rounding/precision: display to a sensible precision per unit (kg/lb ~1 decimal); never
  lose precision in storage.

---

## 6. Open product questions

Resolved by the design delivery (see [../design/handoff/](../design/handoff/README.md)):
- ✅ **Stone display format:** composite `st + lb`.
- ✅ **App accent/brand & logo:** seed `#1F6A5C` (light) / `#8ED8C4` (dark); "weigh-point"
  mark; Manrope wordmark. Assets in `design/handoff/assets/`.
- ✅ **Navigation model:** bottom tabs (Home/History/Goals/Settings); logging is a modal
  sheet from a FAB.
- ✅ **Delta color semantics:** neutral-informative (down = brand green, up = ochre),
  always with icon + text — never good/bad.

Still open (decide before the relevant milestone):
- Monthly reminder on the 29th–31st in short months: **default = clamp to last day**.
- Whether the home sparkline and the full history chart share one component (likely yes;
  the design specifies distinct sizes/behaviors but the same line styling).
- Exact onboarding step count — design shows welcome → language → theme → unit →
  (optional) first weight → (optional) reminder → "all set".
