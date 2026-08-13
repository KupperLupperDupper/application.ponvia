# Ponvia — Height → BMI and App lock
Handoff for round 9. Frames live in `Ponvia.dc.html` sections **16–19**. Tokens: `tokens.json → height, bmi, appLock`. Copy: `strings.en-da.json → height, bmi, appLock`.

Both features are **opt-in and inert until enabled**, and nothing else in the app may depend on either.

---

# 1 — Height → BMI

## Storage and units
- Canonical storage is **cm** (int, 100–250). Weight stays canonical **kg**. BMI = kg / (cm/100)².
- Display converts by the user's weight unit: **kg → cm**, **lb or st → ft/in**.

## Resolved: imperial users enter ft/in, not cm
A user who weighs in lb or st does not know their height in centimetres — asking for cm makes them convert in their head for the one value we ask them to type, which is exactly the friction that stops an optional setting from being adopted.

Implementation keeps the shared `NumericKeypad` untouched:
- Metric: one **cm** field, up to 3 digits, underline in `primary` while focused.
- Imperial: two fields, **ft** then **in**, side by side with 20 gap. ft accepts 1 digit and auto-advances; in accepts up to 2 and clamps at 11. Backspace at the start of *in* returns focus to *ft*.
- Under the fields, imperial shows a quiet `Stored as {cm} cm` line (13sp, `onSurfaceVariant`) — no conversion surprise later.
- Save is disabled until the value is in range. **Remove height** (TextButton) clears it and empties the Home slot; no confirmation.

## Settings row
Sits in **Preferences**, between Weight unit and Notifications. Icon `height`. Two-line row (min 72) while unset: label + "Valgfri — låser op for BMI på forsiden", trailing "Ikke angivet". Once set it collapses to the standard 60 single-line row with the value (tabular) as the trailing text. Tapping opens the entry sheet — same sheet family as Log weight (28 top radius, `surfaceContainerHighest`, elevation 3, 36×4 handle).

## Home second-metric slot
BMI appears on Home **only when a height is set**. With no height there is no tile, no dashed placeholder and no prompt — the 7-day average card takes the full width and the screen reads as complete. Home never advertises the feature; it is discovered in Settings.

When a height is saved the tile appears over 250ms (fade), with the average card reflowing to half width in the same beat; the grid is the existing 2-up, 12 gap. Removing the height removes the tile the same way.

Tile: 24 radius, min 104, 18/20 padding, `surface` + 1dp `outline` like its sibling. Label "BMI" 13sp `onSurfaceVariant`, value 24sp/800 one decimal tabular `onSurface`, band word 13sp `onSurfaceVariant`. Tapping it opens Settings › Height, not a BMI explainer.

## Tone (non-negotiable)
- Identical colours for every value. No red/amber/green, no gauge, no bar, no marker, no arrow, no target.
- Band wording is **relative to the normal range** — "Under normalområdet" / "Normalområdet" / "Over normalområdet". Never "overweight", "obese", "underweight"; never advice.
- BMI never appears in the goal flow, History, notifications, or export prompts. It is one tile.
- Recomputes silently on each new weight; no "your BMI changed" messaging of any kind.

---

# 2 — App lock: PIN + optional fingerprint

## Two switches, no timer
A new **Sikkerhed** group sits between Preferences and Data — Preferences is for consequence-free cosmetic choices, and a launch lock isn't one. The group also gives the on-device promise somewhere to live as supporting text.

| Row | Behaviour |
|---|---|
| **App-lås** (parent) | Switch, two-line (min 76): "Kræv pinkode når Ponvia åbnes". On → pushes the set-PIN flow; the switch only moves once a PIN is confirmed. Off → requires the current PIN, clears the stored hash, and switches fingerprint off with it. |
| **Fingeraftryk** (nested, 60 leading inset) | Switch, two-line: "Lås op med fingeraftryk i stedet for pinkoden". Disabled at 38% while the lock is off ("Slå app-lås til først") or when the device has no enrolment ("Ingen fingeraftryk på denne telefon"). On → fires the OS prompt immediately; the switch moves only on success, and cancelling leaves it off with no error. |
| **Skift pinkode** | Visible only while the lock is on. Current PIN, then the same two-step set flow. |

