import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initialize(); // Initialize the database
  runApp(WorkHoursTrackerApp());
}

class WorkHoursTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Hours Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
