import 'package:flutter/material.dart';

import 'app_design_tokens.dart';

/// Apple-inspired light design language: restrained color, frosted surfaces,
/// generous radii, subtle dividers, and system-like typography.
class AppleTheme {
  AppleTheme._();

  static const Color background = Color(0xFFF2F4F8);
  static const Color surface = Color(0xEFFFFFFF);
  static const Color ink = Color(0xFF172033);
  static const Color secondaryInk = Color(0xFF647084);
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color separator = Color(0xFFDCE2EA);
  static const Color systemRed = Color(0xFFFF3B30);

  static const double cardRadius = 22;
  static const BorderRadius cardBorderRadius =
      BorderRadius.all(Radius.circular(cardRadius));
  static const BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: cardBorderRadius,
    border: Border.fromBorderSide(BorderSide(color: separator)),
    boxShadow: [
      BoxShadow(
        color: Color(0x160E1B2A),
        offset: Offset(0, 8),
        blurRadius: 24,
      ),
    ],
  );

  static const AppDesignTokens designTokens = AppDesignTokens(
    cardColor: surface,
    cardRadius: cardRadius,
    cardBorderColor: Color(0xBFFFFFFF),
    cardShadows: [
      BoxShadow(
        color: Color(0x160E1B2A),
        offset: Offset(0, 8),
        blurRadius: 24,
      ),
    ],
    insetShadows: [],
    frostedGlass: true,
  );

  static ThemeData get theme {
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: ink,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleLarge:
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ink),
      titleMedium:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      bodyLarge:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: ink),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryInk,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryInk,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryInk,
      ),
    );
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: separator),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: systemBlue,
        secondary: Color(0xFF30B0C7),
        surface: Colors.white,
        onSurface: ink,
        error: systemRed,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardBorderRadius,
          side: const BorderSide(color: separator),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: const BorderSide(color: systemBlue, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        indicatorColor: systemBlue.withValues(alpha: 0.12),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? systemBlue
                  : secondaryInk,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
      ),
      extensions: const [designTokens],
    );
  }
}
