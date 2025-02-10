import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.blue.shade400,
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardTheme(
      color: Colors.white54, // Card background color in light mode
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87), // Default text color
      bodyMedium: TextStyle(color: Colors.black87), // Default text color
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
          color: Colors.black87), // Ensures dropdown text is black
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
            Colors.white), // Light mode dropdown background
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: Colors.grey[900],
    scaffoldBackgroundColor: Colors.grey[800],
    cardTheme: CardTheme(
      color: Colors.grey[900], // Card background color in dark mode
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white), // Default text color
      bodyMedium: TextStyle(color: Colors.white), // Default text color
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
          color: Colors.white), // Ensures dropdown text is white
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
            Colors.white70), // Dark mode dropdown background
      ),
    ),
  );
}
