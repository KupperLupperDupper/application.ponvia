import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/ui/motion.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/weight_entry.dart';
import '../../l10n/app_localizations.dart';

/// First-run introduction: welcome → language → unit → theme → optional first
/// weight → all set. Choices apply live (changing the language re-localizes the
/// flow immediately) and are editable later in Settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _weightController = TextEditingController();
  int _index = 0;

  static const _lastIndex = 5;

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    // Step 4: optionally save a first weight entry.
    if (_index == 4) {
      final unit = ref.read(settingsControllerProvider).unit;
      final v =
          double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
      if (v != null && v > 0 && v <= 1000) {
        await ref.read(weightRepositoryProvider).add(
              WeightEntry(
                timestamp: DateTime.now(),
                weightKg: WeightConverter.toKg(v, unit),
              ),
            );
      }
    }
    if (_index >= _lastIndex) {
      await ref.read(settingsControllerProvider.notifier).completeOnboarding();
      if (mounted) context.go('/');
      return;
    }
    _pageController.nextPage(duration: Motion.route, curve: Motion.emphasized);
  }

  void _back() => _pageController.previousPage(
        duration: Motion.route,
        curve: Motion.emphasized,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _Step(
                    title: 'Ponvia',
                    titleStyle: Theme.of(context).textTheme.displaySmall,
                    body: l10n.onboardWelcomeBody,
                  ),
                  _Step(
                    title: l10n.onboardChooseLanguage,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                            value: 'system', label: Text(l10n.languageSystem)),
                        ButtonSegment(
                            value: 'en', label: Text(l10n.languageEnglish)),
                        ButtonSegment(
                            value: 'da', label: Text(l10n.languageDanish)),
                      ],
                      selected: {settings.localeCode ?? 'system'},
                      onSelectionChanged: (s) => controller
                          .setLocale(s.first == 'system' ? null : s.first),
                    ),
                  ),
                  _Step(
                    title: l10n.onboardPreferredUnit,
                    child: SegmentedButton<WeightUnit>(
                      segments: const [
                        ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                        ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                        ButtonSegment(value: WeightUnit.st, label: Text('st')),
                      ],
                      selected: {settings.unit},
                      onSelectionChanged: (s) => controller.setUnit(s.first),
                    ),
                  ),
                  _Step(
                    title: l10n.onboardChooseTheme,
                    child: SegmentedButton<AppThemeMode>(
                      segments: [
                        ButtonSegment(
                            value: AppThemeMode.system,
                            label: Text(l10n.themeSystem)),
                        ButtonSegment(
                            value: AppThemeMode.light,
                            label: Text(l10n.themeLight)),
                        ButtonSegment(
                            value: AppThemeMode.dark,
                            label: Text(l10n.themeDark)),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) =>
                          controller.setThemeMode(s.first),
                    ),
                  ),
                  _Step(
                    title: l10n.onboardFirstWeightTitle,
                    body: l10n.onboardFirstWeightBody,
                    child: TextField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: Theme.of(context).textTheme.displaySmall,
                      decoration: InputDecoration(
                        labelText: l10n.logWeightField(settings.unit.code),
                        suffixText: settings.unit.code,
                      ),
                    ),
                  ),
                  _Step(
                    title: l10n.onboardAllSetTitle,
                    body: l10n.onboardAllSetBody,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
            ),
            _DotsIndicator(count: _lastIndex + 1, index: _index),
            Padding(
              padding: const EdgeInsets.all(Insets.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _next,
                    child: Text(_index >= _lastIndex
                        ? l10n.onboardGetStarted
                        : l10n.actionNext),
                  ),
                  if (_index > 0) ...[
                    const SizedBox(height: Insets.sm),
                    TextButton(
                      onPressed: _back,
                      child: Text(l10n.actionBack),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    this.body,
    this.child,
    this.icon,
    this.titleStyle,
  });

  final String title;
  final String? body;
  final Widget? child;
  final IconData? icon;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          if (icon != null) ...[
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: Insets.lg),
          ],
          Text(title, style: titleStyle ?? text.headlineMedium),
          if (body != null) ...[
            const SizedBox(height: Insets.md),
            Text(body!, style: text.bodyLarge),
          ],
          if (child != null) ...[
            const SizedBox(height: Insets.xxl),
            child!,
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.selection,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? scheme.primary : scheme.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
