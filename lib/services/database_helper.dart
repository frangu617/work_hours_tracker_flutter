import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/user.dart';
import '../models/entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  // Initialize the correct database based on the platform
  static void initialize() {
    if (kIsWeb) {
      print('Initializing database for web...');
      databaseFactory = databaseFactoryFfiWeb; // Use Web database
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      print('Initializing database for desktop...');
      sqfliteFfiInit(); // Initialize FFI
      databaseFactory = databaseFactoryFfi; // Use FFI for desktop
    } else {
      print('Initializing database for mobile...');
      // Use default sqflite for mobile
    }
  }

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path;
    if (kIsWeb) {
      path = 'work_hours.db'; // Web uses an in-memory database
    } else {
      path = join(await getDatabasesPath(), 'work_hours.db');
    }

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        clockIn TEXT,
        clockOut TEXT,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
  }

  // ==================== CRUD Methods for Users ====================

  // Add a new user to the database
  Future<int> addUser(User user) async {
    final db = await database; // Get the database instance
    return await db.insert('users', user.toMap()); // Insert the user into the 'users' table
  }

  // Get all users from the database
  Future<List<User>> getUsers() async {
    final db = await database; // Get the database instance
    final List<Map<String, dynamic>> maps = await db.query('users'); // Query all rows in the 'users' table

    // Convert the list of maps to a list of User objects
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Update a user in the database
  Future<int> updateUser(User user) async {
    final db = await database; // Get the database instance
    return await db.update(
      'users', // Table name
      user.toMap(), // Updated user data
      where: 'id = ?', // Condition to find user by ID
      whereArgs: [user.id], // Arguments for the condition
    );
  }

  // Delete a user from the database
  Future<int> deleteUser(int id) async {
    final db = await database; // Get the database instance
    return await db.delete(
      'users', // Table name
      where: 'id = ?', // Condition to find user by ID
      whereArgs: [id], // Arguments for the condition
    );
  }

  // ==================== CRUD Methods for Entries ====================

  // Add a new entry to the database
  Future<int> addEntry(Entry entry) async {
    final db = await database; // Get the database instance
    return await db.insert('entries', entry.toMap()); // Insert the entry into the 'entries' table
  }

  // Get all entries for a specific user
  Future<List<Entry>> getEntries(int userId) async {
    final db = await database; // Get the database instance
    final List<Map<String, dynamic>> maps = await db.query(
      'entries', // Table name
      where: 'userId = ?', // Condition to find entries by user ID
      whereArgs: [userId], // Arguments for the condition
    );
    // Convert the list of maps to a list of Entry objects
    return List.generate(maps.length, (i) {
      return Entry.fromMap(maps[i]);
    });
  }

  // Update an entry in the database (e.g. add clock-out time)
  Future<int> updateEntry(Entry entry) async {
    final db = await database; // Get the database instance
    return await db.update(
      'entries', // Table name
      entry.toMap(), // Updated entry data
      where: 'id = ?', // Condition to find the entry by ID
      whereArgs: [entry.id], // Arguments for the condition
    );
  }

  // Delete an entry from the database
  Future<int> deleteEntry(int id) async {
    final db = await database; // Get the database instance
    return await db.delete(
      'entries', // Table name
      where: 'id = ?', // Condition to find the entry by ID
      whereArgs: [id], // Arguments for the condition
    );
  }

  Future<int> addCustomEntry(int userId, DateTime clockIn, DateTime clockOut) async {
    final entry = Entry.custom(
      userId: userId, 
      clockIn: clockIn, 
      clockOut: clockOut
      );
      return await addEntry(entry);
  }

  // ==================== Utility Methods ====================

  // Calculate total hours worked for a user within a date range
  Future<double> calculateTotalHours(int userId, DateTime startDate, DateTime endDate) async {
    final db = await database; // Get the database instance
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',  // Table name
      where: 'userId = ? AND clockIn >= ? AND clockIn <= ?', // Condition to find entries within the date range
      whereArgs: [userId, startDate.toIso8601String(), endDate.toIso8601String()], // Arguments for the condition
    );

    double totalHours = 0;
    for (var map in maps) {
      final entry = Entry.fromMap(map);
      if (entry.clockOut != null) {
        final clockIn = DateTime.parse(entry.clockIn);
        final clockOut = DateTime.parse(entry.clockOut!);
        totalHours += clockOut.difference(clockIn).inHours.toDouble();
      }
    }
    return totalHours;
  }
}