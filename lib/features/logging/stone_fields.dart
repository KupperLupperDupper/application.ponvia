import 'package:flutter/material.dart';

import '../../app/theme/typography.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import 'stone_input.dart';

/// The two-column **stone + pounds** entry surface
/// (`design/handoff/STONE_ENTRY_WEEKLY_MULTI.md` §A, decision 3). Two layouts,
/// selected by [boxed]:
///
/// * `boxed == false` — the log sheet / onboarding: two 150×90 columns, 22dp
///   gap, 48sp value + 20sp suffix, a 2dp `primary` / 1dp `outline` underline.
/// * `boxed == true` — the goal sheet: two flex-1 bordered 64dp fields, 12dp
///   gap, 32sp value + 18sp suffix, a 2dp `primary` / 1dp `outline` border.
///
/// The whole column is the hit area, so a single-digit stone (which does not
/// auto-advance) can still reach pounds by tapping.
class StoneFields extends StatelessWidget {
  const StoneFields({
    super.key,
    required this.stone,
    required this.boxed,
    required this.onTapSt,
    required this.onTapLb,
  });

  final StoneInput stone;
  final bool boxed;
  final VoidCallback onTapSt;
  final VoidCallback onTapLb;

  @override
  Widget build(BuildContext context) {
    final stColumn = _StoneColumn(
      value: stone.st.isEmpty ? '0' : stone.st,
      suffix: WeightUnit.st.code,
      focused: !stone.focusLb,
      boxed: boxed,
      semanticLabel: 'Stone',
      onTap: onTapSt,
    );
    final lbColumn = _StoneColumn(
      value: stone.lb.isEmpty ? '0' : stone.lb,
      suffix: WeightUnit.lb.code,
      focused: stone.focusLb,
      boxed: boxed,
      semanticLabel: 'Pounds',
      onTap: onTapLb,
    );

    if (boxed) {
      return Row(
        children: [
          Expanded(child: stColumn),
          const SizedBox(width: Insets.cardGap), // 12dp
          Expanded(child: lbColumn),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        stColumn,
        const SizedBox(width: 22),
        lbColumn,
      ],
    );
  }
}

class _StoneColumn extends StatelessWidget {
  const _StoneColumn({
    required this.value,
    required this.suffix,
    required this.focused,
    required this.boxed,
    required this.semanticLabel,
    required this.onTap,
  });

  final String value;
  final String suffix;
  final bool focused;
  final bool boxed;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueSize = boxed ? 32.0 : 48.0;
    final suffixSize = boxed ? 18.0 : 20.0;
    final edgeColor = focused ? scheme.primary : scheme.outline;
    final edgeWidth = focused ? 2.0 : 1.0;

    final label = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: PonviaTypography.heroWeight.copyWith(
              fontSize: valueSize,
              letterSpacing: -0.03 * valueSize,
              color: scheme.onSurface,
            ),
          ),
          TextSpan(
            text: ' $suffix',
            style: TextStyle(
              fontFamily: PonviaTypography.family,
              fontSize: suffixSize,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    final Widget content;
    if (boxed) {
      content = Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: edgeColor, width: edgeWidth),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: label),
      );
    } else {
      content = SizedBox(
        width: 150,
        height: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: label),
            const SizedBox(height: Insets.sm),
            Container(width: 120, height: edgeWidth, color: edgeColor),
          ],
        ),
      );
    }

    return Semantics(
      label: '$semanticLabel, $value',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}

/// The live echo line under the stone fields (decision 6): while valid it shows
/// the composite `12 st 7 lb · 79.4 kg`; while dirty-and-invalid it shows the
/// range [helperText] (omit it — pass null — to stay blank when invalid, as in
/// onboarding). Pristine `0 st 0 lb` renders nothing.
class StoneEchoLine extends StatelessWidget {
  const StoneEchoLine({
    super.key,
    required this.stone,
    required this.locale,
    this.helperText,
  });

  final StoneInput stone;
  final String locale;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (stone.valid) {
      final kgLabel =
          WeightFormatter(WeightUnit.kg, locale: locale).withUnit(stone.kg);
      final echo = '${stone.stValue} st ${stone.lbValue} lb · $kgLabel';
      return Semantics(
        liveRegion: true,
        child: Text(
          echo,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    if (!stone.isEmpty && helperText != null) {
      return Semantics(
        liveRegion: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 16, color: scheme.error),
            const SizedBox(width: Insets.xs),
            Text(
              helperText!,
              style: text.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
