import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFFE53935); // Main red color
  static const Color primaryDark = Color(0xFFC62828); // Darker red shade
  static const Color primaryLight = Color(0xFFEF5350); // Lighter red shade

  // Background Colors
  static const Color backgroundColor = Color(0xFF121212); // Darker background
  static const Color surfaceColor = Color(0xFF1E1E1E); // Surface color
  static const Color cardColor = Color(0xFF2D2D2D); // Card background

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF8A8A8A);

  // Accent Colors
  static const Color accentSuccess = Color(0xFF43A047); // Green
  static const Color accentError = Color(0xFFD32F2F); // Error red
  static const Color accentWarning = Color(0xFFFFA000); // Warning orange

  // Border and Divider Colors
  static const Color borderColor = Color(0xFF3D3D3D);

  // Opacity Levels
  static const double emphasisHigh = 1.0;
  static const double emphasisMedium = 0.74;
  static const double emphasisLow = 0.38;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    letterSpacing: 0.1,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  // Input Decoration Theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor.withOpacity(0.5),
    hintStyle: bodyMedium.copyWith(color: textHint),
    prefixIconColor: primaryColor,
    suffixIconColor: textHint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: accentError),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: accentError, width: 2),
    ),
  );

  // Button Theme
  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: textPrimary,
      padding: const EdgeInsets.symmetric(vertical: paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      elevation: 0,
      shadowColor: primaryColor.withOpacity(0.3),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return primaryDark;
          }
          if (states.contains(MaterialState.hovered)) {
            return primaryLight;
          }
          return null;
        },
      ),
    ),
  );

  // Card Theme
  static CardTheme cardTheme = CardTheme(
    color: cardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
  );

  // Snackbar Theme
  static SnackBarThemeData snackBarTheme = SnackBarThemeData(
    backgroundColor: surfaceColor,
    contentTextStyle: bodyMedium,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
    ),
    elevation: 4,
    actionTextColor: primaryLight,
  );

  // App Bar Theme
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: backgroundColor,
    elevation: 0,
    iconTheme: IconThemeData(color: primaryColor),
    titleTextStyle: headingMedium,
  );

  // Get ThemeData
  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      brightness: Brightness.dark,
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: buttonText,
      ),
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      cardTheme: cardTheme,
      snackBarTheme: snackBarTheme,
      appBarTheme: appBarTheme,
      iconTheme: IconThemeData(color: primaryColor),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryLight,
        surface: surfaceColor,
        background: backgroundColor,
        error: accentError,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textPrimary,
        brightness: Brightness.dark,
      ),
    );
  }
}
