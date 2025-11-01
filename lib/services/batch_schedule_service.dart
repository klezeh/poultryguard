import 'package:hive/hive.dart';
import 'package:poultryguard/models/vaccination_event.dart';
import '../models/bird_batch.dart';
import '../models/batch_vaccination_event.dart';
import 'package:poultryguard/screens/vaccination_schedule.dart';

class BatchScheduleService {
  final Box<BatchVaccinationEvent> _batchVaccinationBox;

  BatchScheduleService() : _batchVaccinationBox = Hive.box<BatchVaccinationEvent>('batch_vaccinations');

  Future<void> generateScheduleForBatch(BirdBatch batch) async {
    final existingSchedule = _batchVaccinationBox.values.where((event) => event.batchId == batch.name);
    if (existingSchedule.isNotEmpty) {
      print('Schedule already exists for batch ${batch.name}. Skipping generation.');
      return;
    }

    final List<VaccinationEvent> staticSchedule;
    if (batch.type == BirdType.layers) {
      staticSchedule = LayerVaccinationSchedule.schedule;
    } else if (batch.type == BirdType.broilers) {
      staticSchedule = BroilerVaccinationSchedule.schedule;
    } else {
      return;
    }

    for (var event in staticSchedule) {
      final scheduledDate = batch.startDate.add(Duration(days: event.daysAfterBatchStart));
      final newEvent = BatchVaccinationEvent(
        batchId: batch.name,
        vaccinationName: event.name,
        scheduledDate: scheduledDate,
        method: event.method,
        isCompleted: false,
      );
      // Set sync properties for the new object
      newEvent.isSynced = false;
      newEvent.isDeleted = false;
      newEvent.createdAt = DateTime.now();
      await _batchVaccinationBox.add(newEvent);
    }
    print('Generated and saved vaccination schedule for batch: ${batch.name}');
  }

  List<BatchVaccinationEvent> getScheduleForBatch(String batchId) {
    return _batchVaccinationBox.values
        .where((event) => event.batchId == batchId && !event.isDeleted)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  // --- THIS IS THE CRITICAL FIX ---
  // We now correctly set isSynced = false to flag this change for the sync service.
  Future<void> markVaccinationAsCompleted(dynamic key, bool completed) async {
    final event = _batchVaccinationBox.get(key);
    if (event != null) {
      event.isCompleted = completed;
      event.isSynced = false; // <-- THE FIX
      await event.save();
      print('Marked ${event.vaccinationName} for batch ${event.batchId} as completed: $completed and flagged for sync.');
    }
  }
}