import 'package:flutter/material.dart';

import '../../core/ui/spacing.dart';
import '../../l10n/app_localizations.dart';
import '../logging/numeric_keypad.dart';
import 'pin_widgets.dart';

/// Two-step "choose a PIN, then confirm it" flow. Shown via `Navigator.push`;
/// pops with the confirmed 4-digit PIN string, or `null` if cancelled. Used both
/// to enable the lock and to change the PIN.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  static Future<String?> show(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push<String>(
          MaterialPageRoute(builder: (_) => const SetPinScreen()));

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen>
    with SingleTickerProviderStateMixin, PinShakeMixin {
  bool _confirming = false;
  String _first = '';
  String _entry = '';
  bool _error = false;

  @override
  void dispose() {
    disposeShake();
    super.dispose();
  }

  void _onKey(String k) {
    if (int.tryParse(k) == null || _entry.length >= 4) return;
    setState(() {
      _entry += k;
      _error = false;
    });
    if (_entry.length == 4) _advance();
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _advance() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    if (!_confirming) {
      setState(() {
        _first = _entry;
        _entry = '';
        _confirming = true;
      });
      return;
    }
    if (_entry == _first) {
      Navigator.of(context).pop(_first);
    } else {
      setState(() => _error = true);
      await shakeController.forward(from: 0);
      if (!mounted) return;
      setState(() {
        _entry = '';
        _first = '';
        _confirming = false;
        _error = true; // keep the mismatch hint until the next key
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final title = _confirming ? l10n.appLockConfirmPin : l10n.appLockChoosePin;
    final hint = _error && !_confirming
        ? l10n.appLockPinMismatch
        : _confirming
            ? l10n.appLockConfirmPinBody
            : '';

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(title,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: Insets.md),
            AnimatedBuilder(
              animation: shakeController,
              builder: (context, child) =>
                  Transform.translate(offset: Offset(shakeOffset, 0), child: child),
              child: PinDots(filled: _entry.length, error: _error),
            ),
            const SizedBox(height: Insets.md),
            SizedBox(
              height: 24,
              child: Text(hint,
                  style: text.bodyMedium?.copyWith(
                      color: _error ? scheme.error : scheme.onSurfaceVariant)),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.screenH, 0, Insets.screenH, Insets.xl),
              child: NumericKeypad(
                onKey: _onKey,
                onBackspace: _onBackspace,
                decimalSeparator: '',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
