import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(WorkHoursTrackerApp());
}

class WorkHoursTrackerApp extends StatelessWidget {
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