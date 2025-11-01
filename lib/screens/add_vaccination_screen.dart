// screens/add_vaccination_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Changed from Provider to Riverpod's ConsumerStatefulWidget
import 'package:poultryguard/services/data_sync_service.dart';
import '../models/vaccination_record.dart';
import '../models/bird_batch.dart'; // Import BirdBatch to select batches

import '../providers/provider.dart'; // Corrected import: 'providers.dart'

// Changed from StatefulWidget to ConsumerStatefulWidget for Riverpod integration
class AddVaccinationScreen extends ConsumerStatefulWidget {
  final VaccinationRecord? record; // Optional: for editing an existing record
  final dynamic recordKey; // Optional: Hive key for updating existing record

  const AddVaccinationScreen({super.key, this.record, this.recordKey});

  @override
  ConsumerState<AddVaccinationScreen> createState() => _AddVaccinationScreenState(); // Changed to ConsumerState
}

// Changed from State to ConsumerState for Riverpod integration
class _AddVaccinationScreenState extends ConsumerState<AddVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vaccineNameController = TextEditingController();
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

    if (widget.record != null) {
      // Populate fields if editing an existing record
      _vaccineNameController.text = widget.record!.vaccineName;
      _quantityController.text = widget.record!.quantity.toString();
      _notesController.text = widget.record!.notes;
      _selectedDate = widget.record!.dateGiven;
      _selectedBatchName = widget.record!.batchName; // Set existing batch name
    } else {
      // For new records, try to pre-select the first batch if available
      // This is now handled within _loadBatches after it completes
    }
  }

  Future<void> _loadBatches() async {
    final batchBox = Hive.box<BirdBatch>('batches');
    setState(() {
      _availableBatches = batchBox.values.toList();
      // If adding a new record and no batch is selected, try to select the first one
      if (widget.record == null && _selectedBatchName == null && _availableBatches.isNotEmpty) {
        _selectedBatchName = _availableBatches.first.name;
      }
    });
  }

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Saves or updates a vaccination record in Hive and flags it for sync.
  void _saveVaccinationRecord() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return; // If validation fails, do not proceed and keep fields enabled.
    }
    _formKey.currentState!.save();

    if (_selectedBatchName == null || _selectedBatchName!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a batch for this vaccination.')),
        );
      }
      return;
    }

    // Set _isSaving to true and trigger UI rebuild ONLY after validation passes
    setState(() {
      _isSaving = true;
    });

    try {
      final VaccinationRecord newRecord;
      if (widget.recordKey != null) {
        // Update existing record
        newRecord = VaccinationRecord(
          batchName: _selectedBatchName!,
          vaccineName: _vaccineNameController.text.trim(),
          dateGiven: _selectedDate,
          notes: _notesController.text.trim(),
          quantity: int.tryParse(_quantityController.text) ?? 0,
          isSynced: false, // Flag for sync after update
          createdAt: widget.record?.createdAt ?? DateTime.now(), // Preserve original createdAt, or use DateTime.now() if null
          firestoreDocId: widget.record?.firestoreDocId, // Preserve original Firestore ID for updates
        );
      } else {
        // Add new record
        newRecord = VaccinationRecord(
          batchName: _selectedBatchName!, // Assign the selected batch name
          vaccineName: _vaccineNameController.text.trim(), // Trim whitespace
          dateGiven: _selectedDate,
          notes: _notesController.text.trim(), // Trim whitespace
          quantity: int.tryParse(_quantityController.text) ?? 0,
          isSynced: false, // <-- CRUCIAL: Set to false for new/updated records
          createdAt: DateTime.now(), // Add creation timestamp for new records
        );
      }

      final box = Hive.box<VaccinationRecord>('vaccination_records'); // Use 'vaccination_records' as per common practice

      if (widget.recordKey != null) {
        await box.put(widget.recordKey, newRecord);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vaccination record updated successfully!')),
          );
        }
      } else {
        await box.add(newRecord);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vaccination record added successfully!')),
          );
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
      debugPrint('Error saving vaccination record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save vaccination record: $e')),
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

  /// Shows a date picker to select the vaccination date.
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
          widget.record == null ? 'Add Vaccination' : 'Edit Vaccination',
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
              AbsorbPointer( // NEW: AbsorbPointer for disabling input during saving
                absorbing: _isSaving,
                child: DropdownButtonFormField<String>(
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
                  onChanged: (val) { // onChanged logic remains, AbsorbPointer handles blocking
                    setState(() {
                      _selectedBatchName = val;
                    });
                  },
                  onSaved: (val) {
                    _selectedBatchName = val;
                  },
                ),
              ),
              const SizedBox(height: 15),

              // Vaccine Name Input Field
              AbsorbPointer( // NEW: AbsorbPointer for disabling input during saving
                absorbing: _isSaving,
                child: TextFormField(
                  controller: _vaccineNameController,
                  decoration: InputDecoration(
                    labelText: 'Vaccine Name',
                    labelStyle: TextStyle(color: primaryColor),
                    prefixIcon: Icon(Icons.medication, color: primaryColor),
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
                      return 'Please enter vaccine name';
                    }
                    return null;
                  },
                  onSaved: (value) => _vaccineNameController.text = value ?? '',
                ),
              ),
              const SizedBox(height: 15),

              // Quantity Input Field
              AbsorbPointer( // NEW: AbsorbPointer for disabling input during saving
                absorbing: _isSaving,
                child: TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity of Birds Vaccinated',
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
                      return 'Please enter quantity';
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

              // Date Picker Row
              AbsorbPointer( // NEW: AbsorbPointer for disabling the date picker during saving
                absorbing: _isSaving,
                child: Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date Given',
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
              const SizedBox(height: 15),

              // Notes Input Field
              AbsorbPointer( // NEW: AbsorbPointer for disabling input during saving
                absorbing: _isSaving,
                child: TextFormField(
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
                  onSaved: (value) => _notesController.text = value ?? '',
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
              onPressed: _isSaving ? null : _saveVaccinationRecord, // Disable button if already saving
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
                  : Text(widget.record == null ? 'Save Record' : 'Update Record', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
