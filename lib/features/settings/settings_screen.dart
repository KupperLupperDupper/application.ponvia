import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/reminder_config.dart';
import '../../l10n/app_localizations.dart';

String _freqLabel(AppLocalizations l10n, ReminderFrequency f) => switch (f) {
      ReminderFrequency.daily => l10n.freqDaily,
      ReminderFrequency.weekly => l10n.freqWeekly,
      ReminderFrequency.monthly => l10n.freqMonthly,
    };

/// App settings: theme, unit, language, JSON/CSV export (share sheet) & import
/// (file picker), and clear-data.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        children: [
          _sectionHeader(context, l10n.settingsAppearance),
          ListTile(
            title: Text(l10n.settingsTheme),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: SegmentedButton<AppThemeMode>(
                segments: [
                  ButtonSegment(
                      value: AppThemeMode.system, label: Text(l10n.themeSystem)),
                  ButtonSegment(
                      value: AppThemeMode.light, label: Text(l10n.themeLight)),
                  ButtonSegment(
                      value: AppThemeMode.dark, label: Text(l10n.themeDark)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => controller.setThemeMode(s.first),
              ),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsUnit),
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
            title: Text(l10n.settingsLanguage),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'system', label: Text(l10n.languageSystem)),
                  ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                  ButtonSegment(value: 'da', label: Text(l10n.languageDanish)),
                ],
                selected: {settings.localeCode ?? 'system'},
                onSelectionChanged: (s) =>
                    controller.setLocale(s.first == 'system' ? null : s.first),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.settingsNotifications),
            subtitle: Text(settings.reminder.enabled
                ? l10n.notifSummary(
                    _freqLabel(l10n, settings.reminder.frequency),
                    TimeOfDay(
                            hour: settings.reminder.hour,
                            minute: settings.reminder.minute)
                        .format(context))
                : l10n.notifOff),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/reminders'),
          ),
          _sectionHeader(context, l10n.settingsData),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(l10n.settingsExportJson),
            subtitle: Text(l10n.settingsExportJsonSub),
            onTap: () => _export(context, ref, csv: false),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(l10n.settingsExportCsv),
            subtitle: Text(l10n.settingsExportCsvSub),
            onTap: () => _export(context, ref, csv: true),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.settingsImport),
            subtitle: Text(l10n.settingsImportSub),
            onTap: () => _import(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error),
            title: Text(l10n.settingsClear),
            onTap: () => _confirmClear(context, ref),
          ),
          _sectionHeader(context, l10n.settingsAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Ponvia'),
            subtitle: Text(l10n.settingsVersion('1.0.0')),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.settingsPrivacy),
            subtitle: Text(l10n.settingsPrivacyBody, style: text.bodyMedium),
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
    final l10n = AppLocalizations.of(context);
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
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed('$e'))));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
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

    final replace = await _askMergeOrReplace(context, l10n);
    if (replace == null) return;

    try {
      final backup = ref.read(backupServiceProvider);
      if (isJson) {
        final data = await backup.importJson(content, replace: replace);
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.importedSummary(data.entries.length, data.goals.length)),
        ));
      } else {
        final n = await backup.importCsv(content, replace: replace);
        messenger.showSnackBar(SnackBar(content: Text(l10n.importedCsv(n))));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed('$e'))));
    }
  }

  /// Returns true for replace, false for merge, null if cancelled.
  Future<bool?> _askMergeOrReplace(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importDialogTitle),
        content: Text(l10n.importDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.importMerge),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.importReplace),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearDialogTitle),
        content: Text(l10n.clearDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(databaseProvider).clearAllData();
    }
  }
}
