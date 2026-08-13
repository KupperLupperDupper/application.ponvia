import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/goals/goals_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/home_shell.dart';
import '../features/logging/log_weight_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/security/app_lock_controller.dart';
import '../features/security/lock_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
import 'providers.dart';

/// Root navigator key — lets the notification tap handler deep-link to `/log`.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// App routing. Redirects gate the app lock and first-run onboarding; the four
/// destinations live in a persistent bottom-nav shell; logging is pushed over it.
final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects when the lock state changes (unlock, resume-relock).
  final refresh = ValueNotifier(0);
  ref.listen(appLockControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Lock gate takes priority — a set PIN means the user has onboarded.
      final locked = ref.read(appLockControllerProvider).isLocked;
      if (locked) return loc == '/lock' ? null : '/lock';
      if (loc == '/lock') return '/';

      final onboarded = ref.read(settingsControllerProvider).hasOnboarded;
      final atOnboarding = loc == '/onboarding';
      if (!onboarded && !atOnboarding) return '/onboarding';
      if (onboarded && atOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/goals',
                builder: (context, state) => const GoalsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/log',
        builder: (context, state) => const LogWeightScreen(),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),
    ],
  );
});
