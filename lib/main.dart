import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initialize(); // Initialize the database
  runApp(WorkHoursTrackerApp());
}

class WorkHoursTrackerApp extends StatelessWidget {
  const WorkHoursTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Hours Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HomeScreen(),
    );
  }
}
