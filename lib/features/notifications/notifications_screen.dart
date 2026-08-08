import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/providers.dart';
import '../../core/ui/spacing.dart';
import '../../domain/models/reminder_config.dart';
import '../../l10n/app_localizations.dart';
import 'reminder_schedule.dart';

/// Weigh-in reminder settings, styled to DESIGN_SPEC §8.
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
    final locale = Localizations.localeOf(context).languageCode;
    final config =
        ref.watch(settingsControllerProvider.select((s) => s.reminder));
    final scheme = Theme.of(context).colorScheme;

    String? nextFire;
    if (config.enabled) {
      final next = nextReminderInstance(config, tz.TZDateTime.now(tz.local));
      nextFire = DateFormat('EEE d MMM · HH:mm', locale).format(next);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Insets.screenH),
        children: [
          // Master row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Insets.lg, vertical: Insets.xs),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined,
                    color: scheme.onPrimaryContainer),
                const SizedBox(width: Insets.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.notifWeighInReminder,
                          style: TextStyle(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      if (nextFire != null)
                        Text(l10n.notifNext(nextFire),
                            style: TextStyle(
                                color: scheme.onPrimaryContainer
                                    .withValues(alpha: 0.8),
                                fontSize: 13)),
                    ],
                  ),
                ),
                Switch(
                  value: config.enabled,
                  onChanged: (on) => _toggle(on, config),
                ),
              ],
            ),
          ),
          if (config.enabled && !_permissionGranted) ...[
            const SizedBox(height: Insets.md),
            _PermissionPanel(onAllow: () => _toggle(true, config)),
          ],
          if (config.enabled) ...[
            const SizedBox(height: Insets.xl),
            _Header(l10n.notifFrequency),
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
              _Header(l10n.notifDayOfWeek),
              _WeekdayCircles(
                selected: config.weekday,
                locale: locale,
                onSelected: (w) => _update(config.copyWith(weekday: w)),
              ),
              const SizedBox(height: Insets.sm),
              Text(
                l10n.notifDaySelected(DateFormat.EEEE(locale)
                    .format(DateTime(2024, 1, config.weekday))),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (config.frequency == ReminderFrequency.monthly) ...[
              const SizedBox(height: Insets.xl),
              _Header(l10n.notifDayOfMonth),
              _DayOfMonthGrid(
                selected: config.dayOfMonth,
                onSelected: (d) => _update(config.copyWith(dayOfMonth: d)),
              ),
            ],
            const SizedBox(height: Insets.xl),
            _Header(l10n.notifTimeOfDay),
            _TimeCard(
              hour: config.hour,
              minute: config.minute,
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
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Text(label.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}

class _WeekdayCircles extends StatelessWidget {
  const _WeekdayCircles(
      {required this.selected, required this.locale, required this.onSelected});

  final int selected;
  final String locale;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final narrow = DateFormat('EEEEE', locale);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var w = 1; w <= 7; w++)
          InkWell(
            onTap: () => onSelected(w),
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected == w ? scheme.primary : null,
                border: selected == w
                    ? null
                    : Border.all(color: scheme.outline),
              ),
              child: Text(
                narrow.format(DateTime(2024, 1, w)),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected == w ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayOfMonthGrid extends StatelessWidget {
  const _DayOfMonthGrid({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: Insets.xs,
      crossAxisSpacing: Insets.xs,
      children: [
        for (var d = 1; d <= 31; d++)
          InkWell(
            onTap: () => onSelected(d),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected == d ? scheme.primary : scheme.surfaceContainer,
              ),
              child: Text('$d',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color:
                          selected == d ? scheme.onPrimary : scheme.onSurface)),
            ),
          ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard(
      {required this.hour, required this.minute, required this.onTap});

  final int hour;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget block(String text, Color bg, Color fg) => Container(
          width: 88,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(14)),
          child: Text(text,
              style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w800, color: fg)),
        );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outline)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            block(hour.toString().padLeft(2, '0'), scheme.primaryContainer,
                scheme.onPrimaryContainer),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.md),
              child: Text(':',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant)),
            ),
            block(minute.toString().padLeft(2, '0'), scheme.surfaceContainer,
                scheme.onSurface),
          ],
        ),
      ),
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
