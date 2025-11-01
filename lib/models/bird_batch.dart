// models/bird_batch.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp and FieldValue
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'bird_batch.g.dart';

@HiveType(typeId: 0) // Ensure this is a unique typeId
class BirdBatch extends HiveObject with FirestoreSyncable { // Implement FirestoreSyncable
  @HiveField(0)
  String name;

  @HiveField(1)
  int quantity; // Made mutable

  @HiveField(2)
  DateTime startDate;

  @HiveField(3)
  BirdType? type; // Nullable type for flexibility

  @HiveField(4) // Marked as @override
  @override
  late bool isSynced; // Existing field for sync status (made late)

  @HiveField(5) // Marked as @override
  @override
  String? firestoreDocId; // Existing field for Firestore document ID

  @HiveField(6) // Changed to 6 for continuity, assuming 7 was for createdAt
  @override
  DateTime? createdAt; // New field for creation timestamp (made late if null, but with default for consistency)

  @HiveField(7) // NEW: Added isDeleted field for consistency with other syncable models
  @override
  late bool isDeleted; // Flag to mark this batch for deletion

  BirdBatch({
    required this.name,
    required this.quantity,
    required this.startDate,
    this.type,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced, // Changed to nullable bool for constructor flexibility
    bool? isDeleted, // Changed to nullable bool for constructor flexibility
  }) :
    this.firestoreDocId = firestoreDocId,
    this.createdAt = createdAt ?? DateTime.now(), // Initialize createdAt if not provided
    this.isSynced = isSynced ?? false, // Default to false if not provided
    this.isDeleted = isDeleted ?? false; // Default to false if not provided


  // Age calculation for display purposes
  int get ageInDays => DateTime.now().difference(startDate).inDays;

  String get stage {
    if (type == BirdType.broilers) {
      if (ageInDays <= 7) return 'Brooding (0-7 days)';
      if (ageInDays <= 21) return 'Grower (8-21 days)';
      if (ageInDays <= 42) return 'Finisher (22-42 days)';
      return 'Market Age (>42 days)';
    } else if (type == BirdType.layers) {
      if (ageInDays <= 60) return 'Chick (0-60 days)';
      if (ageInDays <= 140) return 'Pullet (61-140 days)';
      if (ageInDays <= 500) return 'Laying (141-500 days)';
      return 'End of Lay (>500 days)';
    }
    return 'Unknown Stage';
  }

  // Convert to Map for Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'startDate': Timestamp.fromDate(startDate), // Convert DateTime to Firestore Timestamp
      'type': type?.name, // Store enum as string
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Use serverTimestamp for new records
      // REMOVED: 'firestoreDocId': firestoreDocId, // This field is the document ID, not typically stored within the document's data
      'isDeleted': isDeleted, // Include isDeleted in map
    };
  }

  // Create from Map (Firestore) - Now more robust against type mismatches
  factory BirdBatch.fromMap(Map<String, dynamic> map, String docId) {
    // Safely retrieve isSynced, defaulting if not a bool or if a Timestamp (due to old data)
    bool isSyncedValue = false;
    if (map.containsKey('isSynced')) {
      final dynamic syncedData = map['isSynced'];
      if (syncedData is bool) {
        isSyncedValue = syncedData;
      } else if (syncedData is Timestamp) {
        // Handle cases where an old Timestamp might have been written into isSynced field
        print('Warning: isSynced for batch ${map['name']} is a Timestamp. Defaulting to false.');
        isSyncedValue = false; // Default to false, potentially triggering a re-sync fix
      }
    } else {
      // If 'isSynced' key doesn't exist, assume it needs to be synced (or true if from Firestore is considered synced by default)
      // For data coming from Firestore, it's generally assumed to be synced if the field is missing
      isSyncedValue = true;
    }

    // Safely retrieve isDeleted, defaulting if not a bool or if a Timestamp (due to old data)
    bool isDeletedValue = false;
    if (map.containsKey('isDeleted')) {
      final dynamic deletedData = map['isDeleted'];
      if (deletedData is bool) {
        isDeletedValue = deletedData;
      } else if (deletedData is Timestamp) {
        print('Warning: isDeleted for batch ${map['name']} is a Timestamp. Defaulting to false.');
        isDeletedValue = false; // Default to false
      }
    }

    return BirdBatch(
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toInt(),
      startDate: (map['startDate'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      type: map['type'] != null ? BirdType.values.byName(map['type'] as String) : null,
      isSynced: isSyncedValue,
      firestoreDocId: docId, // Assign Firestore document ID
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Convert Timestamp to DateTime, handle null
      isDeleted: isDeletedValue, // Get isDeleted from map, default to false
    );
  }

  /// Creates a new [BirdBatch] instance with modified properties.
  BirdBatch copyWith({
    String? name,
    int? quantity,
    DateTime? startDate,
    BirdType? type,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return BirdBatch(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      startDate: startDate ?? this.startDate,
      type: type ?? this.type,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(name, quantity, startDate, type, isSynced, firestoreDocId, createdAt, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BirdBatch &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity &&
          startDate == other.startDate &&
          type == other.type &&
          isSynced == other.isSynced &&
          firestoreDocId == other.firestoreDocId &&
          createdAt == other.createdAt &&
          isDeleted == other.isDeleted;
}

@HiveType(typeId: 1) // Unique typeId for the enum
enum BirdType {
  @HiveField(0)
  broilers,
  @HiveField(1)
  layers,
}