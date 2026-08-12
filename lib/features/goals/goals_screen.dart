import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/ponvia_colors.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/ui/undo_snackbar.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/goal.dart';
import '../../l10n/app_localizations.dart';

/// Goals list styled to DESIGN_SPEC §6: a highlighted "closest goal" card plus
/// regular / achieved / gain cards, each with progress and a footer.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final closest = ref.watch(closestGoalProvider);
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final currentKg = entries.isEmpty ? null : entries.first.weightKg;
    final startKg = entries.isEmpty ? null : entries.last.weightKg;
    final fmt = WeightFormatter(settings.unit,
        locale: Localizations.localeOf(context).languageCode);
    final dateFmt =
        PonviaDateFormatter(locale: Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalsTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Insets.md),
            child: FilledButton.tonalIcon(
              onPressed: () => _showGoalDialog(context, ref, settings.unit),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.goalNew),
              style: FilledButton.styleFrom(
                // The theme's minimumSize is Size.fromHeight(56) (infinite
                // width); pin a finite 40dp height so it fits an AppBar action.
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: Insets.md),
              ),
            ),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (goals) {
          if (goals.isEmpty) return _EmptyGoals(l10n: l10n);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                Insets.screenH, Insets.lg, Insets.screenH, 96),
            children: [
              for (final g in goals)
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.cardGap),
                  child: _SwipeToDelete(
                    dismissKey:
                        ValueKey(g.id ?? g.createdAt.toIso8601String()),
                    radius: g.id == closest?.id ? 28 : 24,
                    onDismissed: () => _delete(context, ref, g),
                    child: _GoalCard(
                      goal: g,
                      fmt: fmt,
                      dateFmt: dateFmt,
                      unit: settings.unit,
                      currentKg: currentKg,
                      startKg: startKg,
                      highlighted: g.id == closest?.id,
                      onTap: () => _showGoalDialog(context, ref, settings.unit,
                          existing: g),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _delete(BuildContext context, WidgetRef ref, Goal g) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(goalRepositoryProvider);
    if (g.id != null) repo.delete(g.id!);
    showUndoSnackbar(
      context,
      message: l10n.snackbarGoalDeleted,
      undoLabel: l10n.actionUndo,
      icon: Icons.delete_outline,
      onUndo: () => repo.add(Goal(
        targetWeightKg: g.targetWeightKg,
        label: g.label,
        startWeightKg: g.startWeightKg,
        createdAt: g.createdAt,
        achievedAt: g.achievedAt,
        reachedPromptShownAt: g.reachedPromptShownAt,
      )),
    );
  }

  Future<void> _showGoalDialog(
    BuildContext context,
    WidgetRef ref,
    WeightUnit unit, {
    Goal? existing,
  }) async {
    final l10n = AppLocalizations.of(context);
    final valueController = TextEditingController(
      text: existing == null
          ? ''
          : WeightConverter.fromKg(existing.targetWeightKg, unit)
              .toStringAsFixed(1),
    );
    final labelController = TextEditingController(text: existing?.label ?? '');
    final repo = ref.read(goalRepositoryProvider);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? l10n.goalNew : l10n.goalEdit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: l10n.goalTargetField(unit.code)),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: labelController,
              decoration: InputDecoration(labelText: l10n.goalLabelField),
            ),
            if (existing != null) ...[
              const SizedBox(height: Insets.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: Icon(existing.isAchieved
                      ? Icons.undo
                      : Icons.check_circle_outline),
                  label: Text(existing.isAchieved
                      ? l10n.goalReopen
                      : l10n.goalMarkAchieved),
                  onPressed: () {
                    repo.update(existing.isAchieved
                        ? existing.copyWith(clearAchieved: true)
                        : existing.copyWith(achievedAt: DateTime.now()));
                    Navigator.pop(context, false);
                  },
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(existing == null ? l10n.actionAdd : l10n.actionSave),
          ),
        ],
      ),
    );

    if (result != true) return;
    final value =
        double.tryParse(valueController.text.trim().replaceAll(',', '.'));
    if (value == null) return;
    final kg = WeightConverter.toKg(value, unit);
    final label = labelController.text.trim();
    if (existing == null) {
      // Anchor the goal's direction (lose vs gain) to the current weight.
      final startKg = ref.read(latestWeightProvider).asData?.value?.weightKg;
      await repo.add(Goal(
        targetWeightKg: kg,
        label: label.isEmpty ? null : label,
        startWeightKg: startKg,
        createdAt: DateTime.now(),
      ));
    } else {
      await repo.update(Goal(
        id: existing.id,
        targetWeightKg: kg,
        label: label.isEmpty ? null : label,
        startWeightKg: existing.startWeightKg,
        createdAt: existing.createdAt,
        achievedAt: existing.achievedAt,
        reachedPromptShownAt: existing.reachedPromptShownAt,
      ));
    }
  }
}

