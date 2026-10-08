import 'package:flutter/material.dart';

/// Theme extension for surface treatments shared by the custom UI atoms.
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  const AppDesignTokens({
    required this.cardColor,
    required this.cardRadius,
    required this.cardBorderColor,
    required this.cardShadows,
    required this.insetShadows,
    this.frostedGlass = false,
  });

  final Color cardColor;
  final double cardRadius;
  final Color cardBorderColor;
  final List<BoxShadow> cardShadows;
  final List<BoxShadow> insetShadows;
  final bool frostedGlass;

  @override
  AppDesignTokens copyWith({
    Color? cardColor,
    double? cardRadius,
    Color? cardBorderColor,
    List<BoxShadow>? cardShadows,
    List<BoxShadow>? insetShadows,
    bool? frostedGlass,
  }) =>
      AppDesignTokens(
        cardColor: cardColor ?? this.cardColor,
        cardRadius: cardRadius ?? this.cardRadius,
        cardBorderColor: cardBorderColor ?? this.cardBorderColor,
        cardShadows: cardShadows ?? this.cardShadows,
        insetShadows: insetShadows ?? this.insetShadows,
        frostedGlass: frostedGlass ?? this.frostedGlass,
      );

  @override
  AppDesignTokens lerp(ThemeExtension<AppDesignTokens>? other, double t) {
    if (other is! AppDesignTokens) return this;
    return AppDesignTokens(
      cardColor: Color.lerp(cardColor, other.cardColor, t) ?? cardColor,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      cardBorderColor: Color.lerp(cardBorderColor, other.cardBorderColor, t) ??
          cardBorderColor,
      cardShadows: t < 0.5 ? cardShadows : other.cardShadows,
      insetShadows: t < 0.5 ? insetShadows : other.insetShadows,
      frostedGlass: t < 0.5 ? frostedGlass : other.frostedGlass,
    );
  }
}
