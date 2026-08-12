import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logging/log_weight_screen.dart';
import 'ponvia_bottom_nav.dart';

/// Persistent bottom-navigation shell hosting the four destinations plus a
/// universal centre "add" that logs a weight from any tab. Each branch screen
/// supplies its own app bar. See `BOTTOM_NAV_SNACKBAR_PRIVACY.md` §1.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Let the body extend under the nav so the raised hump paints the nav
      // fill over content instead of leaving a see-through notch.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: PonviaBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        onAddPressed: () => showLogWeightSheet(context),
      ),
    );
  }
}
