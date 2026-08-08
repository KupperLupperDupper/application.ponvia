# Fonts & licenses

## Manrope — UI font (all app text)
- Designer: Mikhail Sharanda / Mirko Velimirovic
- License: SIL Open Font License 1.1 (free for commercial use, embedding and bundling in apps)
- Source: https://fonts.google.com/specimen/Manrope — download the family and add `Manrope-Regular/Medium/SemiBold/Bold/ExtraBold.ttf` to `assets/fonts/`, then declare in `pubspec.yaml`:

```yaml
fonts:
  - family: Manrope
    fonts:
      - asset: assets/fonts/Manrope-Regular.ttf
        weight: 400
      - asset: assets/fonts/Manrope-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Manrope-Bold.ttf
        weight: 700
      - asset: assets/fonts/Manrope-ExtraBold.ttf
        weight: 800
```
Ship a copy of `OFL.txt` from the download and surface it in Settings → About → Licenses (Flutter's `showLicensePage` picks it up via `LicenseRegistry`).

## Material Symbols Rounded — icons
- License: Apache License 2.0
- Source: https://fonts.google.com/icons (or the `material_symbols_icons` pub package). Variable axes used: `opsz 24, wght 400, GRAD 0, FILL 0` (FILL 1 for the selected bottom-nav destination).

## JetBrains Mono — annotation only
- License: SIL Open Font License 1.1. Used in the design documentation/mockup annotations; **not** required by the app.

Binary font files are not bundled in this handoff — the two links above are the canonical, freely licensed sources.
