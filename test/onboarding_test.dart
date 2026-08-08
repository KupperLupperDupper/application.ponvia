import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/app/providers.dart';
import 'package:ponvia/app/theme/app_theme.dart';
import 'package:ponvia/features/onboarding/onboarding_screen.dart';
import 'package:ponvia/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Onboarding welcome renders title and Next', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OnboardingScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Ponvia'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
