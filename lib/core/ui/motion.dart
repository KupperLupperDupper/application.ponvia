import 'package:flutter/animation.dart';

/// Motion tokens from the design system. Durations in ms; curves are the M3
/// emphasized/standard sets.
abstract final class Motion {
  static const Duration route = Duration(milliseconds: 300);
  static const Duration sheetOpen = Duration(milliseconds: 350);
  static const Duration sheetClose = Duration(milliseconds: 250);
  static const Duration valueChange = Duration(milliseconds: 250);
  static const Duration splashToApp = Duration(milliseconds: 200);
  static const Duration selection = Duration(milliseconds: 120);

  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0, 0.8, 0.15);
  static const Curve standardDecelerate = Cubic(0, 0, 0, 1);
}
