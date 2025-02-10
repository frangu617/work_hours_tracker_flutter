import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/entry.dart';
import '../services/database_helper.dart';
import '../widgets/week_card.dart';
import 'admin_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<User> _users = [];
  User? _selectedUser;
  List<Entry> _entries = [];
  bool _isClockedIn = false;
  bool _isDarkMode = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _dbHelper.getUsers();
    if (mounted) {
      setState(() {
        _users = users.toSet().toList();
      });
    }
  }

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
      _loadEntries();
    }
  }

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
      _loadEntries();
    }
  }

  Future<void> _addCustomHours() async {
    if (_selectedUser == null) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final DateTime clockIn = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final DateTime? pickedOutDate = await showDatePicker(
      context: context,
      initialDate: clockIn,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedOutDate == null) return;

    final TimeOfDay? pickedOutTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(clockIn),
    );

    if (pickedOutTime == null) return;

    final DateTime clockOut = DateTime(
      pickedOutDate.year,
      pickedOutDate.month,
      pickedOutDate.day,
      pickedOutTime.hour,
      pickedOutTime.minute,
    );

    await _dbHelper.addCustomEntry(_selectedUser!.id!, clockIn, clockOut);
    _loadEntries();
  }

  Future<void> _calculateWorkedHoursForDateRange() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user first.')),
      );
      return;
    }

    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (dateRange == null) return;

    final double totalHours = await _dbHelper.calculateTotalHours(
      _selectedUser!.id!,
      dateRange.start,
      dateRange.end,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Total Worked Hours'),
            content: Text(
              'Total hours worked from ${DateFormat('MM/dd/yyyy').format(dateRange.start)} '
              'to ${DateFormat('MM/dd/yyyy').format(dateRange.end)}: '
              '${totalHours.toStringAsFixed(2)} hours',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Hours Tracker',
      theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Work Hours Tracker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminScreen()),
                );
                _loadUsers();
              },
            ),
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white),
              onPressed: _toggleTheme,
            ),
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
              DropdownButton<User>(
                isExpanded: true,
                value: _selectedUser,
                hint: Text(
                  'Select a user',
                  style: _isDarkMode
                      ? AppTheme.darkTheme.textTheme.bodyLarge : AppTheme.lightTheme.textTheme.bodyLarge,
                       // Uses theme text color
                ),
                items: _users.map((user) {
                  return DropdownMenuItem<User>(
                    value: user,
                    child: Text(
                      user.name,
                      style: _isDarkMode ? AppTheme.darkTheme.textTheme.bodyLarge : AppTheme.lightTheme.textTheme.bodyLarge, // Uses theme text color
                    ),
                  );
                }).toList(),
                onChanged: (user) {
                  setState(() {
                    _selectedUser = user;
                    _isClockedIn = false;
                  });
                  _loadEntries();
                },
                dropdownColor: Theme.of(context)
                    .scaffoldBackgroundColor, // Matches theme background
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge, // Ensures selected item follows theme
                icon: Icon(Icons.arrow_drop_down,
                    color: Theme.of(context).iconTheme.color),
                underline: Container(
                  height: 2,
                  color: Theme.of(context)
                      .primaryColor, // Uses theme primary color for underline
                ),
              ),

              const SizedBox(height: 20),
              // Clock In/Out Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed:
                        _selectedUser == null || _isClockedIn ? null : _clockIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Clock In',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: _selectedUser == null || !_isClockedIn
                        ? null
                        : _clockOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                onPressed: _selectedUser == null ? null : _addCustomHours,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add Custom Hours',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // Calculate Worked Hours for Date Range Button
              ElevatedButton(
                onPressed: _calculateWorkedHoursForDateRange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Calculate Worked Hours for Date Range',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // Entries List Grouped by Week
              Expanded(
                child: ListView(
                  children:
                      _groupEntriesByWeek(_entries).entries.map((weekEntry) {
                    return WeekCard(
                      weekStartDate: weekEntry.key,
                      dailyEntries: weekEntry.value,
                      isEditMode: _isEditMode,
                      onDeleteEntry: (entryId) async {
                        await _dbHelper.deleteEntry(entryId);
                        _loadEntries();
                      },
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

  Map<String, Map<String, List<Entry>>> _groupEntriesByWeek(
      List<Entry> entries) {
    final Map<String, Map<String, List<Entry>>> groupedEntries = {};

    for (var entry in entries) {
      final DateTime clockInDate = DateTime.parse(entry.clockIn);
      final DateTime startOfWeek = _getStartOfWeek(clockInDate);
      final String weekKey = DateFormat('MM/dd/yyyy').format(startOfWeek);
      final String dayKey = DateFormat('EEEE, MM/dd/yyyy').format(clockInDate);

      if (!groupedEntries.containsKey(weekKey)) {
        groupedEntries[weekKey] = {};
      }

      if (!groupedEntries[weekKey]!.containsKey(dayKey)) {
        groupedEntries[weekKey]![dayKey] = [];
      }

      groupedEntries[weekKey]![dayKey]!.add(entry);
    }

    return groupedEntries;
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}
