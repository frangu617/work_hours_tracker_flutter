import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';

void main() {
  // Initialize the database factory for FFI
  DatabaseHelper.initialize();
  runApp(WorkHoursTrackerApp());
}

class WorkHoursTrackerApp extends StatelessWidget {
  const WorkHoursTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Hours Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // Set the HomeScreen as the initial screen
    );
  }
}