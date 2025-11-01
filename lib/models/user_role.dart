// lib/models/user_role.dart
import 'package:hive/hive.dart';

part 'user_role.g.dart';

@HiveType(typeId: 21) // IMPORTANT: Ensure this typeId is UNIQUE across all your Hive models
enum UserRole {
  @HiveField(0)
  admin,
  @HiveField(1)
  midLevel,
  @HiveField(2)
  lowLevel,
  @HiveField(3)
  unassigned, // Default for new users until assigned (previously 'guest')
}
