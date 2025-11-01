// lib/models/release_log.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'release_log.g.dart'; // Generated file for Hive

@HiveType(typeId: 15) // Ensure this typeId is unique across all your Hive models
class ReleaseLog extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  String batchName;

  @HiveField(1)
  int numberOfBirds;

  @HiveField(2)
  String? notes; // Made nullable for optionality

  @HiveField(3)
  DateTime releaseDate; // Date when birds were released

  @HiveField(4)
  @override
  late bool isSynced; // Flag for sync status

  @HiveField(5)
  @override
  String? firestoreDocId; // Firestore document ID

  @HiveField(6)
  @override
  DateTime? createdAt; // Creation timestamp

  @HiveField(7) // NEW: Unique HiveField for isDeleted
  @override
  late bool isDeleted; // Flag to mark this item for deletion


  ReleaseLog({
    required this.batchName,
    required this.numberOfBirds,
    this.notes, // Made optional in constructor
    required this.releaseDate,
    String? firestoreDocId,
    DateTime? createdAt, // Added to constructor
    bool? isSynced,     // Added to constructor
    bool? isDeleted,    // Added to constructor
  }) :
    this.firestoreDocId = firestoreDocId,
    this.createdAt = createdAt ?? DateTime.now(), // Initialize createdAt if not provided
    this.isSynced = isSynced ?? false, // Default to false if not provided
    this.isDeleted = isDeleted ?? false; // Default to false if not provided


  /// Factory constructor to create a [ReleaseLog] from a Firestore Map.
  factory ReleaseLog.fromMap(Map<String, dynamic> map, String docId) {
    return ReleaseLog(
      // Defensive null checks for non-nullable fields when parsing from map
      batchName: map['batchName'] as String? ?? 'Unknown Batch', // Provide default if null
      numberOfBirds: (map['numberOfBirds'] as num?)?.toInt() ?? 0, // Provide default if null
      notes: map['notes'] as String?,
      releaseDate: (map['releaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(), // Provide default if null
      isSynced: map['isSynced'] as bool? ?? true, // Default to true if from Firestore and missing
      firestoreDocId: docId,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Already handles null gracefully
      isDeleted: map['isDeleted'] as bool? ?? false, // Already handles null gracefully
    );
  }

  /// Converts the [ReleaseLog] object to a Map<String, dynamic> suitable for uploading to Firestore.
  @override
  Map<String, dynamic> toMap() {
    return {
      'batchName': batchName,
      'numberOfBirds': numberOfBirds,
      'notes': notes,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isDeleted': isDeleted,
    };
  }

  /// Creates a new [ReleaseLog] instance with modified properties.
  ReleaseLog copyWith({
    String? batchName,
    int? numberOfBirds,
    String? notes,
    DateTime? releaseDate,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return ReleaseLog(
      batchName: batchName ?? this.batchName,
      numberOfBirds: numberOfBirds ?? this.numberOfBirds,
      notes: notes ?? this.notes,
      releaseDate: releaseDate ?? this.releaseDate,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(batchName, numberOfBirds, notes, releaseDate, isSynced, firestoreDocId, createdAt, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReleaseLog &&
          runtimeType == other.runtimeType &&
          batchName == other.batchName &&
          numberOfBirds == other.numberOfBirds &&
          notes == other.notes &&
          releaseDate == other.releaseDate &&
          isSynced == other.isSynced &&
          firestoreDocId == other.firestoreDocId &&
          createdAt == other.createdAt &&
          isDeleted == other.isDeleted;
}
