import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:poultryguard/providers/provider.dart';
import '../models/batch_vaccination_event.dart';
import '../models/vaccination_record.dart';
import '../models/bird_batch.dart';
import '../services/batch_schedule_service.dart';
import '../screens/add_vaccination_record_screen.dart';
import '../services/notification_service.dart';

class VaccinationChecklistScreen extends ConsumerWidget {
  final BirdBatch batch;

  const VaccinationChecklistScreen({super.key, required this.batch});

  Future<void> _showNotification(BuildContext context, WidgetRef ref, BatchVaccinationEvent event) async {
    final FlutterLocalNotificationsPlugin localNotifications = ref.read(flutterLocalNotificationsPluginProvider);
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'vaccination_channel', 'Vaccination Reminders',
      channelDescription: 'Notifications for upcoming and completed vaccinations in Farm Space',
      importance: Importance.max, priority: Priority.high, ticker: 'Vaccination Update',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    await localNotifications.show(
      event.key.hashCode,
      'Vaccination Status Updated for Batch ${event.batchId}',
      '${event.vaccinationName} has been marked as ${event.isCompleted ? 'completed' : 'pending'}.',
      platformChannelSpecifics,
      payload: 'batchId:${event.batchId},vaccineName:${event.vaccinationName}',
    );
  }

  // FIX: Added a check for !record.isDeleted
  bool _isVaccinationRecorded(String vaccinationName, String batchId) {
    final recordBox = Hive.box<VaccinationRecord>('vaccination_records');
    return recordBox.values.any(
      (record) => !record.isDeleted && record.batchName == batchId && record.vaccineName == vaccinationName,
    );
  }

  // FIX: Added logic to prevent inconsistent states and trigger sync
  Future<void> _toggleCompletionStatus(BuildContext context, WidgetRef ref, BatchVaccinationEvent event) async {
    final batchScheduleService = ref.read(batchScheduleServiceProvider);
    final notificationService = ref.read(notificationServiceProvider);

    // Rule 1: User cannot check a task as 'complete' unless a record exists.
    if (!event.isCompleted && !_isVaccinationRecorded(event.vaccinationName, event.batchId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add a record for "${event.vaccinationName}" in Vaccination Records first.'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'ADD RECORD',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddVaccinationRecordScreen(
                      batchId: event.batchId,
                      prefillVaccinationName: event.vaccinationName,
                      prefillMethod: event.method,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    // Rule 2: User cannot un-check a task if the record still exists.
    if (event.isCompleted && _isVaccinationRecorded(event.vaccinationName, event.batchId)) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete the corresponding record from the Vaccination History list to un-mark this task.')));
      }
      return;
    }

    // If all rules pass, toggle the completion status
    await batchScheduleService.markVaccinationAsCompleted(event.key, !event.isCompleted);
    await notificationService.rescheduleAllBatchNotifications();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${event.vaccinationName} marked as ${!event.isCompleted ? "Completed" : "Incomplete"}'),
          backgroundColor: !event.isCompleted ? Colors.green : Colors.grey,
        ),
      );
    }
    // _showNotification(context, ref, event); // This was already correctly commented out.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final batchScheduleService = ref.read(batchScheduleServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Vaccination Checklist for ${batch.name}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<Box<BatchVaccinationEvent>>(
        valueListenable: Hive.box<BatchVaccinationEvent>('batch_vaccinations').listenable(),
        builder: (context, box, _) {
          final List<BatchVaccinationEvent> vaccinationSchedule = batchScheduleService.getScheduleForBatch(batch.name);

          if (vaccinationSchedule.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'No scheduled vaccinations found for batch "${batch.name}".',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Ensure the batch is added correctly and the schedule is generated.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final pendingCount = vaccinationSchedule.where((event) => !event.isCompleted).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$pendingCount vaccinations pending',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12.0),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.builder(
                    itemCount: vaccinationSchedule.length,
                    itemBuilder: (context, index) {
                      final event = vaccinationSchedule[index];
                      final int daysFromStart = event.scheduledDate.difference(batch.startDate).inDays;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        child: CheckboxListTile(
                          value: event.isCompleted,
                          onChanged: (bool? newValue) async {
                            if (newValue != null) {
                              await _toggleCompletionStatus(context, ref, event);
                            }
                          },
                          title: Text(
                            event.vaccinationName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                              color: event.isCompleted ? Colors.grey[600] : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Due: ${DateFormat.yMMMd().format(event.scheduledDate)} (Day $daysFromStart)'),
                              Text('Method: ${event.method}'),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          tileColor: event.isCompleted ? Colors.green.withOpacity(0.05) : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}