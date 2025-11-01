// lib/models/egg_collected.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp conversion
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'egg_collected.g.dart'; // Ensure this part file is correctly generated

@HiveType(typeId: 6) // Make sure this typeId is unique across all your models
class EggCollected extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int count;

  @HiveField(2)
  String? notes;

  @HiveField(3)
  String batchName;

  @HiveField(4)
  @override
  late bool isSynced; // Flag for sync status (implements FirestoreSyncable)

  @HiveField(5)
  @override
  DateTime? createdAt; // Timestamp for creation/last modification

  @HiveField(6)
  @override
  String? firestoreDocId; // Stores the Firestore document ID

  @HiveField(7) // NEW: Field for deletion status
  @override
  late bool isDeleted; // Flag to mark this item for deletion

  EggCollected({
    required this.date,
    required this.count,
    this.notes,
    required this.batchName,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced, // Changed to nullable bool
    bool? isDeleted, // Changed to nullable bool
  }) :
    this.firestoreDocId = firestoreDocId,
    this.createdAt = createdAt ?? DateTime.now(),
    this.isSynced = isSynced ?? false, // Default to false if not provided
    this.isDeleted = isDeleted ?? false; // Default to false if not provided


  /// Convert EggCollected object to a Map for Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date), // Convert DateTime to Firestore Timestamp
      'count': count,
      'notes': notes,
      'batchName': batchName,
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Use serverTimestamp for new records
      'isDeleted': isDeleted, // Include isDeleted in the map
    };
  }

  /// Create an EggCollected object from a Firestore Map
  factory EggCollected.fromMap(Map<String, dynamic> map, String docId) {
    return EggCollected(
      date: (map['date'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      count: map['count'] as int,
      notes: map['notes'] as String?,
      batchName: map['batchName'] as String,
      firestoreDocId: docId, // Assign the Firestore document ID
      isSynced: map['isSynced'] as bool? ?? true, // Assume true if coming from Firestore, or use default
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Convert Timestamp to DateTime, handle null
      isDeleted: map['isDeleted'] as bool? ?? false, // Get isDeleted from map, default to false
    );
  }

  /// Creates a new [EggCollected] instance with modified properties.
  EggCollected copyWith({
    DateTime? date,
    int? count,
    String? notes,
    String? batchName,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return EggCollected(
      date: date ?? this.date,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      batchName: batchName ?? this.batchName,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(date, count, notes, batchName, isSynced, createdAt, firestoreDocId, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EggCollected &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          count == other.count &&
          notes == other.notes &&
          batchName == other.batchName &&
          isSynced == other.isSynced &&
          createdAt == other.createdAt &&
          firestoreDocId == other.firestoreDocId &&
          isDeleted == other.isDeleted;
}
