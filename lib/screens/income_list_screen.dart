import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:poultryguard/services/data_sync_service.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/income.dart';
import '../../providers/provider.dart';
import 'add_income_screen.dart';

// CHANGE: Converted to ConsumerStatefulWidget to use Riverpod for sync service
class IncomeListScreen extends ConsumerStatefulWidget {
  const IncomeListScreen({super.key});

  @override
  ConsumerState<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends ConsumerState<IncomeListScreen> {
  late Box<Income> incomeBox;
  String? _selectedSourceFilter;
  DateTimeRange? _selectedDateRange;

  // Moved these into the state class
  bool _selectionMode = false;
  final Set<dynamic> _selectedKeys = {};

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
    incomeBox = Hive.box<Income>('income');

    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30)),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  // NOTE: listener in initState and _loadIncomes() are no longer needed
  // as ValueListenableBuilder will handle UI updates automatically.

  double _totalIncome(List<Income> incomes) {
    return incomes.fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> _exportCSV(List<Income> incomes) async {
    if (incomes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No income to export for the current filters.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      buffer.writeln('Note,Amount (K),Date,Source,Is Synced');

      for (final e in incomes) {
        buffer.writeln(
            '"${e.note?.replaceAll('"', '""') ?? ''}","${e.amount.toStringAsFixed(2)}","${DateFormat.yMMMd().format(e.date)}","${e.source?.replaceAll('"', '""') ?? ''}","${e.isSynced ? 'Yes' : 'No'}"');
      }

      final dir = await getApplicationDocumentsDirectory();
      String dateRangeString = _selectedDateRange != null
          ? '${DateFormat('yyyyMMdd').format(_selectedDateRange!.start)}-${DateFormat('yyyyMMdd').format(_selectedDateRange!.end)}'
          : DateFormat('yyyyMMdd').format(DateTime.now());

      final fileName = 'income_report_$dateRangeString.csv';
      final file = File('${dir.path}/$fileName');

      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'Income Report from PoultryGuard.');

      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Income report exported successfully to ${file.path}'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('CSV Export Error: $e');
    }
  }

  List<Income> _getFilteredIncomes() {
    return incomeBox.values.where((income) {
      // Important: Exclude items marked for deletion from the UI.
      if (income.isDeleted) return false;
      
      final matchesSource = _selectedSourceFilter == null || income.source == _selectedSourceFilter;
      final matchesDate = _selectedDateRange == null ||
          (income.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              income.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
      return matchesSource && matchesDate;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  // --- FIX #1: Corrected the entire delete logic ---
  void _confirmDeleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete', style: TextStyle(color: deleteColor, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${_selectedKeys.length} selected entries?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: deleteColor, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final keysToDelete = Set.from(_selectedKeys);
      int deletedCount = 0;

      for (final key in keysToDelete) {
        final incomeToDelete = incomeBox.get(key);
        if (incomeToDelete != null) {
          // Use the correct method to flag the item for deletion by the sync service.
          await incomeToDelete.markAsDeleted();
          deletedCount++;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $deletedCount income entries. Syncing...')),
        );
        setState(() {
          _selectedKeys.clear();
          _selectionMode = false;
        });
      }

      // Trigger a sync to push the deletions to the server.
      ref.read(dataSyncServiceProvider).triggerManualSync();
    }
  }

  IconData _getIncomeIcon(String? source) {
    switch (source?.toLowerCase()) {
      case 'sales':
        return Icons.attach_money;
      case 'loans':
        return Icons.handshake;
      case 'grants':
        return Icons.payments;
      default:
        return Icons.trending_up;
    }
  }

  Widget _buildSummary(List<Income> filteredIncomes) {
    final totalAmount = _totalIncome(filteredIncomes);
    final allSources = incomeBox.values.map((e) => e.source).toSet().where((source) => source != null && source.isNotEmpty).cast<String>().toList();

    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 8,
      color: primaryColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Income:',
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
                        initialDateRange: _selectedDateRange,
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
                        setState(() => _selectedDateRange = picked);
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
                        _selectedDateRange != null
                            ? '${DateFormat.yMMMd().format(_selectedDateRange!.start)} - ${DateFormat.yMMMd().format(_selectedDateRange!.end)}'
                            : 'Select Dates',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSourceFilter,
                    hint: Text(
                      'Source',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
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
                        child: Text('All Sources', style: TextStyle(color: Colors.black87)),
                      ),
                      ...allSources.map((source) {
                        return DropdownMenuItem(
                          value: source,
                          child: Text(source, style: TextStyle(color: textColor)),
                        );
                      }).toList(),
                    ],
                    onChanged: (val) => setState(() => _selectedSourceFilter = val),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeListItem(Income income) {
    final isSelected = _selectedKeys.contains(income.key);

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
            _selectionMode = true;
            if (!_selectedKeys.contains(income.key)) {
              _selectedKeys.add(income.key!);
            }
          });
        },
        onTap: () {
          if (_selectionMode) {
            setState(() {
              if (_selectedKeys.contains(income.key)) {
                _selectedKeys.remove(income.key);
              } else {
                _selectedKeys.add(income.key!);
              }
            });
            if (_selectedKeys.isEmpty) {
              setState(() {
                _selectionMode = false;
              });
            }
          } else {
            debugPrint('Tapped on income item, but edit is currently disabled.');
          }
        },
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getIncomeIcon(income.source), color: primaryColor, size: 24),
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
                            income.note ?? 'No note',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? primaryColor : textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${income.source ?? 'N/A'} | ${DateFormat.yMMMd().format(income.date)}',
                      style: TextStyle(fontSize: 13, color: isSelected ? primaryColor : iconColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'K${income.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (_selectionMode) ...[
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            _selectionMode
                ? '${_selectedKeys.length} selected'
                : 'Income Records',
            key: ValueKey<bool>(_selectionMode),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share Report',
            onPressed: () => _exportCSV(_getFilteredIncomes()),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _selectionMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Enable Delete Mode',
              onPressed: () => setState(() {
                _selectionMode = true;
                _selectedKeys.clear();
              }),
            ),
            secondChild: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              tooltip: 'Delete Selected',
              onPressed: _selectedKeys.isNotEmpty ? _confirmDeleteSelected : null,
            ),
          ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white),
              tooltip: 'Cancel Delete Mode',
              onPressed: () => setState(() {
                _selectionMode = false;
                _selectedKeys.clear();
              }),
            ),
        ],
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectionMode = false;
                    _selectedKeys.clear();
                  });
                },
              )
            : null,
      ),
      body: ValueListenableBuilder(
        valueListenable: incomeBox.listenable(),
        builder: (context, Box<Income> box, _) {
          final filteredIncomes = _getFilteredIncomes();
          
          return Column(
            children: [
              _buildSummary(filteredIncomes),
              Expanded(
                child: filteredIncomes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.money_off, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              'No income records yet!',
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
                        itemCount: filteredIncomes.length,
                        itemBuilder: (context, i) {
                          final income = filteredIncomes[i];
                          return _buildIncomeListItem(income);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddIncomeScreen(),
            ),
          );
        },
        label: const Text('Add Income', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 10,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}