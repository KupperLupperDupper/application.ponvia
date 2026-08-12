import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Custom bottom navigation with a universal centre "add" button (DESIGN_SPEC
/// `BOTTOM_NAV_SNACKBAR_PRIVACY.md` §1). An 84dp block — a 64dp bar body plus a
/// 20dp hump drawn in the *same* path — hosts four unlabelled icon tabs and a
/// 64dp circular add button that logs a weight from every tab.
class PonviaBottomNav extends StatelessWidget {
  const PonviaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  static const double _blockHeight = 84;
  static const double _barBody = 64;
  static const double _addSize = 64;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final tabs = <_TabSpec>[
      _TabSpec(Icons.monitor_weight_outlined, Icons.monitor_weight, l10n.navHome),
      _TabSpec(Icons.show_chart_outlined, Icons.show_chart, l10n.navHistory),
      _TabSpec(Icons.flag_outlined, Icons.flag, l10n.navGoals),
      _TabSpec(Icons.settings_outlined, Icons.settings, l10n.navSettings),
    ];

    // One shaped Material for the whole bar (hump included): it fills the
    // humped shape with the nav colour *and* clips every tab's press ink to
    // that same shape, so the highlight reads continuously across the hump.
    return SizedBox(
      height: _blockHeight + bottomInset,
      child: Material(
        color: scheme.surfaceContainerHighest,
        shape: _NavShapeBorder(stroke: scheme.outline),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Four icon tabs, in the 64dp bar body, split 2 + 2 around the hump.
            Positioned(
              left: 0,
              right: 0,
              top: _blockHeight - _barBody,
              height: _barBody,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavTab(
                      spec: tabs[0],
                      selected: currentIndex == 0,
                      onTap: () => onTabSelected(0)),
                  const SizedBox(width: 14),
                  _NavTab(
                      spec: tabs[1],
                      selected: currentIndex == 1,
                      onTap: () => onTabSelected(1)),
                  const SizedBox(width: 96),
                  _NavTab(
                      spec: tabs[2],
                      selected: currentIndex == 2,
                      onTap: () => onTabSelected(2)),
                  const SizedBox(width: 14),
                  _NavTab(
                      spec: tabs[3],
                      selected: currentIndex == 3,
                      onTap: () => onTabSelected(3)),
                ],
              ),
            ),
            // Centre add button, sitting in the hump with an even 10dp collar.
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: _AddButton(
                  label: l10n.homeLogWeight,
                  onPressed: onAddPressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        containedInkWell: false,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(selected ? spec.selectedIcon : spec.icon,
                  size: 24, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pressedFill =
        dark ? const Color(0xFF6FC3AE) : const Color(0xFF175449);

    return Semantics(
      button: true,
      label: widget.label,
      child: Tooltip(
        message: widget.label,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: PonviaBottomNav._addSize,
            height: PonviaBottomNav._addSize,
            decoration: BoxDecoration(
              color: _pressed ? pressedFill : scheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0x33102820),
                  blurRadius: _pressed ? 6 : 12,
                  offset: Offset(0, _pressed ? 2 : 3),
                ),
              ],
            ),
            child: Icon(Icons.add, size: 32, color: scheme.onPrimary),
          ),
        ),
      ),
    );
  }
}

/// The one-path humped bar shape (bar body + 20dp hump), used as a `Material`
/// shape so the fill, the ink clip and the 1dp top hairline all follow the same
/// contour. The path x-coords are scaled from the 390dp design width.
class _NavShapeBorder extends ShapeBorder {
  const _NavShapeBorder({required this.stroke});

  final Color stroke;

  static const double _designWidth = 390;

  Path _topContour(Rect rect) {
    final l = rect.left, t = rect.top, w = rect.width;
    final sx = w / _designWidth;
    // M0,20 H128 C154,20 150,0 195,0 C240,0 236,20 262,20 H390
    return Path()
      ..moveTo(l, t + 20)
      ..lineTo(l + 128 * sx, t + 20)
      ..cubicTo(l + 154 * sx, t + 20, l + 150 * sx, t, l + 195 * sx, t)
      ..cubicTo(l + 240 * sx, t, l + 236 * sx, t + 20, l + 262 * sx, t + 20)
      ..lineTo(l + w, t + 20);
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _topContour(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      _topContour(rect),
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  ShapeBorder scale(double t) => this;

  @override
  bool operator ==(Object other) =>
      other is _NavShapeBorder && other.stroke == stroke;

  @override
  int get hashCode => stroke.hashCode;
}
