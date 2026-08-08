# Design Handoff — drop zone

This folder receives the output of the **Claude design** step (see
[../DESIGN_BRIEF.md](../DESIGN_BRIEF.md)). The design session produces the files below;
you place them here, and the Flutter build (M5) consumes them via
[../HANDOFF.md](../HANDOFF.md).

> The design session runs in the browser and can't write to this disk directly. You bring
> its output here (download/paste). The brief instructs it to emit these exact files.

## Expected contents

```
design/handoff/
  DESIGN_SYSTEM.md     ← Claude design generates this: the FILLED token set
                          (real hex/sizes/etc.), following the template in
                          ../DESIGN_SYSTEM.md. This is the canonical source for
                          the Flutter theme.
  tokens.json          ← same tokens, machine-readable (optional but preferred)
  rationale.md         ← one-paragraph palette/mood rationale (optional)
  mockups/             ← screen mockups: PNG or HTML
                          naming: <screen>.<theme>[.<lang>][.<unit>].png
                          e.g. home.light.png, home.dark.da.png, home.light.st.png,
                               onboarding.light.en.png, log.dark.png, ...
  assets/
    icon/              ← app icon master 1024×1024 + adaptive fg/bg (Android)
    splash/            ← splash logo, light + dark
    fonts/             ← font files (if self-hosted) + license
    illustrations/     ← optional empty-state art
```

## Relationship to `../DESIGN_SYSTEM.md`
- `../DESIGN_SYSTEM.md` is the **template / contract** — it defines *which* tokens must
  exist (the `‹fill in›` skeleton). Keep it as the spec.
- `handoff/DESIGN_SYSTEM.md` is the **filled version** the design step produces. At M5,
  this filled file is the one the theme is built from; the template stays as the checklist.

## What "ready to implement" means
See the checklist in [../HANDOFF.md](../HANDOFF.md) §1. In short: `handoff/DESIGN_SYSTEM.md`
has every value filled, mockups cover all screens in light+dark (Home+Onboarding also in
en+da and kg/lb/st), and the `assets/` are delivered.
