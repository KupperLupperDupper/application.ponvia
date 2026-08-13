import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/domain/models/reminder_config.dart';
import 'package:ponvia/features/notifications/reminder_schedule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location utc;
  setUpAll(() {
    tzdata.initializeTimeZones();
    utc = tz.getLocation('UTC');
  });

  test('daily fires today if the time is still ahead, else tomorrow', () {
    const c = ReminderConfig(
        enabled: true, frequency: ReminderFrequency.daily, hour: 8, minute: 30);

    final before = nextReminderInstance(c, tz.TZDateTime(utc, 2026, 8, 8, 6));
    expect(before.day, 8);
    expect(before.hour, 8);
    expect(before.minute, 30);

    final after = nextReminderInstance(c, tz.TZDateTime(utc, 2026, 8, 8, 9));
    expect(after.day, 9);
  });

  test('weekly picks the next occurrence of the chosen weekday', () {
    const c = ReminderConfig(
        enabled: true,
        frequency: ReminderFrequency.weekly,
        weekdays: {DateTime.monday},
        hour: 7,
        minute: 0);
    final now = tz.TZDateTime(utc, 2026, 8, 8, 9);
    final n = nextReminderInstance(c, now);
    expect(n.weekday, DateTime.monday);
    expect(n.isAfter(now), isTrue);
    expect(n.difference(now).inDays, lessThanOrEqualTo(7));
  });

  group('multi-weekday weekly', () {
    // Aug 2026: 10th = Mon, 11th = Tue, 12th = Wed, 13th = Thu, 14th = Fri,
    // 15th = Sat, 16th = Sun.
    const c = ReminderConfig(
        enabled: true,
        frequency: ReminderFrequency.weekly,
        weekdays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
        hour: 7,
        minute: 0);

    test('returns the nearest selected day ahead', () {
      // Tuesday → next is Wednesday.
      final n = nextReminderInstance(c, tz.TZDateTime(utc, 2026, 8, 11, 9));
      expect(n.weekday, DateTime.wednesday);
      expect(n.day, 12);
    });

    test('skips today once its time has passed, to the next selected day', () {
      // Wednesday after 07:00 → Friday.
      final n = nextReminderInstance(c, tz.TZDateTime(utc, 2026, 8, 12, 9));
      expect(n.weekday, DateTime.friday);
      expect(n.day, 14);
    });

    test('wraps across the week end back to the earliest selected day', () {
      // Saturday → next is Monday.
      final n = nextReminderInstance(c, tz.TZDateTime(utc, 2026, 8, 15, 9));
      expect(n.weekday, DateTime.monday);
      expect(n.day, 17);
    });

    test('fires today if the time is still ahead', () {
      // Wednesday before 07:00 → today.
      final n = nextReminderInstance(c, tz.TZDateTime(utc, 2026, 8, 12, 6));
      expect(n.weekday, DateTime.wednesday);
      expect(n.day, 12);
    });
  });

  group('ReminderConfig weekday migration', () {
    test('legacy single "weekday" int reads as a one-element set', () {
      final c = ReminderConfig.fromJson({
        'enabled': true,
        'frequency': 'weekly',
        'weekday': DateTime.thursday,
        'hour': 8,
        'minute': 0,
      });
      expect(c.weekdays, {DateTime.thursday});
    });

    test('new "weekdays" list round-trips', () {
      const c = ReminderConfig(
          frequency: ReminderFrequency.weekly,
          weekdays: {DateTime.tuesday, DateTime.saturday});
      final back = ReminderConfig.fromJson(c.toJson());
      expect(back.weekdays, {DateTime.tuesday, DateTime.saturday});
    });

    test('missing/empty weekday data falls back to Monday, never empty', () {
      final c = ReminderConfig.fromJson({'frequency': 'weekly'});
      expect(c.weekdays, {DateTime.monday});
      final empty = ReminderConfig.fromJson({'weekdays': <int>[]});
      expect(empty.weekdays, {DateTime.monday});
    });
  });

  test('monthly clamps the day to a short month', () {
    const c = ReminderConfig(
        enabled: true,
        frequency: ReminderFrequency.monthly,
        dayOfMonth: 31,
        hour: 8,
        minute: 0);
    final n = nextReminderInstance(c, tz.TZDateTime(utc, 2026, 2, 1, 9));
    expect(n.month, 2);
    expect(n.day, 28); // Feb 2026 has 28 days
  });

  test('monthly rolls into next month once the day has passed', () {
    const c = ReminderConfig(
        enabled: true,
        frequency: ReminderFrequency.monthly,
        dayOfMonth: 5,
        hour: 8,
        minute: 0);
    final n = nextReminderInstance(c, tz.TZDateTime(utc, 2026, 8, 20, 9));
    expect(n.month, 9);
    expect(n.day, 5);
  });
}
