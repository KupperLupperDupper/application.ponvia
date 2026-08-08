import 'package:flutter/material.dart';

/// Material 3 [ColorScheme]s built from the design tokens. We seed a full scheme
/// (so every role is populated) then override the roles the design specified.
const _seedColor = Color(0xFF1F6A5C);

ColorScheme buildLightColorScheme() {
  final base =
      ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light);
  return base.copyWith(
    primary: const Color(0xFF1F6A5C),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFB3EEDD),
    onPrimaryContainer: const Color(0xFF00201A),
    secondary: const Color(0xFF4A635C),
    surface: const Color(0xFFF6F8F7),
    onSurface: const Color(0xFF171D1B),
    surfaceContainerHighest: const Color(0xFFFFFFFF),
    surfaceContainer: const Color(0xFFEAEFEC),
    onSurfaceVariant: const Color(0xFF59635F),
    outline: const Color(0xFFD3DBD8),
    error: const Color(0xFFBA1A1A),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
  );
}

ColorScheme buildDarkColorScheme() {
  final base =
      ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark);
  return base.copyWith(
    primary: const Color(0xFF8ED8C4),
    onPrimary: const Color(0xFF00382F),
    primaryContainer: const Color(0xFF005046),
    onPrimaryContainer: const Color(0xFFB3EEDD),
    secondary: const Color(0xFFB1CCC4),
    surface: const Color(0xFF0E1412),
    onSurface: const Color(0xFFDEE4E1),
    surfaceContainerHighest: const Color(0xFF161D1B),
    surfaceContainer: const Color(0xFF1F2724),
    onSurfaceVariant: const Color(0xFFA6B0AC),
    outline: const Color(0xFF333C39),
    error: const Color(0xFFFFB4AB),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
  );
}
