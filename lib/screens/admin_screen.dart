import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart'; // Import the theme file

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Database helper instance
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final _nameController = TextEditingController(); // Controller for the name input field

  // Add a new user to the database
  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) { // Validate the form
      final user = User(name: _nameController.text); // Create a new User object
      await _dbHelper.addUser(user); // Save the user to the database
      _nameController.clear(); // Clear the input field
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User added successfully!')), // Show a success message
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add User'),
        backgroundColor: AppTheme.primaryColor, // Use primary color from theme
        foregroundColor: Colors.white, // White text
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name input field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name'; // Validation message
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Add user button
              ElevatedButton(
                onPressed: _addUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buttonColor, // Use button color from theme
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Add User', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}