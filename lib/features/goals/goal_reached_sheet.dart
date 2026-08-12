import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The calm "you reached it" moment — a light modal bottom sheet shown when the
/// latest weight reaches a goal's target. See `design/handoff/GOAL_REACHED.md`.
///
/// Returns `true` when the user chose "Mark achieved", `false`/`null` when they
/// kept the goal open (also via swipe-down or scrim tap). Tone is a product
/// rule: an acknowledgement, not a reward — no confetti, sound, or haptics.
Future<bool?> showGoalReachedSheet(
  BuildContext context, {
  required String weightLabel,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    // rgba(10,20,17,.42) light · rgba(0,0,0,.60) dark
    barrierColor: dark ? const Color(0x99000000) : const Color(0x6B0A1411),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _GoalReachedSheet(),
    routeSettings: RouteSettings(arguments: weightLabel),
  );
}

class _GoalReachedSheet extends StatelessWidget {
  const _GoalReachedSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final weightLabel =
        ModalRoute.of(context)!.settings.arguments as String? ?? '';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 4,
        bottom: 28 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 28 below the drag handle.
          const SizedBox(height: 24),
          const _Emblem(),
          const SizedBox(height: 24),
          Semantics(
            container: true,
            label: '${l10n.goalReachedTitle}. ${l10n.goalReachedBody(weightLabel)}',
            child: Column(
              children: [
                ExcludeSemantics(
                  child: Text(
                    l10n.goalReachedTitle,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.46, // -0.02em at 23sp
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ExcludeSemantics(
                  child: Text(
                    l10n.goalReachedBody(weightLabel),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.goalMarkAchieved),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.goalReachedKeepOpen,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 64dp `primaryContainer` disc with a `check_circle` glyph. Fades and gently
/// scales in once (250ms), then holds still. Honors reduced motion.
class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final disc = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.check_circle, size: 36, color: scheme.primary),
    );

    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: reduceMotion ? 100 : 250),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: reduceMotion
              ? child
              : Transform.scale(scale: 0.92 + 0.08 * t, child: child),
        ),
        child: disc,
      ),
    );
  }
}
