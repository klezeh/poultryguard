// lib/screens/batch_list_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:poultryguard/models/income.dart'; 

import '../models/bird_batch.dart';
import 'new_batch_screen.dart';
import 'vaccination_screen.dart';
import 'add_mortality_screen.dart';
import 'add_isolation_screen.dart';
import 'remove_flock_screen.dart'; // Correct import for RemoveFlockScreen
import 'daily_checklist_screen.dart'; // Import the DailyChecklistScreen
import 'release_from_isolation_screen.dart'; // NEW: Import ReleaseFromIsolationScreen

class BatchListScreen extends StatelessWidget {
  const BatchListScreen({super.key});

  // --- NEW: Method to show batch selection dialog ---
  void _showBatchSelectionDialog(BuildContext context) {
    final batches = Hive.box<BirdBatch>('batches').values.toList(); // Access the box directly

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Select a Batch for Checklist', // More descriptive title
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // Adjust height as needed
            child: batches.isEmpty
                ? Center(
                    child: Text(
                      'No batches available.\nPlease create one first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  )
                : ListView.builder(
                    itemCount: batches.length,
                    itemBuilder: (context, index) {
                      final batch = batches[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: Colors.deepOrange.shade100, width: 0.8),
                        ),
                        child: ListTile(
                          title: Text(
                            batch.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          subtitle: Text(
                            'Qty: ${batch.quantity} • Started: ${batch.startDate.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.deepOrange),
                          onTap: () {
                            Navigator.pop(dialogContext); // Close the selection dialog
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DailyChecklistScreen(initialBatch: batch), // Pass the selected batch
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Dismiss the dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }
  // --- END NEW METHOD ---

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<BirdBatch>('batches');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bird Batches',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.vaccines, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const VaccinationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.checklist, color: Colors.white),
            onPressed: () {
              // --- FIX: Call the new selection dialog instead of direct navigation ---
              _showBatchSelectionDialog(context);
            },
          ),
          // NEW: Button to navigate to ReleaseFromIsolationScreen
          IconButton(
            icon: const Icon(Icons.lock_open, color: Colors.white), // Choose an appropriate icon
            tooltip: 'Release from Isolation',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ReleaseFromIsolationScreen()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<BirdBatch> box, _) {
          // Filter out batches marked as deleted
          final List<BirdBatch> activeBatches = box.values.where((b) => !b.isDeleted).toList();

          if (activeBatches.isEmpty) {
            return const Center(child: Text('No active batches added yet.'));
          }
          return ListView.builder(
            itemCount: activeBatches.length,
            itemBuilder: (context, index) {
              final batch = activeBatches[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                elevation: 2.0,
                child: ListTile(
                  title: Text(
                    batch.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${batch.quantity} birds • ${batch.stage} (${batch.ageInDays} days)',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.deepOrange),
                  onTap: () {
                    // This navigation is already correct, as 'batch' is in scope here.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DailyChecklistScreen(initialBatch: batch),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.more_vert,
        activeIcon: Icons.close,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.group_add_rounded, color: Colors.white),
            backgroundColor: Colors.deepOrange.shade700,
            label: 'New Batch',
            labelStyle: const TextStyle(color: Colors.black),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NewBatchScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.remove_circle_outline, color: Colors.white),
            backgroundColor: Colors.deepOrange.shade500,
            label: 'Remove Flock',
            labelStyle: const TextStyle(color: Colors.black),
            onTap: () {
              // FIX: Removed the 'incomeBox' parameter from the constructor call
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RemoveFlockScreen(), // Corrected call
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.local_hospital, color: Colors.white),
            backgroundColor: Colors.deepOrange.shade600,
            label: 'Record Mortality',
            labelStyle: const TextStyle(color: Colors.black),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AddMortalityScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.sick, color: Colors.white),
            backgroundColor: Colors.deepOrange.shade400,
            label: 'Record Isolation',
            labelStyle: const TextStyle(color: Colors.black),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AddIsolationScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
