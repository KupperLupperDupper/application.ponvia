import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/app_settings.dart';

/// App settings. M1 covers theme, unit, language (persisted; Danish UI lands in
/// M3), JSON export, and clear-data. Notifications + full import/about are M3/M4.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        children: [
          _sectionHeader(context, 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: SegmentedButton<AppThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: AppThemeMode.system, label: Text('System')),
                  ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => controller.setThemeMode(s.first),
              ),
            ),
          ),
          ListTile(
            title: const Text('Weight unit'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: SegmentedButton<WeightUnit>(
                segments: const [
                  ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                  ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                  ButtonSegment(value: WeightUnit.st, label: Text('st')),
                ],
                selected: {settings.unit},
                onSelectionChanged: (s) => controller.setUnit(s.first),
              ),
            ),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'system', label: Text('System')),
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'da', label: Text('Dansk')),
                ],
                selected: {settings.localeCode ?? 'system'},
                onSelectionChanged: (s) => controller
                    .setLocale(s.first == 'system' ? null : s.first),
              ),
            ),
          ),
          _sectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export backup (JSON)'),
            subtitle: const Text('Saves a full backup file to app storage'),
            onTap: () => _exportJson(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import backup'),
            subtitle: const Text('Coming in M2 (file picker)'),
            enabled: false,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error),
            title: const Text('Clear entries & goals'),
            onTap: () => _confirmClear(context, ref),
          ),
          _sectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Ponvia'),
            subtitle: Text('Version 1.0.0 · milestone M1'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy'),
            subtitle: Text('All data stays on your device.',
                style: text.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.screenH, Insets.lg, Insets.screenH, Insets.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = await ref.read(backupServiceProvider).exportJson(
            settings: ref.read(settingsControllerProvider),
            now: DateTime.now(),
          );
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path,
          'ponvia-backup-${DateTime.now().millisecondsSinceEpoch}.json'));
      await file.writeAsString(json);
      messenger.showSnackBar(
        SnackBar(content: Text('Backup saved to ${file.path}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear entries & goals?'),
        content: const Text(
            'This permanently deletes all weight entries and goals. This cannot '
            'be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(databaseProvider).clearAllData();
    }
  }
}
