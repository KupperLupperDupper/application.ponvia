import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Reverse-chronological history with a trend chart and a range switcher.
/// Tap a row to edit; swipe to delete.
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
    final fmt = WeightFormatter(settings.unit, locale: settings.localeCode);
    final dateFmt = PonviaDateFormatter(locale: settings.localeCode);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          if (all.isEmpty) {
            return Center(
              child: Text(l10n.historyEmpty,
                  style: Theme.of(context).textTheme.bodyLarge),
            );
          }
          final cutoff = _range.duration == null
              ? null
              : DateTime.now().subtract(_range.duration!);
          final inRange = cutoff == null
              ? all
              : all.where((e) => e.timestamp.isAfter(cutoff)).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(Insets.screenH),
                child: SegmentedButton<_Range>(
                  segments: [
                    for (final r in _Range.values)
                      ButtonSegment(value: r, label: Text(r.label(l10n))),
                  ],
                  selected: {_range},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _range = s.first),
                ),
              ),
              if (inRange.length >= 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Insets.screenH, 0, Insets.screenH, Insets.sm),
                  child: SizedBox(
                    height: 180,
                    child: _TrendChart(
                      entries: inRange,
                      unit: settings.unit,
                      fmt: fmt,
                      dateFmt: dateFmt,
                    ),
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: inRange.isEmpty
                    ? Center(
                        child: Text(l10n.historyEmptyRange,
                            style: Theme.of(context).textTheme.bodyMedium),
                      )
                    : ListView.separated(
                        itemCount: inRange.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final e = inRange[i];
                          final prev =
                              i + 1 < inRange.length ? inRange[i + 1] : null;
                          final deltaKg =
                              prev == null ? null : e.weightKg - prev.weightKg;
                          return Dismissible(
                            key: ValueKey(
                                e.id ?? e.timestamp.toIso8601String()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: Insets.xl),
                              child: const Icon(Icons.delete_outline),
                            ),
                            onDismissed: (_) async {
                              if (e.id != null) {
                                await ref
                                    .read(weightRepositoryProvider)
                                    .delete(e.id!);
                              }
                            },
                            child: ListTile(
                              onTap: () =>
                                  showLogWeightSheet(context, existing: e),
                              title: Text(fmt.withUnit(e.weightKg),
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(
                                [
                                  dateFmt.dateTime(e.timestamp),
                                  if (deltaKg != null) fmt.delta(deltaKg),
                                  if (e.note != null && e.note!.isNotEmpty)
                                    e.note!,
                                ].join('  ·  '),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
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
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${fmt.value(WeightConverter.toKg(s.y, unit))}\n'
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
              color: ponvia.chartArea.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
