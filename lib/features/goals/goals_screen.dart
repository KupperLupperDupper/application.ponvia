import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/goal.dart';
import '../../l10n/app_localizations.dart';

/// Goals list with the closest active goal highlighted. Add, edit, delete, and
/// mark achieved; each tile shows distance to target.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final closest = ref.watch(closestGoalProvider);
    final currentKg = ref.watch(latestWeightProvider).asData?.value?.weightKg;
    final fmt = WeightFormatter(settings.unit, locale: settings.localeCode);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalDialog(context, ref, settings.unit),
        child: const Icon(Icons.add),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Text(l10n.goalsEmpty,
                  style: Theme.of(context).textTheme.bodyLarge),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(Insets.screenH),
            children: [
              for (final g in goals)
                _GoalTile(
                  goal: g,
                  fmt: fmt,
                  currentKg: currentKg,
                  highlighted: g.id == closest?.id,
                  onEdit: () =>
                      _showGoalDialog(context, ref, settings.unit, existing: g),
                  onToggleAchieved: () => ref.read(goalRepositoryProvider).update(
                        g.isAchieved
                            ? g.copyWith(clearAchieved: true)
                            : g.copyWith(achievedAt: DateTime.now()),
                      ),
                  onDelete: () async {
                    if (g.id != null) {
                      await ref.read(goalRepositoryProvider).delete(g.id!);
                    }
                  },
                ),
            ],
          );
        },
      ),
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
    final repo = ref.read(goalRepositoryProvider);
    if (existing == null) {
      await repo.add(Goal(
        targetWeightKg: kg,
        label: label.isEmpty ? null : label,
        createdAt: DateTime.now(),
      ));
    } else {
      await repo.update(Goal(
        id: existing.id,
        targetWeightKg: kg,
        label: label.isEmpty ? null : label,
        createdAt: existing.createdAt,
        achievedAt: existing.achievedAt,
      ));
    }
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.fmt,
    required this.currentKg,
    required this.highlighted,
    required this.onEdit,
    required this.onToggleAchieved,
    required this.onDelete,
  });

  final Goal goal;
  final WeightFormatter fmt;
  final double? currentKg;
  final bool highlighted;
  final VoidCallback onEdit;
  final VoidCallback onToggleAchieved;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final onColor = highlighted ? scheme.onPrimaryContainer : null;

    final String subtitle;
    if (goal.isAchieved) {
      subtitle = l10n.goalAchieved;
    } else if (currentKg != null) {
      final remaining = (goal.targetWeightKg - currentKg!).abs();
      subtitle = goal.targetWeightKg < currentKg!
          ? l10n.goalToLose(fmt.withUnit(remaining))
          : l10n.goalToGain(fmt.withUnit(remaining));
    } else if (goal.label != null) {
      subtitle = goal.label!;
    } else {
      subtitle = highlighted ? l10n.homeClosestGoal : '';
    }

    return Card(
      color: highlighted ? scheme.primaryContainer : null,
      child: ListTile(
        onTap: onEdit,
        leading: Icon(
          goal.isAchieved ? Icons.check_circle : Icons.flag,
          color: onColor,
        ),
        title: Text(
          goal.label ?? fmt.withUnit(goal.targetWeightKg),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onColor,
                decoration: goal.isAchieved ? TextDecoration.lineThrough : null,
              ),
        ),
        subtitle: Text(
          goal.label != null && !goal.isAchieved && currentKg != null
              ? '${fmt.withUnit(goal.targetWeightKg)} · $subtitle'
              : subtitle,
          style: TextStyle(color: onColor),
        ),
        trailing: PopupMenuButton<String>(
          iconColor: onColor,
          onSelected: (v) {
            switch (v) {
              case 'edit':
                onEdit();
              case 'achieve':
                onToggleAchieved();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
            PopupMenuItem(
              value: 'achieve',
              child: Text(goal.isAchieved ? l10n.goalReopen : l10n.goalMarkAchieved),
            ),
            PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
          ],
        ),
      ),
    );
  }
}
