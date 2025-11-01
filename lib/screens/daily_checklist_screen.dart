import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:poultryguard/models/bird_batch.dart';
import 'package:poultryguard/models/poultry_task.dart';
import 'package:intl/intl.dart';
import 'package:poultryguard/screens/checklist_log_feed.dart';
import 'package:poultryguard/screens/checklist_log_lighting.dart';
import 'package:poultryguard/screens/checklist_log_observation.dart';
import 'package:poultryguard/screens/checklist_log_temperature.dart';
import 'package:poultryguard/services/checklist_service.dart' as ChecklistService;
import 'package:poultryguard/services/batch_schedule_service.dart';
import 'package:poultryguard/models/batch_vaccination_event.dart';
import 'package:poultryguard/models/vaccination_record.dart';
import 'package:poultryguard/screens/add_vaccination_record_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/providers/provider.dart';
import 'package:poultryguard/models/daily_checklist_record.dart';

import 'package:poultryguard/screens/add_isolation_screen.dart';
import 'package:poultryguard/screens/add_mortality_screen.dart';
import 'package:poultryguard/services/data_sync_service.dart';
import 'package:poultryguard/widgets/generic_form_dialog.dart';

class DailyChecklistScreen extends ConsumerStatefulWidget {
  final BirdBatch? initialBatch;

  const DailyChecklistScreen({super.key, this.initialBatch});

  @override
  ConsumerState<DailyChecklistScreen> createState() => _DailyChecklistScreenState();
}

class _DailyChecklistScreenState extends ConsumerState<DailyChecklistScreen> {
  BirdBatch? _selectedBatch;
  List<PoultryTask> _currentChecklist = [];
  bool _isDialogShowing = false;
  final Box<BirdBatch> _batchBox = Hive.box<BirdBatch>('batches');

  // --- FIX: Use the new box for DailyChecklistRecord ---
  final Box<DailyChecklistRecord> _checklistRecordBox = Hive.box<DailyChecklistRecord>('daily_checklists');
  final Box<VaccinationRecord> _vaccinationRecordsBox = Hive.box<VaccinationRecord>('vaccination_records');
  // --- REMOVED: Unused and old boxes ---
  // final Box<Map<dynamic, dynamic>> _dailyCompletionBox = Hive.box<Map<dynamic, dynamic>>('daily_task_completion');
  // final Box<EnvironmentRecord> _environmentRecordsBox = Hive.box<EnvironmentRecord>('environment_records');

  double _progress = 0.0;

  final Color _primaryOrange = Colors.deepOrange;
  final Color _lightOrange = Colors.deepOrange.shade100;
  final Color _darkGrey = Colors.grey.shade800;
  final Color _lightGrey = Colors.grey.shade200;

  @override
  void initState() {
    super.initState();
    _loadInitialBatch();

    // Setup listeners to automatically refresh the checklist when data changes
    _batchBox.listenable().addListener(_generateChecklist);
    Hive.box<BatchVaccinationEvent>('batch_vaccinations').listenable().addListener(_generateChecklist);
    _vaccinationRecordsBox.listenable().addListener(_generateChecklist);
    _checklistRecordBox.listenable().addListener(_generateChecklist); // Listen to the new box
  }

  @override
  void dispose() {
    // Crucial: Remove all listeners when the state is disposed
    _batchBox.listenable().removeListener(_generateChecklist);
    Hive.box<BatchVaccinationEvent>('batch_vaccinations').listenable().removeListener(_generateChecklist);
    _vaccinationRecordsBox.listenable().removeListener(_generateChecklist);
    _checklistRecordBox.listenable().removeListener(_generateChecklist); // Remove listener from the new box
    super.dispose();
  }

  void _loadInitialBatch() {
    if (widget.initialBatch != null) {
      _selectedBatch = widget.initialBatch;
    } else if (_batchBox.values.where((b) => !b.isDeleted).isNotEmpty) {
      _selectedBatch = _batchBox.values.firstWhere((b) => !b.isDeleted, orElse: () => _batchBox.values.first);
    }
    _generateChecklist();
  }

