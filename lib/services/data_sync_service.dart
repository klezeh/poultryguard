import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

// Import your user session provider
import 'package:poultryguard/providers/user_session_provider.dart';

// Import all necessary models
import 'package:poultryguard/models/expense.dart';
import 'package:poultryguard/models/income.dart';
import 'package:poultryguard/models/bird_batch.dart';
import 'package:poultryguard/models/batch_vaccination_event.dart';
import 'package:poultryguard/models/vaccination_record.dart';
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
import 'package:poultryguard/models/daily_checklist_record.dart';
import 'package:poultryguard/models/notification.dart';
import 'package:poultryguard/providers/notification_provider.dart';

// --- NEW IMPORT ---
// Import the main provider file to get access to lastSyncTimeProvider
import 'package:poultryguard/providers/provider.dart';


mixin FirestoreSyncable on HiveObject {
  @HiveField(100)
  String? firestoreDocId;

  @HiveField(101)
  DateTime? createdAt;

  @HiveField(102)
  late bool isSynced;

  @HiveField(103)
  late bool isDeleted;

  Map<String, dynamic> toMap();

  Future<void> markAsDeleted() {
    isDeleted = true;
    isSynced = false;
    return save();
  }
}

enum DataType {
  batches,
  expenses,
  incomes,
  vaccinationRecords,
  batchVaccinationEvents,
  eggCollected,
  eggSupplied,
  isolation,
  mortality,
  environmentRecords,
  feedUsed,
  lightingRecords,
  temperatureHumidityRecords,
  observationRecords,
  releaseLog,
  poultryTasks,
  dailyChecklists,
}

final dataSyncServiceProvider = Provider.autoDispose<DataSyncService>((ref) {
  final service = DataSyncService(
    ref,
    Hive.box<BirdBatch>('batches'),
    Hive.box<BatchVaccinationEvent>('batch_vaccinations'),
    Hive.box<MortalityRecord>('mortality'),
    Hive.box<Expense>('expenses'),
    Hive.box<Income>('income'),
    Hive.box<EggCollected>('egg_collected'),
    Hive.box<EggSupplied>('egg_supplied'),
    Hive.box<IsolationRecord>('isolation'),
    Hive.box<EnvironmentRecord>('environment_records'),
    Hive.box<FeedUsed>('feed_used'),
    Hive.box<LightingRecord>('lighting_records'),
    Hive.box<TemperatureHumidityRecord>('temperature_humidity_records'),
    Hive.box<ObservationRecord>('observation_records'),
    Hive.box<ReleaseLog>('release_log'),
    Hive.box<PoultryTask>('poultryTasks'),
    Hive.box<VaccinationRecord>('vaccination_records'),
    Hive.box<DailyChecklistRecord>('daily_checklists'),
  );

  service.startListeners();
  ref.onDispose(() => service.dispose());

  return service;
});

