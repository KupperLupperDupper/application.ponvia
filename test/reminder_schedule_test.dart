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
        weekday: DateTime.monday,
        hour: 7,
        minute: 0);
    final now = tz.TZDateTime(utc, 2026, 8, 8, 9);
    final n = nextReminderInstance(c, now);
    expect(n.weekday, DateTime.monday);
    expect(n.isAfter(now), isTrue);
    expect(n.difference(now).inDays, lessThanOrEqualTo(7));
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
