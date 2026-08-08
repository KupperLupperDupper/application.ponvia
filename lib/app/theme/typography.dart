import 'package:flutter/material.dart';

/// Type scale from the design tokens, in Manrope. Tracking is given in em and
/// converted to logical-pixel letter-spacing (`em * size`).
///
/// Manrope TTFs are not yet bundled (see `design/handoff/README.md`); until they
/// are added under `assets/fonts/`, text falls back to the platform font. The
/// sizes/weights are already correct, so bundling later is a drop-in.
abstract final class PonviaTypography {
  static const String family = 'Manrope';

  static TextStyle _style(
    double size,
    FontWeight weight,
    double lineHeight,
    double trackingEm,
  ) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      letterSpacing: trackingEm * size,
    );
  }

  /// The oversized last-weight number on Home. Uses tabular figures so digits
  /// don't jitter as the value animates.
  static const TextStyle heroWeight = TextStyle(
    fontFamily: family,
    fontSize: 72,
    fontWeight: FontWeight.w800,
    height: 76 / 72,
    letterSpacing: -0.04 * 72,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextTheme textTheme(ColorScheme scheme) {
    final t = TextTheme(
      displaySmall: _style(36, FontWeight.w800, 42, -0.02),
      headlineMedium: _style(28, FontWeight.w800, 34, -0.02),
      titleLarge: _style(22, FontWeight.w800, 28, -0.02),
      titleMedium: _style(20, FontWeight.w700, 26, 0),
      bodyLarge: _style(16, FontWeight.w400, 24, 0),
      bodyMedium: _style(16, FontWeight.w400, 24, 0),
      labelLarge: _style(14, FontWeight.w700, 20, 0.01),
      labelSmall: _style(12, FontWeight.w800, 16, 0.06),
    );
    return t.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
  }
}
