import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/app_settings.dart';
import '../features/security/app_lock_controller.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget. Wires the router and light/dark themes, reacts to the user's
/// theme-mode setting, and re-arms the app lock when backgrounded.
class PonviaApp extends ConsumerStatefulWidget {
  const PonviaApp({super.key});

  @override
  ConsumerState<PonviaApp> createState() => _PonviaAppState();
}

class _PonviaAppState extends ConsumerState<PonviaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock only on a full background (not `inactive`, which fires during the
    // biometric prompt) — no timer, the lock returns the moment you leave.
    if (state == AppLifecycleState.paused) {
      ref.read(appLockControllerProvider.notifier).relock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode =
        ref.watch(settingsControllerProvider.select((s) => s.themeMode));
    final localeCode =
        ref.watch(settingsControllerProvider.select((s) => s.localeCode));
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ponvia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      locale: localeCode == null ? null : Locale(localeCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
