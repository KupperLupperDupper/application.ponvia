import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/goal.dart';

/// Goals list with the closest active goal highlighted. M1: list + add/delete.
/// Full editor and achieved treatment refine in M2/M5.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final closest = ref.watch(closestGoalProvider);
    final fmt = WeightFormatter(settings.unit, locale: settings.localeCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addGoalDialog(context, ref, settings.unit),
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
                  highlighted: g.id == closest?.id,
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

  Future<void> _addGoalDialog(
    BuildContext context,
    WidgetRef ref,
    WeightUnit unit,
  ) async {
    final valueController = TextEditingController();
    final labelController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
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
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final value = double.tryParse(valueController.text.trim().replaceAll(',', '.'));
    if (value == null) return;
    final kg = WeightConverter.toKg(value, unit);
    final label = labelController.text.trim();
    await ref.read(goalRepositoryProvider).add(
          Goal(
            targetWeightKg: kg,
            label: label.isEmpty ? null : label,
            createdAt: DateTime.now(),
          ),
        );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.fmt,
    required this.highlighted,
    required this.onDelete,
  });

  final Goal goal;
  final WeightFormatter fmt;
  final bool highlighted;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: highlighted ? scheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(goal.isAchieved ? Icons.check_circle : Icons.flag,
            color: highlighted ? scheme.onPrimaryContainer : null),
        title: Text(
          fmt.withUnit(goal.targetWeightKg),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: highlighted ? scheme.onPrimaryContainer : null,
              ),
        ),
        subtitle: goal.label == null
            ? (highlighted ? const Text('Closest goal') : null)
            : Text(goal.label!),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
