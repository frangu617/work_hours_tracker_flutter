import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/entry.dart';
import '../services/database_helper.dart';
import './admin_screen.dart';
import 'package:intl/intl.dart'; // For date formatting

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Database helper instance
  List<User> _users = []; // List of users
  User? _selectedUser; // Currently selected user
  List<Entry> _entries =
      []; // List of clock-in/out entries for the selected user
  bool _isClockedIn = false; // Tracks if the user is currently clocked in

  @override
  void initState() {
    super.initState();
    _loadUsers(); // Load users when the screen is first created
  }

  // Load all users from the database
  Future<void> _loadUsers() async {
    final users = await _dbHelper.getUsers();
    setState(() {
      _users = users;
    });
  }

  // Load entries for the selected user
  Future<void> _loadEntries() async {
    if (_selectedUser != null) {
      final entries = await _dbHelper.getEntries(_selectedUser!.id!);
      setState(() {
        _entries = entries;
      });
    }
  }

  // Handle clock-in action
  Future<void> _clockIn() async {
    if (_selectedUser != null) {
      final entry = Entry(
        userId: _selectedUser!.id!,
        clockIn: DateTime.now().toIso8601String(),
      );
      await _dbHelper.addEntry(entry);
      setState(() {
        _isClockedIn = true;
      });
      _loadEntries(); // Refresh the entries list
    }
  }

  // Handle clock-out action
  Future<void> _clockOut() async {
    if (_selectedUser != null && _entries.isNotEmpty) {
      final lastEntry = _entries.last;
      lastEntry.clockOut = DateTime.now().toIso8601String();
      await _dbHelper.updateEntry(lastEntry);
      setState(() {
        _isClockedIn = false;
      });
      _loadEntries(); // Refresh the entries list
    }
  }

  // Helper function to calculate total hours worked
  double _calculateTotalHours() {
    double totalHours = 0.0;
    for (var entry in _entries) {
      if (entry.clockOut != null) {
        final clockIn = DateTime.parse(entry.clockIn);
        final clockOut = DateTime.parse(entry.clockOut!);
        totalHours += clockOut.difference(clockIn).inHours.toDouble();
      }
    }
    return totalHours;
  }

  // Helper function to calculate total hours worked for a specific user
  double _calculateTotalHoursForUser(User user) {
    double totalHours = 0.0;
    for (var entry in _entries) {
      if (entry.userId == user.id && entry.clockOut != null) {
        final clockIn = DateTime.parse(entry.clockIn);
        final clockOut = DateTime.parse(entry.clockOut!);
        totalHours += clockOut.difference(clockIn).inHours.toDouble();
      }
    }
    return totalHours;
  }

  // Helper function to calculate total hours worked for a specific date
  double _calculateTotalHoursForDate(DateTime date) {
    double totalHours = 0.0;
    for (var entry in _entries) {
      if (entry.clockOut != null) {
        final clockIn = DateTime.parse(entry.clockIn);
        final clockOut = DateTime.parse(entry.clockOut!);
        if (clockIn.day == date.day &&
            clockIn.month == date.month &&
            clockIn.year == date.year) {
          totalHours += clockOut.difference(clockIn).inHours.toDouble();
        }
      }
    }
    return totalHours;
  }

  // Helper function to calculate total hours worked for a specific month
  double _calculateTotalHoursForMonth(DateTime date) {
    double totalHours = 0.0;
    for (var entry in _entries) {
      if (entry.clockOut != null) {
        final clockIn = DateTime.parse(entry.clockIn);
        final clockOut = DateTime.parse(entry.clockOut!);
        if (clockIn.month == date.month && clockIn.year == date.year) {
          totalHours += clockOut.difference(clockIn).inHours.toDouble();
        }
      }
    }
    return totalHours;
  }

  // Helper function to calculate total hours worked for a specific year
  double _calculateTotalHoursForYear(DateTime date) {
    double totalHours = 0.0;
    for (var entry in _entries) {
      if (entry.clockOut != null) {
        final clockIn = DateTime.parse(entry.clockIn);
        final clockOut = DateTime.parse(entry.clockOut!);
        if (clockIn.year == date.year) {
          totalHours += clockOut.difference(clockIn).inHours.toDouble();
        }
      }
    }
    return totalHours;
  }

  // Helper function to calculate total hours worked for a specific date range
  double _calculateTotalHoursForDateRange(
      DateTime startDate, DateTime endDate) {
    double totalHours = 0.0;
    for (var entry in _entries) {
      if (entry.clockOut != null) {
        final clockIn = DateTime.parse(entry.clockIn);
        final clockOut = DateTime.parse(entry.clockOut!);
        if (clockIn.isAfter(startDate) && clockIn.isBefore(endDate)) {
          totalHours += clockOut.difference(clockIn).inHours.toDouble();
        }
      }
    }
    return totalHours;
  }

  // Add custom hours (clock-in and clock-out times)
  Future<void> _addCustomHours() async {
    if (_selectedUser == null) return; // Ensure a user is selected

    // Step 1: Select clock-in date
    DateTime? clockInDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (clockInDate == null) return; // User canceled date picker

    // Step 2: Select clock-in time
    TimeOfDay? clockInTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (clockInTime == null) return; // User canceled time picker

    // Step 3: Select clock-out date
    DateTime? clockOutDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (clockOutDate == null) return; // User canceled date picker

    // Step 4: Select clock-out time
    TimeOfDay? clockOutTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (clockOutTime == null) return; // User canceled time picker

    // Combine date and time for clock-in and clock-out
    final customClockIn = DateTime(
      clockInDate.year,
      clockInDate.month,
      clockInDate.day,
      clockInTime.hour,
      clockInTime.minute,
    );

    final customClockOut = DateTime(
      clockOutDate.year,
      clockOutDate.month,
      clockOutDate.day,
      clockOutTime.hour,
      clockOutTime.minute,
    );

    // Add the custom entry to the database
    await _dbHelper.addCustomEntry(
        _selectedUser!.id!, customClockIn, customClockOut);
    _loadEntries(); // Refresh the entries list
  }

  // Helper function to format date and time
  String formatDateTime(String isoDate) {
    final DateTime dateTime = DateTime.parse(isoDate);
    final DateFormat formatter =
        DateFormat('EEEE, h:mm a, MM/dd/yyyy'); // Desired format
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work Hours Tracker'),
        actions: [
          // Button to navigate to the AdminScreen
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen()),
              );
              _loadUsers(); // Refresh the users list after returning
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown to select a user
            DropdownButton<User>(
              value: _selectedUser,
              hint: Text('Select a user'),
              items: _users.map((user) {
                return DropdownMenuItem<User>(
                  value: user,
                  child: Row(
                    children: [
                      Text(user.name), // Display user name
                      Spacer(), // Add space between name and delete button
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Delete the selected user
                          await _dbHelper.deleteUser(user.id!);
                          _loadUsers(); // Refresh the users list
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (user) {
                setState(() {
                  _selectedUser = user;
                  _isClockedIn =
                      false; // Reset clock-in status when user changes
                });
                _loadEntries(); // Load entries for the selected user
              },
            ),
            SizedBox(height: 20),

            // Clock-in/out and custom hours buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Clock In button
                ElevatedButton(
                  onPressed:
                      _selectedUser == null || _isClockedIn ? null : _clockIn,
                  child: Text('Clock In'),
                ),
                // Clock Out button
                ElevatedButton(
                  onPressed:
                      _selectedUser == null || !_isClockedIn ? null : _clockOut,
                  child: Text('Clock Out'),
                ),
                // Add Custom Hours button
                ElevatedButton(
                  onPressed: _selectedUser == null ? null : _addCustomHours,
                  child: Text('Add Custom Hours'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Display total hours worked
            Text(
              'Total Hours Worked: ${_calculateTotalHours().toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // List of clock-in/out entries
            Expanded(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return ListTile(
                    title: Text('Clock In: ${formatDateTime(entry.clockIn)}'),
                    subtitle: entry.clockOut != null
                        ? Text('Clock Out: ${formatDateTime(entry.clockOut!)}')
                        : Text('Still clocked in'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Delete the selected entry
                        await _dbHelper.deleteEntry(entry.id!);
                        _loadEntries(); // Refresh the entries list
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
