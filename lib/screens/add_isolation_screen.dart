// screens/add_isolation_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/providers/provider.dart';

import '../models/isolation_record.dart';
import '../models/bird_batch.dart'; // Import BirdBatch to select batches
import '../services/data_sync_service.dart'; // Import DataSyncService

class AddIsolationScreen extends ConsumerStatefulWidget {
  final IsolationRecord? record;
  final dynamic recordKey;
  final String? initialBatchName;

  const AddIsolationScreen({
    super.key,
    this.record,
    this.recordKey,
    this.initialBatchName,
  });

  @override
  ConsumerState<AddIsolationScreen> createState() => _AddIsolationScreenState();
}

class _AddIsolationScreenState extends ConsumerState<AddIsolationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numberOfBirdsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedBatchName;
  List<BirdBatch> _availableBatches = [];

  final Color primaryColor = Colors.deepOrange;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBatches();

    if (widget.record != null) {
      _numberOfBirdsController.text = widget.record!.numberOfBirds.toString();
      _reasonController.text = widget.record!.reason;
      _selectedDate = widget.record!.isolationDate;
      _selectedBatchName = widget.record!.batchName;
    } else if (widget.initialBatchName != null) {
      _selectedBatchName = widget.initialBatchName;
    }
  }

  Future<void> _loadBatches() async {
    final batchBox = Hive.box<BirdBatch>('batches');
    setState(() {
      _availableBatches = batchBox.values.where((batch) => !batch.isDeleted).toList(); // Only show active batches
      if (widget.record == null && _selectedBatchName == null && _availableBatches.isNotEmpty) {
        _selectedBatchName = _availableBatches.first.name;
      }
    });
  }

  @override
  void dispose() {
    _numberOfBirdsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _saveIsolationRecord() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedBatchName == null || _selectedBatchName!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a batch for this isolation record.')),
          );
        }
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final isolationBox = Hive.box<IsolationRecord>('isolation');
        final batchBox = Hive.box<BirdBatch>('batches');

        final int birdsIsolated = int.parse(_numberOfBirdsController.text);
        
        // Find the selected BirdBatch object, ensure it's not null via orElse
        final BirdBatch selectedBatch = batchBox.values.firstWhere(
          (batch) => batch.name == _selectedBatchName,
          orElse: () => throw Exception('Selected batch "$_selectedBatchName" not found.'),
        );

        // --- Validation: Ensure birds isolated don't exceed current quantity ---
        if (birdsIsolated > selectedBatch.quantity) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Number of birds to isolate cannot exceed the current batch quantity.')),
            );
          }
          setState(() { _isSaving = false; });
          return;
        }

        // --- Deduct from BirdBatch quantity ---
        selectedBatch.quantity -= birdsIsolated;
        selectedBatch.isSynced = false; // Mark batch for sync
        await selectedBatch.save(); // Save changes to the batch


        if (widget.recordKey != null && widget.record != null) {
          final updatedRecord = widget.record!.copyWith(
            batchName: _selectedBatchName!,
            numberOfBirds: birdsIsolated,
            reason: _reasonController.text,
            isolationDate: _selectedDate,
            isSynced: false,
            isActive: true, // Keep active if editing, unless a specific "release" action is implemented
            releaseDate: null, // Ensure release date is null when editing as an active record
          );
          await isolationBox.put(widget.recordKey, updatedRecord);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Isolation record updated successfully!')),
            );
          }
        } else {
          final newRecord = IsolationRecord(
            batchName: _selectedBatchName!,
            numberOfBirds: birdsIsolated,
            reason: _reasonController.text,
            isolationDate: _selectedDate,
            isSynced: false,
            createdAt: DateTime.now(),
            isDeleted: false,
            isActive: true, // New records are active by default
          );
          await isolationBox.add(newRecord);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Isolation record added successfully!')),
            );
          }
        }

        if (mounted) {
          ref.read(dataSyncServiceProvider).triggerManualSync();
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        debugPrint('Error saving isolation record: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save isolation record: ${e.toString()}')),
          );
        }
        // IMPORTANT: Reset saving state and return on error
        setState(() { _isSaving = false; });
        return; // Ensure function stops here if error occurs
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false; // Ensures _isSaving is always false at end of operation
          });
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.record == null ? 'Add Isolation Record' : 'Edit Isolation Record',
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
                      '${batch.name} (Qty: ${batch.quantity})', // Show current quantity
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
                  labelText: 'Number of Birds Isolated',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.medication_liquid, color: primaryColor),
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
                  if (birds == null || birds < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _numberOfBirdsController.text = value ?? '0',
              ),
              const SizedBox(height: 15),

              // Reason Input Field
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for Isolation',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.description, color: primaryColor),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _reasonController.text = value ?? '',
              ),
              const SizedBox(height: 15),

              // Date Picker Row
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Isolation Date',
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
              onPressed: _isSaving ? null : _saveIsolationRecord,
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
