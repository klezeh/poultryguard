// screens/release_from_isolation_screen.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/providers/provider.dart';

import 'package:poultryguard/services/data_sync_service.dart';

import '../models/release_log.dart';
import '../models/bird_batch.dart'; // Import BirdBatch to select batches
import '../models/isolation_record.dart'; // Import IsolationRecord

class ReleaseFromIsolationScreen extends ConsumerStatefulWidget {
  final ReleaseLog? record; // Optional: for editing an existing record
  final dynamic recordKey; // Optional: Hive key for updating existing record

  const ReleaseFromIsolationScreen({super.key, this.record, this.recordKey});

  @override
  ConsumerState<ReleaseFromIsolationScreen> createState() => _ReleaseFromIsolationScreenState();
}

class _ReleaseFromIsolationScreenState extends ConsumerState<ReleaseFromIsolationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numberOfBirdsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedBatchName; // To store the selected batch name
  List<BirdBatch> _availableBatches = []; // List of available batches

  final Color primaryColor = Colors.deepOrange;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBatches();

    if (widget.record != null) {
      _numberOfBirdsController.text = widget.record!.numberOfBirds.toString();
      _notesController.text = widget.record!.notes ?? '';
      _selectedDate = widget.record!.releaseDate;
      _selectedBatchName = widget.record!.batchName;
    }
  }

  Future<void> _loadBatches() async {
    final batchBox = Hive.box<BirdBatch>('batches');
    final isolationBox = Hive.box<IsolationRecord>('isolation');

    setState(() {
      // Filter for batches that are not deleted AND have at least one active isolation record
      _availableBatches = batchBox.values
          .where((batch) => !batch.isDeleted &&
                          isolationBox.values.any(
                            (rec) => rec.batchName == batch.name && rec.isActive
                          ))
          .toList();

      // If adding a new record and no batch is selected, try to select the first one
      if (widget.record == null && _selectedBatchName == null && _availableBatches.isNotEmpty) {
        _selectedBatchName = _availableBatches.first.name;
      }
    });
  }

  @override
  void dispose() {
    _numberOfBirdsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // <<< THIS METHOD HAS BEEN CORRECTED TO FIX THE CRASH >>>
  /// Saves or updates a release log record in Hive and flags it for sync.
  void _saveReleaseLog() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedBatchName == null || _selectedBatchName!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a batch for this release record.')),
          );
        }
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final releaseLogBox = Hive.box<ReleaseLog>('release_log');
        final isolationBox = Hive.box<IsolationRecord>('isolation');
        final batchBox = Hive.box<BirdBatch>('batches');

        final int birdsToRelease = int.parse(_numberOfBirdsController.text);

        // Find the selected BirdBatch object
        final BirdBatch selectedBatch = batchBox.values.firstWhere(
          (batch) => batch.name == _selectedBatchName,
          orElse: () => throw Exception('Selected batch "$_selectedBatchName" not found.'),
        );

        // Validation: Ensure birds to release don't exceed currently isolated birds
        final List<IsolationRecord> activeIsolationRecordsForBatch = isolationBox.values
            .where((record) => record.batchName == _selectedBatchName && record.isActive)
            .toList();

        final int totalIsolatedInSelectedBatch = activeIsolationRecordsForBatch.fold(0, (sum, record) => sum + record.numberOfBirds);

        if (birdsToRelease > totalIsolatedInSelectedBatch) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cannot release $birdsToRelease birds. Only $totalIsolatedInSelectedBatch are currently isolated for this batch.')),
            );
          }
          setState(() { _isSaving = false; });
          return;
        }


        // --- Update Isolation Records and Batch Quantity ---
        int remainingToRelease = birdsToRelease;
        // THE FIX: Use a Map to store the original key alongside the new record data
        final Map<dynamic, IsolationRecord> recordsToUpdate = {};

        // Iterate through active isolation records to subtract the released birds
        for (var record in activeIsolationRecordsForBatch) {
          if (remainingToRelease <= 0) break;

          final int birdsFromThisRecord = record.numberOfBirds;
          dynamic originalKey = record.key; // Store the original key

          if (remainingToRelease >= birdsFromThisRecord) {
            // Release all birds from this isolation record
            recordsToUpdate[originalKey] = record.copyWith(
              numberOfBirds: 0,
              isActive: false,
              releaseDate: DateTime.now(),
              isSynced: false,
            );
            remainingToRelease -= birdsFromThisRecord;
          } else {
            // Release a partial amount from this isolation record
            recordsToUpdate[originalKey] = record.copyWith(
              numberOfBirds: birdsFromThisRecord - remainingToRelease,
              isSynced: false,
            );
            remainingToRelease = 0;
          }
        }

        // Apply updates to Isolation Records in Hive using the original key
        for (var entry in recordsToUpdate.entries) {
          // Use entry.key (the original key) which is guaranteed to exist
          await isolationBox.put(entry.key, entry.value);
        }

        // Add released birds back to the main BirdBatch quantity
        selectedBatch.quantity += birdsToRelease;
        selectedBatch.isSynced = false;
        await selectedBatch.save();

        // --- Create ReleaseLog Entry ---
        final newReleaseLog = ReleaseLog(
          batchName: _selectedBatchName!,
          numberOfBirds: birdsToRelease,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          releaseDate: _selectedDate,
          isSynced: false,
          createdAt: DateTime.now(),
        );

        if (widget.recordKey != null) {
          await releaseLogBox.put(widget.recordKey, newReleaseLog);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Release record updated successfully!')),
            );
          }
        } else {
          await releaseLogBox.add(newReleaseLog);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Release record added successfully!')),
            );
          }
        }

        // Trigger Data Sync
        if (mounted) {
          ref.read(dataSyncServiceProvider).triggerManualSync();
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        debugPrint('Error saving release log or updating batches: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save release record: ${e.toString()}')),
          );
        }
        setState(() { _isSaving = false; });
        return;
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  /// Shows a date picker to select the release date.
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
          widget.record == null ? 'Add Release Record' : 'Edit Release Record',
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
                  // Display the current quantity AND currently isolated count for this batch
                  final int isolatedCount = Hive.box<IsolationRecord>('isolation')
                      .values
                      .where((rec) => rec.batchName == batch.name && rec.isActive)
                      .fold(0, (sum, rec) => sum + rec.numberOfBirds);
                  return DropdownMenuItem(
                    value: batch.name,
                    child: Text(
                      '${batch.name} (Live: ${batch.quantity}, Isolated: $isolatedCount)',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (!_isSaving) { // Disable when saving
                    setState(() {
                      _selectedBatchName = val;
                    });
                  }
                },
                onSaved: (val) {
                  _selectedBatchName = val;
                },
              ),
              const SizedBox(height: 15),

              // Number of Birds Input Field
              TextFormField(
                controller: _numberOfBirdsController,
                decoration: InputDecoration(
                  labelText: 'Number of Birds Released',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.check_circle_outline, color: primaryColor),
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
                    return 'Please enter number of birds';
                  }
                  final int? birds = int.tryParse(value);
                  if (birds == null || birds <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _numberOfBirdsController.text = value ?? '0',
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
              const SizedBox(height: 15),

              // Date Picker Row
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Release Date',
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
              onPressed: _isSaving ? null : _saveReleaseLog, // Disable button while saving
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
                  : Text(widget.record == null ? 'Save Record' : 'Update Record', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}