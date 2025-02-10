import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/entry.dart';
import '../services/database_helper.dart';
import './admin_screen.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../theme/app_theme.dart'; // Import the theme file

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Database helper instance
  List<User> _users = []; // List of users
  User? _selectedUser; // Currently selected user
  List<Entry> _entries = []; // List of clock-in/out entries for the selected user
  bool _isClockedIn = false; // Tracks if the user is currently clocked in
  bool _isDarkMode = false; // Tracks dark mode

  @override
  void initState() {
    super.initState();
    _loadUsers(); // Load users when the screen is first created
  }

  // Load all users from the database
  Future<void> _loadUsers() async {
    final users = await _dbHelper.getUsers();
    if (mounted) {
      setState(() {
        _users = users.toSet().toList(); // Remove duplicates
      });
    }
  }

  // Load entries for the selected user
  Future<void> _loadEntries() async {
    if (_selectedUser != null) {
      final entries = await _dbHelper.getEntries(_selectedUser!.id!);
      if (mounted) {
        setState(() {
          _entries = entries;
        });
      }
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
      if (mounted) {
        setState(() {
          _isClockedIn = true;
        });
      }
      _loadEntries(); // Refresh the entries list
    }
  }

  // Handle clock-out action
  Future<void> _clockOut() async {
    if (_selectedUser != null && _entries.isNotEmpty) {
      final lastEntry = _entries.last;
      lastEntry.clockOut = DateTime.now().toIso8601String();
      await _dbHelper.updateEntry(lastEntry);
      if (mounted) {
        setState(() {
          _isClockedIn = false;
        });
      }
      _loadEntries(); // Refresh the entries list
    }
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
    await _dbHelper.addCustomEntry(_selectedUser!.id!, customClockIn, customClockOut);
    _loadEntries(); // Refresh the entries list
  }

  // Helper function to format date and time
  String formatDateTime(String isoDate) {
    final DateTime dateTime = DateTime.parse(isoDate);
    final DateFormat formatter = DateFormat('EEEE, h:mm a, MM/dd/yyyy'); // Desired format
    return formatter.format(dateTime);
  }

  // Toggle dark mode
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Hours Tracker',
      theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Work Hours Tracker',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: _isDarkMode ? Colors.grey[900] : AppTheme.primaryColor,
          actions: [
            IconButton(
              icon: Icon(Icons.person_add, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminScreen()),
                );
                _loadUsers();
              },
            ),
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
              onPressed: _toggleTheme,
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
                hint: Text('Select a user', style: TextStyle(color: _isDarkMode ? Colors.white : AppTheme.textColor)),
                items: _users.isNotEmpty
                    ? _users.map((user) {
                        return DropdownMenuItem<User>(
                          value: user,
                          child: SizedBox(
                            width: double.infinity, // Ensure the dropdown item takes full width
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: TextStyle(color: AppTheme.textColor),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await _dbHelper.deleteUser(user.id!);
                                    _loadUsers(); // Refresh the users list
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList()
                    : [], // If _users is empty, provide an empty list
                onChanged: (user) {
                  if (user != null) {
                    setState(() {
                      _selectedUser = user;
                      _isClockedIn = false; // Reset clock-in status when user changes
                    });
                    _loadEntries(); // Load entries for the selected user
                  }
                },
                dropdownColor: _isDarkMode ? Colors.grey[800] : AppTheme.backgroundColor,
                style: TextStyle(color: _isDarkMode ? Colors.white : AppTheme.textColor),
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                underline: Container(
                  height: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 20),

              // Clock-in/out and custom hours buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Clock In button
                  ElevatedButton(
                    onPressed: _selectedUser == null || _isClockedIn ? null : _clockIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Clock In', style: TextStyle(color: Colors.white)),
                  ),
                  // Clock Out button
                  ElevatedButton(
                    onPressed: _selectedUser == null || !_isClockedIn ? null : _clockOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Clock Out', style: TextStyle(color: Colors.white)),
                  ),
                  // Add Custom Hours button
                  ElevatedButton(
                    onPressed: _selectedUser == null ? null : _addCustomHours,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Add Custom Hours', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // List of clock-in/out entries
              Expanded(
                child: ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text('Clock In: ${formatDateTime(entry.clockIn)}', style: TextStyle(color: _isDarkMode ? Colors.white : AppTheme.textColor)),
                        subtitle: entry.clockOut != null
                            ? Text('Clock Out: ${formatDateTime(entry.clockOut!)}', style: TextStyle(color: _isDarkMode ? Colors.white : AppTheme.textColor))
                            : Text('Still clocked in', style: TextStyle(color: _isDarkMode ? Colors.white : AppTheme.textColor)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _dbHelper.deleteEntry(entry.id!);
                            _loadEntries(); // Refresh the entries list
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}