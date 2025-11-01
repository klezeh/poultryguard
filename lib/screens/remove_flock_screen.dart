// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart'; // For animations - you'll need to add this package
import 'package:poultryguard/providers/provider.dart';

import '../models/bird_batch.dart';
import '../models/income.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

import 'package:poultryguard/services/data_sync_service.dart'; // Import DataSyncService (where provider is defined)

// Now a ConsumerStatefulWidget, and the 'incomeBox' parameter is removed.
class RemoveFlockScreen extends ConsumerStatefulWidget {
  const RemoveFlockScreen({super.key});

  @override
  ConsumerState<RemoveFlockScreen> createState() => _RemoveFlockScreenState();
}

class _RemoveFlockScreenState extends ConsumerState<RemoveFlockScreen> {
  final Box<BirdBatch> _batchBox = Hive.box<BirdBatch>('batches');
  final Box<Income> _incomeBox = Hive.box<Income>('income'); // Accessed directly via Hive.box

  final List<BirdBatch> _selectedBatches = [];

  String _selectedAction = "Selling";

  final TextEditingController _costPerChickController = TextEditingController();
  final TextEditingController _newFlockNameController = TextEditingController();

  final Map<dynamic, TextEditingController> _batchRemovalControllers = {};

  final Map<String, String> _dropdownActions = {
    "Selling": "Sell Birds",
    "Moving to New Coop": "Add to New Flock",
  };

