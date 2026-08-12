import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme/ponvia_colors.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/ui/undo_snackbar.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/weight_entry.dart';
import '../../domain/range_stats.dart';
import '../../domain/trend_weight.dart';
import '../../l10n/app_localizations.dart';
import '../logging/log_weight_screen.dart';
import 'trend_bounds.dart';

enum _Range {
  week(Duration(days: 7)),
  month(Duration(days: 31)),
  threeMonths(Duration(days: 93)),
  year(Duration(days: 366)),
  all(null);

  const _Range(this.duration);
  final Duration? duration;

  String label(AppLocalizations l10n) => switch (this) {
        _Range.week => l10n.range1W,
        _Range.month => l10n.range1M,
        _Range.threeMonths => l10n.range3M,
        _Range.year => l10n.range1Y,
        _Range.all => l10n.rangeAll,
      };
}

/// History: a trend chart in a card, then month-grouped entry rows. Styled to
/// DESIGN_SPEC §5. Tap a row to edit; swipe to delete.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Range _range = _Range.month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final entriesAsync = ref.watch(entriesProvider);
    // Closest unachieved goal (null when none / no weight yet) → marker line.
    final goalTargetKg = ref.watch(closestGoalProvider)?.targetWeightKg;
    final fmt = WeightFormatter(settings.unit, locale: Localizations.localeOf(context).languageCode);
    final dateFmt = PonviaDateFormatter(locale: Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          if (all.isEmpty) return _EmptyHistory(l10n: l10n);
          final cutoff = _range.duration == null
              ? null
              : DateTime.now().subtract(_range.duration!);
          final inRange = cutoff == null
              ? all
              : all.where((e) => e.timestamp.isAfter(cutoff)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                Insets.screenH, Insets.md, Insets.screenH, 96),
            children: [
              SegmentedButton<_Range>(
                segments: [
                  for (final r in _Range.values)
                    ButtonSegment(value: r, label: Text(r.label(l10n))),
                ],
                selected: {_range},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _range = s.first),
              ),
              const SizedBox(height: Insets.lg),
              if (inRange.isNotEmpty) ...[
                _SummaryCard(
                  stats: computeRangeStats(inRange)!,
                  fmt: fmt,
                ),
                const SizedBox(height: Insets.md),
              ],
              if (inRange.length >= 2)
                _ChartCard(
                  entries: inRange,
                  unit: settings.unit,
                  fmt: fmt,
                  dateFmt: dateFmt,
                  goalTargetKg: goalTargetKg,
                ),
              if (inRange.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.xxxl),
                  child: Center(
                    child: Text(l10n.historyEmptyRange,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                ..._buildRows(context, inRange, fmt, dateFmt, settings.unit),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildRows(BuildContext context, List<WeightEntry> entries,
      WeightFormatter fmt, PonviaDateFormatter dateFmt, WeightUnit unit) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final monthFmt =
        DateFormat.yMMMM(Localizations.localeOf(context).languageCode);
    final rows = <Widget>[];
    int? lastMonthKey;

    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final monthKey = e.timestamp.year * 100 + e.timestamp.month;
      if (monthKey != lastMonthKey) {
        lastMonthKey = monthKey;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(Insets.xs, Insets.lg, 0, Insets.sm),
          child: Text(monthFmt.format(e.timestamp).toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant)),
        ));
      }
      final prev = i + 1 < entries.length ? entries[i + 1] : null;
      final deltaKg = prev == null ? null : e.weightKg - prev.weightKg;
      final relDay = PonviaDateFormatter.daysAgo(e.timestamp, DateTime.now());
      final when = relDay == 0
          ? l10n.today
          : relDay == 1
              ? l10n.yesterday
              : dateFmt.date(e.timestamp);

      rows.add(Dismissible(
        key: ValueKey(e.id ?? e.timestamp.toIso8601String()),
        direction: DismissDirection.endToStart,
        background: Container(
          color: scheme.errorContainer,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: Insets.xl),
          child: const Icon(Icons.delete_outline),
        ),
        onDismissed: (_) async {
          final repo = ref.read(weightRepositoryProvider);
          if (e.id != null) await repo.delete(e.id!);
          if (!context.mounted) return;
          showUndoSnackbar(
            context,
            message: l10n.snackbarEntryDeleted,
            undoLabel: l10n.actionUndo,
            icon: Icons.delete_outline,
            onUndo: () => repo.add(WeightEntry(
                timestamp: e.timestamp, weightKg: e.weightKg, note: e.note)),
          );
        },
        child: _EntryRow(
          title: '$when · ${dateFmt.time(e.timestamp)}',
          note: e.note,
          value: fmt.withUnit(e.weightKg),
          deltaKg: deltaKg,
          fmt: fmt,
          onTap: () => showLogWeightSheet(context, existing: e),
        ),
      ));
    }
    return rows;
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.title,
    required this.note,
    required this.value,
    required this.deltaKg,
    required this.fmt,
    required this.onTap,
  });

  final String title;
  final String? note;
  final String value;
  final double? deltaKg;
  final WeightFormatter fmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ponvia = Theme.of(context).extension<PonviaColors>()!;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: Insets.md, horizontal: Insets.xs),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  if (note != null && note!.isNotEmpty)
                    Text(note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: Insets.md),
            Text(value,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: Insets.md),
            SizedBox(width: 62, child: _DeltaCell(deltaKg: deltaKg, fmt: fmt, ponvia: ponvia)),
          ],
        ),
      ),
    );
  }
}

