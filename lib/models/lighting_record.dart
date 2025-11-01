// lib/models/lighting_record.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp and FieldValue
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'lighting_record.g.dart';

@HiveType(typeId: 12) // IMPORTANT: Ensure this typeId is UNIQUE across all your Hive models
class LightingRecord extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double lightsOnHours; // Hours lights were on

  @HiveField(2)
  double lightsOffHours; // Hours lights were off

  @HiveField(3)
  String batchName; // The name of the bird batch this record is for

  @HiveField(4)
  @override
  late bool isSynced; // Flag for sync status

  @HiveField(5)
  @override
  String? firestoreDocId; // Firestore document ID

  @HiveField(6)
  @override
  DateTime? createdAt; // Creation timestamp

  @HiveField(7)
  @override
  late bool isDeleted; // Flag to mark this item for deletion


  LightingRecord({
    required this.date,
    required this.lightsOnHours,
    required this.lightsOffHours,
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
      'lightsOnHours': lightsOnHours,
      'lightsOffHours': lightsOffHours,
      'batchName': batchName,
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Handle createdAt
      'isDeleted': isDeleted, // Include isDeleted
    };
  }

  // Create from Map (Firestore)
  factory LightingRecord.fromMap(Map<String, dynamic> map, String docId) {
    return LightingRecord(
      date: (map['date'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      lightsOnHours: (map['lightsOnHours'] as num).toDouble(),
      lightsOffHours: (map['lightsOffHours'] as num).toDouble(),
      batchName: map['batchName'] as String,
      isSynced: map['isSynced'] as bool? ?? true,
      firestoreDocId: docId,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Handle nullable Timestamp
      isDeleted: map['isDeleted'] as bool? ?? false, // Handle nullable isDeleted
    );
  }

  /// Creates a new [LightingRecord] instance with modified properties.
  LightingRecord copyWith({
    DateTime? date,
    double? lightsOnHours,
    double? lightsOffHours,
    String? batchName,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return LightingRecord(
      date: date ?? this.date,
      lightsOnHours: lightsOnHours ?? this.lightsOnHours,
      lightsOffHours: lightsOffHours ?? this.lightsOffHours,
      batchName: batchName ?? this.batchName,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(date, lightsOnHours, lightsOffHours, batchName, isSynced, firestoreDocId, createdAt, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LightingRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          lightsOnHours == other.lightsOnHours &&
          lightsOffHours == other.lightsOffHours &&
          batchName == other.batchName &&
          isSynced == other.isSynced &&
          firestoreDocId == other.firestoreDocId &&
          createdAt == other.createdAt &&
          isDeleted == other.isDeleted;
}
