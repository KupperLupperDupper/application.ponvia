import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/goal.dart';

/// Goals list with the closest active goal highlighted. Add, edit, delete, and
/// mark achieved; each tile shows distance to target.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final closest = ref.watch(closestGoalProvider);
    final currentKg = ref.watch(latestWeightProvider).asData?.value?.weightKg;
    final fmt = WeightFormatter(settings.unit, locale: settings.localeCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
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
              child: Text('No goals yet. Tap + to add one.',
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
        title: Text(existing == null ? 'New goal' : 'Edit goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Target (${unit.code})'),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(existing == null ? 'Add' : 'Save'),
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
    final scheme = Theme.of(context).colorScheme;
    final onColor = highlighted ? scheme.onPrimaryContainer : null;

    final String subtitle;
    if (goal.isAchieved) {
      subtitle = 'Achieved';
    } else if (currentKg != null) {
      final remaining = (goal.targetWeightKg - currentKg!).abs();
      final direction = goal.targetWeightKg < currentKg! ? 'to lose' : 'to gain';
      subtitle = '${fmt.withUnit(remaining)} $direction';
    } else if (goal.label != null) {
      subtitle = goal.label!;
    } else {
      subtitle = highlighted ? 'Closest goal' : '';
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
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'achieve',
              child: Text(goal.isAchieved ? 'Reopen' : 'Mark achieved'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
