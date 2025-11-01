import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:poultryguard/models/bird_batch.dart';
import 'package:poultryguard/models/daily_checklist_record.dart';
import 'package:poultryguard/providers/provider.dart';
import 'package:poultryguard/providers/user_session_provider.dart';
import 'package:poultryguard/screens/ProfileAndSettingsScreen.dart';
import 'package:poultryguard/screens/add_egg_collected_screen.dart';
import 'package:poultryguard/screens/add_egg_supplied_screen.dart';
import 'package:poultryguard/screens/AddExpenseDialog.dart';
import 'package:poultryguard/screens/auth_screen.dart';
import 'package:poultryguard/screens/checklist_log_observation.dart';
import 'package:poultryguard/screens/daily_checklist_screen.dart';
import 'package:poultryguard/screens/admin_user_creation_screen.dart';
import 'package:poultryguard/screens/egg_collection_list_screen.dart';
import 'package:poultryguard/screens/income_list_screen.dart';
import 'package:poultryguard/screens/batch_list_screen.dart';
import 'package:poultryguard/screens/dashboard_home.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:poultryguard/services/checklist_service.dart' as ChecklistService;
import 'package:poultryguard/services/data_sync_service.dart';
import 'package:poultryguard/widgets/notification_icon.dart';
import 'package:poultryguard/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poultryguard/models/expense.dart';
import 'package:poultryguard/models/income.dart';
import 'package:poultryguard/models/egg_collected.dart';
import 'package:poultryguard/models/poultry_task.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poultryguard/models/user_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  int _eggCollectionCount = 0;
  int _financeUpdates = 0;
  int _newBatchCount = 0;
  int _pendingChecklistTasks = 0;

  // --- FIX: Removed the old _dailyCompletionBox and added the new one ---
  final Box<BirdBatch> _batchBox = Hive.box<BirdBatch>('batches');
  final Box<Expense> _expenseBox = Hive.box<Expense>('expenses');
  final Box<Income> _incomeBox = Hive.box<Income>('income');
  final Box<EggCollected> _eggCollectedBox = Hive.box<EggCollected>('egg_collected');
  final Box<DailyChecklistRecord> _checklistRecordBox = Hive.box<DailyChecklistRecord>('daily_checklists');

  DateTime _lastViewedEggsTime = DateTime(2000);
  DateTime _lastViewedFinanceTime = DateTime(2000);
  DateTime _lastViewedBatchesTime = DateTime(2000);
  DateTime _lastViewedChecklistTime = DateTime(2000);

  final List<Widget> _screens = [
    const DashboardHome(),
    const EggCollectionListScreen(),
    const IncomeListScreen(),
    const BatchListScreen(),
  ];

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAndListenToBadgeData();
  }

  @override
  void dispose() {
    _expenseBox.listenable().removeListener(_updateBadgeCounts);
    _incomeBox.listenable().removeListener(_updateBadgeCounts);
    _eggCollectedBox.listenable().removeListener(_updateBadgeCounts);
    _batchBox.listenable().removeListener(_updateBadgeCounts);
    _checklistRecordBox.listenable().removeListener(_updateBadgeCounts); // Listen to new box
    super.dispose();
  }

  Future<void> _loadAndListenToBadgeData() async {
    final prefs = await SharedPreferences.getInstance();
    _lastViewedEggsTime = DateTime.tryParse(prefs.getString('lastViewedEggsTime') ?? '') ?? DateTime(2000);
    _lastViewedFinanceTime = DateTime.tryParse(prefs.getString('lastViewedFinanceTime') ?? '') ?? DateTime(2000);
    _lastViewedBatchesTime = DateTime.tryParse(prefs.getString('lastViewedBatchesTime') ?? '') ?? DateTime(2000);
    _lastViewedChecklistTime = DateTime.tryParse(prefs.getString('lastViewedChecklistTime') ?? '') ?? DateTime(2000);
    
    _updateBadgeCounts();

    _expenseBox.listenable().addListener(_updateBadgeCounts);
    _incomeBox.listenable().addListener(_updateBadgeCounts);
    _eggCollectedBox.listenable().addListener(_updateBadgeCounts);
    _batchBox.listenable().addListener(_updateBadgeCounts);
    _checklistRecordBox.listenable().addListener(_updateBadgeCounts); // Listen to new box
  }

  void _updateBadgeCounts() {
    if (!mounted) return;
    setState(() {
      _eggCollectionCount = _eggCollectedBox.values
          .where((egg) => (egg.createdAt ?? DateTime(2000)).isAfter(_lastViewedEggsTime))
          .length;
      int newExpenses = _expenseBox.values
          .where((expense) => expense.date.isAfter(_lastViewedFinanceTime))
          .length;
      int newIncomes = _incomeBox.values
          .where((income) => income.date.isAfter(_lastViewedFinanceTime))
          .length;
      _financeUpdates = newExpenses + newIncomes;
      _newBatchCount = _batchBox.values
          .where((batch) => batch.startDate.isAfter(_lastViewedBatchesTime))
          .length;
          
      _pendingChecklistTasks = 0;
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);

      // --- FIX: Updated logic to use the new DailyChecklistRecord model ---
      for (var batch in _batchBox.values.where((b) => !b.isDeleted)) {
          final List<PoultryTask> generatedTasks = ChecklistService.generatePoultryChecklist(batch);
          
          final todaysRecord = _checklistRecordBox.values.firstWhere(
            (record) => record.batchKey == batch.key && record.date == todayDateOnly,
            orElse: () => DailyChecklistRecord(batchKey: batch.key, date: todayDateOnly, taskCompletions: {}),
          );

          final savedCompletions = todaysRecord.taskCompletions;

          final incompleteTasksForBatch = generatedTasks
              .where((task) => !(savedCompletions[task.name] ?? false))
              .length;
          _pendingChecklistTasks += incompleteTasksForBatch;
      }
      
      final lastViewedChecklistDateFormatted = DateFormat('yyyy-MM-dd').format(_lastViewedChecklistTime.toLocal());
      if (lastViewedChecklistDateFormatted == DateFormat('yyyy-MM-dd').format(today.toLocal())) {
        _pendingChecklistTasks = 0;
      }
    });
  }

  void _clearBadge(int index) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    if (index == 1) {
      _lastViewedEggsTime = DateTime.now();
      await prefs.setString('lastViewedEggsTime', _lastViewedEggsTime.toIso8601String());
    } else if (index == 2) {
      _lastViewedFinanceTime = DateTime.now();
      await prefs.setString('lastViewedFinanceTime', _lastViewedFinanceTime.toIso8601String());
    } else if (index == 3) {
      _lastViewedBatchesTime = DateTime.now();
      await prefs.setString('lastViewedBatchesTime', _lastViewedBatchesTime.toIso8601String());
    }
    _updateBadgeCounts();
  }

  void _clearChecklistBadge() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lastViewedChecklistTime = DateTime.now();
      prefs.setString('lastViewedChecklistTime', _lastViewedChecklistTime.toIso8601String());
    });
    _updateBadgeCounts();
  }
  
  void _openStyledBottomSheet(Widget sheetContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: sheetContent,
        );
      },
    );
  }

  void _showBatchSelectionDialogForChecklist() {
    final batches = _batchBox.values.where((b) => !b.isDeleted).toList();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Text('Select a Batch for Checklist', textAlign: TextAlign.center, style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: batches.isEmpty
                ? Center(child: Text('No active batches available.\nPlease create one first.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])))
                : ListView.builder(
                    itemCount: batches.length,
                    itemBuilder: (context, index) {
                      final batch = batches[index];
                      return Card(
                        child: ListTile(
                          title: Text(batch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Qty: ${batch.quantity} • Started: ${DateFormat.yMMMd().format(batch.startDate)}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.deepOrange),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _clearChecklistBadge();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => DailyChecklistScreen(initialBatch: batch)),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(currentUserRoleProvider);
    final hasUnreadNotifications = ref.watch(hasUnreadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        actions: [
          const NotificationIcon(),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile_settings') {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileAndSettingsScreen()));
              } else if (value == 'logout') {
                // --- FIX: Robust logout logic ---
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (Route<dynamic> route) => false,
                );
                Future.delayed(const Duration(milliseconds: 300), () {
                  FirebaseAuth.instance.signOut();
                });
              } else if (value == 'manage_users') {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminUserCreationScreen()));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile_settings',
                child: Row(children: [Icon(Icons.settings, color: Colors.black54), SizedBox(width: 12), Text('Profile & Settings')]),
              ),
              if (userRole == UserRole.admin)
                const PopupMenuItem<String>(
                  value: 'manage_users',
                  child: Text('Manage Users'),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(children: [Icon(Icons.logout, color: Colors.redAccent), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.redAccent))]),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.deepOrange,
        onRefresh: () async {
          print('Pull-to-refresh triggered. Starting manual sync...');
          await ref.read(dataSyncServiceProvider).triggerManualSync();
          print('Manual sync complete.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync with cloud complete!'), duration: Duration(seconds: 2)));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _selectedIndex,
        height: 60.0,
        items: <Widget>[
          badges.Badge(
            showBadge: hasUnreadNotifications,
            position: badges.BadgePosition.topEnd(top: -12, end: -12),
            child: const Icon(Icons.dashboard, size: 30, color: Colors.white),
          ),
          badges.Badge(
            showBadge: _eggCollectionCount > 0,
            badgeContent: Text('$_eggCollectionCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: const Icon(Icons.egg, size: 30, color: Colors.white),
          ),
          badges.Badge(
            showBadge: _financeUpdates > 0,
            badgeContent: Text('$_financeUpdates', style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: const Icon(Icons.attach_money, size: 30, color: Colors.white),
          ),
          badges.Badge(
            showBadge: _newBatchCount > 0,
            badgeContent: Text('$_newBatchCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: const Icon(Icons.batch_prediction, size: 30, color: Colors.white),
          ),
        ],
        color: Colors.deepOrange,
        buttonBackgroundColor: Colors.deepOrangeAccent,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          _clearBadge(index);
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  SpeedDialChild _buildSpeedDialChild({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SpeedDialChild(
      child: Icon(icon),
      label: label,
      labelBackgroundColor: Colors.deepOrange,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      onTap: onTap,
    );
  }

  Widget? _buildFAB() {
    switch (_selectedIndex) {
      case 0:
        return SpeedDial(
          icon: Icons.add,
          iconTheme: const IconThemeData(color: Colors.white),
          label: const Text("Routine", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          activeIcon: Icons.close,
          backgroundColor: Colors.deepOrange,
          overlayOpacity: 0.83,
          spacing: 12,
          spaceBetweenChildren: 8,
          children: [
            _buildSpeedDialChild(icon: Icons.receipt, label: 'Report Expenses', onTap: () => _openStyledBottomSheet(const AddExpenseDialog())),
            _buildSpeedDialChild(icon: Icons.delivery_dining, label: 'Ship Eggs', onTap: () => _openStyledBottomSheet(const AddEggSuppliedScreen())),
            _buildSpeedDialChild(icon: Icons.egg, label: 'Collect Eggs', onTap: () => _openStyledBottomSheet(const AddEggCollectedScreen())),
            _buildSpeedDialChild(icon: Icons.notes, label: 'Observation', onTap: () => _openStyledBottomSheet(const AddObservationScreen())),
            SpeedDialChild(
              child: _pendingChecklistTasks > 0
                  ? badges.Badge(
                      badgeContent: Text('$_pendingChecklistTasks', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      child: const Icon(Icons.checklist),
                    )
                  : const Icon(Icons.checklist),
              label: 'Checklist',
              labelBackgroundColor: Colors.deepOrange,
              labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              onTap: () => _showBatchSelectionDialogForChecklist(),
            ),
          ],
        );
      case 1:
        return FloatingActionButton(
          backgroundColor: Colors.deepOrange,
          child: const Icon(Icons.add),
          onPressed: () => _openStyledBottomSheet(const AddEggCollectedScreen()),
        );
      default:
        return null;
    }
  }
}

extension DateTimeParsing on String {
  DateTime toDateTime() {
    try {
      return DateTime.parse(this);
    } catch (e) {
      print('Error parsing date string: $this - $e');
      return DateTime(2000);
    }
  }
}