class _DeltaCell extends StatelessWidget {
  const _DeltaCell(
      {required this.deltaKg, required this.fmt, required this.ponvia});

  final double? deltaKg;
  final WeightFormatter fmt;
  final PonviaColors ponvia;

  @override
  Widget build(BuildContext context) {
    if (deltaKg == null) return const SizedBox.shrink();
    final d = deltaKg!;
    final (Color color, IconData icon) = d < 0
        ? (ponvia.deltaDown, Icons.arrow_downward)
        : d > 0
            ? (ponvia.deltaUp, Icons.arrow_upward)
            : (ponvia.deltaFlat, Icons.remove);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 2),
        Text(fmt.magnitudeShort(d.abs()),
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: color)),
      ],
    );
  }
}

/// Compact stats for the selected range: min / avg / max plus a net-change chip
/// (latest − earliest weight). Rendered above the chart. DESIGN_SPEC §5 language
/// — same card shell as [_ChartCard] and the Home hero's delta chip.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats, required this.fmt});

  final RangeStats stats;
  final WeightFormatter fmt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ponvia = Theme.of(context).extension<PonviaColors>()!;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline),
      ),
      padding:
          const EdgeInsets.fromLTRB(Insets.xl, Insets.lg, Insets.lg, Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.historySummaryEyebrow,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: Insets.sm),
              _NetChip(netKg: stats.netKg, fmt: fmt, ponvia: ponvia),
            ],
          ),
          const SizedBox(height: Insets.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _StatCell(
                      label: l10n.statMin, value: fmt.withUnit(stats.minKg))),
              Expanded(
                  child: _StatCell(
                      label: l10n.statAvg, value: fmt.withUnit(stats.avgKg))),
              Expanded(
                  child: _StatCell(
                      label: l10n.statMax, value: fmt.withUnit(stats.maxKg))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: text.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.4)),
        const SizedBox(height: Insets.xs),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// Net change as a filled chip, mirroring the Home hero's delta chip: green for
/// a decrease, ochre for an increase, neutral for no change. Icon + word carry
/// the direction so colour is never the only signal.
class _NetChip extends StatelessWidget {
  const _NetChip(
      {required this.netKg, required this.fmt, required this.ponvia});

  final double netKg;
  final WeightFormatter fmt;
  final PonviaColors ponvia;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final amount = fmt.withUnit(netKg.abs());

    final (Color bg, Color fg, IconData icon, String label) = netKg < 0
        ? (
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
            Icons.arrow_downward,
            l10n.homeDeltaDown(amount)
          )
        : netKg > 0
            ? (
                ponvia.deltaUpContainer,
                ponvia.onDeltaUpContainer,
                Icons.arrow_upward,
                l10n.homeDeltaUp(amount)
              )
            : (
                scheme.surfaceContainer,
                scheme.onSurfaceVariant,
                Icons.remove,
                l10n.homeDeltaFlat
              );

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: Insets.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: Insets.xs),
          Text(label,
              style:
                  Theme.of(context).textTheme.labelLarge?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.entries,
    required this.unit,
    required this.fmt,
    required this.dateFmt,
    required this.goalTargetKg,
  });

  final List<WeightEntry> entries;
  final WeightUnit unit;
  final WeightFormatter fmt;
  final PonviaDateFormatter dateFmt;
  final double? goalTargetKg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ponvia = Theme.of(context).extension<PonviaColors>()!;
    // Legend appears only when the trend line does (see TrendWeight.minRenderPoints).
    final showLegend = entries.length >= TrendWeight.minRenderPoints;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.md, Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLegend)
            Padding(
              padding: const EdgeInsets.only(right: Insets.xs, bottom: Insets.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LegendItem(
                      color: ponvia.chartLine, label: l10n.chartLegendWeight),
                  const SizedBox(width: Insets.md),
                  _LegendItem(
                      color: scheme.onSurfaceVariant,
                      label: l10n.chartLegendTrend),
                ],
              ),
            ),
          SizedBox(
            height: 170,
            child: _TrendChart(
                entries: entries,
                unit: unit,
                fmt: fmt,
                dateFmt: dateFmt,
                goalTargetKg: goalTargetKg),
          ),
        ],
      ),
    );
  }
}

