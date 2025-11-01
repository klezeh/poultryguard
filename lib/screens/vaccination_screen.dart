import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:poultryguard/models/batch_vaccination_event.dart';
import 'package:poultryguard/providers/provider.dart';
import 'package:poultryguard/services/data_sync_service.dart';
import '../models/vaccination_record.dart';
import '../models/bird_batch.dart';
import 'add_vaccination_record_screen.dart';
import 'package:poultryguard/widgets/vaccination_checklist_screen.dart';
import 'package:poultryguard/services/batch_schedule_service.dart';

class VaccinationScreen extends ConsumerStatefulWidget {
  const VaccinationScreen({super.key});

  @override
  ConsumerState<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends ConsumerState<VaccinationScreen> {
  late Box<VaccinationRecord> _vaccinationBox;
  late Box<BirdBatch> _batchBox;
  BirdBatch? _selectedBatch;

  final Color primaryColor = Colors.deepOrange;

  int _upcomingVaccinationsCount = 0;
  int _missedVaccinationsCount = 0;
  int _totalBirdsVaccinated = 0;
  
  @override
  void initState() {
    super.initState();
    _vaccinationBox = Hive.box<VaccinationRecord>('vaccination_records');
    _batchBox = Hive.box<BirdBatch>('batches');

    _loadInitialBatch();

    _vaccinationBox.listenable().addListener(_calculateVaccinationSummary);
    _batchBox.listenable().addListener(_calculateVaccinationSummary);
    Hive.box<BatchVaccinationEvent>('batch_vaccinations').listenable().addListener(_calculateVaccinationSummary);
  }

  @override
  void dispose() {
    _vaccinationBox.listenable().removeListener(_calculateVaccinationSummary);
    _batchBox.listenable().removeListener(_calculateVaccinationSummary);
    Hive.box<BatchVaccinationEvent>('batch_vaccinations').listenable().removeListener(_calculateVaccinationSummary);
    super.dispose();
  }

  void _loadInitialBatch() {
    final activeBatches = _batchBox.values.where((b) => !b.isDeleted).toList();
    if (activeBatches.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _selectedBatch = activeBatches.first;
        _calculateVaccinationSummary();
      });
    }
  }

  void _calculateVaccinationSummary() {
    if (!mounted) return;

    if (_selectedBatch == null) {
      setState(() {
        _upcomingVaccinationsCount = 0;
        _missedVaccinationsCount = 0;
        _totalBirdsVaccinated = 0;
      });
      return;
    }
    
    final batchScheduleService = ref.read(batchScheduleServiceProvider);
    final batchScheduledEvents = batchScheduleService.getScheduleForBatch(_selectedBatch!.name);
    final today = DateTime.now();
    int upcoming = 0;
    int missed = 0;

    for (var scheduledEvent in batchScheduledEvents) {
      if (!scheduledEvent.isCompleted) {
        if (scheduledEvent.scheduledDate.isBefore(today)) {
          missed++;
        } else {
          upcoming++;
        }
      }
    }

    final totalVaccinated = _vaccinationBox.values
        .where((record) => !record.isDeleted && record.batchName == _selectedBatch!.name)
        .fold(0, (sum, record) => sum + record.quantity);

    setState(() {
      _upcomingVaccinationsCount = upcoming;
      _missedVaccinationsCount = missed;
      _totalBirdsVaccinated = totalVaccinated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine Records', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ValueListenableBuilder<Box<BirdBatch>>(
            valueListenable: _batchBox.listenable(),
            builder: (context, box, _) {
              final batches = box.values.where((b) => !b.isDeleted).toList();
              if (batches.isEmpty) return const SizedBox.shrink();

              final selectedBatchName = _selectedBatch?.name;
              if (_selectedBatch == null || !batches.any((b) => b.name == selectedBatchName)) {
                 WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialBatch());
                 return const SizedBox.shrink();
              }

              return DropdownButtonHideUnderline(
                child: DropdownButton<BirdBatch>(
                  value: _selectedBatch,
                  hint: const Text('Select Batch', style: TextStyle(color: Colors.white70)),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: Colors.deepOrange.shade800,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: batches.map((batch) {
                    return DropdownMenuItem(value: batch, child: Text(batch.name));
                  }).toList(),
                  onChanged: (BirdBatch? newValue) {
                    setState(() {
                      _selectedBatch = newValue;
                      _calculateVaccinationSummary();
                    });
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            tooltip: 'View Schedule/Checklist',
            onPressed: () {
              if (_selectedBatch != null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => VaccinationChecklistScreen(batch: _selectedBatch!)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a batch to view its schedule.')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Vaccination Record',
            onPressed: () {
              if (_selectedBatch != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddVaccinationRecordScreen(batchId: _selectedBatch!.name)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a batch to add a record.')));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard('Upcoming', _upcomingVaccinationsCount, Colors.blueAccent),
                _buildSummaryCard('Missed', _missedVaccinationsCount, Colors.redAccent),
                _buildSummaryCard('Total Vaccinated', _totalBirdsVaccinated, Colors.green),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: _selectedBatch == null
                ? const Center(child: Text('No active batch selected.'))
                : ValueListenableBuilder(
                    valueListenable: _vaccinationBox.listenable(),
                    builder: (context, Box<VaccinationRecord> box, _) {
                      final recordsForSelectedBatch = box.values
                          .where((record) => record.batchName == _selectedBatch!.name && !record.isDeleted)
                          .toList()
                        ..sort((a, b) => b.dateGiven.compareTo(a.dateGiven));

                      if (recordsForSelectedBatch.isEmpty) {
                        return Center(child: Text('No vaccination records for batch "${_selectedBatch!.name}".'));
                      }

                      return ListView.builder(
                        itemCount: recordsForSelectedBatch.length,
                        itemBuilder: (context, index) {
                          final record = recordsForSelectedBatch[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                            child: ListTile(
                              title: Text('${record.vaccineName} - Batch: ${record.batchName}'),
                              subtitle: Text('Given on: ${DateFormat.yMMMd().format(record.dateGiven)}\nNotes: ${record.notes ?? 'N/A'}'),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Text('Are you sure you want to delete this vaccination record for ${record.batchName}? This will also unmark its corresponding scheduled event.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Delete')),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await record.markAsDeleted();
                                    final batchScheduleService = ref.read(batchScheduleServiceProvider);
                                    final eventToUpdate = Hive.box<BatchVaccinationEvent>('batch_vaccinations').values.firstWhereOrNull(
                                          (e) => e.batchId == record.batchName && e.vaccinationName == record.vaccineName,
                                    );
                                    if (eventToUpdate != null && eventToUpdate.isCompleted) {
                                      await batchScheduleService.markVaccinationAsCompleted(eventToUpdate.key, false);
                                    }
                                    ref.read(dataSyncServiceProvider).triggerManualSync();
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record marked for deletion.')));
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: MediaQuery.of(context).size.width / 3.5,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}