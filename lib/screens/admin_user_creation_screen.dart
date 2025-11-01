// screens/AdminUserCreationScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // NEW: Import for Riverpod's ConsumerStatefulWidget
import 'package:poultryguard/services/data_sync_service.dart';
import '../providers/provider.dart'; // Import your Riverpod providers (even if not directly used here, common pattern)


// Changed from StatefulWidget to ConsumerStatefulWidget for Riverpod integration
class AdminUserCreationScreen extends ConsumerStatefulWidget {
  const AdminUserCreationScreen({super.key});

  @override
  ConsumerState<AdminUserCreationScreen> createState() => _AdminUserCreationScreenState(); // Changed to ConsumerState
}

// Changed from State to ConsumerState for Riverpod integration
class _AdminUserCreationScreenState extends ConsumerState<AdminUserCreationScreen> {
  final _formKey = GlobalKey<FormState>(); // NEW: Added Form key for validation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'low_level';
  final List<String> _roles = ['admin', 'mid_level', 'low_level'];
  String? _message;
  bool _isLoading = false; // Renamed from _isCreatingUser for consistency

  // Consistent primary theme color (optional, but good for design consistency)
  final Color primaryColor = Colors.deepOrange;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) { // NEW: Validate form before proceeding
      return;
    }

    setState(() {
      _isLoading = true; // Set loading state
      _message = null; // Clear previous messages
    });

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createUserWithRole');
      final result = await callable.call<Map<String, dynamic>>({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'role': _selectedRole,
      });

      if (mounted) { // Check if the widget is still mounted before setState
        setState(() {
          _message = 'User created: ${result.data?['email']} with role ${result.data?['role']}';
        });
        _emailController.clear(); // Clear fields on success
        _passwordController.clear();
      }
      // Although not directly syncing a Hive box for this action,
      // it's good practice to trigger a general sync if this action
      // might affect any data that needs to be reflected elsewhere.
      // If this screen only manages Firebase Auth users and doesn't impact
      // local Hive data or other synced data, this line can be removed.
      // Keeping it for demonstration of pattern consistency.
      if (mounted) {
        ref.read(dataSyncServiceProvider).triggerManualSync();
      }

    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          _message = 'Error creating user: ${e.message} (Code: ${e.code})';
        });
      }
    } catch (e) {
      debugPrint('General Error: $e');
      if (mounted) {
        setState(() {
          _message = 'An unexpected error occurred: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Reset loading state
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New User (Admin Only)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView( // NEW: Added SingleChildScrollView
        padding: const EdgeInsets.all(24.0), // Increased padding
        child: Form( // NEW: Wrap content in Form
          key: _formKey, // Assign form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch fields
            children: [
              TextFormField( // Changed to TextFormField for validation
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'New User Email',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.email, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                enabled: !_isLoading, // Disable when loading
              ),
              const SizedBox(height: 15),
              TextFormField( // Changed to TextFormField for validation
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New User Password',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.lock, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
                enabled: !_isLoading, // Disable when loading
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>( // Changed to DropdownButtonFormField for validation
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _roles.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: _isLoading ? null : (String? newValue) { // Disable when loading
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  }
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please select a role' : null,
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon( // Changed to ElevatedButton.icon for consistency
                onPressed: _isLoading ? null : _createUser, // Disable button if loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                icon: _isLoading // Show loading indicator when loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_add), // Consistent icon for adding user
                label: _isLoading
                    ? const Text('Creating User...', style: TextStyle(fontSize: 16)) // Change text to 'Creating User...'
                    : const Text('Create User', style: TextStyle(fontSize: 16)),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0), // Adjusted padding
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center, // Center text
                    style: TextStyle(
                      color: _message!.startsWith('Error') ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
