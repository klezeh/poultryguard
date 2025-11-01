// screens/add_income_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // NEW: Import for Riverpod's ConsumerStatefulWidget
import 'package:poultryguard/providers/provider.dart';

import '../models/income.dart';
import '../services/data_sync_service.dart'; // Import DataSyncService


// Changed from StatefulWidget to ConsumerStatefulWidget for Riverpod integration
class AddIncomeScreen extends ConsumerStatefulWidget {
  final Income? income; // Optional: for editing an existing record (currently not used for population)
  final dynamic incomeKey; // Optional: Hive key for updating existing record (currently not used for updating)

  const AddIncomeScreen({super.key, this.income, this.incomeKey});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState(); // Changed to ConsumerState
}

// Changed from State to ConsumerState for Riverpod integration
class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory; // State variable to hold the selected category for the dropdown

  final Color primaryColor = Colors.deepOrange; // Consistent primary theme color
  bool _isSaving = false; // NEW: State to manage saving process

  // Example list of income sources, can be expanded or made dynamic
  final List<String> _incomeSources = [
    'Sales',
    'Grants',
    'Loans',
    'Investments',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // This screen is currently configured exclusively for adding new income.
    // The `income` and `incomeKey` are kept as parameters for flexibility,
    // but the form population and save logic below only handle new entries.
    _selectedCategory = _incomeSources.first;
    _sourceController.text = _incomeSources.first; // Initialize controller for default display
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _sourceController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Saves an income record in Hive and flags it for sync.
  /// This version of the screen is focused solely on adding new income.
  void _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // NEW: Set _isSaving to true and trigger UI rebuild
      setState(() {
        _isSaving = true;
      });

      try {
        final incomeToSave = Income(
          source: _selectedCategory,
          amount: double.tryParse(_amountController.text) ?? 0.0,
          date: _selectedDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          isSynced: false, // <-- CRUCIAL: Set to false for new/updated records
          createdAt: DateTime.now(), // Set creation timestamp for new records
        );

        final box = Hive.box<Income>('income');
        await box.add(incomeToSave); // Always add new record for this screen's current functionality

        if (mounted) { // Check mounted before showing SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income added successfully!')),
          );
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
        debugPrint('Error saving income: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save income: $e')),
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

  /// Shows a date picker to select the income date.
  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // Allow selection from 2020 onwards
      lastDate: DateTime.now().add(const Duration(days: 365)), // Allow selection up to one year in the future
      builder: (context, child) {
        // Apply theme to the date picker
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryColor, // Header background color
            colorScheme: ColorScheme.light(primary: primaryColor), // Selected day color
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    // Update the selected date if a date is picked
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text( // Always display "Add New Income" as per current functionality
          'Add New Income',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white), // Ensures back button is white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24), // Increased padding for a better look
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min to wrap content
            children: [
              // Source Dropdown Field
              DropdownButtonFormField<String>(
                value: _selectedCategory, // Use the dedicated state variable
                decoration: InputDecoration(
                  labelText: 'Source',
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
                    value == null || value.isEmpty ? 'Please select a source' : null,
                items: _incomeSources.map(
                  (src) => DropdownMenuItem(
                    value: src,
                    child: Text(src, style: const TextStyle(fontSize: 16)),
                  ),
                ).toList(),
                onChanged: _isSaving ? null : (val) { // Disable when saving
                  setState(() {
                    _selectedCategory = val; // Update state variable on change
                  });
                  _sourceController.text = val ?? ''; // Keep controller in sync if needed elsewhere
                },
                onSaved: (val) {
                  _selectedCategory = val; // Assign directly to _selectedCategory
                },
              ),
              const SizedBox(height: 15),

              // Amount Input Field
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
                    return 'Please enter a valid number.';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than zero.';
                  }
                  return null;
                },
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _amountController.text = value ?? '0.0',
              ),
              const SizedBox(height: 15),

              // Date Picker Row - adjusted to handle overflow
              Row(
                children: [
                  Expanded( // Ensure the text part takes available space
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
                        overflow: TextOverflow.ellipsis, // Add overflow handling for long dates
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
                      elevation: 5, // Add a slight shadow
                    ),
                    child: const Text('Change Date'),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Note (Optional) Input Field
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
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
                maxLines: 2, // Allow multiple lines for notes
                keyboardType: TextInputType.multiline,
                enabled: !_isSaving, // Disable when saving
                onSaved: (value) => _noteController.text = value ?? '',
              ),
            ],
          ),
        ),
      ),
      // Buttons moved to bottomNavigationBar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0), // Consistent padding
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
              onPressed: _isSaving ? null : _saveIncome, // Disable button if already saving
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
                  : const Text('Save Income', style: TextStyle(fontSize: 16)), // Always display "Save Income"
            ),
          ],
        ),
      ),
    );
  }
}
