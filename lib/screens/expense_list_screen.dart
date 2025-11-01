// screens/ExpenseListScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poultryguard/providers/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import 'AddExpenseDialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import '../services/data_sync_service.dart'; // Ensure DataSyncService is imported


class ExpenseListScreen extends ConsumerStatefulWidget { // Changed to ConsumerStatefulWidget
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState(); // Changed to ConsumerState
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> { // Changed to ConsumerState
  List<Expense> _expenses = [];
  final List<dynamic> _selectedKeysForDeletion = [];
  // Stores original state of expenses marked for deletion for undo functionality
  final List<MapEntry<dynamic, Expense>> _recentlyMarkedForDeletion = [];
  bool _isDeleteMode = false;
  String? _selectedCategory;

  DateTimeRange? _selectedRange;

  // Updated colors to match deepOrange theme
  final Color primaryColor = Colors.deepOrange;
  final Color accentColor = Colors.orangeAccent;
  final Color backgroundColor = Colors.grey.shade100;
  final Color cardColor = Colors.white;
  final Color textColor = Colors.grey.shade800;
  final Color iconColor = Colors.grey.shade600;
  final Color deleteColor = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    // Listen for changes in the expenses box to auto-update the list
    Hive.box<Expense>('expenses').listenable().addListener(_loadExpenses);
  }

