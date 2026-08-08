import 'package:flutter/material.dart';

/// Semantic colors Material 3 has no slot for — weight-delta direction and
/// chart styling. Exposed as a [ThemeExtension] so widgets read them from the
/// active theme. Values come from `design/handoff/tokens.json`.
@immutable
class PonviaColors extends ThemeExtension<PonviaColors> {
  const PonviaColors({
    required this.deltaDown,
    required this.deltaUp,
    required this.deltaUpContainer,
    required this.onDeltaUpContainer,
    required this.deltaFlat,
    required this.chartLine,
    required this.chartArea,
    required this.chartGrid,
  });

  final Color deltaDown;
  final Color deltaUp;
  final Color deltaUpContainer;
  final Color onDeltaUpContainer;
  final Color deltaFlat;
  final Color chartLine;
  final Color chartArea;
  final Color chartGrid;

  static const light = PonviaColors(
    deltaDown: Color(0xFF1F6A5C),
    deltaUp: Color(0xFF8A6238),
    deltaUpContainer: Color(0xFFF3E5D3),
    onDeltaUpContainer: Color(0xFF3E2E17),
    deltaFlat: Color(0xFF59635F),
    chartLine: Color(0xFF1F6A5C),
    chartArea: Color(0xFFB3EEDD),
    chartGrid: Color(0xFFE4EAE7),
  );

  static const dark = PonviaColors(
    deltaDown: Color(0xFF8ED8C4),
    deltaUp: Color(0xFFE0BC88),
    deltaUpContainer: Color(0xFF4A3A22),
    onDeltaUpContainer: Color(0xFFF3E5D3),
    deltaFlat: Color(0xFFA6B0AC),
    chartLine: Color(0xFF8ED8C4),
    chartArea: Color(0xFF005046),
    chartGrid: Color(0xFF2A3431),
  );

  @override
  PonviaColors copyWith({
    Color? deltaDown,
    Color? deltaUp,
    Color? deltaUpContainer,
    Color? onDeltaUpContainer,
    Color? deltaFlat,
    Color? chartLine,
    Color? chartArea,
    Color? chartGrid,
  }) {
    return PonviaColors(
      deltaDown: deltaDown ?? this.deltaDown,
      deltaUp: deltaUp ?? this.deltaUp,
      deltaUpContainer: deltaUpContainer ?? this.deltaUpContainer,
      onDeltaUpContainer: onDeltaUpContainer ?? this.onDeltaUpContainer,
      deltaFlat: deltaFlat ?? this.deltaFlat,
      chartLine: chartLine ?? this.chartLine,
      chartArea: chartArea ?? this.chartArea,
      chartGrid: chartGrid ?? this.chartGrid,
    );
  }

  @override
  PonviaColors lerp(ThemeExtension<PonviaColors>? other, double t) {
    if (other is! PonviaColors) return this;
    return PonviaColors(
      deltaDown: Color.lerp(deltaDown, other.deltaDown, t)!,
      deltaUp: Color.lerp(deltaUp, other.deltaUp, t)!,
      deltaUpContainer: Color.lerp(deltaUpContainer, other.deltaUpContainer, t)!,
      onDeltaUpContainer:
          Color.lerp(onDeltaUpContainer, other.onDeltaUpContainer, t)!,
      deltaFlat: Color.lerp(deltaFlat, other.deltaFlat, t)!,
      chartLine: Color.lerp(chartLine, other.chartLine, t)!,
      chartArea: Color.lerp(chartArea, other.chartArea, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
    );
  }
}