/// Swipe-to-delete that keeps the red delete surface as a single full-bleed
/// layer *behind* the card (not a separate rounded shape beside it), so the red
/// is revealed flush with the card edge as you swipe — no gap, no hard cut.
class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    required this.dismissKey,
    required this.radius,
    required this.onDismissed,
    required this.child,
  });

  final Key dismissKey;
  final double radius;
  final VoidCallback onDismissed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          // Full-bleed red under the whole card; the sliding card sits on top,
          // so whatever it uncovers is red — flush by construction.
          Positioned.fill(
            child: Container(
              color: scheme.errorContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: Insets.xl),
              child: Icon(Icons.delete_outline,
                  color: scheme.onErrorContainer),
            ),
          ),
          Dismissible(
            key: dismissKey,
            direction: DismissDirection.endToStart,
            // The red is the Stack layer above; Dismissible needs none of its own.
            background: const SizedBox.shrink(),
            onDismissed: (_) => onDismissed(),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.fmt,
    required this.dateFmt,
    required this.unit,
    required this.currentKg,
    required this.startKg,
    required this.highlighted,
    required this.onTap,
  });

  final Goal goal;
  final WeightFormatter fmt;
  final PonviaDateFormatter dateFmt;
  final WeightUnit unit;
  final double? currentKg;
  final double? startKg;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ponvia = Theme.of(context).extension<PonviaColors>()!;
    final text = Theme.of(context).textTheme;

    final onColor = highlighted ? scheme.onPrimaryContainer : scheme.onSurface;
    final subColor =
        highlighted ? scheme.onPrimaryContainer.withValues(alpha: 0.8) : scheme.onSurfaceVariant;

    final isGain = currentKg != null && goal.targetWeightKg > currentKg!;
    final remaining =
        currentKg == null ? null : (goal.targetWeightKg - currentKg!).abs();

    double? progress;
    if (goal.isAchieved) {
      progress = 1;
    } else if (currentKg != null &&
        startKg != null &&
        startKg != goal.targetWeightKg) {
      progress = ((currentKg! - startKg!) / (goal.targetWeightKg - startKg!))
          .clamp(0.0, 1.0);
    }

    Widget directionRow() {
      if (goal.isAchieved) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 18, color: scheme.primary),
          const SizedBox(width: Insets.xs),
          Text(l10n.goalAchieved,
              style: text.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary)),
        ]);
      }
      if (remaining == null) return const SizedBox.shrink();
      final color = isGain ? ponvia.deltaUp : onColor;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isGain ? Icons.arrow_upward : Icons.arrow_downward,
            size: 18, color: color),
        const SizedBox(width: Insets.xs),
        Text(
          isGain
              ? l10n.goalToGain(fmt.withUnit(remaining))
              : l10n.goalToLose(fmt.withUnit(remaining)),
          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: color),
        ),
      ]);
    }

    final showBar = progress != null && (!isGain || progress > 0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(highlighted ? 28 : 24),
      child: Container(
        padding: const EdgeInsets.all(Insets.xl),
        decoration: BoxDecoration(
          color: highlighted
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(highlighted ? 28 : 24),
          border: highlighted ? null : Border.all(color: scheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlighted) ...[
              _ClosestChip(label: l10n.goalClosest.toUpperCase()),
              const SizedBox(height: Insets.md),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: fmt.value(goal.targetWeightKg),
                        style: text.headlineMedium?.copyWith(
                            fontSize: highlighted ? 40 : 32, color: onColor)),
                    if (unit != WeightUnit.st)
                      TextSpan(
                          text: ' ${unit.code}',
                          style: text.titleMedium?.copyWith(color: subColor)),
                  ]),
                ),
                const Spacer(),
                directionRow(),
              ],
            ),
            if (showBar) ...[
              const SizedBox(height: Insets.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: highlighted ? 10 : 8,
                  backgroundColor: highlighted
                      ? scheme.onPrimaryContainer.withValues(alpha: 0.16)
                      : scheme.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
            ],
            _footer(context, l10n, subColor, progress),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n, Color subColor,
      double? progress) {
    final text = Theme.of(context).textTheme;
    if (goal.isAchieved && goal.achievedAt != null) {
      return Padding(
        padding: const EdgeInsets.only(top: Insets.sm),
        child: Text(l10n.goalReached(dateFmt.date(goal.achievedAt!)),
            style: text.bodySmall?.copyWith(color: subColor)),
      );
    }
    if (highlighted && startKg != null && progress != null) {
      return Padding(
        padding: const EdgeInsets.only(top: Insets.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.goalStarted(
                  fmt.withUnit(startKg!), dateFmt.date(goal.createdAt)),
              style: text.bodySmall?.copyWith(color: subColor),
            ),
            Text('${(progress * 100).round()}%',
                style: text.bodySmall
                    ?.copyWith(color: subColor, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }
    if (goal.label != null && goal.label!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: Insets.sm),
        child: Text(goal.label!, style: text.bodySmall?.copyWith(color: subColor)),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ClosestChip extends StatelessWidget {
  const _ClosestChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: scheme.onPrimary),
          const SizedBox(width: Insets.xs),
          Text(label,
              style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.l10n});
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
              child: Icon(Icons.flag, size: 40, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.xl),
            Text(l10n.goalsEmpty,
                textAlign: TextAlign.center, style: text.bodyLarge),
          ],
        ),
      ),
    );
  }
}
