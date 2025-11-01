// screens/isolation_report_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:poultryguard/providers/provider.dart';
import '../models/isolation_record.dart';
import '../models/bird_batch.dart'; // Import BirdBatch
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/services/data_sync_service.dart';



class IsolationReportScreen extends ConsumerStatefulWidget {
  const IsolationReportScreen({super.key});

  @override
  ConsumerState<IsolationReportScreen> createState() => _IsolationReportScreenState();
}

class _IsolationReportScreenState extends ConsumerState<IsolationReportScreen> {
  String? _selectedBatchName;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Set default date range to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
  }

  List<IsolationRecord> _applyFilters(List<IsolationRecord> records) {
    return records.where((record) {
      final matchesBatch =
          _selectedBatchName == null || record.batchName == _selectedBatchName;
      final matchesStart = _startDate == null ||
          record.isolationDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
      final matchesEnd = _endDate == null ||
          record.isolationDate.isBefore(_endDate!.add(const Duration(days: 1)));
      return matchesBatch && matchesStart && matchesEnd;
    }).toList();
  }

  /// Marks an isolation record as released and updates batch quantity.
  Future<void> _markAsReleased(IsolationRecord record) async {
    final isolationBox = Hive.box<IsolationRecord>('isolation');
    final batchBox = Hive.box<BirdBatch>('batches');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Release'),
        content: Text('Are you sure you want to mark ${record.numberOfBirds} birds from Batch "${record.batchName}" as released from isolation? This will return them to the main flock quantity.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Release'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Find the corresponding batch
        final BirdBatch? batchToUpdate = batchBox.values.firstWhere(
          (batch) => batch.name == record.batchName,
          orElse: () => throw Exception('Batch not found for isolation record.'),
        );

        if (batchToUpdate == null) {
          throw Exception('Batch not found for isolation record.');
        }

        // Update IsolationRecord status
        final updatedIsolationRecord = record.copyWith(
          isActive: false,
          releaseDate: DateTime.now(),
          isSynced: false, // Mark for sync
        );
        await isolationBox.put(record.key, updatedIsolationRecord);

        // Add birds back to the batch quantity
        batchToUpdate.quantity += record.numberOfBirds;
        batchToUpdate.isSynced = false; // Mark batch for sync
        await batchToUpdate.save();

        if (context.mounted) {
          ref.read(dataSyncServiceProvider).triggerManualSync(); // Trigger sync for both changes
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Birds released and batch quantity updated.')),
          );
        }
      } catch (e) {
        debugPrint('Error marking as released or updating batch: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to release birds: ${e.toString()}')),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final recordBox = Hive.box<IsolationRecord>('isolation');
    final batchBox = Hive.box<BirdBatch>('batches');
    final allBatches = batchBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Isolation Report', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedBatchName,
                  hint: const Text('Select Batch'),
                  decoration: InputDecoration(
                    labelText: 'Select Batch',
                    labelStyle: const TextStyle(color: Colors.deepOrange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.deepOrange, width: 2.0),
                    ),
                  ),
                  items: allBatches.map((batch) {
                    return DropdownMenuItem(
                      value: batch.name,
                      child: Text('${batch.name} (Current Qty: ${batch.quantity})'), // Display current quantity
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBatchName = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor: Colors.deepOrange,
                                  colorScheme: ColorScheme.light(primary: Colors.deepOrange),
                                  buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        child: Text(_startDate == null
                            ? 'Start Date'
                            : 'From: ${DateFormat.yMMMd().format(_startDate!)}'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor: Colors.deepOrange,
                                  colorScheme: ColorScheme.light(primary: Colors.deepOrange),
                                  buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                        child: Text(_endDate == null
                            ? 'End Date'
                            : 'To: ${DateFormat.yMMMd().format(_endDate!)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: recordBox.listenable(),
              builder: (context, Box<IsolationRecord> box, _) {
                final filteredRecords = _applyFilters(box.values.toList());
                final activeIsolatedRecords = filteredRecords.where((r) => r.isActive).toList();
                final totalCurrentlyIsolated = activeIsolatedRecords.fold(0, (sum, record) => sum + record.numberOfBirds);


                if (filteredRecords.isEmpty) {
                  return const Center(child: Text('No isolation records found for selected filters.'));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        color: Colors.deepOrange.shade50,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Currently Isolated Birds:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                              ),
                              Text(
                                '$totalCurrentlyIsolated',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            elevation: 1.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(color: Colors.deepOrange.shade100),
                            ),
                            child: ListTile(
                              title: Text(
                                '${record.numberOfBirds} birds isolated for ${record.reason}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: record.isActive ? Colors.black87 : Colors.grey),
                              ),
                              subtitle: Text(
                                '${record.batchName} on ${DateFormat.yMMMd().format(record.isolationDate)}'
                                '${record.isActive ? '' : '\nReleased: ${DateFormat.yMMMd().format(record.releaseDate!)}'}',
                                style: TextStyle(color: record.isActive ? Colors.grey[600] : Colors.grey[400], fontSize: 12),
                              ),
                              trailing: record.isActive
                                  ? ElevatedButton(
                                      onPressed: () => _markAsReleased(record),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                      ),
                                      child: const Text('Release'),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
