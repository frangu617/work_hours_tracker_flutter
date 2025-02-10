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
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<User> _users = [];
  User? _selectedUser;
  List<Entry> _entries = [];
  bool _isClockedIn = false;
  bool _isDarkMode = false;

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

  String formatDateTime(String isoDate) {
    final DateTime dateTime = DateTime.parse(isoDate);
    final DateFormat formatter = DateFormat('EEEE, h:mm a, MM/dd/yyyy');
    return formatter.format(dateTime);
  }

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
          title: const Text('Work Hours Tracker'),
          backgroundColor:
              _isDarkMode ? Colors.grey[900] : AppTheme.primaryColor,
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
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed Dropdown Button
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
                            child: Text(user.name),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _dbHelper.deleteUser(user.id!);
                              _loadUsers();
                            },
                          ),
                        ],
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
                  dropdownColor:
                      _isDarkMode ? Colors.grey[800] : AppTheme.backgroundColor,
                  style: const TextStyle(color: AppTheme.textColor),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: AppTheme.primaryColor),
                  underline: Container(
                    height: 2,
                    color: AppTheme.primaryColor,
                  ),
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
                      backgroundColor: AppTheme.buttonColor,
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
                      backgroundColor: AppTheme.buttonColor,
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

              // Entries List
              Expanded(
                child: ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title:
                            Text('Clock In: ${formatDateTime(entry.clockIn)}'),
                        subtitle: entry.clockOut != null
                            ? Text(
                                'Clock Out: ${formatDateTime(entry.clockOut!)}')
                            : const Text('Still clocked in'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _dbHelper.deleteEntry(entry.id!);
                            _loadEntries();
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