  // State to control the visibility of the confirmation animation
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    // Pre-initialize controllers for existing batches (if any)
    _batchBox.values.forEach((batch) {
      if (!_batchRemovalControllers.containsKey(batch.key)) {
        _batchRemovalControllers[batch.key] = TextEditingController();
      }
    });
  }

  /// Custom Dialog for selecting Flock Age with better UI/UX
  Future<DateTime?> _selectFlockAgeFromOptions(List<DateTime> options) async {
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text(
            'Select Flock Age',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: options.map((date) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.deepOrange),
                    title: Text(
                      date.toLocal().toString().split(" ")[0],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(date);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  /// The NEW "Unimaginable" Confirmation Dialog
  Future<bool> _showUnimaginableConfirmationDialog(int totalBirdsToRemove) async {
    setState(() {
      _isConfirming = true; // Show animation when dialog is active
    });
    bool? confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true, // Allow tapping outside to dismiss
      barrierLabel: 'Confirm Removal',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, a1, a2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lottie animation for visual impact
                  Lottie.asset(
                    'assets/lottie/bird_flying.json', // You'll need to add this Lottie animation file
                    height: 150,
                    repeat: false,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Are you sure you want to remove $totalBirdsToRemove birds?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This action cannot be undone for these birds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  // Swipe-to-confirm widget
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true), // Direct confirm
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange, // Background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Confirm Removal',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    setState(() {
      _isConfirming = false; // Hide animation after dialog closes
    });
    return confirmed ?? false;
  }

  Future<void> _processFlockRemoval() async {
    int totalBirdsRemoved = 0;
    // Validate input for each selected batch.
    for (var batch in _selectedBatches.toSet()) {
      final controller = _batchRemovalControllers[batch.key];
      if (controller == null || controller.text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Enter the number of birds to remove for batch ${batch.name}.',
              ),
            ),
          );
        }
        return;
      }
      int removalCount = int.tryParse(controller.text.trim()) ?? 0;
      if (removalCount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid removal count for batch ${batch.name}.'),
            ),
          );
        }
        return;
      }
      if (removalCount > batch.quantity) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Batch ${batch.name} does not have enough birds (max ${batch.quantity}).'),
            ),
          );
        }
        return;
      }
      totalBirdsRemoved += removalCount;
    }

    // New: Show unimaginable confirmation dialog
    bool confirmed = await _showUnimaginableConfirmationDialog(totalBirdsRemoved);
    if (!confirmed) {
      return; // User cancelled the removal
    }

    // Access DataSyncService via Riverpod
    final dataSyncService = ref.read(dataSyncServiceProvider); // Access ref here

    // Proceed with actual removal only if confirmed
    for (var batch in _selectedBatches.toSet()) {
      final controller = _batchRemovalControllers[batch.key]; // Controller already validated above
      int removalCount = int.tryParse(controller!.text.trim()) ?? 0; // Safe to use !
      
      // Get the live batch object from Hive to modify it
      final BirdBatch? liveBatch = _batchBox.get(batch.key);

      if (liveBatch == null) {
        print('Error: Live batch object not found in Hive for key ${batch.key}. Skipping update.');
        continue; // Skip this batch if not found
      }

      int newQuantity = liveBatch.quantity - removalCount;

      if (newQuantity <= 0) { // If all birds or more are removed, mark the entire batch as deleted
        liveBatch.isDeleted = true;
        liveBatch.quantity = 0; // Set quantity to 0
        print('Batch ${liveBatch.name} marked for full deletion and quantity set to 0.');
      } else {
        liveBatch.quantity = newQuantity;
        print('Batch ${liveBatch.name} quantity updated to ${liveBatch.quantity}.');
      }

      liveBatch.isSynced = false; // Mark the batch as unsynced
      await liveBatch.save(); // Save the updated batch to Hive

      // If the batch's quantity becomes 0 and it's marked as deleted,
      // the DataSyncService will pick it up and delete it from Firestore.
    }

    // Process based on the selected action.
    if (_selectedAction == "Selling") {
      double costPerChick =
          double.tryParse(_costPerChickController.text.trim()) ?? 0;
      if (_costPerChickController.text.trim().isEmpty || costPerChick <= 0) {
        if (mounted) { // Added mounted check
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid sale price per bird.')),
          );
        }
        return;
      }
      double totalIncome = totalBirdsRemoved * costPerChick;
      debugPrint('Cost per bird: $costPerChick');
      debugPrint('Total income to be recorded: $totalIncome');
      Income newIncome = Income(
        source: "flock sales",
        amount: totalIncome,
        date: DateTime.now(),
        note: "Sold $totalBirdsRemoved birds",
        isSynced: false, // Mark new income for sync
        createdAt: DateTime.now(),
      );
      await _incomeBox.add(newIncome);
    } else if (_selectedAction == "Moving to New Coop") {
      if (_newFlockNameController.text.trim().isEmpty) {
        if (mounted) { // Added mounted check
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a name for the new flock.')),
          );
        }
        return;
      }
      final uniqueAges =
          _selectedBatches.map((b) => b.startDate).toSet().toList();
      DateTime? selectedAge = await _selectFlockAgeFromOptions(uniqueAges);
      if (selectedAge == null) return;
      BirdBatch newFlock = BirdBatch(
        name: _newFlockNameController.text.trim(),
        startDate: selectedAge,
        quantity: totalBirdsRemoved,
        type: _selectedBatches.first.type, // Assuming consistent type for moved birds
        isSynced: false, // Mark new batch for sync
        createdAt: DateTime.now(),
      );
      await _batchBox.add(newFlock);
    }

    // Trigger data sync after all local modifications are made
    dataSyncService.triggerManualSync();

    if (mounted) { // Added mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully processed removal of $totalBirdsRemoved birds!'),
          backgroundColor: Colors.green, // Success feedback
        ),
      );
    }

    if (mounted) { // Added mounted check
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (var controller in _batchRemovalControllers.values) {
      controller.dispose();
    }
    _costPerChickController.dispose();
    _newFlockNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Flock', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange, // Consistent theme
        iconTheme: const IconThemeData(color: Colors.white), // Back arrow color
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Batches to Process:',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _batchBox.listenable(),
                    builder: (context, Box<BirdBatch> box, _) {
                      // Only show batches that are NOT deleted
                      List<BirdBatch> batches = box.values.where((b) => !b.isDeleted).toList().cast<BirdBatch>();
                      if (batches.isEmpty) {
                        return const Center(
                          child: Text(
                            'No active batches to remove.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: batches.length,
                        itemBuilder: (context, index) {
                          final batch = batches[index];
                          final bool isSelected = _selectedBatches.contains(batch);
                          // Ensure a controller exists for this batch's key
                          _batchRemovalControllers.putIfAbsent(batch.key, () => TextEditingController());

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.deepOrange.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(15.0),
                              border: Border.all(
                                color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
                                  blurRadius: isSelected ? 10 : 5,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedBatches.remove(batch);
                                    _batchRemovalControllers[batch.key]?.clear(); // Clear input when deselected
                                  } else {
                                    _selectedBatches.add(batch);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(15.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                          color: isSelected ? Colors.deepOrange : Colors.grey,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${batch.name} (${batch.quantity} birds)',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.deepOrange : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Age: ${DateTime.now().difference(batch.startDate).inDays} days',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) {
                                        return SizeTransition(
                                          sizeFactor: animation,
                                          axisAlignment: -1.0,
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: isSelected
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 12.0),
                                              child: TextFormField(
                                                controller: _batchRemovalControllers[batch.key],
                                                keyboardType: TextInputType.number,
                                                style: const TextStyle(fontSize: 16),
                                                decoration: InputDecoration(
                                                  labelText: 'Number to remove',
                                                  hintText: 'e.g., ${batch.quantity}',
                                                  prefixIcon: const Icon(Icons.numbers, color: Colors.deepOrange),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: const BorderSide(color: Colors.deepOrange),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: BorderSide(color: Colors.deepOrange.shade200),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(), // No input field when not selected
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Action Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedAction,
                  decoration: InputDecoration(
                    labelText: 'Choose Action for Removed Birds',
                    labelStyle: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                    prefixIcon: const Icon(Icons.swap_horiz, color: Colors.deepOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15), // More rounded corners
                      borderSide: BorderSide(color: Colors.deepOrange.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.deepOrange.shade50, // Light orange fill
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  dropdownColor: Colors.white, // Dropdown menu background
                  iconEnabledColor: Colors.deepOrange, // Dropdown arrow color
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  items: _dropdownActions.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (action) => setState(() => _selectedAction = action!),
                ),
                const SizedBox(height: 16),

                // Conditional Input Fields with enhanced styling
                if (_selectedAction == "Selling")
                  TextFormField(
                    controller: _costPerChickController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Sale Price per Bird',
                      hintText: 'e.g., 5.00',
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.deepOrange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.deepOrange.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  )
                else if (_selectedAction == "Moving to New Coop")
                  TextFormField(
                    controller: _newFlockNameController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Name for New Flock',
                      hintText: 'e.g., New Layers Batch',
                      prefixIcon: const Icon(Icons.group_add, color: Colors.deepOrange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.deepOrange.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                const SizedBox(height: 30),

                // Confirm Button
                Center(
                  child: AnimatedOpacity(
                    opacity: _selectedBatches.isNotEmpty ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton.icon(
                      onPressed: _selectedBatches.isNotEmpty ? _processFlockRemoval : null,
                      icon: const Icon(Icons.remove_circle, color: Colors.white),
                      label: const Text(
                        'Process Flock Removal',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, // Red for 'remove' action
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        elevation: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Overlay for the confirmation animation
          if (_isConfirming)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/loading_animation.json', // Another Lottie for loading
                  height: 100,
                  width: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
