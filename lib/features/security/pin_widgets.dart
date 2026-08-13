import 'package:flutter/material.dart';

/// The four-dot PIN progress indicator (empty / filled / wrong), shared by the
/// set-PIN flow and the lock screen. Animates each fill and reflects an error
/// tint; the parent drives the shake.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.filled, this.error = false, this.length = 4});

  final int filled;
  final bool error;
  final int length;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutBack,
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled
                    ? (error ? scheme.error : scheme.primary)
                    : Colors.transparent,
                border: i < filled
                    ? null
                    : Border.all(color: scheme.outline, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// Runs a short horizontal shake (used for a wrong PIN), then calls [onDone].
mixin PinShakeMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  late final AnimationController shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Horizontal offset in logical px for the current shake frame.
  double get shakeOffset {
    // 3 cycles, ±6dp, decaying — a quick "no".
    final t = shakeController.value;
    if (t == 0) return 0;
    return 6 * (1 - t) * -_sin3(t);
  }

  static double _sin3(double t) {
    // sin(2π · 3 · t)
    const twoPi = 6.283185307179586;
    return _fastSin(twoPi * 3 * t);
  }

  static double _fastSin(double x) {
    // Reduce to [-π, π] then a cheap poly — precise enough for a shake.
    const pi = 3.141592653589793;
    const twoPi = 6.283185307179586;
    var v = x % twoPi;
    if (v > pi) v -= twoPi;
    if (v < -pi) v += twoPi;
    final v2 = v * v;
    return v * (1 - v2 / 6 + v2 * v2 / 120);
  }

  void disposeShake() => shakeController.dispose();
}
