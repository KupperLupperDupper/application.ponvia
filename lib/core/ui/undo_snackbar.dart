import 'package:flutter/material.dart';

/// The bespoke undo snackbar (DESIGN_SPEC `BOTTOM_NAV_SNACKBAR_PRIVACY.md` §2),
/// replacing the default Material `SnackBar` app-wide. Floating, inset 16 each
/// side and 98 from the bottom so it clears the nav hump; a draining timer bar
/// runs along the bottom edge.
///
/// [icon] distinguishes the surface: `delete` for a single delete,
/// `settings_backup_restore` for clear-all, `restore` for import-replace.
/// [bulk] uses the longer 6s window; single deletes use 4s.
void showUndoSnackbar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required IconData icon,
  required VoidCallback onUndo,
  bool bulk = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final duration = Duration(milliseconds: bulk ? 6000 : 4000);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        content: _UndoSnackContent(
          message: message,
          undoLabel: undoLabel,
          icon: icon,
          duration: duration,
          onUndo: () {
            messenger.hideCurrentSnackBar();
            onUndo();
          },
        ),
      ),
    );
}

class _UndoSnackContent extends StatefulWidget {
  const _UndoSnackContent({
    required this.message,
    required this.undoLabel,
    required this.icon,
    required this.duration,
    required this.onUndo,
  });

  final String message;
  final String undoLabel;
  final IconData icon;
  final Duration duration;
  final VoidCallback onUndo;

  @override
  State<_UndoSnackContent> createState() => _UndoSnackContentState();
}

class _UndoSnackContentState extends State<_UndoSnackContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final fill = dark ? const Color(0xFF1F2724) : const Color(0xFF173A34);
    final onFill = dark ? const Color(0xFFDEE4E1) : const Color(0xFFE3F3EE);
    final outline = dark ? const Color(0xFF333C39) : null;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
        border: outline == null ? null : Border.all(color: outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47102820), // level 3, rgba(16,32,28,.28)
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, size: 20, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onFill,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _UndoAction(label: widget.undoLabel, onTap: widget.onUndo),
                ],
              ),
            ),
            // Draining timer bar along the bottom edge.
            SizedBox(
              height: 3,
              child: AnimatedBuilder(
                animation: _timer,
                builder: (context, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 1 - _timer.value,
                    child: Container(color: scheme.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UndoAction extends StatelessWidget {
  const _UndoAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
            : null,
      ),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8ED8C4),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
