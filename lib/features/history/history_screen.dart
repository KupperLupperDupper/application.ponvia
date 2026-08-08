import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme/ponvia_colors.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/weight_entry.dart';
import '../../l10n/app_localizations.dart';
import '../logging/log_weight_screen.dart';

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
              if (inRange.length >= 2)
                _ChartCard(
                  entries: inRange,
                  unit: settings.unit,
                  fmt: fmt,
                  dateFmt: dateFmt,
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
          if (e.id != null) await ref.read(weightRepositoryProvider).delete(e.id!);
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.entries,
    required this.unit,
    required this.fmt,
    required this.dateFmt,
  });

  final List<WeightEntry> entries;
  final WeightUnit unit;
  final WeightFormatter fmt;
  final PonviaDateFormatter dateFmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.md, Insets.md),
      child: SizedBox(
        height: 170,
        child: _TrendChart(
            entries: entries, unit: unit, fmt: fmt, dateFmt: dateFmt),
      ),
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
  });

  final List<WeightEntry> entries; // newest-first
  final WeightUnit unit;
  final WeightFormatter fmt;
  final PonviaDateFormatter dateFmt;

  @override
  Widget build(BuildContext context) {
    final ponvia = Theme.of(context).extension<PonviaColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final chrono = entries.reversed.toList();
    final values = [
      for (final e in chrono) WeightConverter.fromKg(e.weightKg, unit),
    ];
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxV - minV) * 0.15).clamp(0.5, double.infinity);
    final labelEvery = (chrono.length / 4).ceil().clamp(1, chrono.length);

    return LineChart(
      LineChartData(
        minY: minV - pad,
        maxY: maxV + pad,
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
              reservedSize: 34,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: labelEvery.toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= chrono.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: Insets.xs),
                  child: Text(
                    dateFmt.date(chrono[i].timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant, letterSpacing: 0),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.primary,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${fmt.value(WeightConverter.toKg(s.y, unit))} · '
                  '${dateFmt.date(chrono[s.x.round()].timestamp)}',
                  TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
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
            dotData: const FlDotData(show: false),
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
        ],
      ),
    );
  }
}
