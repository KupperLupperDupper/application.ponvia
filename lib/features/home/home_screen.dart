import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/ponvia_colors.dart';
import '../../app/theme/typography.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/weight_entry.dart';
import '../../l10n/app_localizations.dart';
import '../logging/log_weight_screen.dart';

/// The weight-first dashboard: hero last weight, delta vs previous, a recent
/// trend sparkline, and progress toward the highlighted goal.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final entriesAsync = ref.watch(entriesProvider);
    final closest = ref.watch(closestGoalProvider);
    final fmt = WeightFormatter(settings.unit, locale: settings.localeCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Ponvia')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogWeightSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.homeLogWeight),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) {
          if (entries.isEmpty) return const _EmptyHome();
          final latest = entries.first;
          final deltaKg =
              entries.length >= 2 ? latest.weightKg - entries[1].weightKg : null;
          return ListView(
            padding: const EdgeInsets.all(Insets.screenH),
            children: [
              _HeroCard(
                entry: latest,
                fmt: fmt,
                deltaKg: deltaKg,
                unit: settings.unit,
                recent: entries,
              ),
              if (closest != null) ...[
                const SizedBox(height: Insets.cardGap),
                _GoalCard(
                  targetKg: closest.targetWeightKg,
                  currentKg: latest.weightKg,
                  startKg: entries.last.weightKg,
                  label: closest.label,
                  fmt: fmt,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.entry,
    required this.fmt,
    required this.unit,
    required this.recent,
    this.deltaKg,
  });

  final WeightEntry entry;
  final WeightFormatter fmt;
  final WeightUnit unit;
  final List<WeightEntry> recent;
  final double? deltaKg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ponvia = Theme.of(context).extension<PonviaColors>()!;
    final dateFmt = PonviaDateFormatter(locale: Localizations.localeOf(context).languageCode);
    final daysAgo = PonviaDateFormatter.daysAgo(entry.timestamp, DateTime.now());
    final when = daysAgo == 0
        ? l10n.today
        : daysAgo == 1
            ? l10n.yesterday
            : dateFmt.date(entry.timestamp);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homeLatestWeight,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: Insets.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                fmt.value(entry.weightKg),
                style:
                    PonviaTypography.heroWeight.copyWith(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: Insets.sm),
            Row(
              children: [
                Text(when, style: Theme.of(context).textTheme.bodyLarge),
                if (deltaKg != null) ...[
                  const SizedBox(width: Insets.md),
                  _DeltaChip(deltaKg: deltaKg!, fmt: fmt, ponvia: ponvia),
                ],
              ],
            ),
            if (recent.length >= 2) ...[
              const SizedBox(height: Insets.lg),
              SizedBox(
                height: 68,
                child: _Sparkline(entries: recent, unit: unit, color: ponvia),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Minimal trend line for the Home hero: no axes, no grid, newest point dotted.
class _Sparkline extends StatelessWidget {
  const _Sparkline({
    required this.entries,
    required this.unit,
    required this.color,
  });

  final List<WeightEntry> entries; // newest-first
  final WeightUnit unit;
  final PonviaColors color;

  @override
  Widget build(BuildContext context) {
    final recent = entries.take(30).toList().reversed.toList();
    final spots = <FlSpot>[
      for (var i = 0; i < recent.length; i++)
        FlSpot(i.toDouble(), WeightConverter.fromKg(recent[i].weightKg, unit)),
    ];
    final lastX = (recent.length - 1).toDouble();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: color.chartLine,
            barWidth: 2.5,
            dotData: FlDotData(
              checkToShowDot: (spot, _) => spot.x == lastX,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 3.5,
                color: color.chartLine,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.chartArea.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.deltaKg,
    required this.fmt,
    required this.ponvia,
  });

  final double deltaKg;
  final WeightFormatter fmt;
  final PonviaColors ponvia;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = deltaKg < 0
        ? (ponvia.deltaDown, Icons.arrow_downward)
        : deltaKg > 0
            ? (ponvia.deltaUp, Icons.arrow_upward)
            : (ponvia.deltaFlat, Icons.remove);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Insets.xs),
        Text(
          fmt.delta(deltaKg),
          style:
              Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.targetKg,
    required this.currentKg,
    required this.startKg,
    required this.fmt,
    this.label,
  });

  final double targetKg;
  final double currentKg;
  final double startKg;
  final String? label;
  final WeightFormatter fmt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remainingKg = (targetKg - currentKg).abs();
    final remainingText = targetKg < currentKg
        ? l10n.goalToLose(fmt.withUnit(remainingKg))
        : l10n.goalToGain(fmt.withUnit(remainingKg));
    final span = startKg - targetKg;
    final progress = span == 0
        ? (currentKg == targetKg ? 1.0 : 0.0)
        : ((startKg - currentKg) / span).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 20),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(label ?? l10n.homeClosestGoal,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(l10n.homeTarget(fmt.withUnit(targetKg)),
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: Insets.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: Insets.sm),
            Text(remainingText, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monitor_weight_outlined, size: 64),
            const SizedBox(height: Insets.lg),
            Text(l10n.homeEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            Text(
              l10n.homeEmptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
