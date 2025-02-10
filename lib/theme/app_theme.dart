import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    cardTheme: const CardTheme(
      color: Colors.white, // Card background color in light mode
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87), // Default text color
      bodyMedium: TextStyle(color: Colors.black87), // Default text color
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
  );
}
