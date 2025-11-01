// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:poultryguard/models/vaccination_event.dart'; // Assuming this is still used
import 'package:poultryguard/providers/vaccination_schedule_notifier.dart'; // Your existing notifier
import 'package:poultryguard/services/batch_schedule_service.dart'; // Import BatchScheduleService
import 'package:poultryguard/services/notification_service.dart'; // Import NotificationService
import 'package:poultryguard/services/data_sync_service.dart'; // NEW: Import DataSyncService (for the class, not the provider)

// User session providers (defined in user_session_provider.dart)
// REMOVED: export 'package:poultryguard/providers/user_session_provider.dart';
// Files should import user_session_provider.dart directly to avoid circular dependencies.


// Existing providers
// Changed from StateNotifierProvider to NotifierProvider
final vaccinationScheduleProvider =
    NotifierProvider<VaccinationScheduleNotifier, List<VaccinationEvent>>(
        () => VaccinationScheduleNotifier());

final completedVaccinationsProvider = Provider<List<VaccinationEvent>>((ref) {
  final allVaccinations = ref.watch(vaccinationScheduleProvider);
  return allVaccinations.where((event) => event.isCompleted).toList();
});

final pendingVaccinationsProvider = Provider<List<VaccinationEvent>>((ref) {
  final allVaccinations = ref.watch(vaccinationScheduleProvider);
  return allVaccinations.where((event) => !event.isCompleted).toList();
});

final flutterLocalNotificationsPluginProvider = Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final plugin = ref.read(flutterLocalNotificationsPluginProvider);
  return NotificationService(plugin);
});

final batchScheduleServiceProvider = Provider<BatchScheduleService>((ref) {
  return BatchScheduleService();
});

// NEW: Provider for the last sync time
// (Moved from ProfileAndSettingsScreen.dart)
class LastSyncTimeNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null; // Initial state
  
  void setTime(DateTime time) {
    state = time;
  }
}
final lastSyncTimeProvider = NotifierProvider<LastSyncTimeNotifier, DateTime?>(() {
  return LastSyncTimeNotifier();
});
