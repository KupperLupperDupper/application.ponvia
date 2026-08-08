import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/ui/spacing.dart';
import '../../domain/models/reminder_config.dart';
import '../../l10n/app_localizations.dart';

/// Weigh-in reminder settings. Functional M4 build (polished in M5).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _permissionGranted = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final granted = await ref.read(notificationServiceProvider).hasPermission();
      if (mounted) setState(() => _permissionGranted = granted);
    });
  }

  Future<void> _update(ReminderConfig config) async {
    final l10n = AppLocalizations.of(context);
    await ref.read(settingsControllerProvider.notifier).setReminder(config);
    final service = ref.read(notificationServiceProvider);
    if (config.enabled) {
      await service.apply(config,
          title: l10n.notifPushTitle, body: l10n.notifPushBody);
    } else {
      await service.cancelAll();
    }
  }

  Future<void> _toggle(bool on, ReminderConfig config) async {
    if (on) {
      final granted = await ref.read(notificationServiceProvider).requestPermission();
      if (mounted) setState(() => _permissionGranted = granted);
      if (!granted) {
        await _update(config.copyWith(enabled: false));
        return;
      }
    }
    await _update(config.copyWith(enabled: on));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(
        settingsControllerProvider.select((s) => s.reminder));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Insets.screenH),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: SwitchListTile(
              value: config.enabled,
              onChanged: (on) => _toggle(on, config),
              secondary: Icon(Icons.notifications_outlined,
                  color: scheme.onPrimaryContainer),
              title: Text(l10n.notifWeighInReminder,
                  style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          if (config.enabled && !_permissionGranted) ...[
            const SizedBox(height: Insets.md),
            _PermissionPanel(onAllow: () => _toggle(true, config)),
          ],
          if (config.enabled) ...[
            const SizedBox(height: Insets.xl),
            _SectionHeader(l10n.notifFrequency),
            SegmentedButton<ReminderFrequency>(
              segments: [
                ButtonSegment(
                    value: ReminderFrequency.daily, label: Text(l10n.freqDaily)),
                ButtonSegment(
                    value: ReminderFrequency.weekly, label: Text(l10n.freqWeekly)),
                ButtonSegment(
                    value: ReminderFrequency.monthly,
                    label: Text(l10n.freqMonthly)),
              ],
              selected: {config.frequency},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  _update(config.copyWith(frequency: s.first)),
            ),
            if (config.frequency == ReminderFrequency.weekly) ...[
              const SizedBox(height: Insets.xl),
              _SectionHeader(l10n.notifDayOfWeek),
              _WeekdayPicker(
                selected: config.weekday,
                locale: Localizations.localeOf(context).languageCode,
                onSelected: (w) => _update(config.copyWith(weekday: w)),
              ),
            ],
            if (config.frequency == ReminderFrequency.monthly) ...[
              const SizedBox(height: Insets.xl),
              _SectionHeader(l10n.notifDayOfMonth),
              _DayOfMonthPicker(
                selected: config.dayOfMonth,
                onSelected: (d) => _update(config.copyWith(dayOfMonth: d)),
              ),
            ],
            const SizedBox(height: Insets.xl),
            _SectionHeader(l10n.notifTimeOfDay),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(
                  TimeOfDay(hour: config.hour, minute: config.minute)
                      .format(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        TimeOfDay(hour: config.hour, minute: config.minute),
                  );
                  if (picked != null) {
                    await _update(config.copyWith(
                        hour: picked.hour, minute: picked.minute));
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({
    required this.selected,
    required this.locale,
    required this.onSelected,
  });

  final int selected;
  final String locale;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.E(locale);
    // 2024-01-01 is a Monday, so day `i` has weekday `i`.
    return Wrap(
      spacing: Insets.sm,
      children: [
        for (var w = 1; w <= 7; w++)
          ChoiceChip(
            label: Text(fmt.format(DateTime(2024, 1, w))),
            selected: selected == w,
            onSelected: (_) => onSelected(w),
          ),
      ],
    );
  }
}

class _DayOfMonthPicker extends StatelessWidget {
  const _DayOfMonthPicker({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Insets.xs,
      runSpacing: Insets.xs,
      children: [
        for (var d = 1; d <= 31; d++)
          ChoiceChip(
            label: Text('$d'),
            selected: selected == d,
            onSelected: (_) => onSelected(d),
          ),
      ],
    );
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({required this.onAllow});
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Insets.xl),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_off_outlined,
                  color: scheme.onErrorContainer),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(l10n.notifPermTitle,
                    style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Text(l10n.notifPermBody,
              style: TextStyle(color: scheme.onErrorContainer)),
          const SizedBox(height: Insets.md),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
                minimumSize: const Size.fromHeight(48)),
            onPressed: onAllow,
            child: Text(l10n.notifAllow),
          ),
        ],
      ),
    );
  }
}
