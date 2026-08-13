import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/spacing.dart';
import '../../l10n/app_localizations.dart';
import '../logging/numeric_keypad.dart';
import 'app_lock_controller.dart';
import 'pin_widgets.dart';

/// Asks for the current PIN and returns `true` once it verifies (used before
/// turning the lock off or changing the PIN). Returns `false`/`null` if cancelled.
Future<bool?> showVerifyPinSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => const _VerifyPinSheet(),
  );
}

class _VerifyPinSheet extends ConsumerStatefulWidget {
  const _VerifyPinSheet();

  @override
  ConsumerState<_VerifyPinSheet> createState() => _VerifyPinSheetState();
}

class _VerifyPinSheetState extends ConsumerState<_VerifyPinSheet>
    with SingleTickerProviderStateMixin, PinShakeMixin {
  String _entry = '';
  bool _wrong = false;

  @override
  void dispose() {
    disposeShake();
    super.dispose();
  }

  void _onKey(String d) {
    if (int.tryParse(d) == null || _entry.length >= 4) return;
    setState(() {
      _entry += d;
      _wrong = false;
    });
    if (_entry.length == 4) _verify();
  }

  void _onBackspace() {
    if (_entry.isNotEmpty) {
      setState(() => _entry = _entry.substring(0, _entry.length - 1));
    }
  }

  Future<void> _verify() async {
    final ok = await ref.read(appLockControllerProvider.notifier).verify(_entry);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
      HapticFeedback.lightImpact();
      await shakeController.forward(from: 0);
      if (!mounted) return;
      setState(() => _entry = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: Insets.screenH,
        right: Insets.screenH,
        bottom: Insets.xxl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.appLockEnterPin,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: Insets.lg),
          AnimatedBuilder(
            animation: shakeController,
            builder: (context, child) =>
                Transform.translate(offset: Offset(shakeOffset, 0), child: child),
            child: PinDots(filled: _entry.length, error: _wrong),
          ),
          const SizedBox(height: Insets.md),
          SizedBox(
            height: 20,
            child: Text(_wrong ? l10n.appLockWrongPin : '',
                style: text.bodyMedium?.copyWith(color: scheme.error)),
          ),
          const SizedBox(height: Insets.md),
          NumericKeypad(
              onKey: _onKey, onBackspace: _onBackspace, decimalSeparator: ''),
        ],
      ),
    );
  }
}
