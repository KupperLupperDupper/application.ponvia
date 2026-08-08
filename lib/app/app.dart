import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/app_settings.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget. Wires the router and light/dark themes, and reacts to the
/// user's theme-mode setting.
class PonviaApp extends ConsumerWidget {
  const PonviaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
