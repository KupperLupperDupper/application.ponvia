import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/ui/spacing.dart';
import '../../core/ui/undo_snackbar.dart';
import '../../core/units/weight_unit.dart';
import '../../data/backup/backup_service.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/reminder_config.dart';
import '../../l10n/app_localizations.dart';
import '../security/app_lock_controller.dart';
import '../security/set_pin_screen.dart';
import '../security/verify_pin_sheet.dart';
import 'height_sheet.dart';

String _freqLabel(AppLocalizations l10n, ReminderFrequency f) => switch (f) {
      ReminderFrequency.daily => l10n.freqDaily,
      ReminderFrequency.weekly => l10n.freqWeekly,
      ReminderFrequency.monthly => l10n.freqMonthly,
    };

/// Settings as a grouped list of icon rows (DESIGN_SPEC §7).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final r = settings.reminder;

    final languageValue = switch (settings.localeCode) {
      'en' => l10n.languageEnglish,
      'da' => l10n.languageDanish,
      _ => l10n.languageSystem,
    };
    final themeValue = switch (settings.themeMode) {
      AppThemeMode.light => l10n.themeLight,
      AppThemeMode.dark => l10n.themeDark,
      AppThemeMode.system => l10n.themeSystem,
    };
    final notifValue = r.enabled
        ? l10n.notifSummary(_freqLabel(l10n, r.frequency),
            TimeOfDay(hour: r.hour, minute: r.minute).format(context))
        : l10n.notifOff;

    final h = settings.heightCm;
    final String heightValue;
    if (h == null) {
      heightValue = l10n.heightUnset;
    } else if (settings.unit == WeightUnit.kg) {
      heightValue = '$h cm';
    } else {
      final totalIn = (h / 2.54).round();
      heightValue = '${totalIn ~/ 12} ft ${totalIn % 12} in';
    }

    final lock = ref.watch(appLockControllerProvider);
    final biometricAvailable =
        ref.watch(biometricAvailableProvider).asData?.value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, Insets.sm, 0, 96),
        children: [
          _Header(l10n.settingsPreferences),
          _SettingRow(
            icon: Icons.language,
            title: l10n.settingsLanguage,
            trailing: _valueChevron(context, languageValue),
            onTap: () => _pickLanguage(context, ref, settings.localeCode),
          ),
          _SettingRow(
            icon: Icons.contrast,
            title: l10n.settingsTheme,
            trailing: _valueChevron(context, themeValue),
            onTap: () => _pickTheme(context, ref, settings.themeMode),
          ),
          _SettingRow(
            icon: Icons.scale,
            title: l10n.settingsUnit,
            trailing: SegmentedButton<WeightUnit>(
              style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              segments: const [
                ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                ButtonSegment(value: WeightUnit.st, label: Text('st')),
              ],
              selected: {settings.unit},
              showSelectedIcon: false,
              onSelectionChanged: (s) => ref
                  .read(settingsControllerProvider.notifier)
                  .setUnit(s.first),
            ),
          ),
          _SettingRow(
            icon: Icons.height,
            title: l10n.heightLabel,
            subtitle: h == null ? l10n.heightSublabel : null,
            trailing: _valueChevron(context, heightValue),
            onTap: () => showHeightSheet(context),
          ),
          _SettingRow(
            icon: Icons.notifications_outlined,
            title: l10n.settingsNotifications,
            trailing: _valueChevron(context, notifValue),
            onTap: () => context.push('/reminders'),
          ),
          _Header(l10n.appLockGroup),
          _SettingRow(
            icon: Icons.lock_outline,
            title: l10n.appLockToggle,
            subtitle: l10n.appLockToggleSub,
            trailing: Switch(
              value: lock.enabled,
              onChanged: (v) => _toggleLock(context, ref, v),
            ),
          ),
          // Fingerprint only appears once the lock (and its PIN) exist.
          if (lock.enabled)
            _SettingRow(
              icon: Icons.fingerprint,
              title: l10n.appLockBiometric,
              subtitle: biometricAvailable
                  ? l10n.appLockBiometricSub
                  : l10n.appLockBiometricUnavailable,
              trailing: Switch(
                value: lock.biometricEnabled,
                onChanged: biometricAvailable
                    ? (v) => _toggleBiometric(context, ref, v)
                    : null,
              ),
            ),
          if (lock.enabled)
            _SettingRow(
              icon: Icons.password_outlined,
              title: l10n.appLockChangePin,
              trailing: Icon(Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              onTap: () => _changePin(context, ref),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Insets.lg, Insets.xs, Insets.lg, Insets.sm),
            child: Text(l10n.appLockOnDeviceNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          _Header(l10n.settingsData),
          _SettingRow(
            icon: Icons.upload_outlined,
            title: l10n.settingsExportData,
            trailing: Text('CSV / JSON',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            onTap: () => _exportChooser(context, ref),
          ),
          _SettingRow(
            icon: Icons.download_outlined,
            title: l10n.settingsImportData,
            onTap: () => _import(context, ref),
          ),
          _SettingRow(
            icon: Icons.delete_forever_outlined,
            title: l10n.settingsClear,
            error: true,
            onTap: () => _confirmClear(context, ref),
          ),
          _Header(l10n.settingsAbout),
          _SettingRow(
            icon: Icons.lock_outline,
            title: l10n.settingsPrivacy,
            trailing: Icon(Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: () => context.push('/privacy'),
          ),
          _SettingRow(
            icon: Icons.description_outlined,
            title: l10n.settingsLicenses,
            trailing: Icon(Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Ponvia',
              applicationVersion: '0.4.0',
              useRootNavigator: true,
            ),
          ),
          _SettingRow(
            icon: Icons.info_outline,
            title: 'Ponvia',
            trailing: Text(l10n.settingsVersion('0.5.0'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _valueChevron(BuildContext context, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(width: Insets.xs),
        Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
      ],
    );
  }

  Future<void> _pickLanguage(
      BuildContext context, WidgetRef ref, String? current) async {
    final l10n = AppLocalizations.of(context);
    await _pickSheet<String?>(
      context,
      title: l10n.settingsLanguage,
      current: current,
      options: [
        (null, l10n.languageSystem),
        ('en', l10n.languageEnglish),
        ('da', l10n.languageDanish),
      ],
      onSelected: (v) =>
          ref.read(settingsControllerProvider.notifier).setLocale(v),
    );
  }

  Future<void> _pickTheme(
      BuildContext context, WidgetRef ref, AppThemeMode current) async {
    final l10n = AppLocalizations.of(context);
    await _pickSheet<AppThemeMode>(
      context,
      title: l10n.settingsTheme,
      current: current,
      options: [
        (AppThemeMode.system, l10n.themeSystem),
        (AppThemeMode.light, l10n.themeLight),
        (AppThemeMode.dark, l10n.themeDark),
      ],
      onSelected: (v) =>
          ref.read(settingsControllerProvider.notifier).setThemeMode(v),
    );
  }

  Future<void> _pickSheet<T>(
    BuildContext context, {
    required String title,
    required T current,
    required List<(T, String)> options,
    required ValueChanged<T> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.xl, 0, Insets.xl, Insets.sm),
              child: Text(title,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final (value, label) in options)
              ListTile(
                title: Text(label),
                trailing: value == current
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  onSelected(value);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: Insets.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _exportChooser(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.data_object),
              title: Text(l10n.settingsExportJson),
              subtitle: Text(l10n.settingsExportJsonSub),
              onTap: () {
                Navigator.pop(context);
                _export(context, ref, csv: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(l10n.settingsExportCsv),
              subtitle: Text(l10n.settingsExportCsvSub),
              onTap: () {
                Navigator.pop(context);
                _export(context, ref, csv: true);
              },
            ),
            const SizedBox(height: Insets.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref,
      {required bool csv}) async {
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

    final backup = ref.read(backupServiceProvider);
    // A replace wipes existing data first — snapshot it so the import is undoable.
    final String? snapshot = replace
        ? await backup.exportJson(
            settings: ref.read(settingsControllerProvider),
            now: DateTime.now())
        : null;

    try {
      if (isJson) {
        final data = await backup.importJson(content, replace: replace);
        if (!context.mounted) return;
        if (snapshot != null) {
          _showReplaceUndo(context, l10n, backup, snapshot);
        } else {
          messenger.showSnackBar(SnackBar(
              content: Text(l10n.importedSummary(
                  data.entries.length, data.goals.length))));
        }
      } else {
        final n = await backup.importCsv(content, replace: replace);
        if (!context.mounted) return;
        if (snapshot != null) {
          _showReplaceUndo(context, l10n, backup, snapshot);
        } else {
          messenger.showSnackBar(SnackBar(content: Text(l10n.importedCsv(n))));
        }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed('$e'))));
    }
  }

  void _showReplaceUndo(BuildContext context, AppLocalizations l10n,
      BackupService backup, String snapshot) {
    showUndoSnackbar(
      context,
      message: l10n.snackbarDataReplaced,
      undoLabel: l10n.actionUndo,
      icon: Icons.restore,
      bulk: true,
      onUndo: () => backup.importJson(snapshot, replace: true),
    );
  }

  Future<bool?> _askMergeOrReplace(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importDialogTitle),
        content: Text(l10n.importDialogBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.actionCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.importMerge)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
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
              child: Text(l10n.actionCancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Snapshot everything before wiping so the undo can restore it in full.
    final backup = ref.read(backupServiceProvider);
    final settings = ref.read(settingsControllerProvider);
    final entriesCount =
        ref.read(entriesProvider).asData?.value.length ?? 0;
    final goalsCount = ref.read(goalsProvider).asData?.value.length ?? 0;
    final snapshot =
        await backup.exportJson(settings: settings, now: DateTime.now());
    await ref.read(databaseProvider).clearAllData();
    if (!context.mounted) return;
    showUndoSnackbar(
      context,
      message: l10n.snackbarAllDataCleared(entriesCount, goalsCount),
      undoLabel: l10n.actionUndo,
      icon: Icons.settings_backup_restore,
      bulk: true,
      onUndo: () => backup.importJson(snapshot, replace: true),
    );
  }

  Future<void> _toggleLock(BuildContext context, WidgetRef ref, bool on) async {
    final notifier = ref.read(appLockControllerProvider.notifier);
    if (on) {
      final pin = await SetPinScreen.show(context);
      if (pin != null) await notifier.enable(pin);
    } else {
      final ok = await showVerifyPinSheet(context);
      if (ok == true) await notifier.disable();
    }
  }

  Future<void> _toggleBiometric(
      BuildContext context, WidgetRef ref, bool on) async {
    final notifier = ref.read(appLockControllerProvider.notifier);
    if (!on) {
      await notifier.setBiometric(false);
      return;
    }
    final reason = AppLocalizations.of(context).appLockBiometricPromptTitle;
    var ok = false;
    try {
      ok = await LocalAuthentication().authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      ok = false;
    }
    if (ok) await notifier.setBiometric(true);
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final ok = await showVerifyPinSheet(context);
    if (ok != true || !context.mounted) return;
    final pin = await SetPinScreen.show(context);
    if (pin != null) {
      await ref.read(appLockControllerProvider.notifier).changePin(pin);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, Insets.lg, Insets.lg, Insets.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.error = false,
  });

  final IconData icon;
  final String title;

  /// Optional second line — makes the row two-line (e.g. Height unset, or the
  /// app-lock switches).
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = error ? scheme.error : scheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg, vertical: Insets.md),
        child: Row(
          children: [
            Icon(icon,
                size: 24, color: error ? scheme.error : scheme.onSurfaceVariant),
            const SizedBox(width: Insets.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: color,
                            fontWeight:
                                error ? FontWeight.w700 : FontWeight.w600,
                          )),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
