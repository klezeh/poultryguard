
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp and FieldValue
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'temperature_humidity_record.g.dart';

@HiveType(typeId: 16) // IMPORTANT: Ensure this typeId is UNIQUE across all your Hive models
class TemperatureHumidityRecord extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double temperatureC;

  @HiveField(2)
  double humidityPercent;

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


  TemperatureHumidityRecord({
    required this.date,
    required this.temperatureC,
    required this.humidityPercent,
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
      'temperatureC': temperatureC,
      'humidityPercent': humidityPercent,
      'batchName': batchName,
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(), // Handle createdAt
      'isDeleted': isDeleted, // Include isDeleted
    };
  }

  // Create from Map (Firestore)
  factory TemperatureHumidityRecord.fromMap(Map<String, dynamic> map, String docId) {
    return TemperatureHumidityRecord(
      date: (map['date'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      temperatureC: (map['temperatureC'] as num).toDouble(),
      humidityPercent: (map['humidityPercent'] as num).toDouble(),
      batchName: map['batchName'] as String,
      isSynced: map['isSynced'] as bool? ?? true,
      firestoreDocId: docId,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(), // Handle nullable Timestamp
      isDeleted: map['isDeleted'] as bool? ?? false, // Handle nullable isDeleted
    );
  }

  /// Creates a new [TemperatureHumidityRecord] instance with modified properties.
  TemperatureHumidityRecord copyWith({
    DateTime? date,
    double? temperatureC,
    double? humidityPercent,
    String? batchName,
    String? firestoreDocId,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return TemperatureHumidityRecord(
      date: date ?? this.date,
      temperatureC: temperatureC ?? this.temperatureC,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      batchName: batchName ?? this.batchName,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Override hashCode and == for proper list comparisons
  @override
  int get hashCode => Object.hash(date, temperatureC, humidityPercent, batchName, isSynced, firestoreDocId, createdAt, isDeleted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemperatureHumidityRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          temperatureC == other.temperatureC &&
          humidityPercent == other.humidityPercent &&
          batchName == other.batchName &&
          isSynced == other.isSynced &&
          firestoreDocId == other.firestoreDocId &&
          createdAt == other.createdAt &&
          isDeleted == other.isDeleted;
}
