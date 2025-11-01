import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/screens/AddExpenseDialog.dart';
import 'package:poultryguard/screens/checklist_log_feed.dart';
import 'package:poultryguard/screens/checklist_log_temperature.dart';
import 'package:poultryguard/screens/vaccination_screen.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:poultryguard/models/daily_checklist_record.dart';
import 'firebase_options.dart';
import 'models/user_role.dart';
import 'package:poultryguard/providers/theme_provider.dart';
import 'models/expense.dart';
import 'models/income.dart';
import 'models/bird_batch.dart';
import 'models/poultry_task.dart';
import 'models/vaccination_record.dart';
import 'models/egg_collected.dart';
import 'models/egg_supplied.dart';
import 'models/environment_record.dart';
import 'models/mortality_record.dart';
import 'models/isolation_record.dart';
import 'models/release_log.dart';
import 'models/feed_used.dart';
import 'models/lighting_record.dart';
import 'models/temperature_humidity_record.dart';
import 'models/observation_record.dart';
import 'models/batch_vaccination_event.dart';
import 'utils/hive_adapters/timestamp_adapter.dart';

import 'providers/provider.dart';
import 'providers/user_session_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/farm_setup_screen.dart';
import 'screens/checklist_log_lighting.dart';
import 'screens/checklist_log_observation.dart';
import 'screens/add_income_screen.dart';
import 'screens/income_list_screen.dart';
import 'screens/add_egg_collected_screen.dart';
import 'screens/add_egg_supplied_screen.dart';
import 'screens/egg_collection_list_screen.dart';
import 'screens/egg_supplied_list_screen.dart';
import 'screens/new_batch_screen.dart';
import 'screens/batch_list_screen.dart';

import 'screens/add_mortality_screen.dart';
import 'screens/add_isolation_screen.dart';
import 'screens/release_from_isolation_screen.dart';
import 'screens/mortality_report_screen.dart';
import 'screens/remove_flock_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/daily_checklist_screen.dart';
import 'screens/notification_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
Map<String, dynamic> appConfig = {};

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Background notification tapped: ${notificationResponse.payload}');
}

Future<void> registerAdapterSafely<T>(TypeAdapter<T> adapter, int typeId) async {
  if (!Hive.isAdapterRegistered(typeId)) {
    Hive.registerAdapter(adapter);
  }
}

Future<void> openBoxSafely<T>(String name) async {
  try {
    await Hive.openBox<T>(name);
  } catch (e) {
    print('Error opening box "$name": $e');
  }
}

void main() async { // Added async
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final configString = await rootBundle.loadString('assets/config/config.json');
      appConfig = json.decode(configString);
      print('App configuration loaded successfully.');
    } catch (e) {
      print('Error loading app configuration: $e');
    }

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // --- Corrected FCM Setup Location ---
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $fcmToken");

    await Hive.initFlutter();

    // Register Hive adapters
    await registerAdapterSafely(BirdBatchAdapter(), 0);
    await registerAdapterSafely(BirdTypeAdapter(), 1);
    await registerAdapterSafely(VaccinationRecordAdapter(), 2);
    await registerAdapterSafely(IncomeAdapter(), 3);
    await registerAdapterSafely(ExpenseAdapter(), 4);
    await registerAdapterSafely(PoultryTaskAdapter(), 5);
    await registerAdapterSafely(EggCollectedAdapter(), 6);
    await registerAdapterSafely(EggSuppliedAdapter(), 7);
    await registerAdapterSafely(EnvironmentRecordAdapter(), 8);
    await registerAdapterSafely(MortalityRecordAdapter(), 9);
    await registerAdapterSafely(IsolationRecordAdapter(), 10);
    await registerAdapterSafely(FeedUsedAdapter(), 11);
    await registerAdapterSafely(LightingRecordAdapter(), 12);
    await registerAdapterSafely(BatchVaccinationEventAdapter(), 13);
    await registerAdapterSafely(ObservationRecordAdapter(), 14);
    await registerAdapterSafely(ReleaseLogAdapter(), 15);
    await registerAdapterSafely(TemperatureHumidityRecordAdapter(), 16);
    await registerAdapterSafely(TimestampAdapter(), 17);
    await registerAdapterSafely(UserRoleAdapter(), 18);
    await registerAdapterSafely(DailyChecklistRecordAdapter(), 19);

    // Open Hive boxes
    await openBoxSafely('filters');
    await openBoxSafely<BirdBatch>('batches');
    await openBoxSafely<PoultryTask>('poultryTasks');
    await openBoxSafely<VaccinationRecord>('vaccination_records');
    await openBoxSafely<Expense>('expenses');
    await openBoxSafely<Income>('income');
    await openBoxSafely<EggCollected>('egg_collected');
    await openBoxSafely<EggSupplied>('egg_supplied');
    await openBoxSafely<MortalityRecord>('mortality');
    await openBoxSafely<IsolationRecord>('isolation');
    await openBoxSafely<ReleaseLog>('release_log');
    await openBoxSafely<EnvironmentRecord>('environment_records');
    // Note: 'daily_task_completion' box is no longer needed after refactor
    await openBoxSafely<BatchVaccinationEvent>('batch_vaccinations');
    await openBoxSafely<FeedUsed>('feed_used');
    await openBoxSafely<LightingRecord>('lighting_records');
    await openBoxSafely<TemperatureHumidityRecord>('temperature_humidity_records');
    await openBoxSafely<ObservationRecord>('observation_records');
    await openBoxSafely<DailyChecklistRecord>('daily_checklists');

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Dubai'));
    } catch (e) {
      print("Error setting local timezone: $e. Falling back to UTC.");
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }

    // Request permissions before initializing local notifications
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Foreground notification tapped: ${response.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    runApp(const ProviderScope(child: MyApp()));
  }, (error, stackTrace) {
    print('Uncaught error: $error');
  });
}