  @override
  void dispose() {
    Hive.box<Expense>('expenses').listenable().removeListener(_loadExpenses);
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getString('dateRangeStart');
    final end = prefs.getString('dateRangeEnd');
    if (start != null && end != null) {
      _selectedRange = DateTimeRange(
        start: DateTime.parse(start),
        end: DateTime.parse(end),
      );
    } else {
      final now = DateTime.now();
      _selectedRange = DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    }
    _loadExpenses();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedRange != null) {
      prefs.setString('dateRangeStart', _selectedRange!.start.toIso8601String());
      prefs.setString('dateRangeEnd', _selectedRange!.end.toIso8601String());
    } else {
      prefs.remove('dateRangeStart');
      prefs.remove('dateRangeEnd');
    }
  }

  void _loadExpenses() {
    final box = Hive.box<Expense>('expenses');
    setState(() {
      // Filter out expenses marked as deleted
      _expenses = box.values.where((e) => !e.isDeleted).toList();
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _markSelectedForDeletion() async {
    final box = Hive.box<Expense>('expenses');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Deletion',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to mark ${_selectedKeysForDeletion.length} selected expenses for deletion? They will be removed from your list and synced to the cloud.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm', style: TextStyle(color: deleteColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _recentlyMarkedForDeletion.clear(); // Clear previous undo data
      for (final key in _selectedKeysForDeletion) {
        final expenseToMark = box.get(key);
        if (expenseToMark != null) {
          // Store a copy of the expense *before* marking it as deleted for undo
          _recentlyMarkedForDeletion.add(MapEntry(key, expenseToMark.copyWith()));

          // Mark the existing Hive object as deleted and not synced for DataSyncService
          expenseToMark.isDeleted = true;
          expenseToMark.isSynced = false;
          await expenseToMark.save(); // Save changes to the existing Hive object
        }
      }
      _selectedKeysForDeletion.clear(); // Clear selected for current operation
      _isDeleteMode = false;
      _loadExpenses(); // Reload to reflect filtered list (deleted items hidden)

      // Trigger sync for marked-for-deletion items
      if (context.mounted) {
        ref.read(dataSyncServiceProvider).triggerManualSync(); // Use ref.read for Riverpod
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Marked ${_recentlyMarkedForDeletion.length} expenses for deletion.'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: primaryColor,
          onPressed: () async {
            for (var entry in _recentlyMarkedForDeletion) {
              final originalKey = entry.key;
              final originalExpense = entry.value; // The expense object with original state

              final existingExpense = box.get(originalKey);
              if (existingExpense != null) {
                // If the item still exists in Hive, revert its isDeleted status
                existingExpense.isDeleted = false;
                existingExpense.isSynced = false; // Mark for re-sync
                await existingExpense.save();
              } else {
                // If it was already removed (e.g., by sync service), re-add the original object
                originalExpense.isDeleted = false; // Ensure it's not marked deleted when re-added
                originalExpense.isSynced = false; // Mark for re-sync
                await box.put(originalKey, originalExpense); // Re-add with original key
              }
            }
            _recentlyMarkedForDeletion.clear(); // Clear undo list after action
            _loadExpenses(); // Reload to show restored items
            if (context.mounted) {
              ref.read(dataSyncServiceProvider).triggerManualSync(); // Trigger sync for undone items
            }
          },
        ),
        backgroundColor: Colors.grey.shade900,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // New function to toggle flag status
  void _toggleFlag(Expense expense) {
    final box = Hive.box<Expense>('expenses');
    expense.isFlagged = !expense.isFlagged;
    expense.isSynced = false; // Mark as not synced for DataSyncService
    box.put(expense.key, expense); // Save the updated expense back to Hive
    setState(() {
      // Trigger rebuild to update UI
    });
    // Trigger sync for updated flag status
    if (context.mounted) {
      ref.read(dataSyncServiceProvider).triggerManualSync(); // Use ref.read for Riverpod
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(expense.isFlagged ? 'Expense Flagged!' : 'Expense Unflagged.'),
        backgroundColor: expense.isFlagged ? primaryColor : Colors.grey,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  List<Expense> _getFilteredExpenses() {
    return _expenses.where((e) {
      final inDateRange = _selectedRange == null ||
          (e.date.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(_selectedRange!.end.add(const Duration(days: 1))));
      final matchesCategory = _selectedCategory == null || e.category == _selectedCategory;
      return inDateRange && matchesCategory && !e.isDeleted; // Ensure not deleted
    }).toList();
  }

  double _calculateTotal(List<Expense> list) {
    return list.fold(0, (sum, item) => sum + item.amount);
  }

  IconData _getCategoryIcon(String? category) { // Make category nullable
    switch (category?.toLowerCase()) { // Use null-aware operator
      case 'food':
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_car;
      case 'housing':
        return Icons.home;
      case 'utilities':
        return Icons.lightbulb;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'feed':
        return Icons.grass;
      case 'labor':
        return Icons.engineering;
      case 'medicine':
        return Icons.medical_services;
      case 'equipment':
        return Icons.handyman;
      case 'miscellaneous':
        return Icons.more_horiz;
      case 'general':
      default:
        return Icons.category;
    }
  }

  Widget _buildSummary(List<Expense> filteredExpenses) {
    final totalAmount = _calculateTotal(filteredExpenses);

    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 8,
      color: primaryColor, // Consistent primary color
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Expenses:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  'K${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white54, height: 25),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        initialDateRange: _selectedRange,
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
                      if (picked != null) {
                        setState(() => _selectedRange = picked);
                        _savePreferences();
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date Range',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        _selectedRange != null
                            ? '${DateFormat.yMMMd().format(_selectedRange!.start)} - ${DateFormat.yMMMd().format(_selectedRange!.end)}'
                            : 'Select Dates',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis, // Added for overflow fix
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: Text(
                      'Category',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                      overflow: TextOverflow.ellipsis, // Added for overflow fix
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.filter_list, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    dropdownColor: cardColor,
                    iconEnabledColor: Colors.white70,
                    style: TextStyle(fontSize: 14, color: textColor),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All Categories',
                          overflow: TextOverflow.ellipsis, // Added for overflow fix
                        ),
                      ),
                      ..._expenses.map((e) => e.category).toSet().map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat ?? 'N/A',
                            style: TextStyle(color: textColor),
                            overflow: TextOverflow.ellipsis, // Added for overflow fix
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Expense List Item Builder ---
  Widget _buildExpenseListItem(Expense expense) {
    final isSelected = _selectedKeysForDeletion.contains(expense.key);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.1) : cardColor,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.15 : 0.05),
            blurRadius: isSelected ? 10 : 5,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.shade400,
          width: isSelected ? 2.0 : 0.8,
        ),
      ),
      child: InkWell(
        onLongPress: () {
          setState(() {
            _isDeleteMode = true;
            if (!_selectedKeysForDeletion.contains(expense.key)) {
              _selectedKeysForDeletion.add(expense.key);
            }
          });
        },
        onTap: () {
          if (_isDeleteMode) {
            setState(() {
              if (_selectedKeysForDeletion.contains(expense.key)) {
                _selectedKeysForDeletion.remove(expense.key);
              } else {
                _selectedKeysForDeletion.add(expense.key);
              }
            });
            if (_selectedKeysForDeletion.isEmpty) {
              setState(() {
                _isDeleteMode = false;
              });
            }
          } else {
            // Re-enable edit functionality: show AddExpenseDialog in edit mode
            showDialog(
              context: context,
              builder: (context) => AddExpenseDialog(
                expense: expense,
                expenseKey: expense.key,
              ),
            ).then((result) {
              if (result == true) {
                _loadExpenses(); // Reload expenses if edited successfully
              }
            });
          }
        },
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getCategoryIcon(expense.category), color: primaryColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.description,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? primaryColor : textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (expense.isFlagged)
                          IconButton(
                            icon: const Icon(Icons.flag, color: Colors.orange, size: 20),
                            onPressed: () => _toggleFlag(expense),
                            tooltip: 'Flagged',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expense.category ?? 'N/A'} | ${DateFormat.yMMMd().format(expense.date)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? primaryColor.withOpacity(0.7) : iconColor,
                      ),
                    ),
                    Text(
                      'Batch: ${expense.batchName}', // Display batch name
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Amount
              Text(
                'K${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              // Checkbox for delete mode
              if (_isDeleteMode) ...[
                const SizedBox(width: 10),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
                  color: isSelected ? primaryColor : iconColor,
                  size: 26,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- REFINED _exportCSV function ---
  Future<void> _exportCSV(List<Expense> expenses) async {
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No expenses to export for the current filters.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      // CSV Header: Added 'Is Flagged' and 'Batch Name'
      buffer.writeln('Category,Amount (K),Date,Description,Is Flagged,Batch Name');

      // CSV Data
      for (final e in expenses) {
        // Enclose fields in double quotes to handle commas within descriptions
        // Also ensure amounts are formatted consistently
        buffer.writeln(
            '"${e.category?.replaceAll('"', '""') ?? 'N/A'}","${e.amount.toStringAsFixed(2)}","${DateFormat.yMMMd().format(e.date)}","${e.description.replaceAll('"', '""')}","${e.isFlagged ? 'Yes' : 'No'}","${e.batchName.replaceAll('"', '""')}"');
      }

      final dir = await getApplicationDocumentsDirectory();
      String dateRangeString = _selectedRange != null
          ? '${DateFormat('yyyyMMdd').format(_selectedRange!.start)}-${DateFormat('yyyyMMdd').format(_selectedRange!.end)}'
          : DateFormat('yyyyMMdd').format(DateTime.now());

      final fileName = 'expenses_report_$dateRangeString.csv';
      final file = File('${dir.path}/$fileName');

      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'Expense Report from your app.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense report exported successfully to ${file.path}'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('CSV Export Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _getFilteredExpenses();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            _isDeleteMode
                ? '${_selectedKeysForDeletion.length} Selected'
                : 'Expense Tracker',
            key: ValueKey<bool>(_isDeleteMode),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share Report',
            onPressed: () => _exportCSV(filteredExpenses),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isDeleteMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Enable Delete Mode',
              onPressed: () => setState(() {
                _isDeleteMode = true;
                _selectedKeysForDeletion.clear();
              }),
            ),
            secondChild: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              tooltip: 'Delete Selected',
              onPressed: _selectedKeysForDeletion.isNotEmpty ? _markSelectedForDeletion : null, // Changed
            ),
          ),
          if (_isDeleteMode)
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white),
              tooltip: 'Cancel Delete Mode',
              onPressed: () => setState(() {
                _isDeleteMode = false;
                _selectedKeysForDeletion.clear();
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(filteredExpenses),
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          'No expenses recorded yet!',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                        Text(
                          'Tap the + button to add one.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, i) {
                      final expense = filteredExpenses[i];
                      return _buildExpenseListItem(expense);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog( // Using showDialog for AddExpenseDialog
            context: context,
            builder: (context) => const AddExpenseDialog(),
          ).then((result) {
            if (result == true) {
              _loadExpenses();
            }
          });
        },
        label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 10,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
