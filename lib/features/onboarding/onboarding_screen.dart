import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/typography.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/motion.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/weight_entry.dart';
import '../../l10n/app_localizations.dart';
import '../logging/numeric_keypad.dart';

/// First-run introduction, styled to DESIGN_SPEC §2: welcome → language → theme
/// → unit → optional first weight → all set, with a progress bar and localized,
/// live-applying choices.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  String _weightInput = '';
  int _index = 0;

  static const _lastIndex = 5; // welcome, language, theme, unit, weight, done

  String get _sep =>
      Localizations.localeOf(context).languageCode == 'da' ? ',' : '.';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index == 4 && _weightInput.isNotEmpty) {
      final unit = ref.read(settingsControllerProvider).unit;
      final v = double.tryParse(_weightInput.replaceAll(_sep, '.'));
      if (v != null && v > 0 && v <= 1000) {
        await ref.read(weightRepositoryProvider).add(WeightEntry(
            timestamp: DateTime.now(), weightKg: WeightConverter.toKg(v, unit)));
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
      duration: Motion.route, curve: Motion.emphasized);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final showStepper = _index >= 1 && _index <= 4;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress chrome for the configurable steps.
            AnimatedOpacity(
              opacity: showStepper ? 1 : 0,
              duration: Motion.selection,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.xxl, Insets.lg, Insets.xxl, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (_index / 4).clamp(0.0, 1.0),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: Insets.sm),
                    Text(l10n.onboardStep(_index.clamp(1, 4), 4),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _Welcome(l10n: l10n),
                  _RadioStep(
                    title: l10n.onboardChooseLanguage,
                    options: [
                      (null, l10n.languageSystem),
                      ('en', l10n.languageEnglish),
                      ('da', l10n.languageDanish),
                    ],
                    selected: settings.localeCode,
                    onSelected: controller.setLocale,
                  ),
                  _ThemeStep(
                    title: l10n.onboardChooseTheme,
                    selected: settings.themeMode,
                    onSelected: controller.setThemeMode,
                  ),
                  _UnitStep(
                    title: l10n.onboardPreferredUnit,
                    unit: settings.unit,
                    locale: Localizations.localeOf(context).languageCode,
                    onSelected: controller.setUnit,
                  ),
                  _FirstWeightStep(
                    l10n: l10n,
                    unit: settings.unit,
                    input: _weightInput,
                    separator: _sep,
                    onKey: (k) => setState(() {
                      if (k == _sep && _weightInput.contains(_sep)) return;
                      if (_weightInput.replaceAll(_sep, '').length >= 5) return;
                      _weightInput += _weightInput.isEmpty && k == _sep
                          ? '0$_sep'
                          : k;
                    }),
                    onBackspace: () => setState(() {
                      if (_weightInput.isNotEmpty) {
                        _weightInput =
                            _weightInput.substring(0, _weightInput.length - 1);
                      }
                    }),
                  ),
                  _AllSet(l10n: l10n, settings: settings),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Insets.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _next,
                    child: Text(_index >= _lastIndex
                        ? l10n.onboardStartTracking
                        : _index == 0
                            ? l10n.onboardGetStarted
                            : l10n.actionNext),
                  ),
                  if (_index > 0 && _index < _lastIndex) ...[
                    const SizedBox(height: Insets.sm),
                    TextButton(onPressed: _back, child: Text(l10n.actionBack)),
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

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.title, this.subtitle, required this.child});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Insets.xxl),
          Text(title, style: text.headlineMedium),
          if (subtitle != null) ...[
            const SizedBox(height: Insets.sm),
            Text(subtitle!,
                style: text.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: Insets.xxl),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset('assets/icon/icon-master-1024.png',
                width: 96, height: 96),
          ),
          const SizedBox(height: Insets.xxl),
          Text(l10n.onboardWelcomeTitle,
              textAlign: TextAlign.center, style: text.displaySmall),
          const SizedBox(height: Insets.md),
          Text(l10n.onboardWelcomeBody,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RadioStep extends StatelessWidget {
  const _RadioStep({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<(String?, String)> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StepScaffold(
      title: title,
      child: Column(
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelected(value),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                  decoration: BoxDecoration(
                    color: value == selected
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: value == selected
                        ? null
                        : Border.all(color: scheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        value == selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: value == selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Insets.lg),
                      Text(label,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: value == selected
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeStep extends StatelessWidget {
  const _ThemeStep(
      {required this.title, required this.selected, required this.onSelected});

  final String title;
  final AppThemeMode selected;
  final ValueChanged<AppThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cells = <(AppThemeMode, String, List<Color>)>[
      (AppThemeMode.system, l10n.themeSystem,
          [const Color(0xFFF6F8F7), const Color(0xFF0E1412)]),
      (AppThemeMode.light, l10n.themeLight, [const Color(0xFFF6F8F7)]),
      (AppThemeMode.dark, l10n.themeDark, [const Color(0xFF0E1412)]),
    ];
    final scheme = Theme.of(context).colorScheme;
    return _StepScaffold(
      title: title,
      child: Row(
        children: [
          for (final (mode, label, colors) in cells)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelected(mode),
                  child: Container(
                    padding: const EdgeInsets.all(Insets.md),
                    decoration: BoxDecoration(
                      color: mode == selected ? scheme.primaryContainer : null,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: mode == selected
                              ? scheme.primary
                              : scheme.outline,
                          width: mode == selected ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.outline),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: colors.length == 1
                                  ? [colors.first, colors.first]
                                  : colors,
                              stops: colors.length == 1 ? null : const [0.5, 0.5],
                            ),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        Text(label,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: mode == selected
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurface)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitStep extends StatelessWidget {
  const _UnitStep({
    required this.title,
    required this.unit,
    required this.locale,
    required this.onSelected,
  });

  final String title;
  final WeightUnit unit;
  final String locale;
  final ValueChanged<WeightUnit> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = WeightFormatter(unit, locale: locale);
    return _StepScaffold(
      title: title,
      child: Column(
        children: [
          SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
              ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
              ButtonSegment(value: WeightUnit.st, label: Text('st')),
            ],
            selected: {unit},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onSelected(s.first),
          ),
          const SizedBox(height: Insets.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Insets.xxl),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outline),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(fmt.withUnit(82.4),
                  style: PonviaTypography.heroWeight
                      .copyWith(fontSize: 48, color: scheme.onSurface)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstWeightStep extends StatelessWidget {
  const _FirstWeightStep({
    required this.l10n,
    required this.unit,
    required this.input,
    required this.separator,
    required this.onKey,
    required this.onBackspace,
  });

  final AppLocalizations l10n;
  final WeightUnit unit;
  final String input;
  final String separator;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StepScaffold(
      title: l10n.onboardFirstWeightTitle,
      subtitle: l10n.onboardFirstWeightBody,
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: input.isEmpty ? '0' : input,
                  style: PonviaTypography.heroWeight
                      .copyWith(fontSize: 64, color: scheme.onSurface)),
              TextSpan(
                  text: ' ${unit.code}',
                  style: TextStyle(
                      fontFamily: PonviaTypography.family,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant)),
            ])),
          ),
          const SizedBox(height: Insets.sm),
          Container(width: 200, height: 2, color: scheme.primary),
          const SizedBox(height: Insets.xl),
          NumericKeypad(
              onKey: onKey, onBackspace: onBackspace, decimalSeparator: separator),
        ],
      ),
    );
  }
}

class _AllSet extends StatelessWidget {
  const _AllSet({required this.l10n, required this.settings});
  final AppLocalizations l10n;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final language = switch (settings.localeCode) {
      'en' => l10n.languageEnglish,
      'da' => l10n.languageDanish,
      _ => l10n.languageSystem,
    };
    final theme = switch (settings.themeMode) {
      AppThemeMode.light => l10n.themeLight,
      AppThemeMode.dark => l10n.themeDark,
      AppThemeMode.system => l10n.themeSystem,
    };

    Widget summaryRow(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Insets.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: text.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              Text(value,
                  style: text.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration:
                BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.check, size: 48, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: Insets.xl),
          Text(l10n.onboardAllSetTitle,
              textAlign: TextAlign.center, style: text.displaySmall),
          const SizedBox(height: Insets.md),
          Text(l10n.onboardAllSetBody,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Insets.xxl),
          Container(
            padding: const EdgeInsets.all(Insets.xl),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outline),
            ),
            child: Column(
              children: [
                summaryRow(l10n.settingsLanguage, language),
                summaryRow(l10n.settingsTheme, theme),
                summaryRow(l10n.settingsUnit, settings.unit.code),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
