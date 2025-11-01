import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:poultryguard/models/egg_collected.dart';
import 'package:poultryguard/providers/provider.dart';
import 'package:poultryguard/services/data_sync_service.dart';
import 'package:poultryguard/utils/csv_exporter.dart';
import 'add_egg_collected_screen.dart';

// CHANGE: Converted to ConsumerStatefulWidget
class EggCollectionListScreen extends ConsumerStatefulWidget {
  const EggCollectionListScreen({super.key});

  @override
  ConsumerState<EggCollectionListScreen> createState() =>
      _EggCollectionListScreenState();
}

class _EggCollectionListScreenState extends ConsumerState<EggCollectionListScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _filterBox = Hive.box('filters');
  final Color primaryColor = Colors.deepOrange;

  @override
  void initState() {
    super.initState();
    _loadFilterDates();
  }

  void _loadFilterDates() {
    final saved = _filterBox.get('egg_collected_date_filter') as Map?;
    final now = DateTime.now();
    setState(() {
      _startDate = saved?['start'] != null
          ? DateTime.parse(saved!['start'])
          : DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      _endDate = saved?['end'] != null
          ? DateTime.parse(saved!['end'])
          : DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  void _saveFilterDates() {
    _filterBox.put('egg_collected_date_filter', {
      'start': _startDate!.toIso8601String(),
      'end': _endDate!.toIso8601String()
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _saveFilterDates();
    }
  }

  Future<void> _exportToCsv() async {
    final box = Hive.box<EggCollected>('egg_collected');
    final data = box.values
        .where((egg) =>
            !egg.isDeleted &&
            egg.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            egg.date.isBefore(_endDate!.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No records to export for selected range.')),
      );
      return;
    }

    try {
      final path = await CsvExporter.exportEggCollectedToCsv(data);
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
    } catch (e) {
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eggBox = Hive.box<EggCollected>('egg_collected');

    return Scaffold(
      appBar: AppBar(
        title: const Text('🥚 Collected Eggs', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDateRange),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportToCsv),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEggCollectedScreen()));
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: eggBox.listenable(),
        builder: (context, Box<EggCollected> box, _) {
          final entries = box.values
              .where((egg) =>
                  !egg.isDeleted && // Important: Filter out deleted items
                  egg.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                  egg.date.isBefore(_endDate!.add(const Duration(days: 1))))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (entries.isEmpty) {
            return const Center(child: Text('No egg collection records for the selected date range.'));
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final egg = entries[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: ListTile(
                  title: Text("${egg.count} eggs", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat.yMMMd().format(egg.date)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEggCollectedScreen(existing: egg, eggKey: egg.key),
                            ),
                          );
                        },
                      ),
                      // --- THIS IS THE FIX ---
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete this record of ${egg.count} eggs?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            // Use the correct method to flag for sync
                            await egg.markAsDeleted();
                            
                            if(context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record marked for deletion.')));
                                // Trigger sync
                                ref.read(dataSyncServiceProvider).triggerManualSync();
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}