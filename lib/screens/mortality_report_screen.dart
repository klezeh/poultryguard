// screens/mortality_report_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mortality_record.dart';
import '../models/bird_batch.dart'; // Import BirdBatch
import 'package:intl/intl.dart';

class MortalityReportScreen extends StatefulWidget {
  const MortalityReportScreen({super.key});

  @override
  State<MortalityReportScreen> createState() => _MortalityReportScreenState();
}

class _MortalityReportScreenState extends State<MortalityReportScreen> {
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

  List<MortalityRecord> _applyFilters(List<MortalityRecord> records) {
    return records.where((record) {
      final matchesBatch =
          _selectedBatchName == null || record.batchName == _selectedBatchName;
      final matchesStart = _startDate == null ||
          record.date.isAfter(_startDate!.subtract(const Duration(days: 1)));
      final matchesEnd = _endDate == null ||
          record.date.isBefore(_endDate!.add(const Duration(days: 1)));
      return matchesBatch && matchesStart && matchesEnd;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recordBox = Hive.box<MortalityRecord>('mortality');
    final batchBox = Hive.box<BirdBatch>('batches');
    final allBatches = batchBox.values.toList(); // Get full batch objects for quantity

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mortality Report', style: TextStyle(color: Colors.white)),
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
              builder: (context, Box<MortalityRecord> box, _) {
                final filtered = _applyFilters(box.values.toList());
                final totalMortality = filtered.fold(0, (sum, record) => sum + record.numberOfBirds);

                if (filtered.isEmpty) {
                  return const Center(child: Text('No mortality records found for selected filters.'));
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
                                'Total Birds Lost:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                              ),
                              Text(
                                '$totalMortality',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final record = filtered[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            elevation: 1.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(color: Colors.deepOrange.shade100),
                            ),
                            child: ListTile(
                              title: Text('${record.numberOfBirds} birds lost',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${record.batchName} on ${DateFormat.yMMMd().format(record.date)}\nReason: ${record.reason}',
                              ),
                              isThreeLine: true,
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
