import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';

/// Reverse-chronological history. M1: list with delta + swipe-to-delete. The
/// trend chart (fl_chart) and range switcher come in M2.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final entriesAsync = ref.watch(entriesProvider);
    final fmt = WeightFormatter(settings.unit, locale: settings.localeCode);
    final dateFmt = PonviaDateFormatter(locale: settings.localeCode);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text('No entries yet.',
                  style: Theme.of(context).textTheme.bodyLarge),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: Insets.sm),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = entries[i];
              final prev = i + 1 < entries.length ? entries[i + 1] : null;
              final deltaKg =
                  prev == null ? null : e.weightKg - prev.weightKg;
              return Dismissible(
                key: ValueKey(e.id ?? e.timestamp.toIso8601String()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: Insets.xl),
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) async {
                  if (e.id != null) {
                    await ref.read(weightRepositoryProvider).delete(e.id!);
                  }
                },
                child: ListTile(
                  title: Text(fmt.withUnit(e.weightKg),
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(
                    [
                      dateFmt.dateTime(e.timestamp),
                      if (deltaKg != null) fmt.delta(deltaKg),
                      if (e.note != null && e.note!.isNotEmpty) e.note!,
                    ].join('  ·  '),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
