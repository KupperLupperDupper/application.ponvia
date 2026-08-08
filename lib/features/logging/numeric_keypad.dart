import 'package:flutter/material.dart';

import '../../app/theme/typography.dart';

/// A styled 3×4 numeric keypad (1–9, decimal, 0, backspace) that replaces the
/// OS keyboard for weight/goal entry. See DESIGN_SPEC §4.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    this.decimalSeparator = '.',
  });

  /// Called with the tapped digit ('0'–'9') or the decimal separator.
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final String decimalSeparator;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(context, ['1', '2', '3']),
        _row(context, ['4', '5', '6']),
        _row(context, ['7', '8', '9']),
        _row(context, [decimalSeparator, '0', '⌫']),
      ],
    );
  }

  Widget _row(BuildContext context, List<String> keys) {
    return Row(
      children: [
        for (final k in keys)
          Expanded(
            child: _Key(
              label: k,
              onTap: k == '⌫' ? onBackspace : () => onKey(k),
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBackspace = label == '⌫';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 56,
        child: Center(
          child: isBackspace
              ? Icon(Icons.backspace_outlined,
                  size: 24, color: scheme.onSurfaceVariant)
              : Text(
                  label,
                  style: const TextStyle(
                    fontFamily: PonviaTypography.family,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
