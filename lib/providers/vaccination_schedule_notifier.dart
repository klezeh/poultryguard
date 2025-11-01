// lib/providers/vaccination_schedule_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/screens/vaccination_schedule.dart';
import '../models/vaccination_event.dart';


/// A Notifier to manage the list of VaccinationEvent objects.
/// It holds the dynamic state of the vaccination checklist.
// Changed from StateNotifier to Notifier
class VaccinationScheduleNotifier extends Notifier<List<VaccinationEvent>> {
  // Removed super() constructor

  // The build method replaces the constructor for initial state
  @override
  List<VaccinationEvent> build() {
    return _initializeSchedule();
  }

  // Private static method to initialize the schedule
  static List<VaccinationEvent> _initializeSchedule() {
    // Create new instances of VaccinationEvent from the static schedule
    // ensuring each has its own mutable isCompleted flag, initially false.
    return LayerVaccinationSchedule.schedule.map((e) => VaccinationEvent(
      name: e.name,
      daysAfterBatchStart: e.daysAfterBatchStart,
      method: e.method,
      isCompleted: false, // Ensure initial state is not completed
    )).toList();
  }

  /// Toggles the completion status of a given VaccinationEvent.
  ///
  /// This method finds the event in the current state list and
  /// flips its `isCompleted` flag. It then creates a new list
  /// instance and updates the `state` property, which notifies
  /// Riverpod listeners to rebuild the UI.
  void toggleCompletion(VaccinationEvent eventToToggle) {
    // Find the index of the event to toggle based on its unique properties.
    // Using name and daysAfterBatchStart for identification as events
    // within the static schedule should have unique combinations of these.
    // Read state directly
    final index = state.indexWhere((event) =>
        event.name == eventToToggle.name &&
        event.daysAfterBatchStart == eventToToggle.daysAfterBatchStart);

    if (index != -1) {
      // Create a new list to ensure Riverpod detects a state change.
      // This is crucial for Riverpod to re-render widgets that watch this state.
      // Read state directly
      final updatedList = List<VaccinationEvent>.from(state);

      // Directly modify the isCompleted property of the existing object in the new list.
      // Although `isCompleted` is mutable, updating the list reference (`state = updatedList`)
      // is what triggers the UI update in Riverpod.
      updatedList[index].isCompleted = !updatedList[index].isCompleted;

      // Update the state with the new list instance.
      state = updatedList;
    }
  }
}
