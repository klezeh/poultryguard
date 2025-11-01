import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poultryguard/services/data_sync_service.dart'; // Import FirestoreSyncable

part 'poultry_task.g.dart';

@HiveType(typeId: 5) 
// <<< FIX: Implemented FirestoreSyncable >>>
class PoultryTask extends HiveObject with FirestoreSyncable {
  @HiveField(0)
  String name;

  @HiveField(1)
  String category;

  @HiveField(2)
  DateTime dueDate;

  @HiveField(3)
  bool isDone;

  @HiveField(4)
  bool isAdhoc;

  @override
  @HiveField(5, defaultValue: false)
  late bool isSynced;

  @override
  @HiveField(6)
  String? firestoreDocId;

  @override
  @HiveField(7)
  DateTime? createdAt;

  // <<< FIX: Added the missing isDeleted field >>>
  @override
  @HiveField(8, defaultValue: false)
  late bool isDeleted;

  PoultryTask({
    required this.name,
    required this.category,
    required this.dueDate,
    this.isDone = false,
    this.isAdhoc = false,
    this.isSynced = false,
    this.firestoreDocId,
    this.createdAt,
    this.isDeleted = false, // Initialize in constructor
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'dueDate': Timestamp.fromDate(dueDate), // Use Firestore Timestamp
      'isDone': isDone,
      'isAdhoc': isAdhoc,
      'isSynced': isSynced,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'firestoreDocId': firestoreDocId,
      'isDeleted': isDeleted, // Include in map
    };
  }

  factory PoultryTask.fromMap(Map<String, dynamic> map, String docId) {
    return PoultryTask(
      name: map['name'] as String,
      category: map['category'] as String,
      dueDate: (map['dueDate'] as Timestamp).toDate(), // Parse from Timestamp
      isDone: map['isDone'] as bool? ?? false,
      isAdhoc: map['isAdhoc'] as bool? ?? false,
      isSynced: map['isSynced'] as bool? ?? true,
      firestoreDocId: docId,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      isDeleted: map['isDeleted'] as bool? ?? false, // Get from map
    );
  }
}
