// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Correct import for flutter_local_notifications
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart'; // For formatting dates in notification body
import 'package:hive/hive.dart'; // To access Hive boxes
import '../models/batch_vaccination_event.dart'; // Import your BatchVaccinationEvent

class NotificationService {
  // This instance of FlutterLocalNotificationsPlugin is now passed via the constructor
  // from main.dart, ensuring it's the globally initialized one.
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  // The constructor now requires the FlutterLocalNotificationsPlugin instance.
  NotificationService(this._flutterLocalNotificationsPlugin);

  /// Schedules a single notification for a vaccination event.
  /// This should be called when a batch schedule is generated or updated.
  Future<void> scheduleVaccinationNotification(
    BatchVaccinationEvent event,
    int notificationId, // A unique ID for this specific notification
  ) async {
    // Calculate the notification date: 1 week before the scheduled vaccination date.
    final notificationDate = event.scheduledDate.subtract(const Duration(days: 7));

    // Only schedule the notification if:
    // 1. The calculated notification date is in the future.
    // 2. The vaccination event is not yet marked as completed.
    if (notificationDate.isAfter(DateTime.now()) && !event.isCompleted) {
      // Determine the exact time for the notification in the local timezone.
      // We'll aim for 9 AM on the notification day.
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDayAtTime = tz.TZDateTime(
        tz.local,
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        9, // Schedule at 9 AM local time
        0,
        0,
      );

      // If the calculated 9 AM time is in the past (e.g., if the app starts
      // after 9 AM on a day where a notification was already due),
      // schedule it to fire immediately (e.g., in 10 seconds) to ensure it's delivered.
      if (scheduledDayAtTime.isBefore(now)) {
        scheduledDayAtTime = now.add(const Duration(seconds: 10));
      }

      // Define Android-specific notification details.
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'vaccination_channel', // This ID must match the channel ID initialized in main.dart.
        'Vaccination Reminders', // The channel name visible to the user in Android settings.
        channelDescription: 'Reminders for upcoming poultry vaccinations in Farm Space.', // Channel description.
        importance: Importance.max, // Highest importance to make the notification prominent.
        priority: Priority.high, // High priority for immediate attention.
        ticker: 'Vaccination Alert', // Text that briefly appears in the status bar.
        // You can also specify a custom small icon here (e.g., icon: 'my_notification_icon')
        // Ensure 'my_notification_icon.png' is in android/app/src/main/res/drawable.
      );

      // Define iOS/macOS-specific notification details.
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        // iOS specific settings, such as custom sound, badge, or how alerts are presented.
        // For example: presentAlert: true, presentBadge: true, presentSound: true,
      );

      // Combine platform-specific details into a single object.
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Schedule the notification using zonedSchedule.
      // IMPORTANT FIX: androidScheduleMode is now included as it is required.
      // It is set to AndroidScheduleMode.inexact to bypass strict exact alarm permissions.
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId, // Unique ID for this notification.
        'Upcoming Vaccination for Batch ${event.batchId}', // Notification title.
        // Bypassing potential error by using null-aware operator for vaccinationName
        '${event.vaccinationName ?? 'Unknown Vaccine'} for Batch ${event.batchId} is due on ${DateFormat.yMMMd().format(event.scheduledDate)}. Method: ${event.method}.', // Notification body.
        scheduledDayAtTime, // The precise scheduled date and time.
        platformChannelSpecifics, // Platform-specific details.
        androidScheduleMode: AndroidScheduleMode.inexact, // Re-added as required, set to inexact
        payload: 'batchId:${event.batchId},vaccineName:${event.vaccinationName ?? 'Unknown Vaccine'}', // Optional payload string for handling taps.
      );
      print('Scheduled notification for ${event.vaccinationName ?? 'Unknown Vaccine'} (ID: $notificationId) on $scheduledDayAtTime');
    } else {
      print('Notification for ${event.vaccinationName ?? 'Unknown Vaccine'} (ID: ${_generateNotificationId(event)}) not scheduled (already completed or date in past).');
    }
  }

  /// Cancels a specific notification by its ID.
  Future<void> cancelNotification(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    print('Cancelled notification with ID: $notificationId');
  }

  /// Cancels all pending notifications.
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('Cancelled all notifications.');
  }

  // Helper to generate a unique integer ID for each notification.
  // This ID is generated by taking the absolute hash code of a combined string
  // of batchId and vaccinationName, ensuring a consistent ID for the same event.
  int _generateNotificationId(BatchVaccinationEvent event) {
    return '${event.batchId}-${event.vaccinationName ?? 'Unknown Vaccine'}'.hashCode.abs();
  }

  /// Re-schedules all current incomplete batch vaccination notifications.
  /// This method is designed to be called, for example, on app startup or
  /// whenever the vaccination schedule data changes, to ensure all relevant
  /// reminders are active.
  Future<void> rescheduleAllBatchNotifications() async {
    // First, cancel all existing scheduled notifications to prevent duplicates.
    await cancelAllNotifications(); 

    // Access the Hive box that stores BatchVaccinationEvent objects.
    final batchVaccinationBox = Hive.box<BatchVaccinationEvent>('batch_vaccinations');
    for (var event in batchVaccinationBox.values) {
      if (!event.isCompleted) { // Only schedule notifications for events that are not yet completed.
        await scheduleVaccinationNotification(event, _generateNotificationId(event));
      }
    }
    print('Rescheduled notifications for all incomplete batch vaccinations.');
  }
}
