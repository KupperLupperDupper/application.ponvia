import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/app_settings.dart';

/// App settings: theme, unit, language (Danish UI lands in M3), JSON/CSV
/// export (share sheet) & import (file picker), and clear-data.
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
                onSelectionChanged: (s) =>
                    controller.setLocale(s.first == 'system' ? null : s.first),
              ),
            ),
          ),
          _sectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export backup (JSON)'),
            subtitle: const Text('Full backup: weights, goals, settings'),
            onTap: () => _export(context, ref, csv: false),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export weights (CSV)'),
            subtitle: const Text('Weight history for spreadsheets'),
            onTap: () => _export(context, ref, csv: true),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import (JSON or CSV)'),
            subtitle: const Text('Restore or merge a backup'),
            onTap: () => _import(context, ref),
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
            subtitle: Text('Version 1.0.0 · milestone M2'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy'),
            subtitle:
                Text('All data stays on your device.', style: text.bodyMedium),
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

  Future<void> _export(
    BuildContext context,
    WidgetRef ref, {
    required bool csv,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backup = ref.read(backupServiceProvider);
      final settings = ref.read(settingsControllerProvider);
      final content = csv
          ? await backup.exportCsv(settings.unit)
          : await backup.exportJson(settings: settings, now: DateTime.now());
      final fileName = csv ? 'ponvia-weights.csv' : 'ponvia-backup.json';
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, fileName));
      await file.writeAsString(content);
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile(file.path,
              mimeType: csv ? 'text/csv' : 'application/json', name: fileName),
        ],
        subject: fileName,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    const group = XTypeGroup(
      label: 'Ponvia backup',
      extensions: ['json', 'csv'],
      mimeTypes: ['application/json', 'text/csv', 'text/comma-separated-values'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return;
    final content = await file.readAsString();
    final isJson = file.name.toLowerCase().endsWith('.json') ||
        content.trimLeft().startsWith('{');
    if (!context.mounted) return;

    final replace = await _askMergeOrReplace(context);
    if (replace == null) return;

    try {
      final backup = ref.read(backupServiceProvider);
      if (isJson) {
        final data = await backup.importJson(content, replace: replace);
        messenger.showSnackBar(SnackBar(
          content: Text(
              'Imported ${data.entries.length} entries, ${data.goals.length} goals'),
        ));
      } else {
        final n = await backup.importCsv(content, replace: replace);
        messenger.showSnackBar(SnackBar(content: Text('Imported $n entries')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  /// Returns true for replace, false for merge, null if cancelled.
  Future<bool?> _askMergeOrReplace(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import data'),
        content: const Text(
            'Merge adds new records to your existing data. Replace deletes all '
            'current data first. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Merge'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
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
