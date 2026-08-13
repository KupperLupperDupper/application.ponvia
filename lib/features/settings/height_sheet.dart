import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/typography.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../l10n/app_localizations.dart';
import '../logging/numeric_keypad.dart';

/// Opens the optional-height entry sheet (DESIGN_SPEC `HEIGHT_BMI_APPLOCK.md`
/// §1). Metric users type one cm field; imperial users (lb/st) type ft + in and
/// see the cm it's stored as. Height is canonical **cm** (100–250).
Future<void> showHeightSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => const _HeightForm(),
  );
}

const int _cmMin = 100;
const int _cmMax = 250;

int _ftInToCm(int ft, int inches) => ((ft * 12 + inches) * 2.54).round();

(int ft, int inches) _cmToFtIn(int cm) {
  final totalIn = (cm / 2.54).round();
  return (totalIn ~/ 12, totalIn % 12);
}

class _HeightForm extends ConsumerStatefulWidget {
  const _HeightForm();

  @override
  ConsumerState<_HeightForm> createState() => _HeightFormState();
}

class _HeightFormState extends ConsumerState<_HeightForm> {
  late final bool _imperial;
  String _cm = '';
  String _ft = '';
  String _in = '';
  bool _focusIn = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsControllerProvider);
    _imperial = s.unit != WeightUnit.kg;
    final existing = s.heightCm;
    if (existing != null) {
      if (_imperial) {
        final (ft, inches) = _cmToFtIn(existing);
        _ft = '$ft';
        _in = '$inches';
        _focusIn = true;
      } else {
        _cm = '$existing';
      }
    }
  }

  bool get _hasExisting => ref.read(settingsControllerProvider).heightCm != null;

  int? get _cmValue {
    if (_imperial) {
      final ft = int.tryParse(_ft);
      if (ft == null) return null;
      return _ftInToCm(ft, int.tryParse(_in) ?? 0);
    }
    return int.tryParse(_cm);
  }

  bool get _valid {
    final cm = _cmValue;
    return cm != null && cm >= _cmMin && cm <= _cmMax;
  }

  void _onKey(String k) {
    if (int.tryParse(k) == null) return; // ignore the keypad's decimal key
    setState(() {
      if (!_imperial) {
        if (_cm.length < 3) _cm += k;
        return;
      }
      if (!_focusIn) {
        _ft = k; // ft is a single digit, then auto-advance to inches
        _focusIn = true;
      } else {
        final next = _in + k;
        if (next.length <= 2 && (int.tryParse(next) ?? 99) <= 11) _in = next;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (!_imperial) {
        if (_cm.isNotEmpty) _cm = _cm.substring(0, _cm.length - 1);
        return;
      }
      if (_focusIn) {
        if (_in.isNotEmpty) {
          _in = _in.substring(0, _in.length - 1);
        } else {
          _focusIn = false; // backspace at the start of inches returns to ft
        }
      } else if (_ft.isNotEmpty) {
        _ft = '';
      }
    });
  }

  Future<void> _save() async {
    final cm = _cmValue;
    if (cm == null || !_valid) return;
    setState(() => _saving = true);
    await ref.read(settingsControllerProvider.notifier).setHeight(cm);
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _remove() async {
    await ref.read(settingsControllerProvider.notifier).setHeight(null);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cm = _cmValue;

    return Padding(
      padding: EdgeInsets.only(
        left: Insets.screenH,
        right: Insets.screenH,
        bottom: Insets.xxl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.heightLabel,
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          Center(
            child: _imperial
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ValueField(
                          value: _ft.isEmpty ? '0' : _ft,
                          unit: 'ft',
                          focused: !_focusIn),
                      const SizedBox(width: 20),
                      _ValueField(
                          value: _in.isEmpty ? '0' : _in,
                          unit: 'in',
                          focused: _focusIn),
                    ],
                  )
                : _ValueField(
                    value: _cm.isEmpty ? '0' : _cm, unit: 'cm', focused: true),
          ),
          const SizedBox(height: Insets.sm),
          SizedBox(
            height: 20,
            child: Center(
              child: _imperial && cm != null
                  ? Text(l10n.heightStoredAs(cm),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant))
                  : Text(l10n.heightSheetNote,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ),
          const SizedBox(height: Insets.md),
          NumericKeypad(onKey: _onKey, onBackspace: _onBackspace),
          const SizedBox(height: Insets.sm),
          FilledButton(
            onPressed: (_valid && !_saving) ? _save : null,
            child: Text(l10n.actionSave),
          ),
          if (_hasExisting)
            TextButton(
              onPressed: _remove,
              child: Text(l10n.heightRemove),
            ),
        ],
      ),
    );
  }
}

class _ValueField extends StatelessWidget {
  const _ValueField(
      {required this.value, required this.unit, required this.focused});

  final String value;
  final String unit;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: value,
              style: PonviaTypography.heroWeight
                  .copyWith(fontSize: 48, color: scheme.onSurface),
            ),
            TextSpan(
              text: ' $unit',
              style: TextStyle(
                fontFamily: PonviaTypography.family,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ]),
        ),
        const SizedBox(height: Insets.sm),
        Container(
          width: 120,
          height: 2,
          color: focused ? scheme.primary : scheme.outline,
        ),
      ],
    );
  }
}
