import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// The weight-first dashboard, styled to `design/handoff/DESIGN_SPEC.md` §3:
/// hero card (eyebrow, value, delta pill, sparkline + footer), goal card with
/// progress, and a reserved dashed second-metric slot.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final entriesAsync = ref.watch(entriesProvider);
    final closest = ref.watch(closestGoalProvider);
    final fmt = WeightFormatter(settings.unit, locale: Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ponvia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
          const SizedBox(width: Insets.xs),
        ],
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
            padding: const EdgeInsets.fromLTRB(
                Insets.screenH, Insets.sm, Insets.screenH, 96),
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
                  fmt: fmt,
                ),
              ],
              const SizedBox(height: Insets.cardGap),
              const _SecondMetricSlot(),
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
    final text = Theme.of(context).textTheme;
    final dateFmt =
        PonviaDateFormatter(locale: Localizations.localeOf(context).languageCode);
    final now = DateTime.now();
    final daysAgo = PonviaDateFormatter.daysAgo(entry.timestamp, now);
    final when = daysAgo == 0
        ? l10n.today
        : daysAgo == 1
            ? l10n.yesterday
            : dateFmt.date(entry.timestamp);

    // Trend window for the footer.
    final window = recent.take(30).toList();
    final oldest = window.last;
    final totalKg = entry.weightKg - oldest.weightKg;
    final spanDays = (entry.timestamp.difference(oldest.timestamp).inDays) + 1;

    return _PanelCard(
      radius: 28,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(Insets.xl, Insets.xxl, Insets.xl, Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.homeLatestWeight.toUpperCase(),
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Insets.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _HeroValue(kg: entry.weightKg, fmt: fmt, unit: unit),
          ),
          const SizedBox(height: Insets.lg),
          Row(
            children: [
              Text('$when · ${dateFmt.time(entry.timestamp)}',
                  style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: Insets.md),
              if (deltaKg != null)
                _DeltaChip(deltaKg: deltaKg!, fmt: fmt, ponvia: ponvia),
            ],
          ),
          if (recent.length >= 2) ...[
            const SizedBox(height: Insets.lg),
            SizedBox(
                height: 68,
                child: _Sparkline(entries: recent, unit: unit, color: ponvia)),
            const SizedBox(height: Insets.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.homeTrendFooter(spanDays),
                    style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w600)),
                Text(fmt.delta(totalKg),
                    style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Hero number with a baseline-aligned unit suffix (kg/lb). Stone already
/// carries its own unit words, so no suffix is appended.
class _HeroValue extends StatelessWidget {
  const _HeroValue({required this.kg, required this.fmt, required this.unit});

  final double kg;
  final WeightFormatter fmt;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = PonviaTypography.heroWeight.copyWith(
      color: scheme.onSurface,
      fontSize: unit == WeightUnit.st ? 56 : 72,
    );
    if (unit == WeightUnit.st) {
      return Text(fmt.value(kg), style: base);
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: fmt.value(kg), style: base),
        TextSpan(
          text: ' ${unit.code}',
          style: TextStyle(
            fontFamily: PonviaTypography.family,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ]),
    );
  }
}

/// Delta pill: icon + word + amount, colour paired with an icon+word so colour
/// is never the sole signal (accessibility).
class _DeltaChip extends StatelessWidget {
  const _DeltaChip(
      {required this.deltaKg, required this.fmt, required this.ponvia});

  final double deltaKg;
  final WeightFormatter fmt;
  final PonviaColors ponvia;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final amount = fmt.withUnit(deltaKg.abs());

    final (Color bg, Color fg, IconData icon, String label) = deltaKg < 0
        ? (
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
            Icons.arrow_downward,
            l10n.homeDeltaDown(amount)
          )
        : deltaKg > 0
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
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline(
      {required this.entries, required this.unit, required this.color});

  final List<WeightEntry> entries; // newest-first
  final WeightUnit unit;
  final PonviaColors color;

  @override
  Widget build(BuildContext context) {
    final recent = entries.take(30).toList().reversed.toList();
    final minMs = recent.first.timestamp.millisecondsSinceEpoch.toDouble();
    final spots = <FlSpot>[
      for (var i = 0; i < recent.length; i++)
        FlSpot(recent[i].timestamp.millisecondsSinceEpoch - minMs,
            WeightConverter.fromKg(recent[i].weightKg, unit)),
    ];
    final lastX = spots.last.x;

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
                  radius: 4.5, color: color.chartLine, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.chartArea.withValues(alpha: 0.45),
                  color.chartArea.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.targetKg,
    required this.currentKg,
    required this.startKg,
    required this.fmt,
  });

  final double targetKg;
  final double currentKg;
  final double startKg;
  final WeightFormatter fmt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final remainingKg = (targetKg - currentKg).abs();
    final span = startKg - targetKg;
    final progress = span == 0
        ? (currentKg == targetKg ? 1.0 : 0.0)
        : ((startKg - currentKg) / span).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return _PanelCard(
      radius: 24,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(Insets.xl, Insets.lg, Insets.xl, Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, size: 20, color: scheme.primary),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(l10n.homeGoalRow(fmt.withUnit(targetKg)),
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: Insets.sm),
              Text(l10n.homeToGo(fmt.withUnit(remainingKg)),
                  softWrap: false,
                  style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: scheme.primary)),
            ],
          ),
          const SizedBox(height: Insets.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          ),
          const SizedBox(height: Insets.sm),
          Text(l10n.homeProgressFrom(percent, fmt.withUnit(startKg)),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SecondMetricSlot extends StatelessWidget {
  const _SecondMetricSlot();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _DashedRRectPainter(color: scheme.outline, radius: 24),
      child: SizedBox(
        height: 76,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline,
                  size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: Insets.sm),
              Text(l10n.homeCaloriesSlot,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + dash).clamp(0, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// A rounded surface card with a hairline outline (design elevation level 0/1).
class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
    required this.radius,
    required this.color,
    required this.padding,
  });

  final Widget child;
  final double radius;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: scheme.outline),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                color: scheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.monitor_weight_outlined,
                  size: 44, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.xl),
            Text(l10n.homeEmptyTitle, style: text.headlineMedium),
            const SizedBox(height: Insets.sm),
            Text(l10n.homeEmptyBody,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: Insets.xxl),
            Builder(
              builder: (context) => FilledButton.icon(
                onPressed: () => showLogWeightSheet(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.homeLogWeight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
