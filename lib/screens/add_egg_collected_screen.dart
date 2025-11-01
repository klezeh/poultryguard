// screens/add_egg_collected_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Changed from Provider to Riverpod's ConsumerStatefulWidget
import 'package:poultryguard/providers/provider.dart';

import '../models/egg_collected.dart';
import '../models/bird_batch.dart'; // Import BirdBatch to select batches
import '../services/data_sync_service.dart'; // Import DataSyncService


// Changed from StatefulWidget to ConsumerStatefulWidget
class AddEggCollectedScreen extends ConsumerStatefulWidget {
  final EggCollected? existing; // Optional: for editing an existing record
  final dynamic eggKey; // Optional: Hive key for updating existing record

  const AddEggCollectedScreen({super.key, this.existing, this.eggKey});

  @override
  ConsumerState<AddEggCollectedScreen> createState() => _AddEggCollectedScreenState(); // Changed to ConsumerState
}

// Changed from State to ConsumerState
class _AddEggCollectedScreenState extends ConsumerState<AddEggCollectedScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedBatchName; // To store the selected batch name
  List<BirdBatch> _availableBatches = []; // List of available batches

  final Color primaryColor = Colors.deepOrange; // Consistent primary theme color
  bool _isSaving = false; // NEW: State to manage saving process

  @override
  void initState() {
    super.initState();
    _loadBatches(); // Load batches when the screen initializes

    if (widget.existing != null) {
      // Populate fields if editing an existing record
      _quantityController.text = widget.existing!.count.toString(); // Use .count as per your model
      _notesController.text = widget.existing!.notes ?? '';
      _selectedDate = widget.existing!.date;
      _selectedBatchName = widget.existing!.batchName; // Set existing batch name
    }
  }

  Future<void> _loadBatches() async {
    final batchBox = Hive.box<BirdBatch>('batches');
    setState(() {
      _availableBatches = batchBox.values.toList();
      // If adding a new record and no batch is selected, try to select the first one
      if (widget.existing == null && _selectedBatchName == null && _availableBatches.isNotEmpty) {
        _selectedBatchName = _availableBatches.first.name;
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Saves or updates an egg collected record in Hive and flags it for sync.
  void _saveEggCollected() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedBatchName == null || _selectedBatchName!.isEmpty) {
        if (mounted) { // Check mounted before showing SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a batch for this collection.')),
          );
        }
        return;
      }

      // NEW: Set _isSaving to true and trigger UI rebuild
      setState(() {
        _isSaving = true;
      });

      try {
        final box = Hive.box<EggCollected>('egg_collected');

        if (widget.eggKey != null && widget.existing != null) {
          // Update existing record using copyWith to preserve firestoreDocId, createdAt, and isDeleted
          final updatedEggCollected = widget.existing!.copyWith(
            date: _selectedDate,
            count: int.parse(_quantityController.text),
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            batchName: _selectedBatchName!,
            isSynced: false, // Mark as not synced after update
            // firestoreDocId, createdAt, and isDeleted are preserved by copyWith if not explicitly overridden
          );
          await box.put(widget.eggKey, updatedEggCollected);
          if (mounted) { // Check mounted before showing SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Egg collection updated successfully!')),
            );
          }
        } else {
          // Add new record
          final newEggCollected = EggCollected(
            date: _selectedDate,
            count: int.parse(_quantityController.text), // Use .count as per your model
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            batchName: _selectedBatchName!, // Assign the selected batch name
            isSynced: false, // <-- CRUCIAL: Set to false for new/updated records
            createdAt: DateTime.now(), // Local creation timestamp
            isDeleted: false, // Default to false for new records
          );
          await box.add(newEggCollected);
          if (mounted) { // Check mounted before showing SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Egg collection added successfully!')),
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
        debugPrint('Error saving egg collection: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save egg collection: $e')),
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

  /// Shows a date picker to select the collection date.
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
          widget.existing == null ? 'Add Egg Collection' : 'Edit Egg Collection',
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
              // Batch Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBatchName,
                decoration: InputDecoration(
                  labelText: 'Select Batch',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.group, color: primaryColor),
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
                icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                dropdownColor: Colors.white,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please select a batch' : null,
                items: _availableBatches.map((batch) {
                  return DropdownMenuItem(
                    value: batch.name,
                    child: Text(
                      '${batch.name} (${batch.quantity} birds)',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: _isSaving ? null : (val) { // Disable when saving
                  setState(() {
                    _selectedBatchName = val;
                  });
                },
                onSaved: (val) {
                  _selectedBatchName = val;
                },
              ),
              const SizedBox(height: 15),

              // Quantity Input Field
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Number of Eggs Collected',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.egg, color: primaryColor),
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
              onPressed: _isSaving ? null : _saveEggCollected, // Disable button if already saving
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
