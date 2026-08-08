import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/app/providers.dart';
import 'package:ponvia/app/theme/app_theme.dart';
import 'package:ponvia/domain/models/goal.dart';
import 'package:ponvia/domain/models/weight_entry.dart';
import 'package:ponvia/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Home shows the empty state when there are no entries',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entriesProvider
              .overrideWith((ref) => Stream.value(const <WeightEntry>[])),
          goalsProvider.overrideWith((ref) => Stream.value(const <Goal>[])),
          latestWeightProvider
              .overrideWith((ref) => Stream<WeightEntry?>.value(null)),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No weight logged yet'), findsOneWidget);
  });
}
