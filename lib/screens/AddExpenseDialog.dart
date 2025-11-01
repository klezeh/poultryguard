// screens/AddExpenseDialog.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/providers/provider.dart';

import '../models/expense.dart';
import '../models/bird_batch.dart'; // Import BirdBatch
import '../services/data_sync_service.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  final Expense? expense;
  final dynamic expenseKey;

  const AddExpenseDialog({super.key, this.expense, this.expenseKey});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  double? _amount;
  String? _description;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  String? _selectedBatchName; // NEW: To store the selected batch name
  List<BirdBatch> _availableBatches = []; // NEW: List of available batches
  bool _isFlagged = false; // Re-added and initialized

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final Color primaryColor = Colors.deepOrange;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBatches(); // Load batches when the screen initializes

    if (widget.expense != null) {
      // Populate fields if editing an existing record
      _amountController.text = widget.expense!.amount.toString();
      _descriptionController.text = widget.expense!.description;
      _selectedDate = widget.expense!.date;
      _selectedCategory = widget.expense!.category;
      _selectedBatchName = widget.expense!.batchName; // Set existing batch name
      _isFlagged = widget.expense!.isFlagged; // Set existing isFlagged status
    } else {
      _selectedCategory = _categories.first;
    }
  }

  Future<void> _loadBatches() async {
    final batchBox = Hive.box<BirdBatch>('batches');
    setState(() {
      _availableBatches = batchBox.values.toList();
      // If adding a new record and no batch is selected, try to select the first one
      if (widget.expense == null && _selectedBatchName == null && _availableBatches.isNotEmpty) {
        _selectedBatchName = _availableBatches.first.name;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  final List<String> _categories = [
    'General',
    'Feed',
    'Labor',
    'Medicine',
    'Transport',
    'Equipment',
    'Miscellaneous',
    'Food',
    'Housing',
    'Utilities',
    'Entertainment',
    'Health',
    'Education',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
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

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedBatchName == null || _selectedBatchName!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a batch for this expense.')),
          );
        }
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final Expense expenseToSave = Expense(
          category: _selectedCategory ?? 'General',
          amount: _amount ?? 0.0,
          date: _selectedDate,
          description: _description ?? '',
          batchName: _selectedBatchName!, // NEW: Pass the selected batch name
          isFlagged: _isFlagged, // Now properly a parameter
          isSynced: false,
          createdAt: DateTime.now(),
        );

        final box = Hive.box<Expense>('expenses');

        if (widget.expenseKey != null) {
          await box.put(widget.expenseKey, expenseToSave);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense updated successfully!')),
            );
          }
        } else {
          await box.add(expenseToSave);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense added successfully!')),
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
        debugPrint('Error saving expense: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save expense: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      // Removed insetPadding from Dialog to prevent double-padding issues
      // insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40), // REMOVED
      child: Container(
        padding: const EdgeInsets.all(24), // Main internal padding for dialog content
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // Constrain the inner content's width to prevent overflow,
        // especially on wider screens or when content is large.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400, // Adjust this value as needed for optimal appearance
          ),
          child: SingleChildScrollView(
            // No extra padding here as it's handled by the parent Container
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.expense == null ? 'Add New Expense' : 'Edit Expense',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
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
                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(color: primaryColor),
                          prefixIcon: Icon(Icons.category, color: primaryColor),
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
                            value == null || value.isEmpty ? 'Please select a category' : null,
                        items: _categories.map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat, style: const TextStyle(fontSize: 16)),
                          ),
                        ).toList(),
                        onChanged: _isSaving ? null : (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                        onSaved: (val) {
                          _selectedCategory = val;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount (K)',
                          labelStyle: TextStyle(color: primaryColor),
                          prefixIcon: Icon(Icons.attach_money, color: primaryColor),
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
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Amount must be greater than zero';
                          }
                          return null;
                        },
                        enabled: !_isSaving,
                        onSaved: (value) => _amount = double.tryParse(value ?? '0.0'),
                      ),
                      const SizedBox(height: 15),

                      // Description Input
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
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
                        enabled: !_isSaving,
                        onSaved: (value) => _description = value,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Flag for Review',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          Switch(
                            value: _isFlagged,
                            onChanged: _isSaving ? null : (value) {
                              setState(() {
                                _isFlagged = value;
                              });
                            },
                            activeColor: primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Row(
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
                      onPressed: _isSaving ? null : _saveExpense,
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
                          : Text(widget.expense == null ? 'Save Expense' : 'Update Expense', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
