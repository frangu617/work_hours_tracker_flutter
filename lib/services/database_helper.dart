import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/entry.dart';

class DatabaseHelper{
  // Singleton pattern to ensure only one instance of DatabaseHelper exists
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  // Getter for the database instance
  Future<Database> get database async{
    if (_database != null) return _database!;
    _database = await _initDatabase(); // Initialize the database if it doesn't exist
    return _database!;
  }

  //Initialize the database
  Future<Database> _initDatabase() async {
    //Get the path to the database file
    String path = join(await getDatabasesPath(), 'work_hours.db');
    return await openDatabase(
      path,
      version:1,
      onCreate: _onCreate, // Create Database tables when the database is first created
    );
  }

  // Create tables in the database
  Future<void> _onCreate(Database db, int version) async {
    //Create the 'users' table
    await db.execute('''
    CREATE TABLE users(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT
    )
    ''');

    //Create the 'entries' table with a foreign key to 'users'
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

//Add a new user to the database
Future<int> addUser(User user) async {
    final db = await database; // get the database instance
  return await db. insert('users', user.toMap()); // Insert the user into the 'users' table
}

// Get all users from the database
Future<List<User>> getUsers() async {
  final db = await database; // Get the database instance
  final List<Map<String, dynamic>> maps = await db.query('users'); // Query all rows in the 'users' table

  // Convert the list of maps to a list of User objects
  return List.generate(maps.length, (i){
    return User.fromMap(maps[i]);
  });
}

// Update a user in the database
Future<int> updateUser(User user) async {
  final db = await database; // Get the database instance
  return await db.update(
    'users', //table name
    user.toMap(), //updated user data
    where: 'id = ?', //condition to find user by ID
    whereArgs: [user.id], //Arguments for the condition
  );
}

// Delete a user from the database
Future<int> deleteUser(int id) async {
  final db = await database; // Get the database instance
  return await db.delete(
    'users', // Table name
    where: 'id = ?', // condition to find user by ID
    whereArgs: [id], //Arguments for the condition
  );
}

  // ==================== CRUD Methods for Entries ====================

// Add a new entry to the database
Future<int> addEntry(Entry entry) async{
  final db = await database; // Get the database instance
  return await db.insert('entries', entry.toMap()); // Insert the entry into the 'entries' table
}

// Get all entries for a specific user
Future<List<Entry>> getEntries(int userId) async {
  final db = await database; //Get the database instance
  final List<Map<String, dynamic>> maps = await db.query(
    'entries', //Table name
    where: 'userId = ?', //condition to find entries by user ID
    whereArgs: [userId], // Arguments for the condition
  );
  //convert the list of maps to a list of Entry objects
  return List.generate(maps.length, (i) {
    return Entry.fromMap(maps[i]);
  });
}

//Update an entry in the database (e.g. add clock-out time)
Future<int> updateEntry(Entry entry) async {
  final db = await database; // Get the database instance
  return await db.update(
    'entries', //Table name
    entry.toMap(), // Updated entry data
    where: 'id = ?' // Condition to find the entry by ID
    whereArgs: [entry.id], // Arguments for the condition
  );
}

//Delete an entry from the database
Future<int> deleteEntry(int id) async {
  final db = await database; // Get Database instance
  return await db.delete(
    'entries', //Table name
    where: 'id = ?', // Condition to find the entry by ID
    whereArgs: [id],
  );
}


}