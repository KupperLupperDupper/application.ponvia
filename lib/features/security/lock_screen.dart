import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/ui/spacing.dart';
import '../../l10n/app_localizations.dart';
import 'app_lock_controller.dart';
import 'pin_widgets.dart';

/// The launch lock. The Ponvia PIN is always the floor; when fingerprint is on,
/// the OS prompt fires automatically on top. A correct PIN or accepted
/// fingerprint goes straight to Home (the router redirects on unlock).
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with TickerProviderStateMixin, PinShakeMixin {
  String _entry = '';
  bool _wrong = false;
  bool _accepted = false;
  bool _waitingBiometric = false;

  // The "unlocked" flourish — the disc gives a soft bounce as the lock opens.
  late final AnimationController _acceptController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _discScale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45),
    TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55),
  ]).animate(_acceptController);

  @override
  void initState() {
    super.initState();
    // Auto-fire the fingerprint prompt after the entrance settles.
    if (ref.read(appLockControllerProvider).biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 300), _authBiometric);
      });
    }
  }

  @override
  void dispose() {
    _acceptController.dispose();
    disposeShake();
    super.dispose();
  }

  Future<void> _authBiometric() async {
    if (!mounted || _accepted) return;
    setState(() => _waitingBiometric = true);
    final l10n = AppLocalizations.of(context);
    var ok = false;
    try {
      ok = await LocalAuthentication().authenticate(
        localizedReason: l10n.appLockBiometricPromptTitle,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _waitingBiometric = false);
    if (ok) _unlock();
  }

  void _onKey(String d) {
    if (_entry.length >= 4 || _accepted) return;
    setState(() {
      _entry += d;
      _wrong = false;
    });
    if (_entry.length == 4) _verify();
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _verify() async {
    final ok = await ref.read(appLockControllerProvider.notifier).verify(_entry);
    if (!mounted) return;
    if (ok) {
      _unlock();
    } else {
      setState(() => _wrong = true);
      HapticFeedback.lightImpact();
      await shakeController.forward(from: 0);
      if (!mounted) return;
      setState(() => _entry = '');
    }
  }

  Future<void> _unlock() async {
    setState(() => _accepted = true);
    HapticFeedback.mediumImpact();
    _acceptController.forward(from: 0);
    // Let the lock-open crossfade + disc bounce play before handing off to Home.
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    ref.read(appLockControllerProvider.notifier).markUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final biometricOn = ref.watch(
        appLockControllerProvider.select((s) => s.biometricEnabled));

    final title = _accepted
        ? l10n.appLockUnlocking
        : _wrong
            ? l10n.appLockWrongPin
            : l10n.appLockEnterPin;
    final hint = _waitingBiometric
        ? l10n.appLockWaitingFingerprint
        : _wrong
            ? l10n.appLockWrongPin
            : l10n.appLockFourDigits;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Disc + (lock → lock_open) icon, with a soft bounce on unlock.
              ScaleTransition(
                scale: _discScale,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: scheme.primaryContainer, shape: BoxShape.circle),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(_accepted ? Icons.lock_open : Icons.lock,
                        key: ValueKey(_accepted),
                        size: 36,
                        color: scheme.onPrimaryContainer),
                  ),
                ),
              ),
              const SizedBox(height: Insets.lg),
              Text('PONVIA',
                  style: text.labelLarge?.copyWith(
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: Insets.xl),
              Text(title,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: Insets.lg),
              AnimatedBuilder(
                animation: shakeController,
                builder: (context, child) => Transform.translate(
                    offset: Offset(shakeOffset, 0), child: child),
                child: PinDots(filled: _entry.length, error: _wrong),
              ),
              const SizedBox(height: Insets.md),
              SizedBox(
                height: 20,
                child: Text(hint,
                    style: text.bodyMedium?.copyWith(
                        color:
                            _wrong ? scheme.error : scheme.onSurfaceVariant)),
              ),
              const Spacer(flex: 3),
              _LockKeypad(
                onKey: _onKey,
                onBackspace: _onBackspace,
                onBiometric: biometricOn ? _authBiometric : null,
              ),
              const SizedBox(height: Insets.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lock-screen keypad: 1–9, then [fingerprint (if enabled) · 0 · backspace].
class _LockKeypad extends StatelessWidget {
  const _LockKeypad({
    required this.onKey,
    required this.onBackspace,
    this.onBiometric,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) {
      final scheme = Theme.of(context).colorScheme;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: icon == null && label.isNotEmpty
                ? scheme.surfaceContainerHighest
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: icon == null && label.isNotEmpty
                  ? BorderSide(color: scheme.outline)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 64,
                child: Center(
                  child: icon != null
                      ? Icon(icon, size: 26, color: scheme.onSurface)
                      : Text(label,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(List<Widget> children) =>
        Row(children: children);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([for (final d in ['1', '2', '3']) key(d, onTap: () => onKey(d))]),
        row([for (final d in ['4', '5', '6']) key(d, onTap: () => onKey(d))]),
        row([for (final d in ['7', '8', '9']) key(d, onTap: () => onKey(d))]),
        row([
          onBiometric != null
              ? key('', onTap: onBiometric, icon: Icons.fingerprint)
              : key(''),
          key('0', onTap: () => onKey('0')),
          key('', onTap: onBackspace, icon: Icons.backspace_outlined),
        ]),
      ],
    );
  }
}
