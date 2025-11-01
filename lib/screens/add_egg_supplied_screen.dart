// screens/add_egg_supplied_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // NEW: Import for Riverpod's ConsumerStatefulWidget
import 'package:poultryguard/providers/provider.dart';

import '../models/egg_supplied.dart';
import '../services/data_sync_service.dart'; // Import DataSyncService


// Changed from StatefulWidget to ConsumerStatefulWidget for Riverpod integration
class AddEggSuppliedScreen extends ConsumerStatefulWidget {
  final EggSupplied? existing; // Optional: for editing an existing record
  final dynamic eggKey; // Optional: Hive key for updating existing record

  const AddEggSuppliedScreen({super.key, this.existing, this.eggKey});

  @override
  ConsumerState<AddEggSuppliedScreen> createState() => _AddEggSuppliedScreenState(); // Changed to ConsumerState
}

// Changed from State to ConsumerState for Riverpod integration
class _AddEggSuppliedScreenState extends ConsumerState<AddEggSuppliedScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  final Color primaryColor = Colors.deepOrange; // Consistent primary theme color
  bool _isSaving = false; // NEW: State to manage saving process

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      // Populate fields if editing an existing record
      _quantityController.text = widget.existing!.quantity.toString();
      _customerNameController.text = widget.existing!.customerName;
      _notesController.text = widget.existing!.notes ?? '';
      _selectedDate = widget.existing!.date;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Saves or updates an egg supplied record in Hive and flags it for sync.
  void _saveEggSupplied() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // NEW: Set _isSaving to true and trigger UI rebuild
      setState(() {
        _isSaving = true;
      });

      try {
        final box = Hive.box<EggSupplied>('egg_supplied');

        if (widget.eggKey != null && widget.existing != null) {
          // Update existing record using copyWith to preserve firestoreDocId, createdAt, and isDeleted
          final updatedEggSupplied = widget.existing!.copyWith(
            date: _selectedDate,
            quantity: int.parse(_quantityController.text),
            customerName: _customerNameController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            isSynced: false, // Mark as not synced after update
            // firestoreDocId, createdAt, and isDeleted are preserved by copyWith if not explicitly overridden
          );
          await box.put(widget.eggKey, updatedEggSupplied);
          if (mounted) { // Check mounted before showing SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Egg supply record updated successfully!')),
            );
          }
        } else {
          // Add new record
          final newEggSupplied = EggSupplied(
            date: _selectedDate,
            quantity: int.parse(_quantityController.text),
            customerName: _customerNameController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            isSynced: false, // <-- CRUCIAL: Set to false for new records
            createdAt: DateTime.now(), // Local creation timestamp for new records
            isDeleted: false, // Default to false for new records
          );
          await box.add(newEggSupplied);
          if (mounted) { // Check mounted before showing SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Egg supply record added successfully!')),
            );
          }
        }

        // --- IMPORTANT: Trigger manual sync after saving to Hive ---
        // This will tell DataSyncService to push the new/updated data to Firebase.
        if (mounted) { // Check mounted before accessing ref
          ref.read(dataSyncServiceProvider).triggerManualSync(); // Access via Riverpod's ref.read
        }

        // CRITICAL: Close the current screen only after successful save
        if (mounted) {
          Navigator.pop(context, true); // Indicate save success and pop the screen
        }
      } catch (e) {
        // Handle any errors during save
        debugPrint('Error saving egg supplied record: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save egg supplied record: $e')),
          );
        }
      } finally {
        // Ensure _isSaving is reset even if an error occurs
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  /// Shows a date picker to select the supply date.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryColor,
            colorScheme: ColorScheme.light(primary: primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add Egg Supply' : 'Edit Egg Supply',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quantity Input Field
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Number of Eggs Supplied',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.egg_alt, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of eggs';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _quantityController.text = value ?? '0',
              ),
              const SizedBox(height: 15),

              // Customer Name Input Field
              TextFormField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _customerNameController.text = value ?? '',
              ),
              const SizedBox(height: 15),

              // Date Picker Row
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        labelStyle: TextStyle(color: primaryColor),
                        prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      child: Text(
                        DateFormat.yMMMd().format(_selectedDate),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _pickDate, // Disable when saving
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text('Change Date'),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Notes Input Field
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.notes, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
                keyboardType: TextInputType.multiline,
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _notesController.text = value ?? '',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context, false), // Disable when saving
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveEggSupplied, // Disable button if already saving
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              icon: _isSaving // Show loading indicator when saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: _isSaving
                  ? const Text('Saving...', style: TextStyle(fontSize: 16)) // Change text to 'Saving...'
                  : Text(widget.existing == null ? 'Save Record' : 'Update Record', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
