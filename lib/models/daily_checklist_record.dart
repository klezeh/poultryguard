import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:poultryguard/services/data_sync_service.dart';

part 'daily_checklist_record.g.dart';

@HiveType(typeId: 19) 
class DailyChecklistRecord extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  dynamic batchKey;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  Map<String, bool> taskCompletions;

  DailyChecklistRecord({
    required this.batchKey,
    required this.date,
    required this.taskCompletions,
  });

  // --- FIX: Add the required toMap() method ---
  // This converts the object into a Map that Firestore can understand.
  @override
  Map<String, dynamic> toMap() {
    return {
      'batchKey': batchKey,
      'date': Timestamp.fromDate(date), // Convert DateTime to Firestore Timestamp
      'taskCompletions': taskCompletions,
      'firestoreDocId': firestoreDocId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isSynced': isSynced,
      'isDeleted': isDeleted,
    };
  }

  // --- FIX: Add the required fromMap() factory constructor ---
  // This builds a DailyChecklistRecord object from data loaded from Firestore.
  factory DailyChecklistRecord.fromMap(Map<String, dynamic> map, String documentId) {
    final record = DailyChecklistRecord(
      batchKey: map['batchKey'],
      date: (map['date'] as Timestamp).toDate(), // Convert Firestore Timestamp back to DateTime
      taskCompletions: Map<String, bool>.from(map['taskCompletions'] ?? {}),
    );

    // Populate the properties from the FirestoreSyncable mixin
    record.firestoreDocId = documentId;
    record.createdAt = (map['createdAt'] as Timestamp?)?.toDate();
    record.isSynced = map['isSynced'] ?? true; // Default to true when coming from server
    record.isDeleted = map['isDeleted'] ?? false;
    
    return record;
  }

  // A copyWith method for easier updates (optional but good practice)
  DailyChecklistRecord copyWith({
    dynamic batchKey,
    DateTime? date,
    Map<String, bool>? taskCompletions,
    bool? isSynced,
  }) {
    final newRecord = DailyChecklistRecord(
      batchKey: batchKey ?? this.batchKey,
      date: date ?? this.date,
      taskCompletions: taskCompletions ?? Map<String, bool>.from(this.taskCompletions),
    );
    newRecord.isSynced = isSynced ?? this.isSynced;
    newRecord.firestoreDocId = this.firestoreDocId;
    newRecord.isDeleted = this.isDeleted;
    newRecord.createdAt = this.createdAt;
    return newRecord;
  }
}