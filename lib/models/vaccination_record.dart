// lib/models/vaccination_record.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'vaccination_record.g.dart'; // Generated file by Hive

@HiveType(typeId: 2) // Ensure this typeId is unique across your Hive models
class VaccinationRecord extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  final String batchName; // The name of the bird batch
  @HiveField(1)
  final String vaccineName; // Name of the vaccine administered
  @HiveField(2)
  final DateTime dateGiven; // Date the vaccine was administered
  @HiveField(3)
  final int quantity; // Number of birds vaccinated
  @HiveField(4)
  final String notes; // Any additional notes about the vaccination

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

  VaccinationRecord({
    required this.batchName,
    required this.vaccineName,
    required this.dateGiven,
    required this.quantity,
    this.notes = '',
    this.firestoreDocId,
    DateTime? createdAt,
    this.isSynced = false,
    this.isDeleted = false, // NEW: Default to false
  }) : this.createdAt = createdAt ?? DateTime.now(); // Initialize createdAt if not provided

  /// Factory constructor to create a [VaccinationRecord] from a Firestore Map.
  factory VaccinationRecord.fromMap(Map<String, dynamic> map, String docId) {
    return VaccinationRecord(
      batchName: map['batchName'] as String,
      vaccineName: map['vaccineName'] as String,
      dateGiven: (map['dateGiven'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      quantity: map['quantity'] as int,
      notes: map['notes'] as String? ?? '', // Handle potential null notes
      firestoreDocId: docId, // Assign the Firestore document ID
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Convert Firestore Timestamp to DateTime
      isSynced: map['isSynced'] as bool? ?? true, // Assume true if coming from Firestore, default to true if missing
      isDeleted: map['isDeleted'] as bool? ?? false, // NEW: Get isDeleted from map, default to false
    );
  }

  /// Converts the [VaccinationRecord] object to a Map<String, dynamic>
  /// suitable for uploading to Firestore.
  @override
  Map<String, dynamic> toMap() {
    return {
      'batchName': batchName,
      'vaccineName': vaccineName,
      'dateGiven': Timestamp.fromDate(dateGiven), // Convert DateTime to Firestore Timestamp
      'quantity': quantity,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Use server timestamp for new records
      'isSynced': isSynced,
      'isDeleted': isDeleted, // NEW: Include isDeleted in the map
    };
  }

  // Override hashCode and == for proper list comparisons if needed (optional but good practice)
  @override
  int get hashCode => Object.hash(batchName, vaccineName, dateGiven, quantity, notes, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaccinationRecord &&
          runtimeType == other.runtimeType &&
          batchName == other.batchName &&
          vaccineName == other.vaccineName &&
          dateGiven == other.dateGiven &&
          quantity == other.quantity &&
          notes == other.notes &&
          isDeleted == other.isDeleted; // Include isDeleted in equality check
}
