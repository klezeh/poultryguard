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
import 'add_vaccination_record_screen.dart';
import '../services/notification_service.dart';

class VaccinationChecklistScreen extends ConsumerWidget {
  final BirdBatch batch;

  const VaccinationChecklistScreen({super.key, required this.batch});

  Future<void> _showNotification(BuildContext context, WidgetRef ref, BatchVaccinationEvent event) async {
    final FlutterLocalNotificationsPlugin localNotifications = ref.read(flutterLocalNotificationsPluginProvider);
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'vaccination_channel', 'Vaccination Reminders',
      channelDescription: 'Notifications for upcoming and completed vaccinations in PoultryGuard',
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

  bool _isVaccinationRecorded(String vaccinationName, String batchId) {
    final recordBox = Hive.box<VaccinationRecord>('vaccination_records');
    return recordBox.values.any(
      (record) => !record.isDeleted && record.batchName == batchId && record.vaccineName == vaccinationName,
    );
  }

  Future<void> _toggleCompletionStatus(BuildContext context, WidgetRef ref, BatchVaccinationEvent event) async {
    final batchScheduleService = ref.read(batchScheduleServiceProvider);
    final notificationService = ref.read(notificationServiceProvider);

    if (!event.isCompleted && !_isVaccinationRecorded(event.vaccinationName, event.batchId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add a record for "${event.vaccinationName}" first.'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'ADD RECORD',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddVaccinationRecordScreen(batchId: event.batchId, prefillVaccinationName: event.vaccinationName, prefillMethod: event.method)),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    if (event.isCompleted && _isVaccinationRecorded(event.vaccinationName, event.batchId)) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete the corresponding record from the Vaccination History list to un-mark this task.')));
      }
      return;
    }

    await batchScheduleService.markVaccinationAsCompleted(event.key, !event.isCompleted);
    await notificationService.rescheduleAllBatchNotifications();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${event.vaccinationName} marked as ${!event.isCompleted ? "Completed" : "Incomplete"}'),
        backgroundColor: !event.isCompleted ? Colors.green : Colors.grey,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color primaryColor = Colors.deepOrange;
    final batchScheduleService = ref.read(batchScheduleServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule for Batch: ${batch.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ValueListenableBuilder<Box<BatchVaccinationEvent>>(
        valueListenable: Hive.box<BatchVaccinationEvent>('batch_vaccinations').listenable(),
        builder: (context, box, _) {
          final scheduledEvents = batchScheduleService.getScheduleForBatch(batch.name)
              .where((event) => !event.isCompleted || event.scheduledDate.isAfter(DateTime.now().subtract(const Duration(days: 30))))
              .toList();
          
          if (scheduledEvents.isEmpty) {
            return const Center(child: Text('No scheduled vaccinations found for this batch.'));
          }

          final Map<String, List<BatchVaccinationEvent>> groupedEvents = {};
          for (var event in scheduledEvents) {
            final monthYear = DateFormat('MMMM yyyy').format(event.scheduledDate);
            if (!groupedEvents.containsKey(monthYear)) {
              groupedEvents[monthYear] = [];
            }
            groupedEvents[monthYear]!.add(event);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groupedEvents.keys.length,
            itemBuilder: (context, groupIndex) {
              final monthYear = groupedEvents.keys.elementAt(groupIndex);
              final eventsInMonth = groupedEvents[monthYear]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                    child: Text(monthYear, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  ),
                  ...eventsInMonth.map((event) {
                    final bool isOverdue = event.scheduledDate.isBefore(DateTime.now()) && !event.isCompleted;
                    final bool hasRecord = _isVaccinationRecorded(event.vaccinationName, event.batchId);
                    final int daysFromStart = event.scheduledDate.difference(batch.startDate).inDays;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      color: isOverdue ? Colors.red.shade50 : (event.isCompleted ? Colors.green.shade50 : Colors.white),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: event.isCompleted ? Colors.green : (isOverdue ? Colors.red : primaryColor.withOpacity(0.7)),
                          child: Icon(event.isCompleted ? Icons.check : (isOverdue ? Icons.warning_amber : Icons.vaccines), color: Colors.white),
                        ),
                        title: Text(
                          event.vaccinationName,
                          style: TextStyle(fontWeight: FontWeight.bold, decoration: event.isCompleted ? TextDecoration.lineThrough : TextDecoration.none, color: event.isCompleted ? Colors.green.shade800 : (isOverdue ? Colors.red.shade800 : Colors.black87)),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Due: ${DateFormat.yMMMd().format(event.scheduledDate)} (Day $daysFromStart)'),
                            Text('Method: ${event.method}'),
                            if (isOverdue)
                              Text('Status: OVERDUE!', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            if (hasRecord && !event.isCompleted)
                              Text('Record exists. Tap to mark as complete.', style: TextStyle(color: Colors.blue.shade700, fontStyle: FontStyle.italic)),
                          ],
                        ),
                        trailing: Checkbox(
                          value: event.isCompleted,
                          onChanged: (bool? newValue) {
                            if (newValue != null) {
                              _toggleCompletionStatus(context, ref, event);
                            }
                          },
                          activeColor: primaryColor,
                          checkColor: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}