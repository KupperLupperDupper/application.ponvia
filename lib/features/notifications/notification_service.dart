import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/reminder_config.dart';
import 'reminder_schedule.dart';

/// Local weigh-in reminders. Everything is on-device (no push server).
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'weigh_in_reminders';
  static const _channelName = 'Weigh-in reminders';
  static const _notificationId = 1001;

  void Function()? onTap;

  /// Initializes the timezone database and the plugin. Call once at startup.
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC if the platform timezone can't be resolved.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (_) => onTap?.call(),
    );
  }

  /// Requests notification permission (Android 13+ / iOS). Returns whether it is
  /// granted. Older Android returns true (permission implicit).
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return true;
  }

  Future<bool> hasPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  /// Cancels any existing reminder and, if enabled, schedules the next one as a
  /// recurring notification. [title]/[body] are localized by the caller.
  Future<void> apply(
    ReminderConfig config, {
    required String title,
    required String body,
  }) async {
    await _plugin.cancelAll();
    if (!config.enabled) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders to record your weight',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // Weekly can fire on several weekdays — schedule one recurring notification
    // per selected day, each with a distinct id (1000 + weekday). cancelAll()
    // above clears any prior ids, so the legacy 1001 (= 1000 + Monday) is safe.
    if (config.frequency == ReminderFrequency.weekly) {
      final now = tz.TZDateTime.now(tz.local);
      for (final wd in config.weekdays) {
        await _plugin.zonedSchedule(
          id: 1000 + wd,
          title: title,
          body: body,
          scheduledDate: nextWeeklyInstance(config, wd, now),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      return;
    }

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: title,
      body: body,
      scheduledDate: nextReminderInstance(config, tz.TZDateTime.now(tz.local)),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: _match(config.frequency),
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  DateTimeComponents _match(ReminderFrequency f) => switch (f) {
        ReminderFrequency.daily => DateTimeComponents.time,
        ReminderFrequency.weekly => DateTimeComponents.dayOfWeekAndTime,
        ReminderFrequency.monthly => DateTimeComponents.dayOfMonthAndTime,
      };
}
