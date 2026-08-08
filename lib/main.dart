import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'features/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only: the layouts (hero weight, keypad, chart) are designed for
  // upright phone use. The Android manifest locks this too; this also covers iOS.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  final notifications = NotificationService();
  await notifications.init();
  // Tapping a reminder deep-links to the log-weight flow.
  notifications.onTap = () {
    final context = rootNavigatorKey.currentContext;
    if (context != null) context.push('/log');
  };

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const PonviaApp(),
    ),
  );
}
