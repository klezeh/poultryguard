// models/egg_supplied.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for FieldValue.serverTimestamp()
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'egg_supplied.g.dart';

@HiveType(typeId: 7) // Ensure this is a unique typeId
class EggSupplied extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  String customerName; // Renamed from 'destination' for clarity

  @HiveField(3)
  String? notes;

  @HiveField(4) // Changed to late bool
  @override
  late bool isSynced; // Flag for sync status (implements FirestoreSyncable)

  @HiveField(5)
  @override
  String? firestoreDocId; // New field for Firestore document ID

  @HiveField(6)
  @override
  DateTime? createdAt; // Field for creation timestamp

  @HiveField(7) // NEW: Field for deletion status
  @override
  late bool isDeleted; // Flag to mark this item for deletion

  EggSupplied({
    required this.date,
    required this.quantity,
    required this.customerName,
    this.notes,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced, // Changed to nullable bool
    bool? isDeleted, // Changed to nullable bool
  }) :
    this.firestoreDocId = firestoreDocId,
    this.createdAt = createdAt ?? DateTime.now(), // Initialize createdAt if not provided
    this.isSynced = isSynced ?? false, // Default to false when created locally if not provided
    this.isDeleted = isDeleted ?? false; // Default to false if not provided


  // Convert to Map for Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date), // Convert DateTime to Firestore Timestamp
      'quantity': quantity,
      'customerName': customerName,
      'notes': notes,
      'isSynced': isSynced,
      // If createdAt is null, use serverTimestamp; otherwise, use the existing createdAt.
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isDeleted': isDeleted, // Include isDeleted in the map
    };
  }

  // Create from Map (Firestore)
  factory EggSupplied.fromMap(Map<String, dynamic> map, String docId) {
    return EggSupplied(
      date: (map['date'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      quantity: (map['quantity'] as num).toInt(),
      customerName: map['customerName'] as String,
      notes: map['notes'] as String?,
      isSynced: map['isSynced'] as bool? ?? true, // Assume true if coming from Firestore, or use default
      firestoreDocId: docId,
      // Parse createdAt from Timestamp, or default to null if not present
      createdAt: (map['createdAt'] is Timestamp) ? (map['createdAt'] as Timestamp).toDate() : null,
      isDeleted: map['isDeleted'] as bool? ?? false, // Get isDeleted from map, default to false
    );
  }

  /// Creates a new [EggSupplied] instance with modified properties.
  EggSupplied copyWith({
    DateTime? date,
    int? quantity,
    String? customerName,
    String? notes,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return EggSupplied(
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(date, quantity, customerName, notes, isSynced, firestoreDocId, createdAt, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EggSupplied &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          quantity == other.quantity &&
          customerName == other.customerName &&
          notes == other.notes &&
          isSynced == other.isSynced &&
          createdAt == other.createdAt &&
          firestoreDocId == other.firestoreDocId &&
          isDeleted == other.isDeleted;
}
