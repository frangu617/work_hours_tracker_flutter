import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/entry.dart';
import '../services/database_helper.dart';
import './admin_screen.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Database helper instance
  List<User> _users = []; // List to store all users
  User? _selectedUser; // Currently selected user
  List<Entry> _entries = []; // List to store all entries for the selected user
  bool _isClockedIn = false; // Tracks if the user is currently clocked in
  bool _isDarkMode = false; // Tracks if dark mode is enabled
  bool _isEditMode =
      false; // Tracks if edit mode is enabled (for delete buttons)

  @override
  void initState() {
    super.initState();
    _loadUsers(); // Load users when the screen is initialized
  }

  // Load all users from the database
  Future<void> _loadUsers() async {
    final users = await _dbHelper.getUsers(); // Fetch users from the database
    if (mounted) {
      setState(() {
        _users = users.toSet().toList(); // Update the list of users
      });
    }
  }

  // Load all entries for the selected user
  Future<void> _loadEntries() async {
    if (_selectedUser != null) {
      final entries = await _dbHelper.getEntries(
          _selectedUser!.id!); // Fetch entries for the selected user
      if (mounted) {
        setState(() {
          _entries = entries; // Update the list of entries
        });
      }
    }
  }

  // Clock in the selected user
  Future<void> _clockIn() async {
    if (_selectedUser != null) {
      final entry = Entry(
        userId: _selectedUser!.id!,
        clockIn:
            DateTime.now().toIso8601String(), // Set the clock-in time to now
      );
      await _dbHelper.addEntry(entry); // Save the entry to the database
      if (mounted) {
        setState(() {
          _isClockedIn = true; // Update the clock-in status
        });
      }
      _loadEntries(); // Reload entries to reflect the new clock-in
    }
  }

  // Clock out the selected user
  Future<void> _clockOut() async {
    if (_selectedUser != null && _entries.isNotEmpty) {
      final lastEntry = _entries.last; // Get the last entry (current clock-in)
      lastEntry.clockOut =
          DateTime.now().toIso8601String(); // Set the clock-out time to now
      await _dbHelper
          .updateEntry(lastEntry); // Update the entry in the database
      if (mounted) {
        setState(() {
          _isClockedIn = false; // Update the clock-in status
        });
      }
      _loadEntries(); // Reload entries to reflect the clock-out
    }
  }

  // Add custom hours for the selected user
  Future<void> _addCustomHours() async {
    if (_selectedUser == null) return; // Ensure a user is selected

    // Show a date picker to select the clock-in date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return; // Exit if no date is selected

    // Show a time picker to select the clock-in time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return; // Exit if no time is selected

    // Combine the selected date and time into a DateTime object for clock-in
    final DateTime clockIn = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Show a date picker to select the clock-out date
    final DateTime? pickedOutDate = await showDatePicker(
      context: context,
      initialDate: clockIn,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedOutDate == null) return; // Exit if no date is selected

    // Show a time picker to select the clock-out time
    final TimeOfDay? pickedOutTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(clockIn),
    );

    if (pickedOutTime == null) return; // Exit if no time is selected

    // Combine the selected date and time into a DateTime object for clock-out
    final DateTime clockOut = DateTime(
      pickedOutDate.year,
      pickedOutDate.month,
      pickedOutDate.day,
      pickedOutTime.hour,
      pickedOutTime.minute,
    );

    // Add the custom entry to the database
    await _dbHelper.addCustomEntry(_selectedUser!.id!, clockIn, clockOut);
    _loadEntries(); // Reload entries to reflect the new custom entry
  }

  // Calculate total worked hours for a selected date range
  Future<void> _calculateWorkedHoursForDateRange() async {
    if (_selectedUser == null) {
      // Show a message if no user is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user first.')),
      );
      return;
    }

    // Show a date range picker to select the start and end dates
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // Earliest selectable date
      lastDate: DateTime.now(), // Latest selectable date (today)
      initialDateRange: DateTimeRange(
        start: DateTime.now()
            .subtract(const Duration(days: 7)), // Default to the last 7 days
        end: DateTime.now(),
      ),
    );

    if (dateRange == null) return; // Exit if no date range is selected

    // Calculate the total hours worked within the selected date range
    final double totalHours = await _dbHelper.calculateTotalHours(
      _selectedUser!.id!, // User ID
      dateRange.start, // Start date of the range
      dateRange.end, // End date of the range
    );

    if (mounted) {
      // Show a dialog with the total hours worked
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Total Worked Hours'),
            content: Text(
              'Total hours worked from ${DateFormat('MM/dd/yyyy').format(dateRange.start)} '
              'to ${DateFormat('MM/dd/yyyy').format(dateRange.end)}: '
              '${totalHours.toStringAsFixed(2)} hours', // Display total hours with 2 decimal places
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Format a date string to a readable format
  String formatDateTime(String isoDate) {
    final DateTime dateTime =
        DateTime.parse(isoDate); // Parse the ISO date string
    final DateFormat formatter =
        DateFormat('EEEE, h:mm a, MM/dd/yyyy'); // Define the format
    return formatter.format(dateTime); // Return the formatted date string
  }

  // Toggle between light and dark mode
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode; // Toggle the dark mode state
    });
  }

  // Toggle edit mode (for showing/hiding delete buttons)
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode; // Toggle the edit mode state
    });
  }

  // Helper function to group entries by week and calculate daily hours
  Map<String, Map<String, List<Entry>>> _groupEntriesByWeek(
      List<Entry> entries) {
    final Map<String, Map<String, List<Entry>>> groupedEntries = {};

    for (var entry in entries) {
      final DateTime clockInDate =
          DateTime.parse(entry.clockIn); // Parse the clock-in date
      final DateTime startOfWeek =
          _getStartOfWeek(clockInDate); // Get the start of the week (Monday)
      final String weekKey = DateFormat('MM/dd/yyyy')
          .format(startOfWeek); // Format the start of the week as a key

      // Format the day key (e.g., "Monday, 10/02/2023")
      final String dayKey = DateFormat('EEEE, MM/dd/yyyy').format(clockInDate);

      if (!groupedEntries.containsKey(weekKey)) {
        groupedEntries[weekKey] =
            {}; // Initialize the map for the week if it doesn't exist
      }

      if (!groupedEntries[weekKey]!.containsKey(dayKey)) {
        groupedEntries[weekKey]![dayKey] =
            []; // Initialize the list for the day if it doesn't exist
      }

      groupedEntries[weekKey]![dayKey]!
          .add(entry); // Add the entry to the corresponding day
    }

    return groupedEntries; // Return the grouped entries with daily entries
  }

  // Helper function to get the start of the week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    // Subtract the current weekday to get to the previous Monday
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, List<Entry>>> groupedEntries =
        _groupEntriesByWeek(_entries); // Group entries by week and day

    return MaterialApp(
      title: 'Work Hours Tracker',
      theme: _isDarkMode
          ? AppTheme.darkTheme
          : AppTheme.lightTheme, // Apply light or dark theme
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Work Hours Tracker'),
          backgroundColor: _isDarkMode
              ? Colors.grey[900]
              : AppTheme.primaryColor, // Set app bar color
          actions: [
            // Button to navigate to the admin screen
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminScreen()),
                );
                _loadUsers(); // Reload users after returning from the admin screen
              },
            ),
            // Button to toggle between light and dark mode
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white),
              onPressed: _toggleTheme,
            ),
            // Button to toggle edit mode
            IconButton(
              icon: Icon(_isEditMode ? Icons.done : Icons.edit,
                  color: Colors.white),
              onPressed: _toggleEditMode,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dropdown to select a user
              SizedBox(
                width: double.infinity,
                child: DropdownButton<User>(
                  isExpanded: true, // Ensures dropdown takes full width
                  value: _selectedUser,
                  hint: const Text('Select a user'),
                  items: _users.map((user) {
                    return DropdownMenuItem<User>(
                      value: user,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(user.name), // Display user name
                          ),
                          if (_isEditMode) // Show delete button only in edit mode
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _dbHelper
                                    .deleteUser(user.id!); // Delete the user
                                _loadUsers(); // Reload users after deletion
                              },
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (user) {
                    setState(() {
                      _selectedUser = user; // Update the selected user
                      _isClockedIn = false; // Reset clock-in status
                    });
                    _loadEntries(); // Load entries for the selected user
                  },
                  dropdownColor: _isDarkMode
                      ? Colors.grey[800]
                      : AppTheme.backgroundColor, // Dropdown background color
                  style: const TextStyle(
                      color: AppTheme.textColor), // Dropdown text color
                  icon: const Icon(Icons.arrow_drop_down,
                      color: AppTheme.primaryColor), // Dropdown icon
                  underline: Container(
                    height: 2,
                    color: AppTheme.primaryColor, // Dropdown underline color
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Clock In/Out Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _selectedUser == null || _isClockedIn
                        ? null
                        : _clockIn, // Disable if no user or already clocked in
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor, // Button color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // Rounded corners
                      ),
                    ),
                    child: const Text('Clock In',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: _selectedUser == null || !_isClockedIn
                        ? null // Disable if no user or not clocked in
                        : _clockOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor, // Button color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // Rounded corners
                      ),
                    ),
                    child: const Text('Clock Out',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Add Custom Hours Button
              ElevatedButton(
                onPressed: _selectedUser == null
                    ? null
                    : _addCustomHours, // Disable if no user is selected
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buttonColor, // Button color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
                child: const Text('Add Custom Hours',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // Calculate Worked Hours for Date Range Button
              ElevatedButton(
                onPressed:
                    _calculateWorkedHoursForDateRange, // Trigger date range calculation
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buttonColor, // Button color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
                child: const Text('Calculate Worked Hours for Date Range',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // Entries List Grouped by Week with Daily Entries
              Expanded(
                child: ListView(
                  children: groupedEntries.entries.map((weekEntry) {
                    final String weekStartDate =
                        weekEntry.key; // Week start date (Monday)
                    final Map<String, List<Entry>> dailyEntries =
                        weekEntry.value; // Daily entries for the week

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Week header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Week Starting: $weekStartDate',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        // Daily entries breakdown
                        ...dailyEntries.entries.map((dayEntry) {
                          final String dayKey = dayEntry
                              .key; // Day key (e.g., "Monday, 10/02/2023")
                          final List<Entry> entries =
                              dayEntry.value; // Entries for the day

                          // Calculate total hours worked for the day
                          double totalHours = 0;
                          for (var entry in entries) {
                            if (entry.clockOut != null) {
                              final DateTime clockIn =
                                  DateTime.parse(entry.clockIn);
                              final DateTime clockOut =
                                  DateTime.parse(entry.clockOut!);
                              totalHours +=
                                  clockOut.difference(clockIn).inMinutes /
                                      60.0; // Convert minutes to hours
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // Rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Day and date
                                  Text(
                                    dayKey,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Clock-in and clock-out times
                                  ...entries.map((entry) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Clock In: ${formatDateTime(entry.clockIn)}',
                                                    style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                  if (entry.clockOut != null)
                                                    Text(
                                                      'Clock Out: ${formatDateTime(entry.clockOut!)}',
                                                      style: TextStyle(
                                                        color: _isDarkMode
                                                            ? Colors.white70
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (_isEditMode) // Show delete button only in edit mode
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () async {
                                                  await _dbHelper.deleteEntry(entry
                                                      .id!); // Delete the entry
                                                  _loadEntries(); // Reload entries after deletion
                                                },
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    );
                                  }).toList(),
                                  // Total hours for the day
                                  Text(
                                    'Total Hours: ${totalHours.toStringAsFixed(2)} hours',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
