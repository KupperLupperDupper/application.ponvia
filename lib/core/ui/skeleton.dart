import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'motion.dart';

/// Skeleton loading — the timing rule, the shared-clock pulse, and the block
/// primitive. See `design/handoff/SKELETON_LOADING.md`.
///
/// The whole point is that on a healthy device the skeleton is *unreachable*: a
/// local Drift read resolves in ~10–40ms, so [SkeletonGate] renders a blank body
/// and only builds the skeleton if the stream has not emitted after [showDelay].
abstract final class SkeletonTiming {
  /// App-wide: don't build the skeleton until a load has taken this long.
  static const Duration showDelay = Duration(milliseconds: 200);

  /// Per instance: once shown, hold the skeleton at least this long from its own
  /// first frame so it reads as a breath, never a flash.
  static const Duration minVisible = Duration(milliseconds: 400);

  /// Cross-fade from skeleton to content.
  static const Duration fade = Motion.splashToApp; // 200ms
  static const Curve fadeCurve = Motion.standardDecelerate; // cubic(0,0,0,1)

  /// One pulse cycle (opacity 1 → [pulseMinOpacity] → 1).
  static const Duration pulse = Duration(milliseconds: 1600);
  static const double pulseMinOpacity = 0.55;
  static const Curve pulseCurve = Cubic(0.4, 0, 0.6, 1);
}

/// Exposes the shared pulse clock to descendant [SkeletonBlock]s so every block
/// breathes on one timeline — the screen reads as a single surface, not a grid
/// of independently blinking rectangles.
class SkeletonScope extends InheritedWidget {
  const SkeletonScope({super.key, required this.opacity, required super.child});

  /// Animates 1 → [SkeletonTiming.pulseMinOpacity] → 1 (or a constant 1 under
  /// reduced motion).
  final Animation<double> opacity;

  static SkeletonScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SkeletonScope>();
    assert(scope != null, 'SkeletonBlock must sit inside a skeleton surface');
    return scope!;
  }

  @override
  bool updateShouldNotify(SkeletonScope old) => opacity != old.opacity;
}

/// A single placeholder block: a [SkeletonTiming]-pulsed rounded rectangle in
/// the theme's `surfaceContainer` (the design `base`). Pass a null [width] to
/// fill the available width. Excluded from semantics — the surface announces the
/// load once for the whole screen.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainer;
    final opacity = SkeletonScope.of(context).opacity;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: opacity,
        builder: (context, _) => Opacity(
          opacity: opacity.value,
          child: Container(
            width: width ?? double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a skeleton subtree with the shared pulse clock and a single "loading"
/// live region. Owns one [AnimationController]; honours reduced motion by
/// holding the blocks static at full opacity.
class _SkeletonSurface extends StatefulWidget {
  const _SkeletonSurface({required this.semanticsLabel, required this.child});

  final String semanticsLabel;
  final Widget child;

  @override
  State<_SkeletonSurface> createState() => _SkeletonSurfaceState();
}

class _SkeletonSurfaceState extends State<_SkeletonSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SkeletonTiming.pulse,
    );
    _pulse = Tween<double>(begin: 1, end: SkeletonTiming.pulseMinOpacity)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: SkeletonTiming.pulseCurve,
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!animate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0; // value 0 → tween begin → full opacity
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final opacity = animate ? _pulse : const AlwaysStoppedAnimation<double>(1);
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      container: true,
      child: SkeletonScope(opacity: opacity, child: widget.child),
    );
  }
}

enum _Phase { blank, skeleton, fading, resolved }

/// Gates an [AsyncValue] behind the skeleton timing rule. While the value has no
/// data (or error) it shows: nothing for [SkeletonTiming.showDelay], then the
/// [skeleton] held for [SkeletonTiming.minVisible], then a cross-fade to
/// [data]. If the value resolves within the show-delay, the skeleton is never
/// built and [data] appears with no fade — the happy path.
class SkeletonGate<T> extends StatefulWidget {
  const SkeletonGate({
    super.key,
    required this.value,
    required this.semanticsLabel,
    required this.skeleton,
    required this.data,
    this.error,
  });

  final AsyncValue<T> value;
  final String semanticsLabel;
  final WidgetBuilder skeleton;
  final Widget Function(BuildContext context, T data) data;
  final Widget Function(BuildContext context, Object error, StackTrace? st)?
  error;

  @override
  State<SkeletonGate<T>> createState() => _SkeletonGateState<T>();
}

class _SkeletonGateState<T> extends State<SkeletonGate<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _showTimer;
  Timer? _floorTimer;
  bool _floorElapsed = false;
  bool _dataReady = false;
  _Phase _phase = _Phase.blank;

  bool get _loading => !widget.value.hasValue && !widget.value.hasError;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: SkeletonTiming.fade);
    if (_loading) {
      _startShowTimer();
    } else {
      _phase = _Phase.resolved;
    }
  }

  @override
  void didUpdateWidget(SkeletonGate<T> old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _startShowTimer() {
    _showTimer = Timer(SkeletonTiming.showDelay, () {
      _showTimer = null;
      if (!mounted) return;
      if (_loading) {
        setState(() => _phase = _Phase.skeleton);
        _floorElapsed = false;
        _floorTimer = Timer(SkeletonTiming.minVisible, () {
          _floorElapsed = true;
          if (_dataReady) _startFade();
        });
      } else {
        setState(() => _phase = _Phase.resolved);
      }
    });
  }

  void _sync() {
    if (_loading) return; // still waiting — timers drive the transitions
    switch (_phase) {
      case _Phase.blank:
        _showTimer?.cancel();
        _showTimer = null;
        setState(() => _phase = _Phase.resolved); // happy path, no fade
      case _Phase.skeleton:
        _dataReady = true;
        if (_floorElapsed) _startFade();
      case _Phase.fading:
      case _Phase.resolved:
        break;
    }
  }

  void _startFade() {
    if (_phase == _Phase.fading || _phase == _Phase.resolved) return;
    setState(() => _phase = _Phase.fading);
    final animate = !MediaQuery.disableAnimationsOf(context);
    _fade.duration = animate ? SkeletonTiming.fade : Duration.zero;
    _fade.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _phase = _Phase.resolved);
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _floorTimer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  Widget _resolved(BuildContext context) {
    final value = widget.value;
    if (value.hasValue) return widget.data(context, value.requireValue);
    if (value.hasError) {
      return widget.error?.call(context, value.error!, value.stackTrace) ??
          Center(child: Text('${value.error}'));
    }
    return const SizedBox.expand();
  }

  Widget _surface(BuildContext context) => _SkeletonSurface(
    semanticsLabel: widget.semanticsLabel,
    child: widget.skeleton(context),
  );

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.blank:
        return const SizedBox.expand();
      case _Phase.skeleton:
        return _surface(context);
      case _Phase.fading:
        return Stack(
          fit: StackFit.expand,
          children: [
            _resolved(context),
            IgnorePointer(
              child: FadeTransition(
                opacity: _fade.drive(
                  Tween<double>(
                    begin: 1,
                    end: 0,
                  ).chain(CurveTween(curve: SkeletonTiming.fadeCurve)),
                ),
                child: _surface(context),
              ),
            ),
          ],
        );
      case _Phase.resolved:
        return _resolved(context);
    }
  }
}