// --- FIX: Changed to ConsumerWidget ---
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers for live state changes
    final userSession = ref.watch(userSessionProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    // You can still listen for specific transitions, like login
    ref.listen<UserSession>(userSessionProvider, (prev, next) {
      final wasLoggedIn = prev?.isAuthenticated ?? false;
      final isLoggedIn = next.isAuthenticated;
      if (!wasLoggedIn && isLoggedIn) {
        if (ProviderScope.containerOf(context).exists(notificationServiceProvider)) {
          ref.read(notificationServiceProvider).rescheduleAllBatchNotifications();
        }
      }
    });

    return MaterialApp(
      title: 'PoultryGuard',
      // --- FIX: Connect MaterialApp to the theme provider ---
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepOrange,
        primaryColor: Colors.deepOrangeAccent,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
        ),
         floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.deepOrangeAccent,
          foregroundColor: Colors.white,
        ),
      ),
      // --- END OF THEME FIX ---
      
      home: userSession.isLoading
          ? const SplashScreen()
          : userSession.isAuthenticated
              ? (userSession.farmId == null || userSession.farmId!.isEmpty
                  ? const FarmSetupScreen()
                  : const DashboardScreen())
              : const AuthScreen(),
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/add-expense': (_) => const AddExpenseDialog(),
        '/add-income': (_) => const AddIncomeScreen(),
        '/view-income': (_) => const IncomeListScreen(),
        '/add-egg-collected': (_) => const AddEggCollectedScreen(),
        '/add-egg-supplied': (_) => const AddEggSuppliedScreen(),
        '/egg-collected-list': (_) => const EggCollectionListScreen(),
        '/egg-supplied-list': (_) => const EggSuppliedListScreen(),
        '/bird-batches': (_) => const NewBatchScreen(),
        '/view-batches': (_) => const BatchListScreen(),
        '/vaccination': (_) => const VaccinationScreen(),
        '/mortality': (_) => AddMortalityScreen(),
        '/isolation': (_) => AddIsolationScreen(),
        '/release': (_) => const ReleaseFromIsolationScreen(),
        '/mortality_report': (_) => MortalityReportScreen(),
        '/remove-flock': (_) => const RemoveFlockScreen(),
        '/expense-list': (_) => const ExpenseListScreen(),
        '/daily-checklist': (_) => const DailyChecklistScreen(initialBatch: null),
        '/add-feed-used': (_) => const AddFeedUsedScreen(),
        '/add-lighting': (_) => const AddLightingScreen(),
        '/add-temperature-humidity': (_) => const AddTemperatureHumidityScreen(),
        '/add-observation': (_) => const AddObservationScreen(),
        '/farm-setup': (_) => const FarmSetupScreen(),
        '/notifications': (_) => const NotificationsScreen(),
      },
    );
  }
}