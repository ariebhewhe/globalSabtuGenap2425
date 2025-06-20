import 'package:flutter/material.dart';

class AppTheme {
  // * Light theme colors - Tema Bakso
  static const Color primaryLight = Color(0xFFD2691E); // Cokelat kuah bakso
  static const Color primaryHoverLight = Color(0xFFB8581A);
  static const Color primaryActiveLight = Color(0xFF9E4716);
  static const Color primaryFocusLight = Color(0xFFC85F1C);
  static const Color primaryDisabledLight = Color(0xFFE19560);

  static const Color secondaryLight = Color(0xFF8B4513); // Cokelat daging
  static const Color secondaryHoverLight = Color(0xFF7A3C10);
  static const Color secondaryActiveLight = Color(0xFF69340E);
  static const Color secondaryFocusLight = Color(0xFF804012);
  static const Color secondaryDisabledLight = Color(0xFFA66F47);

  static const Color accentLight = Color(0xFFFF6B35); // Oranye cabai/sambal
  static const Color accentHoverLight = Color(0xFFE55A2F);
  static const Color accentActiveLight = Color(0xFFCC4A28);
  static const Color accentFocusLight = Color(0xFFF06132);
  static const Color accentDisabledLight = Color(0xFFFF9B7A);

  static const Color textPrimaryLight = Color(0xFF2D1810); // Cokelat tua
  static const Color textSecondaryLight = Color(0xFF4A3429);
  static const Color textTertiaryLight = Color(0xFF6B5245);
  static const Color textMutedLight = Color(0xFF8D7269);
  static const Color textInvertedLight = Color(0xFFFFFBF7); // Krem hangat

  static const Color bgMainLight = Color(
    0xFFFFF8F0,
  ); // Krem lembut seperti kuah
  static const Color bgAltLight = Color(0xFFFAF0E6); // Beige hangat
  static const Color bgMutedLight = Color(0xFFF5E6D3);
  static const Color bgElementLight = Color(0xFFFDF5E6); // Putih krem
  static const Color bgHoverLight = Color(0xFFF8F0E0);
  static const Color bgActiveLight = Color(0xFFF0E6D0);

  // * Dark theme colors - Tema Bakso Malam
  static const Color primaryDark = Color(
    0xFFE6843B,
  ); // Cokelat cerah untuk dark mode
  static const Color primaryHoverDark = Color(0xFFED9548);
  static const Color primaryActiveDark = Color(0xFFF4A655);
  static const Color primaryFocusDark = Color(0xFFE98B3F);
  static const Color primaryDisabledDark = Color(0xFFB8682E);

  static const Color secondaryDark = Color(0xFFA66337); // Cokelat hangat
  static const Color secondaryHoverDark = Color(0xFFB87144);
  static const Color secondaryActiveDark = Color(0xFFCA7F51);
  static const Color secondaryFocusDark = Color(0xFFB26A3B);
  static const Color secondaryDisabledDark = Color(0xFF85512B);

  static const Color accentDark = Color(0xFFFF7A4D); // Oranye lembut
  static const Color accentHoverDark = Color(0xFFFF8B63);
  static const Color accentActiveDark = Color(0xFFFF9C79);
  static const Color accentFocusDark = Color(0xFFFF8157);
  static const Color accentDisabledDark = Color(0xFFCC5D3A);

  static const Color textPrimaryDark = Color(0xFFFAF0E6); // Krem terang
  static const Color textSecondaryDark = Color(0xFFE6D4C1);
  static const Color textTertiaryDark = Color(0xFFD1B89C);
  static const Color textMutedDark = Color(0xFFB59C85);
  static const Color textInvertedDark = Color(0xFF1A0F0A); // Cokelat gelap

  static const Color bgMainDark = Color(
    0xFF1A0F0A,
  ); // Cokelat gelap seperti malam
  static const Color bgAltDark = Color(0xFF241610);
  static const Color bgMutedDark = Color(0xFF2E1D16);
  static const Color bgElementDark = Color(0xFF21130C);
  static const Color bgHoverDark = Color(0xFF2B1A12);
  static const Color bgActiveDark = Color(0xFF352218);

  // * Font
  static const String headingFont = 'Exo2';
  static const String bodyFont = 'Quicksand';

  // * ThemeData untuk aplikasi Bakso
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
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: bodyFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontFamily: bodyFont,
          color: textSecondaryLight,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          fontFamily: bodyFont,
          color: textTertiaryLight,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          fontFamily: bodyFont,
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontFamily: bodyFont,
          color: textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: bodyFont,
          color: textTertiaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryLight,
        foregroundColor: textInvertedLight,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      cardTheme: CardTheme(
        color: bgElementLight,
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: textInvertedLight,
          disabledBackgroundColor: primaryDisabledLight,
          disabledForegroundColor: textInvertedLight.withValues(alpha: 0.6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElementLight,
        focusColor: primaryFocusLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: bgMutedLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: bgMutedLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: bgMutedLight.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
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
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontFamily: headingFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: bodyFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontFamily: bodyFont,
          color: textSecondaryDark,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          fontFamily: bodyFont,
          color: textTertiaryDark,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          fontFamily: bodyFont,
          color: textPrimaryDark,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontFamily: bodyFont,
          color: textSecondaryDark,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: bodyFont,
          color: textTertiaryDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgElementDark,
        foregroundColor: textPrimaryDark,
        elevation: 2,
        shadowColor: Colors.black54,
      ),
      cardTheme: CardTheme(
        color: bgElementDark,
        elevation: 3,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: textInvertedDark,
          disabledBackgroundColor: primaryDisabledDark,
          disabledForegroundColor: textInvertedDark.withValues(alpha: 0.6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElementDark,
        focusColor: primaryFocusDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: bgMutedDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: bgMutedDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: bgMutedDark.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
