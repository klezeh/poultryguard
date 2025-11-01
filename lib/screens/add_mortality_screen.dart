// screens/add_mortality_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/providers/provider.dart';
import '../models/mortality_record.dart';
import '../models/bird_batch.dart'; // Import BirdBatch to select batches
import '../services/data_sync_service.dart'; // Import DataSyncService

class AddMortalityScreen extends ConsumerStatefulWidget {
  final MortalityRecord? record;
  final dynamic recordKey;
  final String? initialBatchName;

  const AddMortalityScreen({
    super.key,
    this.record,
    this.recordKey,
    this.initialBatchName,
  });

  @override
  ConsumerState<AddMortalityScreen> createState() => _AddMortalityScreenState();
}

class _AddMortalityScreenState extends ConsumerState<AddMortalityScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numberOfBirdsController =
      TextEditingController();
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
      _selectedDate = widget.record!.date;
      _selectedBatchName = widget.record!.batchName;
    } else if (widget.initialBatchName != null) {
      _selectedBatchName = widget.initialBatchName;
    }
  }

  Future<void> _loadBatches() async {
    final batchBox = Hive.box<BirdBatch>('batches');
    setState(() {
      _availableBatches = batchBox.values.toList();
      if (widget.record == null &&
          _selectedBatchName == null &&
          _availableBatches.isNotEmpty) {
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

  void _saveMortalityRecord() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedBatchName == null || _selectedBatchName!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Please select a batch for this mortality record.')),
          );
        }
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final box = Hive.box<MortalityRecord>('mortality');
        final batchBox = Hive.box<BirdBatch>('batches');

        final int birdsLost = int.parse(_numberOfBirdsController.text);
        final BirdBatch? selectedBatch = batchBox.values.firstWhere(
          (batch) => batch.name == _selectedBatchName,
          orElse: () => throw Exception('Selected batch not found.'),
        );

        if (selectedBatch == null) {
          throw Exception('Selected batch not found.');
        }

        // --- Validation: Ensure birds lost don't exceed current quantity ---
        if (birdsLost > selectedBatch.quantity) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Number of birds lost cannot exceed the current batch quantity.')),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }

        // --- Deduct from BirdBatch quantity ---
        selectedBatch.quantity -= birdsLost;
        selectedBatch.isSynced = false; // Mark batch for sync
        await selectedBatch.save(); // Save changes to the batch

        if (widget.recordKey != null && widget.record != null) {
          final updatedRecord = widget.record!.copyWith(
            batchName: _selectedBatchName!,
            numberOfBirds: birdsLost,
            reason: _reasonController.text,
            date: _selectedDate,
            isSynced: false,
          );
          await box.put(widget.recordKey, updatedRecord);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Mortality record updated successfully!')),
            );
          }
        } else {
          final newRecord = MortalityRecord(
            batchName: _selectedBatchName!,
            numberOfBirds: birdsLost,
            reason: _reasonController.text,
            date: _selectedDate,
            isSynced: false,
            createdAt: DateTime.now(),
            isDeleted: false,
          );
          await box.add(newRecord);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Mortality record added successfully!')),
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
        debugPrint('Error saving mortality record: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save mortality record: $e')),
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
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
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
          widget.record == null
              ? 'Add Mortality Record'
              : 'Edit Mortality Record',
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
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1.5),
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
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a batch'
                    : null,
                items: _availableBatches.map((batch) {
                  return DropdownMenuItem(
                    value: batch.name,
                    child: Text(
                      '${batch.name} (Qty: ${batch.quantity})', // Show current quantity
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (val) {
                        setState(() {
                          _selectedBatchName = val;
                        });
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
                  labelText: 'Number of Birds',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.sick, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1.5),
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
                  // Parse the number once to be safe and efficient
                  final number = int.tryParse(value);
                  if (number == null) {
                    return 'Please enter a valid number';
                  }
                  // THE FIX: Change <= 0 to < 0 to allow zero.
                  if (number < 0) {
                    return 'Please enter a non-negative number (0 or more)';
                  }
                  return null;
                },
                enabled: !_isSaving,
                onSaved: (value) =>
                    _numberOfBirdsController.text = value ?? '0',
              ),
              const SizedBox(height: 15),

              // Reason Input Field
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for Mortality',
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.description, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1.5),
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
                enabled: !_isSaving,
                onSaved: (value) => _reasonController.text = value ?? '',
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
                        prefixIcon:
                            Icon(Icons.calendar_today, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryColor, width: 2.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      child: Text(
                        DateFormat.yMMMd().format(_selectedDate),
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveMortalityRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  : Text(
                      widget.record == null ? 'Save Record' : 'Update Record',
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
