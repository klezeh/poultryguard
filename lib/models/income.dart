// lib/models/income.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Important for Timestamp
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'income.g.dart'; // Regenerate this file after changes

@HiveType(typeId: 3) // Ensure typeId is unique
class Income extends HiveObject with FirestoreSyncable { // Implement FirestoreSyncable
  @HiveField(0)
  String? source;
  @HiveField(1)
  double amount;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  String? note;

  @HiveField(4) // This will be firestoreDocId now
  @override
  String? firestoreDocId; // Store Firestore doc ID

  @HiveField(5) // This will be createdAt now
  @override
  DateTime? createdAt; // Use DateTime? for optional timestamp

  @HiveField(6) // This will be isSynced now
  @override
  late bool isSynced; // Flag to track sync status

  @HiveField(7) // NEW: Add this field for isDeleted with a unique ID
  @override
  late bool isDeleted; // Flag to mark this item for deletion

  Income({
    this.source,
    required this.amount,
    required this.date,
    this.note,
    this.firestoreDocId, // Include in constructor
    DateTime? createdAt, // Include in constructor
    this.isSynced = false, // Default to false for new local records
    this.isDeleted = false, // NEW: Default to false
  }) : this.createdAt = createdAt ?? DateTime.now(); // Initialize createdAt if not provided

  @override // Override from FirestoreSyncable
  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'amount': amount,
      'date': Timestamp.fromDate(date), // Convert DateTime to Timestamp
      'note': note,
      'firestoreDocId': firestoreDocId, // Include in map (though Firestore will set its own ID)
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Use server timestamp for new records
      'isSynced': isSynced,
      'isDeleted': isDeleted, // NEW: Include isDeleted in the map
    };
  }

  factory Income.fromMap(Map<String, dynamic> map, String docId) {
    return Income(
      source: map['source'] as String?,
      amount: (map['amount'] as num).toDouble(), // Handle num to double conversion from Firestore
      date: (map['date'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      note: map['note'] as String?,
      firestoreDocId: docId, // Assign the Firestore document ID
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Convert Firestore Timestamp to DateTime
      isSynced: map['isSynced'] as bool? ?? true, // Assume true if coming from Firestore, default to true if missing
      isDeleted: map['isDeleted'] as bool? ?? false, // NEW: Get isDeleted from map, default to false
    );
  }

  // Override hashCode and == for proper list comparisons if needed (optional but good practice)
  @override
  int get hashCode => Object.hash(source, amount, date, note, isDeleted); // Include isDeleted in hash code

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Income &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          amount == other.amount &&
          date == other.date &&
          note == other.note &&
          isDeleted == other.isDeleted; // Include isDeleted in equality check
}
