import 'package:flutter/material.dart';

class AppTheme {
  // * Light theme colors
  static const Color primaryLight = Color(0xFF39C5BB);
  static const Color primaryHoverLight = Color(0xFF2FB3A9);
  static const Color primaryActiveLight = Color(0xFF25A095);
  static const Color primaryFocusLight = Color(0xFF33BCB2);
  static const Color primaryDisabledLight = Color(0xFF7DDAD3);

  static const Color secondaryLight = Color(0xFF6D7F8C);
  static const Color secondaryHoverLight = Color(0xFF5D6E7A);
  static const Color secondaryActiveLight = Color(0xFF4E5D68);
  static const Color secondaryFocusLight = Color(0xFF637382);
  static const Color secondaryDisabledLight = Color(0xFF8E9CA8);

  static const Color accentLight = Color(0xFFFB8BA0);
  static const Color accentHoverLight = Color(0xFFFA768C);
  static const Color accentActiveLight = Color(0xFFF96179);
  static const Color accentFocusLight = Color(0xFFFA8196);
  static const Color accentDisabledLight = Color(0xFFFCA7B8);

  static const Color textPrimaryLight = Color(0xFF2C3E50);
  static const Color textSecondaryLight = Color(0xFF4A5568);
  static const Color textTertiaryLight = Color(0xFF718096);
  static const Color textMutedLight = Color(0xFFA0AEC0);
  static const Color textInvertedLight = Color(0xFFF7FAFC);

  static const Color bgMainLight = Color(0xFFF0FFFD);
  static const Color bgAltLight = Color(0xFFE0F7F5);
  static const Color bgMutedLight = Color(0xFFD0EFED);
  static const Color bgElementLight = Color(0xFFE6FAF8);
  static const Color bgHoverLight = Color(0xFFDAF5F3);
  static const Color bgActiveLight = Color(0xFFC5EEEB);

  // * Dark theme colors
  static const Color primaryDark = Color(0xFF39C5BB);
  static const Color primaryHoverDark = Color(0xFF4AD1C7);
  static const Color primaryActiveDark = Color(0xFF5DDAD1);
  static const Color primaryFocusDark = Color(0xFF44CDC3);
  static const Color primaryDisabledDark = Color(0xFF277F78);

  static const Color secondaryDark = Color(0xFF8498A7);
  static const Color secondaryHoverDark = Color(0xFF95A7B4);
  static const Color secondaryActiveDark = Color(0xFFA6B6C1);
  static const Color secondaryFocusDark = Color(0xFF8FA2AF);
  static const Color secondaryDisabledDark = Color(0xFF667885);

  static const Color accentDark = Color(0xFFFB8BA0);
  static const Color accentHoverDark = Color(0xFFFC9EB0);
  static const Color accentActiveDark = Color(0xFFFDB0C0);
  static const Color accentFocusDark = Color(0xFFFC95AA);
  static const Color accentDisabledDark = Color(0xFFD46F82);

  static const Color textPrimaryDark = Color(0xFFE2F5F3);
  static const Color textSecondaryDark = Color(0xFFC7E5E2);
  static const Color textTertiaryDark = Color(0xFFA0D0CC);
  static const Color textMutedDark = Color(0xFF7AB0AC);
  static const Color textInvertedDark = Color(0xFF1A2A36);

  static const Color bgMainDark = Color(0xFF111923);
  static const Color bgAltDark = Color(0xFF192630);
  static const Color bgMutedDark = Color(0xFF22333F);
  static const Color bgElementDark = Color(0xFF1D2D38);
  static const Color bgHoverDark = Color(0xFF263945);
  static const Color bgActiveDark = Color(0xFF2F4452);

  // * Font
  static const String headingFont = 'Exo2';
  static const String bodyFont = 'Quicksand';

  // * ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: bgMainLight,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryLight,
        onPrimary: textInvertedLight,
        secondary: secondaryLight,
        onSecondary: textInvertedLight,
        error: accentLight,
        onError: textInvertedLight,
        surface: bgMainLight,
        onSurface: textPrimaryLight,
        tertiary: accentLight,
        onTertiary: textInvertedLight,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
        ),
        displayMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
        ),
        displaySmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
        ),
        headlineLarge: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
        ),
        headlineMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
        ),
        headlineSmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
        ),
        titleLarge: TextStyle(fontFamily: headingFont, color: textPrimaryLight),
        titleMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
        ),
        titleSmall: TextStyle(fontFamily: headingFont, color: textPrimaryLight),
        bodyLarge: TextStyle(fontFamily: bodyFont, color: textPrimaryLight),
        bodyMedium: TextStyle(fontFamily: bodyFont, color: textSecondaryLight),
        bodySmall: TextStyle(fontFamily: bodyFont, color: textTertiaryLight),
        labelLarge: TextStyle(fontFamily: bodyFont, color: textPrimaryLight),
        labelMedium: TextStyle(fontFamily: bodyFont, color: textSecondaryLight),
        labelSmall: TextStyle(fontFamily: bodyFont, color: textTertiaryLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryLight,
        foregroundColor: textInvertedLight,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: bgElementLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: textInvertedLight,
          disabledBackgroundColor: primaryDisabledLight,
          disabledForegroundColor: textInvertedLight.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElementLight,
        focusColor: primaryFocusLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: bgMutedLight, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: bgMainDark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: primaryDark,
        onPrimary: textInvertedDark,
        secondary: secondaryDark,
        onSecondary: textInvertedDark,
        error: accentDark,
        onError: textInvertedDark,
        surface: bgMainDark,
        onSurface: textPrimaryDark,
        tertiary: accentDark,
        onTertiary: textInvertedDark,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
        ),
        displayMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
        ),
        displaySmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
        ),
        headlineLarge: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
        ),
        headlineMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
        ),
        headlineSmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
        ),
        titleLarge: TextStyle(fontFamily: headingFont, color: textPrimaryDark),
        titleMedium: TextStyle(fontFamily: headingFont, color: textPrimaryDark),
        titleSmall: TextStyle(fontFamily: headingFont, color: textPrimaryDark),
        bodyLarge: TextStyle(fontFamily: bodyFont, color: textPrimaryDark),
        bodyMedium: TextStyle(fontFamily: bodyFont, color: textSecondaryDark),
        bodySmall: TextStyle(fontFamily: bodyFont, color: textTertiaryDark),
        labelLarge: TextStyle(fontFamily: bodyFont, color: textPrimaryDark),
        labelMedium: TextStyle(fontFamily: bodyFont, color: textSecondaryDark),
        labelSmall: TextStyle(fontFamily: bodyFont, color: textTertiaryDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgElementDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: bgElementDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: textInvertedDark,
          disabledBackgroundColor: primaryDisabledDark,
          disabledForegroundColor: textInvertedDark.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElementDark,
        focusColor: primaryFocusDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: bgMutedDark, thickness: 1),
    );
  }
}
