// models/environment_record.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'environment_record.g.dart'; // This file will be generated

@HiveType(typeId: 8) // IMPORTANT: Ensure this typeId is UNIQUE across all your Hive models
class EnvironmentRecord extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double temperatureC;

  @HiveField(2)
  double humidityPercent;

  @HiveField(3)
  @override
  late bool isSynced; // Flag for sync status

  @HiveField(4)
  @override
  String? firestoreDocId; // Firestore document ID

  @HiveField(5) // Unique HiveField for createdAt
  @override
  DateTime? createdAt; // Creation timestamp

  @HiveField(6) // Unique HiveField for isDeleted
  @override
  late bool isDeleted; // Flag to mark this item for deletion


  EnvironmentRecord({
    required this.date,
    required this.temperatureC,
    required this.humidityPercent,
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
      'temperatureC': temperatureC,
      'humidityPercent': humidityPercent,
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Handle createdAt
      'isDeleted': isDeleted, // Include isDeleted
    };
  }

  // Create from Map (Firestore)
  factory EnvironmentRecord.fromMap(Map<String, dynamic> map, String docId) {
    return EnvironmentRecord(
      date: (map['date'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      temperatureC: (map['temperatureC'] as num).toDouble(),
      humidityPercent: (map['humidityPercent'] as num).toDouble(), // Corrected field name
      isSynced: map['isSynced'] as bool? ?? true,
      firestoreDocId: docId,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Handle nullable Timestamp
      isDeleted: map['isDeleted'] as bool? ?? false, // Handle nullable isDeleted
    );
  }

  /// Creates a new [EnvironmentRecord] instance with modified properties.
  EnvironmentRecord copyWith({
    DateTime? date,
    double? temperatureC,
    double? humidityPercent,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return EnvironmentRecord(
      date: date ?? this.date,
      temperatureC: temperatureC ?? this.temperatureC,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(date, temperatureC, humidityPercent, isSynced, firestoreDocId, createdAt, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvironmentRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          temperatureC == other.temperatureC &&
          humidityPercent == other.humidityPercent &&
          isSynced == other.isSynced &&
          firestoreDocId == other.firestoreDocId &&
          createdAt == other.createdAt &&
          isDeleted == other.isDeleted;
}
