// lib/models/expense.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'expense.g.dart'; // Generated file by Hive

@HiveType(typeId: 4) // Ensure this typeId is unique across your Hive models
class Expense extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  final String description;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  String? category; // Made nullable to allow for expansion or optionality
  @HiveField(4)
  final String batchName; // The name of the bird batch associated with this expense

  @HiveField(5)
  @override
  String? firestoreDocId; // Firestore document ID for synchronization

  @HiveField(6)
  @override
  DateTime? createdAt; // Timestamp for last modification/creation, for sync conflict resolution

  @HiveField(7)
  @override
  late bool isSynced; // Flag to track sync status (implements FirestoreSyncable)

  @HiveField(8)
  @override
  late bool isDeleted; // Flag to mark this item for deletion

  @HiveField(9) // NEW: Unique HiveField for isFlagged
  late bool isFlagged; // Flag for review, e.g., if expense is unusual (removed 'final')


  Expense({
    required this.description,
    required this.amount,
    required this.date,
    this.category,
    required this.batchName, // Batch name is now required
    this.firestoreDocId,
    DateTime? createdAt,
    bool? isSynced, // Changed to nullable bool
    bool? isDeleted, // Changed to nullable bool
    bool? isFlagged, // Changed to nullable bool
  }) :
    this.createdAt = createdAt ?? DateTime.now(),
    this.isSynced = isSynced ?? false, // Default to false if not provided
    this.isDeleted = isDeleted ?? false, // Default to false if not provided
    this.isFlagged = isFlagged ?? false; // Default to false if not provided


  /// Factory constructor to create an [Expense] from a Firestore Map.
  factory Expense.fromMap(Map<String, dynamic> map, String docId) {
    return Expense(
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(), // Handle num to double conversion
      date: (map['date'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      category: map['category'] as String?, // Nullable
      batchName: map['batchName'] as String,
      firestoreDocId: docId, // Assign the Firestore document ID
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Convert Firestore Timestamp to DateTime
      isSynced: map['isSynced'] as bool? ?? true, // Assume true if coming from Firestore, default to true if missing
      isDeleted: map['isDeleted'] as bool? ?? false, // Get isDeleted from map, default to false
      isFlagged: map['isFlagged'] as bool? ?? false, // NEW: Get isFlagged from map, default to false
    );
  }

  /// Converts the [Expense] object to a Map<String, dynamic>
  /// suitable for uploading to Firestore.
  @override
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date), // Convert DateTime to Firestore Timestamp
      'category': category,
      'batchName': batchName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Use server timestamp for new records
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'isFlagged': isFlagged, // NEW: Include isFlagged in the map
    };
  }

  /// Creates a new [Expense] instance with modified properties.
  Expense copyWith({
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    String? batchName,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
    bool? isFlagged,
  }) {
    return Expense(
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      batchName: batchName ?? this.batchName,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }

  // Override hashCode and == for proper list comparisons if needed (optional but good practice)
  @override
  int get hashCode => Object.hash(description, amount, date, category, batchName, isDeleted, isFlagged);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          amount == other.amount &&
          date == other.date &&
          category == other.category &&
          batchName == other.batchName &&
          isDeleted == other.isDeleted &&
          isFlagged == other.isFlagged; // Include isFlagged in equality check
}
