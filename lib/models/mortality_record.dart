// lib/models/mortality_record.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp and FieldValue
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'mortality_record.g.dart';

@HiveType(typeId: 9) // Ensure this is a unique typeId
class MortalityRecord extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  String batchName;

  @HiveField(1)
  int numberOfBirds;

  @HiveField(2)
  String reason;

  @HiveField(3)
  DateTime date;

  @HiveField(4) // Existing field for sync status
  @override
  late bool isSynced; // Removed defaultValue from here, handled in constructor

  @HiveField(5)
  @override
  String? firestoreDocId; // Existing field for Firestore document ID

  @HiveField(6) // Assigned a unique HiveField ID for createdAt
  @override
  DateTime? createdAt; // New field for creation timestamp

  @HiveField(7) // NEW: Field for deletion status
  @override
  late bool isDeleted; // Flag to mark this item for deletion


  MortalityRecord({
    required this.batchName,
    required this.numberOfBirds,
    required this.reason,
    required this.date,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced, // Changed to nullable bool
    bool? isDeleted, // Changed to nullable bool
  }) :
    this.firestoreDocId = firestoreDocId,
    this.createdAt = createdAt ?? DateTime.now(), // Initialize createdAt if not provided
    this.isSynced = isSynced ?? false, // Default to false when created locally if not provided
    this.isDeleted = isDeleted ?? false; // Default to false if not provided


  // Convert to Map for Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'batchName': batchName,
      'numberOfBirds': numberOfBirds,
      'reason': reason,
      'date': Timestamp.fromDate(date), // Convert DateTime to Firestore Timestamp
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Use serverTimestamp for new records
      'isDeleted': isDeleted, // Include isDeleted in map
    };
  }

  // Create from Map (Firestore)
  factory MortalityRecord.fromMap(Map<String, dynamic> map, String docId) {
    return MortalityRecord(
      batchName: map['batchName'] as String,
      numberOfBirds: (map['numberOfBirds'] as num).toInt(),
      reason: map['reason'] as String,
      date: (map['date'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      isSynced: map['isSynced'] as bool? ?? true, // Assume synced if from Firestore
      firestoreDocId: docId, // Assign Firestore document ID
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Convert Timestamp to DateTime, handle null
      isDeleted: map['isDeleted'] as bool? ?? false, // Get isDeleted from map, default to false
    );
  }

  /// Creates a new [MortalityRecord] instance with modified properties.
  MortalityRecord copyWith({
    String? batchName,
    int? numberOfBirds,
    String? reason,
    DateTime? date,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return MortalityRecord(
      batchName: batchName ?? this.batchName,
      numberOfBirds: numberOfBirds ?? this.numberOfBirds,
      reason: reason ?? this.reason,
      date: date ?? this.date,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(batchName, numberOfBirds, reason, date, isSynced, firestoreDocId, createdAt, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MortalityRecord &&
          runtimeType == other.runtimeType &&
          batchName == other.batchName &&
          numberOfBirds == other.numberOfBirds &&
          reason == other.reason &&
          date == other.date &&
          isSynced == other.isSynced &&
          createdAt == other.createdAt &&
          firestoreDocId == other.firestoreDocId &&
          isDeleted == other.isDeleted;
}