class DataSyncService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = false;
  bool _isSyncing = false;
  Timer? _syncTimer;

  final Box<BirdBatch> _batchBox;
  final Box<BatchVaccinationEvent> _batchVaccinationEventBox;
  final Box<MortalityRecord> _mortalityBox;
  final Box<Expense> _expensesBox;
  final Box<Income> _incomesBox;
  final Box<EggCollected> _eggCollectedBox;
  final Box<EggSupplied> _eggSuppliedBox;
  final Box<IsolationRecord> _isolationBox;
  final Box<EnvironmentRecord> _environmentRecordsBox;
  final Box<FeedUsed> _feedUsedBox;
  final Box<LightingRecord> _lightingRecordsBox;
  final Box<TemperatureHumidityRecord> _temperatureHumidityRecordsBox;
  final Box<ObservationRecord> _observationRecordsBox;
  final Box<ReleaseLog> _releaseLogBox;
  final Box<PoultryTask> _poultryTasksBox;
  final Box<VaccinationRecord> _vaccinationRecordsBox;
  final Box<DailyChecklistRecord> _dailyChecklistsBox;

  final Map<DataType, String> _boxToCollectionMap = {
    DataType.batches: 'batches',
    DataType.expenses: 'expenses',
    DataType.incomes: 'incomes',
    DataType.vaccinationRecords: 'vaccination_records',
    DataType.batchVaccinationEvents: 'batch_vaccination_events',
    DataType.eggCollected: 'egg_collected',
    DataType.eggSupplied: 'egg_supplied',
    DataType.isolation: 'isolation',
    DataType.mortality: 'mortality',
    DataType.environmentRecords: 'environment_records',
    DataType.feedUsed: 'feed_used',
    DataType.lightingRecords: 'lighting_records',
    DataType.temperatureHumidityRecords: 'temperature_humidity_records',
    DataType.observationRecords: 'observation_records',
    DataType.releaseLog: 'release_log',
    DataType.poultryTasks: 'poultryTasks',
    DataType.dailyChecklists: 'daily_checklists',
  };

  final Map<DataType, Function> _fromMapFactories = {
    DataType.batches: BirdBatch.fromMap,
    DataType.expenses: Expense.fromMap,
    DataType.incomes: Income.fromMap,
    DataType.vaccinationRecords: VaccinationRecord.fromMap,
    DataType.batchVaccinationEvents: BatchVaccinationEvent.fromMap,
    DataType.eggCollected: EggCollected.fromMap,
    DataType.eggSupplied: EggSupplied.fromMap,
    DataType.isolation: IsolationRecord.fromMap,
    DataType.mortality: MortalityRecord.fromMap,
    DataType.environmentRecords: EnvironmentRecord.fromMap,
    DataType.feedUsed: FeedUsed.fromMap,
    DataType.lightingRecords: LightingRecord.fromMap,
    DataType.temperatureHumidityRecords: TemperatureHumidityRecord.fromMap,
    DataType.observationRecords: ObservationRecord.fromMap,
    DataType.releaseLog: ReleaseLog.fromMap,
    DataType.poultryTasks: PoultryTask.fromMap,
    DataType.dailyChecklists: DailyChecklistRecord.fromMap,
  };

  DataSyncService(
      this._ref,
      this._batchBox,
      this._batchVaccinationEventBox,
      this._mortalityBox,
      this._expensesBox,
      this._incomesBox,
      this._eggCollectedBox,
      this._eggSuppliedBox,
      this._isolationBox,
      this._environmentRecordsBox,
      this._feedUsedBox,
      this._lightingRecordsBox,
      this._temperatureHumidityRecordsBox,
      this._observationRecordsBox,
      this._releaseLogBox,
      this._poultryTasksBox,
      this._vaccinationRecordsBox,
      this._dailyChecklistsBox,
  );

  Future<void> startListeners() async {
    print('DataSyncService: Starting listeners.');
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi);

      await _connectivitySubscription?.cancel();
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        final newOnlineStatus = results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.wifi);
        if (newOnlineStatus != _isOnline) {
          _isOnline = newOnlineStatus;
          if (_isOnline) {
            print('Network back online. Triggering sync...');
            triggerManualSync();
          }
        }
      });

      _startSyncTimer();
      await triggerManualSync();
    } catch (e) {
      print('Error initializing DataSyncService listeners: $e');
    }
  }

  void dispose() {
    print('DataSyncService: Disposing. Stopping all operations.');
    _stopSyncTimer();
    _connectivitySubscription?.cancel();
  }

  void _startSyncTimer() {
    _stopSyncTimer();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      print('Automatic sync triggered by timer.');
      triggerManualSync();
    });
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> triggerManualSync() async {
    final session = _ref.read(userSessionProvider);
    final farmId = session.farmId;

    if (!_isOnline || !session.isAuthenticated || farmId == null || farmId.isEmpty) {
      print("Manual sync blocked:");
      print("- isOnline: $_isOnline");
      print("- isAuthenticated: ${session.isAuthenticated}");
      print("- farmId: $farmId");
      return;
    }

    await _syncData(farmId);
  }

  String _getCollectionPath(String collectionName, String farmId) {
    return 'farms/$farmId/$collectionName';
  }

  Future<void> _syncData(String farmId) async {
    if (_isSyncing) {
      print('Sync already in progress. Skipping sync attempt.');
      return;
    }

    _isSyncing = true;
    print('Starting data sync for farm: $farmId');

    try {
      await _pushLocalChanges(farmId);
      await _pullAndMergeRemoteChanges(farmId);
      print('Data sync complete.');
      
      // --- UPDATE LAST SYNC TIME ---
      _ref.read(lastSyncTimeProvider.notifier).setTime(DateTime.now());
      // --- END UPDATE ---

      _checkForAlerts();
    } catch (e) {
      print('Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void _checkForAlerts() {
    print("DataSyncService: Checking for new alerts...");
    final notificationNotifier = _ref.read(notificationProvider.notifier);
    final existingNotifications = _ref.read(notificationProvider);

    _checkMissedVaccinations(notificationNotifier, existingNotifications);
    _checkHighMortality(notificationNotifier, existingNotifications);
  }

  void _checkMissedVaccinations(NotificationNotifier notifier, List<AppNotification> existing) {
    final missedEvents = _batchVaccinationEventBox.values.where((event) {
      final parentBatch = _batchBox.values.firstWhereOrNull((b) => b.name == event.batchId);
      return parentBatch != null && !parentBatch.isDeleted && !event.isCompleted && event.scheduledDate.isBefore(DateTime.now());
    });

    for (final event in missedEvents) {
      final notificationId = "vaccine-${event.key}";
      final alreadyExists = existing.any((n) => n.routeArguments?['id'] == notificationId);
      if (!alreadyExists) {
        notifier.add(
          AppNotification(
            title: "Vaccination Overdue",
            body: "Batch '${event.batchId}' is overdue for its ${event.vaccinationName} vaccine.",
            type: NotificationType.vaccination,
            timestamp: DateTime.now(),
            navigationRoute: '/vaccination',
            routeArguments: {'id': notificationId},
          ),
        );
      }
    }
  }

  void _checkHighMortality(NotificationNotifier notifier, List<AppNotification> existing) {
    final today = DateTime.now();
    const int highMortalityThreshold = 5;

    final todaysRecords = _mortalityBox.values.where((rec) => rec.date.year == today.year && rec.date.month == today.month && rec.date.day == today.day);

    if (todaysRecords.isEmpty) return;

    final deathsByBatch = <String, int>{};
    for (final record in todaysRecords) {
      deathsByBatch.update(record.batchName, (value) => value + record.numberOfBirds, ifAbsent: () => record.numberOfBirds);
    }

    deathsByBatch.forEach((batchName, totalDeaths) {
      if (totalDeaths > highMortalityThreshold) {
        final notificationId = "mortality-$batchName-${DateFormat('yyyy-MM-dd').format(today)}";
        final alreadyExists = existing.any((n) => n.routeArguments?['id'] == notificationId);
        if (!alreadyExists) {
          notifier.add(
            AppNotification(
              title: "High Mortality Alert",
              body: "Batch '$batchName' has $totalDeaths deaths recorded today. Please investigate.",
              type: NotificationType.general,
              timestamp: DateTime.now(),
              navigationRoute: '/mortality_report',
              routeArguments: {'id': notificationId},
            ),
          );
        }
      }
    });
  }

  Box _getTypedBoxByDataType(DataType dataType) {
    switch (dataType) {
      case DataType.batches: return _batchBox;
      case DataType.batchVaccinationEvents: return _batchVaccinationEventBox;
      case DataType.mortality: return _mortalityBox;
      case DataType.expenses: return _expensesBox;
      case DataType.incomes: return _incomesBox;
      case DataType.eggCollected: return _eggCollectedBox;
      case DataType.eggSupplied: return _eggSuppliedBox;
      case DataType.isolation: return _isolationBox;
      case DataType.environmentRecords: return _environmentRecordsBox;
      case DataType.feedUsed: return _feedUsedBox;
      case DataType.lightingRecords: return _lightingRecordsBox;
      case DataType.temperatureHumidityRecords: return _temperatureHumidityRecordsBox;
      case DataType.observationRecords: return _observationRecordsBox;
      case DataType.releaseLog: return _releaseLogBox;
      case DataType.poultryTasks: return _poultryTasksBox;
      case DataType.vaccinationRecords: return _vaccinationRecordsBox;
      case DataType.dailyChecklists: return _dailyChecklistsBox;
    }
  }

  Future<void> _pushLocalChanges(String farmId) async {
    print('Pushing local unsynced data...');
    final WriteBatch batch = _firestore.batch();
    bool hasWritesInBatch = false;
    final List<MapEntry<dynamic, FirestoreSyncable>> itemsToDeleteLocally = [];
    final List<MapEntry<dynamic, FirestoreSyncable>> itemsToMarkSyncedLocally = [];

    for (var entry in _boxToCollectionMap.entries) {
      final DataType dataType = entry.key;
      final String collectionNameInFirestore = entry.value;
      final Box currentBox = _getTypedBoxByDataType(dataType);
      final CollectionReference collectionRef = _firestore.collection(_getCollectionPath(collectionNameInFirestore, farmId));

      for (var key in currentBox.keys.toList()) {
        dynamic hiveObject = currentBox.get(key);
        if (hiveObject is! FirestoreSyncable) continue;
        if (hiveObject.isDeleted) {
          if (hiveObject.firestoreDocId != null) {
            batch.delete(collectionRef.doc(hiveObject.firestoreDocId!));
            itemsToDeleteLocally.add(MapEntry(key, hiveObject));
            hasWritesInBatch = true;
          } else {
            await hiveObject.delete();
          }
        } else if (!hiveObject.isSynced) {
          final Map<String, dynamic> data = hiveObject.toMap();
          String docIdToUse;
          if (hiveObject.firestoreDocId == null) {
            docIdToUse = collectionRef.doc().id;
            hiveObject.firestoreDocId = docIdToUse;
            await hiveObject.save();
          } else {
            docIdToUse = hiveObject.firestoreDocId!;
          }
          batch.set(collectionRef.doc(docIdToUse), data, SetOptions(merge: true));
          itemsToMarkSyncedLocally.add(MapEntry(key, hiveObject));
          hasWritesInBatch = true;
        }
      }
    }

    if (hasWritesInBatch) {
      await batch.commit();
      for (var entry in itemsToDeleteLocally) {
        try {
          if (entry.value.isInBox) await entry.value.delete();
        } catch (e) {
          print('Error deleting item from Hive after Firestore sync (key: ${entry.key}): $e');
        }
      }
      for (var entry in itemsToMarkSyncedLocally) {
        try {
          if (entry.value.isInBox) {
            entry.value.isSynced = true;
            await entry.value.save();
          }
        } catch (e) {
          print('Error marking item synced in Hive after Firestore commit (key: ${entry.key}): $e');
        }
      }
    }
  }

  Future<void> _pullAndMergeRemoteChanges(String farmId) async {
    print('Pulling and merging data from Firestore...');
    for (var entry in _boxToCollectionMap.entries) {
      final DataType dataType = entry.key;
      final String collectionNameInFirestore = entry.value;
      try {
        final Box box = _getTypedBoxByDataType(dataType);
        final CollectionReference collectionRef = _firestore.collection(_getCollectionPath(collectionNameInFirestore, farmId));

        final querySnapshot = await collectionRef.get();
        final Set<String> firestoreDocIds = querySnapshot.docs.map((doc) => doc.id).toSet();

        final List<dynamic> localKeysToRemove = [];
        for (var key in box.keys) {
          final item = box.get(key);
          if (item is FirestoreSyncable) {
            final docId = item.firestoreDocId ?? item.key.toString();
            if (item.firestoreDocId != null && !firestoreDocIds.contains(docId) && !item.isDeleted) {
              localKeysToRemove.add(key);
            }
          }
        }
        for (var key in localKeysToRemove) {
          await box.delete(key);
        }

        for (var doc in querySnapshot.docs) {
          final firestoreDocId = doc.id;
          final data = doc.data() as Map<String, dynamic>;
          try {
            final firestoreItem = _fromMapFactories[dataType]?.call(data, firestoreDocId);
            if (firestoreItem == null) continue;

            final firestoreSyncable = firestoreItem as FirestoreSyncable;
            if (firestoreSyncable.isDeleted) {
              final localItemToDelete = box.values.firstWhereOrNull((item) => item is FirestoreSyncable && item.firestoreDocId == firestoreDocId);
              if (localItemToDelete != null) {
                await localItemToDelete.delete();
              }
              continue;
            }
            FirestoreSyncable? existingHiveItem;
            dynamic existingHiveKey;
            for (var k in box.keys) {
              final item = box.get(k);
              if (item is FirestoreSyncable && item.firestoreDocId == firestoreDocId) {
                existingHiveItem = item;
                existingHiveKey = k;
                break;
              }
            }
            if (existingHiveItem == null) {
              firestoreSyncable.isSynced = true;
              firestoreSyncable.firestoreDocId = firestoreDocId;
              firestoreSyncable.isDeleted = false;
              await box.put(firestoreDocId, firestoreItem);
            } else {
              final existingHiveSyncable = existingHiveItem;
              final dataMap = data;
              final dynamic createdAtValue = dataMap['createdAt'];
              DateTime? firestoreTimestamp;
              if (createdAtValue is Timestamp) {
                firestoreTimestamp = createdAtValue.toDate();
              } else if (createdAtValue is DateTime) {
                firestoreTimestamp = createdAtValue;
              }
              DateTime? localTimestamp = existingHiveSyncable.createdAt;
              if ((firestoreTimestamp != null && (localTimestamp == null || firestoreTimestamp.isAfter(localTimestamp))) || !existingHiveSyncable.isSynced) {
                firestoreSyncable.isSynced = true;
                firestoreSyncable.firestoreDocId = firestoreDocId;
                firestoreSyncable.isDeleted = false;
                await box.put(existingHiveKey, firestoreItem);
              }
            }
          } catch (e) {
            print('Error processing Firestore doc $firestoreDocId for ${dataType.toString()}: $e');
          }
        }
      } catch (e) {
        print('Error fetching and merging data for $collectionNameInFirestore: $e');
      }
    }
  }
}
