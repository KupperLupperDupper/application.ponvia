import 'package:flutter/material.dart';

import '../../domain/goal_projection.dart';
import '../../domain/models/weight_entry.dart';
import '../../l10n/app_localizations.dart';
import '../formatting/date_formatter.dart';
import 'spacing.dart';

/// A muted one-line ETA ("At your recent pace · ~12 Oct") for the closest goal.
///
/// Renders **nothing** unless [projectGoalEta] returns a trustworthy date —
/// sparse, flat, noisy, or wrong-way trends collapse to [SizedBox.shrink], so
/// the app never shows a misleading estimate.
class GoalEtaLine extends StatelessWidget {
  const GoalEtaLine({
    super.key,
    required this.entries,
    required this.targetKg,
    this.color,
    this.topPadding = Insets.sm,
  });

  final List<WeightEntry> entries;
  final double targetKg;

  /// Overrides the text/icon colour (e.g. on the highlighted goal card, where
  /// the surface is a primary container). Defaults to `onSurfaceVariant`.
  final Color? color;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final projection = projectGoalEta(entries, targetKg);
    if (!projection.hasEta) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dateFmt = PonviaDateFormatter(
        locale: Localizations.localeOf(context).languageCode);
    final fg = color ?? scheme.onSurfaceVariant;
    final label = dateFmt.etaLabel(projection.etaDate!, DateTime.now());

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 15, color: fg),
          const SizedBox(width: Insets.xs),
          Flexible(
            child: Text(
              l10n.homeGoalEta(label),
              style: text.bodySmall?.copyWith(color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
