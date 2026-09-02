import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary300 = Color(0xFF93C5FD);
  static const Color primary400 = Color(0xFF60A5FA);
  static const Color primary500 = Color(0xFF3B82F6);
  static const Color primary600 = Color(0xFF2563EB);

  static const Color surface700 = Color(0xFF334155);
  static const Color surface800 = Color(0xFF1E293B);
  static const Color surface900 = Color(0xFF0F172A);

  static const Color textHigh = Color(0xFFF8FAFC);
  static const Color textMedium = Color(0xFFCBD5E1);
  static const Color textLow = Color(0xFF64748B);

  static const Color accent = Color(0xFFF97316);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color danger = Color(0xFFEF4444);
  static const Color gold = Color(0xFFFFD700);

  static const Color neutralMuscle = Color(0xFF94A3B8);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}

/// Soft light/dark shadows used by the neumorphic design language.
class NeumorphicStyles {
  /// Top-left highlight that catches the light.
  static const BoxShadow lightShadow = BoxShadow(
    color: Color(0x26FFFFFF),
    offset: Offset(-6, -6),
    blurRadius: 12,
  );

  /// Bottom-right drop shadow that grounds the element.
  static const BoxShadow darkShadow = BoxShadow(
    color: Color(0x66000000),
    offset: Offset(6, 6),
    blurRadius: 12,
  );

  /// Inset shadow used for "pressed" neumorphic elements.
  static const BoxShadow innerShadow = BoxShadow(
    color: Color(0x33000000),
    offset: Offset(4, 4),
    blurRadius: 8,
    spreadRadius: -2,
  );
}

/// Central Flutter theme that strictly consumes the `design-system/design-tokens.json` values.
class AppTheme {
  /// Global default typography family (Montserrat via google_fonts).
  static const String fontFamily = 'Montserrat';

  static ThemeData get light => dark;

  static ThemeData get dark {
    final baseTextTheme = const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textHigh,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textHigh,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.textHigh,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textMedium,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textMedium,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textLow,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textLow,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface900,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary500,
        secondary: AppColors.accent,
        surface: AppColors.surface800,
        onSurface: AppColors.textHigh,
        error: AppColors.danger,
      ),
      fontFamily: fontFamily,
      textTheme: GoogleFonts.montserratTextTheme(baseTextTheme),
      cardTheme: const CardThemeData(
        color: AppColors.surface800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface900,
        foregroundColor: AppColors.textHigh,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.primary500.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary400 : AppColors.textLow,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary300 : AppColors.textLow,
          );
        }),
      ),
    );
  }
}