  void _generateChecklist() {
    if (!mounted) return;

    if (_selectedBatch != null) {
      List<PoultryTask> generatedTasks = ChecklistService.generatePoultryChecklist(_selectedBatch!);

      // --- FIX: Read completion status from the new DailyChecklistRecord model ---
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);

      // Find today's checklist record for this specific batch
      DailyChecklistRecord? todaysRecord = _checklistRecordBox.values.firstWhereOrNull(
        (record) => record.batchKey == _selectedBatch!.key && record.date == todayDateOnly,
      );
      final savedCompletions = todaysRecord?.taskCompletions ?? {};

      for (var task in generatedTasks) {
        if (task.category != "Vaccination") {
          // Use the map from our new model object
          task.isDone = savedCompletions[task.name] ?? false;
        } else {
          task.isDone = _hasMatchingVaccinationRecord(task.name, _selectedBatch!.name);
        }
      }

      // Your filtering logic for vaccination tasks remains the same
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      generatedTasks = generatedTasks.where((task) {
        if (task.category == "Vaccination") {
          final BatchVaccinationEvent? scheduledEvent = Hive.box<BatchVaccinationEvent>('batch_vaccinations').values.firstWhereOrNull(
            (event) => event.batchId == _selectedBatch!.name && event.vaccinationName == task.name,
          );
          return scheduledEvent != null && !scheduledEvent.isCompleted && (scheduledEvent.scheduledDate.year == startOfToday.year && scheduledEvent.scheduledDate.month == startOfToday.month && scheduledEvent.scheduledDate.day == startOfToday.day || scheduledEvent.scheduledDate.isBefore(startOfToday));
        }
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _currentChecklist = generatedTasks;
          _calculateProgress();
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _currentChecklist = [];
          _progress = 0.0;
        });
      }
    }
  }

  void _calculateProgress() {
    if (_currentChecklist.isEmpty) {
      _progress = 0.0;
      return;
    }
    final completedCount = _currentChecklist.where((task) => task.isDone).length;
    _progress = completedCount / _currentChecklist.length;
  }

  bool _hasMatchingVaccinationRecord(String vaccineName, String batchName) {
    return _vaccinationRecordsBox.values.any(
      (record) => !record.isDeleted && record.batchName == batchName && record.vaccineName == vaccineName,
    );
  }

  void _toggleTaskCompletion(PoultryTask task) async {
    // Add the lock to prevent duplicate dialogs
    if (_isDialogShowing) return;

    try {
      _isDialogShowing = true; // Set the lock

      if (_selectedBatch == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a batch first.')));
        return; // Return from inside the try block
      }

      // --- Special handling for Vaccination tasks (Your logic remains unchanged) ---
      if (task.category == "Vaccination") {
        // ... (All your existing, complex vaccination logic from your file is preserved here)
        final batchScheduleService = ref.read(batchScheduleServiceProvider);
        final notificationService = ref.read(notificationServiceProvider);
        if (!task.isDone) {
          if (!_hasMatchingVaccinationRecord(task.name, _selectedBatch!.name)) {
            if (context.mounted) {
              final bool? shouldAddRecord = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  title: Text('Add Vaccination Record', textAlign: TextAlign.center, style: TextStyle(color: _primaryOrange, fontWeight: FontWeight.bold)),
                  content: Text('Before marking "${task.name}" as complete, please add its record to the vaccination history for Batch "${_selectedBatch!.name}".\n\nWould you like to add it now?', style: TextStyle(color: _darkGrey)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), style: TextButton.styleFrom(foregroundColor: _primaryOrange), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10)),
                      child: const Text('Add Record'),
                    ),
                  ],
                ),
              );
              if (shouldAddRecord == true) {
                if (context.mounted) {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return GenericFormDialog(
                        child: AddVaccinationRecordScreen(
                          batchId: _selectedBatch!.name,
                          prefillVaccinationName: task.name,
                          prefillMethod: Hive.box<BatchVaccinationEvent>('batch_vaccinations').values.firstWhere((e) => e.batchId == _selectedBatch!.name && e.vaccinationName == task.name, orElse: () => throw Exception('Event not found')).method,
                        ),
                      );
                    },
                  );
                  if (result == true) {
                    _generateChecklist();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record added. Task marked complete in schedule.')));
                    }
                  }
                }
              }
            }
            return;
          }
        }
        BatchVaccinationEvent? correspondingScheduledEvent;
        try {
          correspondingScheduledEvent = Hive.box<BatchVaccinationEvent>('batch_vaccinations').values.firstWhere((event) => event.batchId == _selectedBatch!.name && event.vaccinationName == task.name);
        } on StateError {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Scheduled vaccination event not found for this task.')));
          }
          return;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: ${e.toString()}')));
          }
          return;
        }
        if (correspondingScheduledEvent != null) {
          await batchScheduleService.markVaccinationAsCompleted(correspondingScheduledEvent.key, !task.isDone);
          await notificationService.rescheduleAllBatchNotifications();
          _generateChecklist();
        }
        return;
      }

      // --- General task handling ---
      bool initialIsDone = task.isDone;
      bool? recordAddedSuccessfully = true;

      if (!initialIsDone) {
        // Your existing logic for showing various dialogs based on task name remains unchanged
        if (task.name.toLowerCase().contains('replenish feed')) {
          recordAddedSuccessfully = await showDialog<bool>(context: context, builder: (dialogContext) => GenericFormDialog(child: AddFeedUsedScreen(initialBatchName: _selectedBatch!.name)));
        } else if (task.name.toLowerCase().contains('record house temperature and humidity')) {
          recordAddedSuccessfully = await showDialog<bool>(context: context, builder: (dialogContext) => GenericFormDialog(child: AddTemperatureHumidityScreen(initialBatchName: _selectedBatch!.name)));
        } else if (task.name.toLowerCase().contains('isolate')) {
          recordAddedSuccessfully = await showDialog<bool>(context: context, builder: (dialogContext) => GenericFormDialog(child: AddIsolationScreen(initialBatchName: _selectedBatch!.name)));
        } else if (task.name.toLowerCase().contains('daily mortality')) {
          recordAddedSuccessfully = await showDialog<bool>(context: context, builder: (dialogContext) => GenericFormDialog(child: AddMortalityScreen(initialBatchName: _selectedBatch!.name)));
        } else if (task.category.toLowerCase().contains('lighting')) {
          recordAddedSuccessfully = await showDialog<bool>(context: context, builder: (dialogContext) => GenericFormDialog(child: AddLightingScreen(initialBatchName: _selectedBatch!.name)));
        } else if (task.name.toLowerCase().contains('general observation')) {
          recordAddedSuccessfully = await showDialog<bool>(context: context, builder: (dialogContext) => GenericFormDialog(child: AddObservationScreen(initialBatchName: _selectedBatch!.name)));
        }
        if (recordAddedSuccessfully != true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task "${task.name}" not marked complete as no record was added.')));
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          task.isDone = !initialIsDone;
          _calculateProgress();
        });
      }

      // --- FIX: Save completion status to the new DailyChecklistRecord model ---
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);

      // Find if a record for today already exists
      DailyChecklistRecord? todaysRecord = _checklistRecordBox.values.firstWhereOrNull(
        (record) => record.batchKey == _selectedBatch!.key && record.date == todayDateOnly,
      );

      if (todaysRecord == null) {
        // If no record exists, create a new one.
        final newRecord = DailyChecklistRecord(
          batchKey: _selectedBatch!.key,
          date: todayDateOnly,
          taskCompletions: {task.name: !initialIsDone},
        );
        // Set sync properties for the new record
        newRecord.isSynced = false;
        newRecord.isDeleted = false;
        newRecord.createdAt = DateTime.now();
        await _checklistRecordBox.add(newRecord);
      } else {
        // If a record already exists, update its map and save.
        todaysRecord.taskCompletions[task.name] = !initialIsDone;
        todaysRecord.isSynced = false; // Mark for sync
        await todaysRecord.save();
      }

      if (context.mounted) {
        ref.read(dataSyncServiceProvider).triggerManualSync();
      }
    } finally {
      _isDialogShowing = false; // Release the lock
    }
  }

  IconData _getTaskIcon(String category) {
    switch (category.toLowerCase()) {
      case 'feed management': return Icons.grass;
      case 'environment': return Icons.thermostat;
      case 'health monitoring': return Icons.medical_services;
      case 'vaccination': return Icons.vaccines;
      case 'egg collection': return Icons.egg;
      case 'general observation': return Icons.remove_red_eye;
      case 'isolation management': return Icons.healing;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allActiveBatches = _batchBox.values.where((b) => !b.isDeleted).toList();

    if (_selectedBatch == null || _selectedBatch!.isDeleted || !allActiveBatches.contains(_selectedBatch)) {
      if (allActiveBatches.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { // Add mounted check
            setState(() {
              _selectedBatch = allActiveBatches.first;
              _generateChecklist();
            });
          }
        });
      } else {
        return Scaffold(
          appBar: AppBar(title: const Text('Daily Checklist', style: TextStyle(color: Colors.white)), backgroundColor: _primaryOrange, iconTheme: const IconThemeData(color: Colors.white)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: _lightOrange),
                const SizedBox(height: 20),
                Text('No active batches found!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkGrey)),
                const SizedBox(height: 10),
                Text('Please add a new batch to start your daily checklist.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/bird-batches'),
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 8),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add New Batch', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        );
      }
    }

    // --- The rest of your build method is preserved exactly as you provided it ---
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        title: Text('Daily Checklist for ${_selectedBatch?.name ?? 'No Batch'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), tooltip: 'Refresh Checklist', onPressed: _generateChecklist)],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _primaryOrange,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<BirdBatch>(
                  value: _selectedBatch,
                  decoration: InputDecoration(
                    labelText: 'Change Batch',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.group, color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: const BorderSide(color: Colors.white, width: 2.0)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: Colors.deepOrange.shade800,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: _batchBox.values.where((b) => !b.isDeleted).toSet().toList().map((batch) {
                    return DropdownMenuItem(value: batch, child: Text('${batch.name} (${batch.ageInDays} days, ${batch.type == BirdType.layers ? 'Layers' : 'Broilers'})', style: const TextStyle(color: Colors.white)));
                  }).toList(),
                  onChanged: (BirdBatch? newValue) {
                    if (mounted) {
                      setState(() {
                        _selectedBatch = newValue;
                        _generateChecklist();
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text('Age: ${_selectedBatch!.ageInDays} days | Type: ${_selectedBatch!.type == BirdType.layers ? 'Layers' : 'Broilers'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                Text('Stage: ${_selectedBatch!.stage}', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkGrey)),
                        Text('${(_progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryOrange)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: _progress, backgroundColor: _lightGrey, color: _primaryOrange, minHeight: 12, borderRadius: BorderRadius.circular(10)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _currentChecklist.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 80, color: _lightOrange),
                        const SizedBox(height: 20),
                        Text(_selectedBatch == null ? 'Select a batch to see the daily checklist.' : 'No tasks scheduled for this batch today.', textAlign: TextAlign.center, style: TextStyle(color: _darkGrey, fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    itemCount: _currentChecklist.length,
                    itemBuilder: (context, index) {
                      final task = _currentChecklist[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: task.isDone ? _lightOrange.withOpacity(0.2) : Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
                          border: Border.all(color: task.isDone ? Colors.deepOrange.shade300 : _lightGrey, width: 1.0),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            checkboxTheme: CheckboxThemeData(
                              fillColor: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return _primaryOrange;
                                }
                                return Colors.grey;
                              }),
                              checkColor: MaterialStateProperty.all(Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            title: Text(task.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, decoration: task.isDone ? TextDecoration.lineThrough : null, color: task.isDone ? Colors.grey.shade600 : _darkGrey)),
                            subtitle: Text(task.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            value: task.isDone,
                            onChanged: (bool? value) {
                              if (value != null) {
                                _toggleTaskCompletion(task);
                              }
                            },
                            secondary: Icon(_getTaskIcon(task.category), color: task.isDone ? Colors.grey.shade400 : _primaryOrange, size: 30),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedBatch != null && _currentChecklist.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Overall Progress: ${(_progress * 100).toStringAsFixed(0)}% Complete')));
              },
              label: Text('${(_progress * 100).toStringAsFixed(0)}% Complete', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              icon: const Icon(Icons.analytics_outlined, color: Colors.white),
              backgroundColor: _primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}