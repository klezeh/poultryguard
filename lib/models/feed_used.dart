// lib/models/feed_used.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp and FieldValue
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'feed_used.g.dart';

@HiveType(typeId: 11) // IMPORTANT: Ensure this typeId is UNIQUE across all your Hive models
class FeedUsed extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double quantityKg; // Quantity of feed used in kg

  @HiveField(2)
  String batchName; // The name of the bird batch this feed was used for

  @HiveField(3)
  String? notes; // Optional notes about the feed usage

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


  FeedUsed({
    required this.date,
    required this.quantityKg,
    required this.batchName,
    this.notes,
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
      'quantityKg': quantityKg,
      'batchName': batchName,
      'notes': notes,
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Handle createdAt
      'isDeleted': isDeleted, // Include isDeleted
    };
  }

  // Create from Map (Firestore)
  factory FeedUsed.fromMap(Map<String, dynamic> map, String docId) {
    return FeedUsed(
      date: (map['date'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      quantityKg: (map['quantityKg'] as num).toDouble(),
      batchName: map['batchName'] as String,
      notes: map['notes'] as String?,
      isSynced: map['isSynced'] as bool? ?? true,
      firestoreDocId: docId,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Handle nullable Timestamp
      isDeleted: map['isDeleted'] as bool? ?? false, // Handle nullable isDeleted
    );
  }

  /// Creates a new [FeedUsed] instance with modified properties.
  FeedUsed copyWith({
    DateTime? date,
    double? quantityKg,
    String? batchName,
    String? notes,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return FeedUsed(
      date: date ?? this.date,
      quantityKg: quantityKg ?? this.quantityKg,
      batchName: batchName ?? this.batchName,
      notes: notes ?? this.notes,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(date, quantityKg, batchName, notes, isSynced, firestoreDocId, createdAt, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedUsed &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          quantityKg == other.quantityKg &&
          batchName == other.batchName &&
          notes == other.notes &&
          isSynced == other.isSynced &&
          firestoreDocId == other.firestoreDocId &&
          createdAt == other.createdAt &&
          isDeleted == other.isDeleted;
}
