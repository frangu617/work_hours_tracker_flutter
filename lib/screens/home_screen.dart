import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/entry.dart';
import '../services/database_helper.dart';
import './admin_screen.dart';

class HomeScreen extends StatefulWidget{
  @override 
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Database helper instance
  List<User> _users = []; // List of user
  User? _selectedUser; //Currently selected user
  List<Entry> _entries = []; // List of clock-in/out entries for the selected user
  bool _isClockedIn = false; // Tracks if the user is currently clocked in

  @override void initState(){
    super.initState();
    _loadUsers(); // Load users when the screen is first created
  }

  // Load all users from the database
  Future<void> _loadUsers()async {
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

  //Handle clock-in action
  Future<void> _clockIn() async {
    if(_selectedUser != null) {
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

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Work Hours Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () async {
              //navigate to the adminscreen and wait for it to return
              await Navigator.push(
                context, MaterialPageRoute(builder: (context) => AdminScreen()), //navigate to admin screen
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
            //Dropdown to select a user
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
                  _isClockedIn = false; // Reset clock-in status when user changes
                });
                _loadEntries(); // Load entries for the selected user
              },
            ),
            SizedBox(height:20),

            //Clock-in/out buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _selectedUser == null || _isClockedIn ? null : _clockIn,
                  child: Text('Clock In'),
                ),
                ElevatedButton(
                  onPressed: _selectedUser == null || _isClockedIn ? null : _clockOut,
                  child: Text('Clock Out'),
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
                  return ListTile(
                    title: Text('Clock In: ${entry.clockIn}'),
                    subtitle: entry.clockOut != null
                        ? Text('Clock Out: ${entry.clockOut}')
                        : Text('Still clocked in'),
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