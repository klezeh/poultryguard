// lib/models/batch_vaccination_event.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'batch_vaccination_event.g.dart'; // Generated file for Hive

@HiveType(typeId: 13) // Ensure this typeId is unique across all your Hive models
class BatchVaccinationEvent extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  final String batchId; // The ID of the batch this vaccination is for

  @HiveField(1)
  final String vaccinationName; // Name of the vaccine

  @HiveField(2)
  final DateTime scheduledDate; // Date when this vaccination is due

  @HiveField(3)
  final String method; // Method of vaccination (e.g., "Eye Drop", "Injection")

  @HiveField(4)
  bool isCompleted; // Whether this specific event has been completed (business logic)

  @HiveField(5)
  @override
  String? firestoreDocId; // Firestore document ID for synchronization

  @HiveField(6)
  @override
  DateTime? createdAt; // Timestamp for last modification/creation, for sync conflict resolution

  @HiveField(7)
  @override
  late bool isSynced; // Flag to track sync status (implements FirestoreSyncable)

  @HiveField(8) // NEW: Unique HiveField for isDeleted
  @override
  late bool isDeleted; // NEW: Flag to mark this item for deletion

  BatchVaccinationEvent({
    required this.batchId,
    required this.vaccinationName,
    required this.scheduledDate,
    required this.method,
    this.isCompleted = false,
    this.firestoreDocId,
    DateTime? createdAt,
    this.isSynced = false,
    this.isDeleted = false, // NEW: Default to false
  }) : this.createdAt = createdAt ?? DateTime.now(); // Initialize createdAt if not provided

  /// Factory constructor to create a [BatchVaccinationEvent] from a Firestore Map.
  /// This is essential for pulling data from Firestore.
  factory BatchVaccinationEvent.fromMap(Map<String, dynamic> map, String docId) {
    return BatchVaccinationEvent(
      batchId: map['batchId'] as String,
      vaccinationName: map['vaccinationName'] as String,
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      method: map['method'] as String,
      isCompleted: map['isCompleted'] as bool,
      firestoreDocId: docId, // Assign the Firestore document ID
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Convert Firestore Timestamp to DateTime
      isSynced: map['isSynced'] as bool? ?? true, // Assume true if coming from Firestore, default to true if missing
      isDeleted: map['isDeleted'] as bool? ?? false, // NEW: Get isDeleted from map, default to false
    );
  }

  /// Converts the [BatchVaccinationEvent] object to a Map<String, dynamic>
  /// suitable for uploading to Firestore.
  /// This is essential for pushing data to Firestore.
  @override
  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'vaccinationName': vaccinationName,
      'scheduledDate': Timestamp.fromDate(scheduledDate), // Convert DateTime to Firestore Timestamp
      'method': method,
      'isCompleted': isCompleted,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Use server timestamp for new records
      'isSynced': isSynced,
      'isDeleted': isDeleted, // NEW: Include isDeleted in the map
    };
  }

  // Override hashCode and == for proper list comparisons if needed (optional but good practice)
  @override
  int get hashCode => Object.hash(batchId, vaccinationName, scheduledDate, method, isCompleted, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchVaccinationEvent &&
          runtimeType == other.runtimeType &&
          batchId == other.batchId &&
          vaccinationName == other.vaccinationName &&
          scheduledDate == other.scheduledDate &&
          method == other.method &&
          isCompleted == other.isCompleted &&
          isDeleted == other.isDeleted; // Include isDeleted in equality check
}