Valid states: off+off (no lock) · on+off (PIN view) · on+on (PIN view + automatic fingerprint prompt). off+on is structurally impossible. **There is no lock timer** — the lock applies on cold start and on resume.

## Setting the PIN
Pushed route, back arrow, no submit button. Step 1 "Vælg en pinkode" → 4 dots + the shared `NumericKeypad`; the fourth digit advances to step 2 "Bekræft pinkoden" ("Indtast de samme fire cifre igen."). A mismatch shakes the dots, clears them and returns to step 1 with "Pinkoderne er ikke ens. Prøv igen." Success pops back to Settings with the switch on.

## Launch: the PIN view is the screen
Launch lands on the PIN view **always**, whether or not fingerprint is on. The PIN is the floor that cannot fail, so it is what the screen is built around; when fingerprint is enabled the OS prompt fires automatically on top of it, and dismissing it leaves the user already where they need to be rather than on a dead "Unlock" screen. A correct PIN or an accepted fingerprint goes **straight to Home** — no confirm button, no success screen.

Layout, centred: 72 `primaryContainer` disc with `lock` 36 in `primary` → PONVIA wordmark (14sp/700, .18em, `onSurfaceVariant`) → title 22sp/800 → 4 dots (14, gap 20; empty 1.5dp `outline`, filled `primary`, wrong `error`) → a hint row of reserved 20 height so nothing reflows. Bottom: the keypad (3 columns, keys h64 r22, gap 12, `surface` + 1dp `outline`, digits 26sp/700; lower-left is `fingerprint` **only when enabled**, lower-right `backspace`), the "Glemt din pinkode?" TextButton, and the "Alt bliver på din telefon" footer. Padding 24 horizontal / 34 bottom, 40 for text.

| State | Treatment |
|---|---|
| Idle | Title "Indtast din pinkode", hint "4 cifre", empty dots. |
| Fingerprint auto | Same view with a 10dp `primary` @10% halo on the disc and hint "Venter på fingeraftryk…"; the OS sheet owns the foreground. We draw no prompt art of our own. |
| Wrong PIN | Dots go `error`, shake, then clear; hint becomes an `errorContainer` pill "Forkert pinkode. Prøv igen." The disc does not change. |
| Accepted | Dots settle filled, `lock` crossfades to `lock_open`, title "Låser op", then fade-through to Home. |

## Micro-animations
| What | Spec |
|---|---|
| Screen in | 250ms fade, no slide |
| Disc + dots in | 40ms stagger, fade + scale 0.94→1 |
| Key press | scale 0.96, 90ms, releases back |
| Dot fill | scale 0→1 + fade, 140ms emphasized |
| Dot clear | reverse, 100ms |
| Wrong PIN | dots → `error`, 320ms 3-cycle shake ±6dp, then clear; one light haptic tick |
| Accepted | `lock`→`lock_open` crossfade 180ms, disc scale 1→1.04→1 |
| To Home | 220ms fade-through, no push |
| Reduced motion | fades only — no shake, no scale |

## Never locked out
- The PIN is Ponvia's own, stored **only** as a salted hash in platform secure storage. No account, no recovery service, nothing to sync.
- Fingerprint is a shortcut, never the only way in: sensor failure, unenrolment or a cancel all leave the PIN view already on screen.
- Wrong entries are not counted and never trigger a Ponvia-side cooldown or timer.
- **Glemt din pinkode?** is honest rather than helpful: a plain dialog explains the PIN exists only on this phone, so the only way back in is clearing Ponvia's data, and points at Export first.
- `FLAG_SECURE` while the lock is on, so the task switcher shows no weight data.

## Frames
`height.row-empty.light.da`, `height.entry-cm.dark.da`, `height.entry-ftin.light.en`, `bmi.no-height.light.da`, `bmi.slot-filled.dark.da`, `lock.pin-idle.light.da`, `lock.biometric-auto.dark.da`, `lock.wrong-pin.light.da`, `lock.accepted.dark.da`, `settings.security-both-on.light.da`, `settings.security-off.dark.da`, `applock.set-pin-confirm.light.da`.
