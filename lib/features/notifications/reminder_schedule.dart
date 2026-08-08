import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/reminder_config.dart';

/// Pure date math for weigh-in reminders: given a [ReminderConfig] and the
/// current time, compute the next fire instant in the local timezone. Monthly
/// day-of-month is clamped to the month's last day (short-month fallback).
tz.TZDateTime nextReminderInstance(ReminderConfig c, tz.TZDateTime now) {
  switch (c.frequency) {
    case ReminderFrequency.daily:
      var d = _at(now, now.year, now.month, now.day, c);
      if (!d.isAfter(now)) d = _at(now, d.year, d.month, d.day + 1, c);
      return d;

    case ReminderFrequency.weekly:
      var d = _at(now, now.year, now.month, now.day, c);
      // Advance day-by-day until we hit the target weekday in the future.
      while (d.weekday != c.weekday || !d.isAfter(now)) {
        final next = d.add(const Duration(days: 1));
        d = _at(now, next.year, next.month, next.day, c);
      }
      return d;

    case ReminderFrequency.monthly:
      var year = now.year;
      var month = now.month;
      var d = _monthly(now, year, month, c);
      if (!d.isAfter(now)) {
        month++;
        if (month > 12) {
          month = 1;
          year++;
        }
        d = _monthly(now, year, month, c);
      }
      return d;
  }
}

tz.TZDateTime _at(tz.TZDateTime ref, int y, int m, int day, ReminderConfig c) =>
    tz.TZDateTime(ref.location, y, m, day, c.hour, c.minute);

tz.TZDateTime _monthly(tz.TZDateTime ref, int y, int m, ReminderConfig c) {
  final lastDay = DateTime(y, m + 1, 0).day; // day 0 of next month = last of this
  final day = c.dayOfMonth.clamp(1, lastDay);
  return tz.TZDateTime(ref.location, y, m, day, c.hour, c.minute);
}
