// lib/models/isolation_record.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp conversion
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'isolation_record.g.dart'; // Ensure this part file exists

@HiveType(typeId: 10) // Make sure typeId is unique across all your models
class IsolationRecord extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  String batchName;

  @HiveField(1)
  int numberOfBirds;

  @HiveField(2)
  String reason;

  @HiveField(3)
  DateTime isolationDate;

  @HiveField(4)
  @override
  late bool isSynced; // This field must exist for DataSyncService to work

  @HiveField(5) // Assign a unique field ID for createdAt
  @override
  DateTime? createdAt; // Make it nullable for existing records, or give a default

  // Optional: field to store Firestore document ID for easier updates/deletes
  @HiveField(6) // Assign another unique field ID
  @override
  String? firestoreDocId;

  @HiveField(7) // Field for deletion status
  @override
  late bool isDeleted; // Flag to mark this item for deletion

  @HiveField(8) // NEW: Flag to indicate if birds are still isolated
  late bool isActive;

  @HiveField(9) // NEW: Date when birds were released from isolation
  DateTime? releaseDate;


  IsolationRecord({
    required this.batchName,
    required this.numberOfBirds,
    required this.reason,
    required this.isolationDate,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced, // Changed to nullable bool
    bool? isDeleted, // Changed to nullable bool
    bool? isActive, // NEW: Added to constructor
    this.releaseDate, // NEW: Added to constructor
  }) :
    this.firestoreDocId = firestoreDocId,
    this.createdAt = createdAt ?? DateTime.now(), // Initialize createdAt if not provided
    this.isSynced = isSynced ?? false, // Default to false when created locally if not provided
    this.isDeleted = isDeleted ?? false, // Default to false if not provided
    this.isActive = isActive ?? true; // NEW: Default to true (currently isolated)


  // --- Add/Update toMap() method for Firestore serialization ---
  @override
  Map<String, dynamic> toMap() {
    return {
      'batchName': batchName,
      'numberOfBirds': numberOfBirds,
      'reason': reason,
      'isolationDate': Timestamp.fromDate(isolationDate), // Convert DateTime to Timestamp
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Handle createdAt for new records
      'isDeleted': isDeleted, // Include isDeleted in the map
      'isActive': isActive, // NEW: Include isActive
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null, // NEW: Include releaseDate
    };
  }

  // --- Add/Update fromMap() factory for Firestore deserialization ---
  factory IsolationRecord.fromMap(Map<String, dynamic> map, String docId) {
    return IsolationRecord(
      batchName: map['batchName'] as String,
      numberOfBirds: map['numberOfBirds'] as int,
      reason: map['reason'] as String,
      isolationDate: (map['isolationDate'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      isSynced: map['isSynced'] as bool? ?? true, // Assume synced if coming from Firestore
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Convert Timestamp to DateTime, handle null
      firestoreDocId: docId,
      isDeleted: map['isDeleted'] as bool? ?? false, // Get isDeleted from map, default to false
      isActive: map['isActive'] as bool? ?? true, // NEW: Get isActive from map, default to true
      releaseDate: (map['releaseDate'] as Timestamp?)?.toDate(), // NEW: Get releaseDate from map, handle null
    );
  }

  /// Creates a new [IsolationRecord] instance with modified properties.
  IsolationRecord copyWith({
    String? batchName,
    int? numberOfBirds,
    String? reason,
    DateTime? isolationDate,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
    bool? isActive, // NEW: Added to copyWith
    DateTime? releaseDate, // NEW: Added to copyWith
  }) {
    return IsolationRecord(
      batchName: batchName ?? this.batchName,
      numberOfBirds: numberOfBirds ?? this.numberOfBirds,
      reason: reason ?? this.reason,
      isolationDate: isolationDate ?? this.isolationDate,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      isActive: isActive ?? this.isActive, // NEW: Use isActive
      releaseDate: releaseDate ?? this.releaseDate, // NEW: Use releaseDate
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(batchName, numberOfBirds, reason, isolationDate, isSynced, firestoreDocId, createdAt, isDeleted, isActive, releaseDate);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IsolationRecord &&
          runtimeType == other.runtimeType &&
          batchName == other.batchName &&
          numberOfBirds == other.numberOfBirds &&
          reason == other.reason &&
          isolationDate == other.isolationDate &&
          isSynced == other.isSynced &&
          createdAt == other.createdAt &&
          firestoreDocId == other.firestoreDocId &&
          isDeleted == other.isDeleted &&
          isActive == other.isActive &&
          releaseDate == other.releaseDate;
}
