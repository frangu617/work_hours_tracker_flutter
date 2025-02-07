import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/entry.dart';
import '../services/database_helper.dart';
import './admin_screen.dart';
import 'package:intl/intl.dart'; // Import the intl package

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

  // Add customr hours worked
  Future<void> _addCustomHours() async {
    if (_selectedUser == null) return;

    DateTime? clockIn = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (clockIn == null) return;

    TimeOfDay? clockInTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (clockInTime == null) return;

    DateTime? clockOut = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (clockOut == null) return;

    TimeOfDay? clockOutTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (clockOutTime == null) return;

    // Combine date and time
    final customClockIn = DateTime(
      clockIn.year,
      clockIn.month,
      clockIn.day,
      clockInTime.hour,
      clockInTime.minute,
    );

    final customClockOut = DateTime(
      clockOut.year,
      clockOut.month,
      clockOut.day,
      clockOutTime.hour,
      clockOutTime.minute,
    );

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
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen()),
              );
              _loadUsers();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<User>(
              value: _selectedUser,
              hint: Text('Select a user'),
              items: _users.map((user) {
                return DropdownMenuItem<User>(
                  value: user,
                  child: Text(user.name),
                );
              }).toList(),
              onChanged: (user) {
                setState(() {
                  _selectedUser = user;
                  _isClockedIn = false;
                });
                _loadEntries();
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      _selectedUser == null || _isClockedIn ? null : _clockIn,
                  child: Text('Clock In'),
                ),
                ElevatedButton(
                  onPressed:
                      _selectedUser == null || !_isClockedIn ? null : _clockOut,
                  child: Text('Clock Out'),
                ),
                ElevatedButton(
                  onPressed: _selectedUser == null ? null : _addCustomHours,
                  child: Text('Add Custom Hours'),
                ),
              ],
            ),
            SizedBox(height: 20),
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
                      icon: Icon(Icons.delete),
                      onPressed: () async {
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
