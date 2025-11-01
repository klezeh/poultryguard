// screens/add_vaccination_record_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // NEW: Import for Riverpod's ConsumerStatefulWidget
import 'package:poultryguard/services/data_sync_service.dart';
import '../models/vaccination_record.dart';
import '../models/batch_vaccination_event.dart'; // To find scheduled event
import '../providers/provider.dart'; // NEW: Import your Riverpod providers

// Changed from StatefulWidget to ConsumerStatefulWidget for Riverpod integration
class AddVaccinationRecordScreen extends ConsumerStatefulWidget {
  final String batchId; // The batch to which this record belongs
  final String? prefillVaccinationName; // Optional: for pre-filling from checklist
  final String? prefillMethod; // Optional: for pre-filling from checklist

  const AddVaccinationRecordScreen({
    super.key,
    required this.batchId,
    this.prefillVaccinationName,
    this.prefillMethod,
  });

  @override
  ConsumerState<AddVaccinationRecordScreen> createState() => _AddVaccinationRecordScreenState(); // Changed to ConsumerState
}

// Changed from State to ConsumerState for Riverpod integration
class _AddVaccinationRecordScreenState extends ConsumerState<AddVaccinationRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vaccineNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _methodController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false; // NEW: State to manage saving process

  final Color primaryColor = Colors.deepOrange;

  @override
  void initState() {
    super.initState();
    // Prefill fields if provided (e.g., from checklist's "ADD RECORD" button)
    if (widget.prefillVaccinationName != null) {
      _vaccineNameController.text = widget.prefillVaccinationName!;
    }
    if (widget.prefillMethod != null) {
      _methodController.text = widget.prefillMethod!;
    }
  }

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _quantityController.dispose();
    _methodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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

  void _saveVaccinationRecord() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // NEW: Set _isSaving to true and trigger UI rebuild
      setState(() {
        _isSaving = true;
      });

      try {
        final newRecord = VaccinationRecord(
          batchName: widget.batchId,
          vaccineName: _vaccineNameController.text.trim(),
          dateGiven: _selectedDate,
          notes: _notesController.text.trim(),
          quantity: int.tryParse(_quantityController.text) ?? 0,
          isSynced: false,
        );

        final box = Hive.box<VaccinationRecord>('vaccination_records');
        await box.add(newRecord);

        // After adding a record, attempt to mark the corresponding scheduled event as completed
        // Access BatchScheduleService via Riverpod
        final batchScheduleService = ref.read(batchScheduleServiceProvider);
        final batchVaccinationBox = Hive.box<BatchVaccinationEvent>('batch_vaccinations');

        // Find the specific scheduled event for this batch and vaccine that is NOT yet completed
        // Using `try` for the `firstWhere` and providing an `orElse` to prevent errors if no match.
        // Note: The `orElse` returns `null as BatchVaccinationEvent` which requires `null safety` handling
        // in `if (matchingScheduledEvent != null)`.
        final matchingScheduledEvent = batchVaccinationBox.values.cast<BatchVaccinationEvent?>().firstWhere(
              (event) =>
                  event != null && // Ensure event is not null before checking properties
                  event.batchId == newRecord.batchName &&
                  event.vaccinationName == newRecord.vaccineName &&
                  !event.isCompleted,
              orElse: () => null, // Provide a null default
            );


        if (matchingScheduledEvent != null) {
          await batchScheduleService.markVaccinationAsCompleted(matchingScheduledEvent.key, true);
          debugPrint('Automatically marked scheduled event as completed for ${newRecord.vaccineName}.');
        }

        if (mounted) {
          // Access DataSyncService via Riverpod's ref.read
          ref.read(dataSyncServiceProvider).triggerManualSync();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vaccination record added successfully!')),
          );
          Navigator.pop(context, true); // Indicate success and pop
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Vaccination for Batch: ${widget.batchId}',
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
              // Vaccine Name
              TextFormField(
                controller: _vaccineNameController,
                decoration: InputDecoration(
                  labelText: 'Vaccine Name',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.medical_services, color: primaryColor),
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
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _vaccineNameController.text = value ?? '',
              ),
              const SizedBox(height: 15),

              // Quantity Administered
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity Administered (birds)',
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
                  if (int.tryParse(value) == null || int.parse(value)! <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _quantityController.text = value ?? '0',
              ),
              const SizedBox(height: 15),

              // Method of Administration
              TextFormField(
                controller: _methodController,
                decoration: InputDecoration(
                  labelText: 'Method of Administration',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.medical_information, color: primaryColor),
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
                    return 'Please enter method';
                  }
                  return null;
                },
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _methodController.text = value ?? '',
              ),
              const SizedBox(height: 15),

              // Date Given
              Row(
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

              // Notes
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
                maxLines: 3,
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
                  : const Text('Save Record', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
