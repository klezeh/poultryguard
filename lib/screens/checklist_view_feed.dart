// screens/add_feed_used_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/providers/provider.dart';
import '../models/feed_used.dart'; // Import the new FeedUsed model
import '../models/bird_batch.dart'; // Import BirdBatch to select batches
import '../services/data_sync_service.dart'; // Import DataSyncService

// Changed from StatelessWidget to ConsumerStatefulWidget for Riverpod integration
class AddFeedUsedScreen extends ConsumerStatefulWidget {
  final FeedUsed? existing; // Optional: for editing an existing record
  final dynamic recordKey; // Optional: Hive key for updating existing record
  final String? initialBatchName; // NEW: Optional: initial batch name to pre-select

  const AddFeedUsedScreen({
    super.key,
    this.existing,
    this.recordKey,
    this.initialBatchName, // NEW: Added to constructor
  });

  @override
  ConsumerState<AddFeedUsedScreen> createState() => _AddFeedUsedScreenState();
}

// Changed from State to ConsumerState for Riverpod integration
class _AddFeedUsedScreenState extends ConsumerState<AddFeedUsedScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedBatchName; // To store the selected batch name
  List<BirdBatch> _availableBatches = []; // List of available batches

  final Color primaryColor = Colors.deepOrange; // Consistent primary theme color
  bool _isSaving = false; // State to manage saving process

  @override
  void initState() {
    super.initState();
    _loadBatches(); // Load batches when the screen initializes

    if (widget.existing != null) {
      // Populate fields if editing an existing record
      _quantityController.text = widget.existing!.quantityKg.toString();
      _notesController.text = widget.existing!.notes ?? '';
      _selectedDate = widget.existing!.date;
      _selectedBatchName = widget.existing!.batchName; // Set existing batch name
    } else if (widget.initialBatchName != null) { // NEW: Pre-fill batch from initialBatchName if available
      _selectedBatchName = widget.initialBatchName;
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

  /// Saves or updates a feed used record in Hive and flags it for sync.
  void _saveFeedUsed() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedBatchName == null || _selectedBatchName!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a batch for this feed usage record.')),
          );
        }
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final box = Hive.box<FeedUsed>('feed_used'); // Use 'feed_used' box

        if (widget.recordKey != null && widget.existing != null) {
          // Update existing record using copyWith to preserve syncable properties
          final updatedRecord = widget.existing!.copyWith(
            date: _selectedDate,
            quantityKg: double.parse(_quantityController.text),
            batchName: _selectedBatchName!,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            isSynced: false, // Mark as not synced after update
            // firestoreDocId, createdAt, and isDeleted are preserved by copyWith
          );
          await box.put(widget.recordKey, updatedRecord);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feed usage record updated successfully!')),
            );
          }
        } else {
          // Add new record
          final newRecord = FeedUsed(
            date: _selectedDate,
            quantityKg: double.parse(_quantityController.text),
            batchName: _selectedBatchName!,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            isSynced: false, // CRUCIAL: Set to false for new records
            createdAt: DateTime.now(), // Local creation timestamp for new records
            isDeleted: false, // Default to false for new records
          );
          await box.add(newRecord);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feed usage record added successfully!')),
            );
          }
        }

        // IMPORTANT: Trigger manual sync after saving to Hive
        if (mounted) {
          ref.read(dataSyncServiceProvider).triggerManualSync();
        }

        // CRITICAL: Close the current screen only after successful save
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        debugPrint('Error saving feed usage record: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save feed usage record: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  /// Shows a date picker to select the date.
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
          widget.existing == null ? 'Add Feed Usage' : 'Edit Feed Usage',
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
                onChanged: _isSaving ? null : (val) {
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
                  labelText: 'Quantity of Feed Used (kg)',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.fitness_center, color: primaryColor), // Icon for weight/quantity
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
                    return 'Please enter the quantity of feed';
                  }
                  if (double.tryParse(value) == null || double.parse(value)! <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
                enabled: !_isSaving,
                onSaved: (value) => _quantityController.text = value ?? '0.0',
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
                    onPressed: _isSaving ? null : _pickDate,
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
                enabled: !_isSaving,
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
              onPressed: _isSaving ? null : () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveFeedUsed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              icon: _isSaving
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
                  ? const Text('Saving...', style: TextStyle(fontSize: 16))
                  : Text(widget.existing == null ? 'Save Record' : 'Update Record', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
