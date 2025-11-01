// lib/models/user_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poultryguard/models/user_role.dart';

class UserProfile {
  final String uid;
  final String? name;
  final String email;
  final UserRole role;
  final String? farmId;
  final DateTime? createdAt; // <-- ADDED THIS FIELD

  UserProfile({
    required this.uid,
    this.name,
    required this.email,
    this.role = UserRole.unassigned,
    this.farmId,
    this.createdAt, // <-- ADDED THIS FIELD
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] as String?,
      email: data['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'] as String?,
        orElse: () => UserRole.unassigned,
      ),
      farmId: data['farmId'] as String?,
      // Read the timestamp from Firestore and convert it to a DateTime object
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(), // <-- ADDED THIS LINE
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'farmId': farmId,
      // When creating a new user, this will be handled by FieldValue.serverTimestamp()
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
