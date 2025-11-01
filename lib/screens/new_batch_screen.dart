// screens/new_batch_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bird_batch.dart'; // Ensure this import is correct and brings in BirdType
import '../services/data_sync_service.dart';
import '../services/batch_schedule_service.dart';
import '../services/notification_service.dart';
import '../providers/provider.dart';

// Removed the temporary BirdType enum from here.
// BirdType should be imported from '../models/bird_batch.dart'.

// Changed from StatefulWidget to ConsumerStatefulWidget for Riverpod integration
class NewBatchScreen extends ConsumerStatefulWidget {
  final BirdBatch? batch; // Optional: for editing an existing batch
  final dynamic batchKey; // Optional: Hive key for updating existing batch

  const NewBatchScreen({super.key, this.batch, this.batchKey});

  @override
  ConsumerState<NewBatchScreen> createState() => _NewBatchScreenState(); // Changed to ConsumerState
}

// Changed from State to ConsumerState for Riverpod integration
class _NewBatchScreenState extends ConsumerState<NewBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  BirdType? _selectedBirdType;

  final Color primaryColor = Colors.deepOrange; // Consistent primary theme color
  bool _isSaving = false; // State to manage saving process

  @override
  void initState() {
    super.initState();
    if (widget.batch != null) {
      // Populate fields if editing an existing batch
      _nameController.text = widget.batch!.name;
      _quantityController.text = widget.batch!.quantity.toString();
      _selectedDate = widget.batch!.startDate;
      _selectedBirdType = widget.batch!.type;
    } else {
      _selectedBirdType = BirdType.layers; // Default for new batches
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Saves or updates a bird batch record in Hive, flags it for sync,
  /// and generates/reschedules vaccination notifications.
  void _saveBatch() async { // Made async as Hive operations are async
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return; // If validation fails, do not proceed and keep fields enabled.
    }
    _formKey.currentState!.save();

    // Set _isSaving to true and trigger UI rebuild ONLY after validation passes
    setState(() {
      _isSaving = true;
    });

    try {
      final newBatch = BirdBatch(
        name: _nameController.text.trim(), // Trim whitespace
        quantity: int.parse(_quantityController.text),
        startDate: _selectedDate,
        type: _selectedBirdType,
        isSynced: false, // <-- CRUCIAL: Set to false for new/updated records
        createdAt: DateTime.now(), // Add creation timestamp for sync logic
      );

      final box = Hive.box<BirdBatch>('batches');

      if (widget.batchKey != null) {
        // Update existing batch
        await box.put(widget.batchKey, newBatch); // Await the put operation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch updated successfully!')),
          );
        }
      } else {
        // Add new batch
        await box.add(newBatch); // Await the add operation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch added successfully!')),
          );
        }

        // --- NEW: Generate vaccination schedule for the new batch ---
        // Access services via Riverpod's ref.read
        if (mounted) {
          final batchScheduleService = ref.read(batchScheduleServiceProvider);
          await batchScheduleService.generateScheduleForBatch(newBatch);
          debugPrint('Generated vaccination schedule for new batch: ${newBatch.name}');

          // --- NEW: Reschedule all notifications to include new batch's events ---
          final notificationService = ref.read(notificationServiceProvider);
          await notificationService.rescheduleAllBatchNotifications();
          debugPrint('Rescheduled all notifications.');
        }
      }

      // --- IMPORTANT: Trigger manual sync after saving to Hive ---
      // This will tell DataSyncService to push the new/updated data to Firebase.
      if (mounted) { // Check mounted again after async operations
        ref.read(dataSyncServiceProvider).triggerManualSync(); // Access via Riverpod's ref.read
      }

      if (mounted) { // Check mounted again before pop
        Navigator.pop(context, true); // Indicate save success and pop the screen
      }
    } catch (e) {
      // Handle any errors during save
      debugPrint('Error saving batch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save batch: $e')),
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

  /// Shows a date picker to select the batch start date.
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
          widget.batch == null ? 'Add New Batch' : 'Edit Batch',
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
              // Batch Name Input Field
              AbsorbPointer( // NEW: AbsorbPointer for disabling input during saving
                absorbing: _isSaving,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Batch Name',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a batch name';
                    }
                    return null;
                  },
                  onSaved: (value) => _nameController.text = value ?? '',
                ),
              ),
              const SizedBox(height: 15),

              // Quantity Input Field
              AbsorbPointer( // NEW: AbsorbPointer for disabling input during saving
                absorbing: _isSaving,
                child: TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity (Number of Birds)',
                    labelStyle: TextStyle(color: primaryColor),
                    prefixIcon: Icon(Icons.numbers, color: primaryColor),
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
                      return 'Please enter the quantity of birds';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                  onSaved: (value) => _quantityController.text = value ?? '0',
                ),
              ),
              const SizedBox(height: 15),

              // Bird Type Dropdown
              AbsorbPointer( // NEW: AbsorbPointer for disabling input during saving
                absorbing: _isSaving,
                child: DropdownButtonFormField<BirdType>(
                  value: _selectedBirdType,
                  decoration: InputDecoration(
                    labelText: 'Bird Type',
                    labelStyle: TextStyle(color: primaryColor),
                    prefixIcon: Icon(Icons.pets, color: primaryColor),
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
                  validator: (value) => value == null ? 'Please select a bird type' : null,
                  items: BirdType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.capitalize(), style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                  onChanged: (val) { // onChanged logic remains, AbsorbPointer handles blocking
                    setState(() {
                      _selectedBirdType = val;
                    });
                  },
                  onSaved: (val) {
                    _selectedBirdType = val;
                  },
                ),
              ),
              const SizedBox(height: 15),

              // Date Picker Row
              AbsorbPointer( // NEW: AbsorbPointer for disabling the date picker during saving
                absorbing: _isSaving,
                child: Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
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
                      onPressed: _pickDate, // onPressed logic remains, AbsorbPointer handles blocking
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
              onPressed: _isSaving ? null : _saveBatch, // Disable button if already saving
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
                  : Text(widget.batch == null ? 'Save Batch' : 'Update Batch', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize enum names for display
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
