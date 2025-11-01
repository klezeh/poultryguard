// lib/models/observation_record.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp and FieldValue
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'observation_record.g.dart';

@HiveType(typeId: 14) // IMPORTANT: Ensure this typeId is UNIQUE across all your Hive models
class ObservationRecord extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String observationText; // The actual observation text

  @HiveField(2)
  String batchName; // The name of the bird batch this record is for

  @HiveField(3)
  @override
  late bool isSynced; // Flag for sync status

  @HiveField(4)
  @override
  String? firestoreDocId; // Firestore document ID

  @HiveField(5)
  @override
  DateTime? createdAt; // Creation timestamp

  @HiveField(6)
  @override
  late bool isDeleted; // Flag to mark this item for deletion


  ObservationRecord({
    required this.date,
    required this.observationText,
    required this.batchName,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) :
    this.firestoreDocId = firestoreDocId,
    this.createdAt = createdAt ?? DateTime.now(), // Initialize createdAt if not provided
    this.isSynced = isSynced ?? false, // Default to false if not provided
    this.isDeleted = isDeleted ?? false; // Default to false if not provided


  // Convert to Map for Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date), // Convert DateTime to Timestamp
      'observationText': observationText,
      'batchName': batchName,
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Handle createdAt
      'isDeleted': isDeleted, // Include isDeleted
    };
  }

  // Create from Map (Firestore)
  factory ObservationRecord.fromMap(Map<String, dynamic> map, String docId) {
    return ObservationRecord(
      date: (map['date'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      observationText: map['observationText'] as String,
      batchName: map['batchName'] as String,
      isSynced: map['isSynced'] as bool? ?? true,
      firestoreDocId: docId,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Handle nullable Timestamp
      isDeleted: map['isDeleted'] as bool? ?? false, // Handle nullable isDeleted
    );
  }

  /// Creates a new [ObservationRecord] instance with modified properties.
  ObservationRecord copyWith({
    DateTime? date,
    String? observationText,
    String? batchName,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return ObservationRecord(
      date: date ?? this.date,
      observationText: observationText ?? this.observationText,
      batchName: batchName ?? this.batchName,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(date, observationText, batchName, isSynced, firestoreDocId, createdAt, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservationRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          observationText == other.observationText &&
          batchName == other.batchName &&
          isSynced == other.isSynced &&
          firestoreDocId == other.firestoreDocId &&
          createdAt == other.createdAt &&
          isDeleted == other.isDeleted;
}
