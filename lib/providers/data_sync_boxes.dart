import 'package:hive/hive.dart';
import 'package:poultryguard/models/bird_batch.dart';
import 'package:poultryguard/models/expense.dart';
import 'package:poultryguard/models/income.dart';
import 'package:poultryguard/models/vaccination_record.dart';
import 'package:poultryguard/models/batch_vaccination_event.dart';
import 'package:poultryguard/models/egg_collected.dart';
import 'package:poultryguard/models/egg_supplied.dart';
import 'package:poultryguard/models/isolation_record.dart';
import 'package:poultryguard/models/mortality_record.dart';
import 'package:poultryguard/models/environment_record.dart';
import 'package:poultryguard/models/feed_used.dart';
import 'package:poultryguard/models/lighting_record.dart';
import 'package:poultryguard/models/temperature_humidity_record.dart';
import 'package:poultryguard/models/observation_record.dart';
import 'package:poultryguard/models/release_log.dart';
import 'package:poultryguard/models/poultry_task.dart';
import 'package:poultryguard/services/data_sync_service.dart';

/// A container class to hold references to all opened Hive boxes.
/// This ensures boxes are opened only once in main.dart and their
/// instances are passed around safely.
class DataSyncBoxes {
  final Box<BirdBatch> batches;
  final Box<BatchVaccinationEvent> batchVaccinationEvents;
  final Box<MortalityRecord> mortality;
  final Box<Map<dynamic, dynamic>> dailyTaskCompletion;
  final Box<Expense> expenses;
  final Box<Income> income;
  final Box<EggCollected> eggCollected;
  final Box<EggSupplied> eggSupplied;
  final Box<IsolationRecord> isolation;
  final Box<EnvironmentRecord> environmentRecords;
  final Box<FeedUsed> feedUsed;
  final Box<LightingRecord> lightingRecords;
  final Box<TemperatureHumidityRecord> temperatureHumidityRecords;
  final Box<ObservationRecord> observationRecords;
  final Box<ReleaseLog> releaseLog;
  final Box<PoultryTask> poultryTasks;
  final Box<VaccinationRecord> vaccinationRecords;

  DataSyncBoxes({
    required this.batches,
    required this.batchVaccinationEvents,
    required this.mortality,
    required this.dailyTaskCompletion,
    required this.expenses,
    required this.income,
    required this.eggCollected,
    required this.eggSupplied,
    required this.isolation,
    required this.environmentRecords,
    required this.feedUsed,
    required this.lightingRecords,
    required this.temperatureHumidityRecords,
    required this.observationRecords,
    required this.releaseLog,
    required this.poultryTasks,
    required this.vaccinationRecords,
  });

  /// A helper method to get all syncable boxes in a list for easier looping.
  List<Box<FirestoreSyncable>> getAllSyncableBoxes() {
    // Cast each box to the correct supertype to create a type-safe list.
    return [
      batches, expenses, income, vaccinationRecords, batchVaccinationEvents,
      eggCollected, eggSupplied, isolation, mortality, environmentRecords, feedUsed,
      lightingRecords, temperatureHumidityRecords, observationRecords,
      releaseLog, poultryTasks
    ].cast<Box<FirestoreSyncable>>();
  }
}