/// A single dot + label used in the chart legend.
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: Insets.xs),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant, letterSpacing: 0)),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                  color: scheme.surfaceContainer, shape: BoxShape.circle),
              child: Icon(Icons.show_chart, size: 40, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.xl),
            Text(l10n.historyEmpty, style: text.headlineMedium),
          ],
        ),
      ),
    );
  }
}

/// Full trend chart: horizontal grid, date axis, touch tooltip.
class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.entries,
    required this.unit,
    required this.fmt,
    required this.dateFmt,
    required this.goalTargetKg,
  });

  final List<WeightEntry> entries; // newest-first
  final WeightUnit unit;
  final WeightFormatter fmt;
  final PonviaDateFormatter dateFmt;
  final double? goalTargetKg;

  @override
  Widget build(BuildContext context) {
    final ponvia = Theme.of(context).extension<PonviaColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final axisDate =
        DateFormat.MMMd(Localizations.localeOf(context).languageCode);
    final chrono = entries.reversed.toList();
    final values = [
      for (final e in chrono) WeightConverter.fromKg(e.weightKg, unit),
    ];
    // Time-based x-axis (normalized to start at 0 so labels align to the data).
    final minXms = chrono.first.timestamp.millisecondsSinceEpoch.toDouble();
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        FlSpot(chrono[i].timestamp.millisecondsSinceEpoch - minXms, values[i]),
    ];
    // Goal target in the display unit (like the series); folded into the
    // y-range so the marker line is visible even when it sits off the data.
    final goalTarget = goalTargetKg == null
        ? null
        : WeightConverter.fromKg(goalTargetKg!, unit);
    final bounds = TrendBounds.of(values, target: goalTarget);
    // Smoothed "trend weight" overlay: EMA in canonical kg, converted for
    // display and pinned to the raw spots' x-coordinates so the two align.
    final showTrend = chrono.length >= TrendWeight.minRenderPoints;
    final trendKg = TrendWeight.ema([for (final e in chrono) e.weightKg]);
    final trendSpots = <FlSpot>[
      for (var i = 0; i < chrono.length; i++)
        FlSpot(spots[i].x, WeightConverter.fromKg(trendKg[i], unit)),
    ];
    final maxX = spots.last.x;
    final xInterval = maxX <= 0 ? 1.0 : maxX / 2;
    final yInterval = bounds.interval;
    final yDecimals = bounds.decimals;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: bounds.minY,
        maxY: bounds.maxY,
        extraLinesData: goalTarget == null
            ? const ExtraLinesData()
            : ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: goalTarget,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    strokeWidth: 1.5,
                    dashArray: const [6, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 4, bottom: 3),
                      labelResolver: (_) =>
                          l10n.homeTarget(fmt.withUnit(goalTargetKg!)),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                ],
              ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: ponvia.chartGrid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: yInterval,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toStringAsFixed(yDecimals),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant, letterSpacing: 0),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final dt = DateTime.fromMillisecondsSinceEpoch(
                    (value + minXms).toInt());
                return SideTitleWidget(
                  meta: meta,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(
                    axisDate.format(dt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant, letterSpacing: 0),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          // No indicator dot/line on the trend bar — keep touch feedback on the
          // raw series only.
          getTouchedSpotIndicator: (barData, indexes) => [
            for (final _ in indexes)
              identical(barData.spots, trendSpots)
                  ? null
                  : TouchedSpotIndicatorData(
                      FlLine(
                          color: ponvia.chartLine.withValues(alpha: 0.4),
                          strokeWidth: 2),
                      const FlDotData(show: false),
                    ),
          ],
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.primary,
            // Only the raw series carries a tooltip; the trend bar (barIndex 1)
            // returns null so a tap shows one clean `value · date`.
            getTooltipItems: (touchedSpots) => [
              for (final s in touchedSpots)
                if (s.barIndex == 0)
                  LineTooltipItem(
                    '${fmt.value(WeightConverter.toKg(s.y, unit))} · '
                    '${dateFmt.date(chrono[s.spotIndex].timestamp)}',
                    TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  )
                else
                  null,
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: ponvia.chartLine,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                  radius: 3, color: ponvia.chartLine, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ponvia.chartArea.withValues(alpha: 0.45),
                  ponvia.chartArea.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Trend line: thin, neutral, dotless, painted over the raw fill.
          if (showTrend)
            LineChartBarData(
              spots: trendSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: scheme.onSurfaceVariant,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }
}
