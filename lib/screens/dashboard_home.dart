import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Import all necessary models
import 'package:poultryguard/models/lighting_record.dart';
import 'package:poultryguard/models/egg_collected.dart';
import 'package:poultryguard/models/egg_supplied.dart';
import 'package:poultryguard/models/feed_used.dart';
import 'package:poultryguard/models/temperature_humidity_record.dart';
import 'package:poultryguard/models/batch_vaccination_event.dart';
import 'package:poultryguard/models/bird_batch.dart';
import 'package:poultryguard/models/mortality_record.dart';
import 'package:poultryguard/models/isolation_record.dart';

import 'lighting_program_screen.dart';

// --- Lighting Program Service ---
class LightingProgramService {
  double getTargetHours(int ageInDays) {
    if (ageInDays <= 3) return 23.0;
    if (ageInDays <= 7) return 20.0;
    if (ageInDays <= 14) return 18.0;
    if (ageInDays <= 21) return 16.0;
    if (ageInDays <= 126) return 12.0;
    if (ageInDays <= 133) return 13.0;
    if (ageInDays <= 140) return 14.0;
    if (ageInDays <= 147) return 15.0;
    if (ageInDays <= 154) return 15.5;
    if (ageInDays <= 161) return 16.0;
    if (ageInDays <= 168) return 16.5;
    return 17.0;
  }
}

class DashboardHome extends ConsumerStatefulWidget {
  const DashboardHome({super.key});

  @override
  ConsumerState<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<DashboardHome> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoSwipeTimer;

  // Hive Box instances
  late final Box<EggCollected> _eggCollectedBox;
  late final Box<EggSupplied> _eggSuppliedBox;
  late final Box<FeedUsed> _feedUsedBox;
  late final Box<TemperatureHumidityRecord> _tempHumidBox;
  late final Box<BatchVaccinationEvent> _batchVaccinationEventBox;
  late final Box<BirdBatch> _birdBatchBox;
  late final Box<MortalityRecord> _mortalityRecordBox;
  late final Box<IsolationRecord> _isolationRecordBox;
  late final Box<LightingRecord> _lightingRecordBox;
  
  final LightingProgramService _lightingService = LightingProgramService();

  // State variables
  int _totalEggsCollected = 0, _totalEggsShipped = 0, _riskyTemperatureDays = 0;
  int _missedVaccinations = 0, _upcomingVaccinations = 0, _dueTodayVaccinations = 0, _totalLiveBirds = 0;
  int _totalMortality = 0, _totalIsolatedBirds = 0, _totalBatches = 0;
  double _totalFeedUsed = 0.0, _fcr = 0.0, _avgTemperature = 0.0, _avgHumidity = 0.0;
  double _mortalityPercentage = 0.0, _isolationPercentage = 0.0, _henDayEggProduction = 0.0;
  double _eggsPerHenHoused = 0.0, _kgFeedPerEgg = 0.0;
  String _litterSuggestionStatus = "N/A", _batchForAnalytics = "All Batches";
  double _todaysLightDuration = 0.0, _avgLightDuration = 0.0, _targetLightDuration = 16.0;
  String _consistencyStatus = "N/A";
  Color _consistencyColor = Colors.grey;

  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  int _filteredDaysCount = 30;

  static const double _averageEggWeightKg = 0.06;

  @override
  void initState() {
    super.initState();
    _eggCollectedBox = Hive.box<EggCollected>('egg_collected');
    _eggSuppliedBox = Hive.box<EggSupplied>('egg_supplied');
    _feedUsedBox = Hive.box<FeedUsed>('feed_used');
    _tempHumidBox = Hive.box<TemperatureHumidityRecord>('temperature_humidity_records');
    _batchVaccinationEventBox = Hive.box<BatchVaccinationEvent>('batch_vaccinations');
    _birdBatchBox = Hive.box<BirdBatch>('batches');
    _mortalityRecordBox = Hive.box<MortalityRecord>('mortality');
    _isolationRecordBox = Hive.box<IsolationRecord>('isolation');
    _lightingRecordBox = Hive.box<LightingRecord>('lighting_records');

    _updateDashboardMetrics();
    _startAutoSwipe();

    // Add listeners
    final boxes = [_eggCollectedBox, _eggSuppliedBox, _feedUsedBox, _tempHumidBox, _batchVaccinationEventBox, _birdBatchBox, _mortalityRecordBox, _isolationRecordBox, _lightingRecordBox];
    for (var box in boxes) {
      box.listenable().addListener(_updateDashboardMetrics);
    }
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    final boxes = [_eggCollectedBox, _eggSuppliedBox, _feedUsedBox, _tempHumidBox, _batchVaccinationEventBox, _birdBatchBox, _mortalityRecordBox, _isolationRecordBox, _lightingRecordBox];
    for (var box in boxes) {
      box.listenable().removeListener(_updateDashboardMetrics);
    }
    super.dispose();
  }
  
  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_pageController.hasClients && mounted) {
        final cardCount = _metricCards.length;
        if (cardCount == 0) return;
        _currentIndex = (_currentIndex + 1) % cardCount;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.deepOrange,
            colorScheme: const ColorScheme.light(primary: Colors.deepOrange),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
        _filteredDaysCount = picked.end.difference(picked.start).inDays + 1;
        _updateDashboardMetrics();
      });
    }
  }

  void _updateDashboardMetrics() {
    if (!mounted) return;

    final DateTime filterStart = _selectedDateRange.start;
    final DateTime filterEnd = DateTime(_selectedDateRange.end.year, _selectedDateRange.end.month, _selectedDateRange.end.day, 23, 59, 59);
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    // Define the end of the 2-week future period for vaccinations
    final twoWeeksFromToday = startOfToday.add(const Duration(days: 14));


    BirdBatch? largestBatch;
    int maxQuantity = 0;
    for (var batch in _birdBatchBox.values) {
      if (!batch.isDeleted && batch.type == BirdType.layers && batch.quantity > maxQuantity) {
        maxQuantity = batch.quantity;
        largestBatch = batch;
      }
    }

    setState(() {
      _batchForAnalytics = largestBatch?.name ?? "All Batches";
      
      // EGG & FEED
      _totalEggsCollected = _eggCollectedBox.values.where((r) => !r.date.isBefore(filterStart) && r.date.isBefore(filterEnd)).fold(0, (s, r) => s + r.count);
      _totalEggsShipped = _eggSuppliedBox.values.where((r) => !r.date.isBefore(filterStart) && r.date.isBefore(filterEnd)).fold(0, (s, r) => s + r.quantity);
      _totalFeedUsed = _feedUsedBox.values.where((r) => !r.date.isBefore(filterStart) && r.date.isBefore(filterEnd)).fold(0.0, (s, r) => s + r.quantityKg);
      _fcr = (_totalEggsCollected * _averageEggWeightKg > 0) ? (_totalFeedUsed / (_totalEggsCollected * _averageEggWeightKg)) : 0.0;
      _kgFeedPerEgg = (_totalEggsCollected > 0) ? (_totalFeedUsed / _totalEggsCollected) : 0.0;

      // FLOCK STATS
      _totalBatches = _birdBatchBox.values.where((b) => !b.isDeleted).length;
      _totalLiveBirds = _birdBatchBox.values.where((b) => !b.isDeleted).fold(0, (s, b) => s + b.quantity);
      _totalMortality = _mortalityRecordBox.values.where((r) => !r.date.isBefore(filterStart) && r.date.isBefore(filterEnd)).fold(0, (s, r) => s + r.numberOfBirds);
      _totalIsolatedBirds = _isolationRecordBox.values.where((r) => r.isActive && !r.isolationDate.isBefore(filterStart) && r.isolationDate.isBefore(filterEnd)).fold(0, (s, r) => s + r.numberOfBirds);
      final double totalOriginalFlock = (_totalLiveBirds + _totalIsolatedBirds + _totalMortality).toDouble();
      _mortalityPercentage = totalOriginalFlock > 0 ? (_totalMortality / totalOriginalFlock) * 100 : 0.0;
      _isolationPercentage = totalOriginalFlock > 0 ? (_totalIsolatedBirds / totalOriginalFlock) * 100 : 0.0;

      // PRODUCTIVITY
      final int eggsTodayCount = _eggCollectedBox.values.where((r) => r.date.year == today.year && r.date.month == today.month && r.date.day == today.day).fold(0, (s, r) => s + r.count);
      _henDayEggProduction = (_totalLiveBirds > 0) ? (eggsTodayCount / _totalLiveBirds) * 100 : 0.0;
      
      if (largestBatch != null) {
        final int totalMortalityForBatch = _mortalityRecordBox.values.where((m) => m.batchName == largestBatch!.name).fold(0, (s, m) => s + m.numberOfBirds);
        final int totalReleasedForBatch = _isolationRecordBox.values.where((i) => i.batchName == largestBatch!.name && !i.isActive).length;
        final int originalQuantity = largestBatch.quantity + totalMortalityForBatch + totalReleasedForBatch;
        final int allTimeEggsForBatch = _eggCollectedBox.values.where((e) => e.batchName == largestBatch!.name).fold(0, (s, e) => s + e.count);
        _eggsPerHenHoused = (originalQuantity > 0) ? (allTimeEggsForBatch / originalQuantity) : 0.0;
        _targetLightDuration = _lightingService.getTargetHours(largestBatch.ageInDays);
      } else { 
        _eggsPerHenHoused = 0.0;
        _targetLightDuration = 16.0; // Default if no batches
      }

      // ENVIRONMENT
      final tempHumidRecordsInPeriod = _tempHumidBox.values.where((r) => !r.date.isBefore(filterStart) && r.date.isBefore(filterEnd)).toList();
      _riskyTemperatureDays = tempHumidRecordsInPeriod.where((r) => r.temperatureC < 20 || r.temperatureC > 30 || r.humidityPercent < 50 || r.humidityPercent > 70).length;
      if (tempHumidRecordsInPeriod.isNotEmpty) {
        _avgTemperature = tempHumidRecordsInPeriod.fold(0.0, (s, r) => s + r.temperatureC) / tempHumidRecordsInPeriod.length;
        _avgHumidity = tempHumidRecordsInPeriod.fold(0.0, (s, r) => s + r.humidityPercent) / tempHumidRecordsInPeriod.length;
      } else { _avgTemperature = 0.0; _avgHumidity = 0.0; }
      
      // VACCINATION
      // For missed vaccinations, use the current date range
      _missedVaccinations = _batchVaccinationEventBox.values.where((event) {
        final parentBatch = _birdBatchBox.values.firstWhere((b) => b.name == event.batchId, orElse: () => BirdBatch(name: '', quantity: 0, startDate: DateTime.now()));
        return !parentBatch.isDeleted && !event.isCompleted && event.scheduledDate.isBefore(startOfToday) && !event.scheduledDate.isBefore(filterStart) && event.scheduledDate.isBefore(filterEnd);
      }).length;

      // For upcoming vaccinations (next 2 weeks)
      _upcomingVaccinations = _batchVaccinationEventBox.values.where((event) {
        final parentBatch = _birdBatchBox.values.firstWhere((b) => b.name == event.batchId, orElse: () => BirdBatch(name: '', quantity: 0, startDate: DateTime.now()));
        return !parentBatch.isDeleted && !event.isCompleted && !event.scheduledDate.isBefore(startOfToday) && event.scheduledDate.isBefore(twoWeeksFromToday);
      }).length;

      // For vaccinations due today
      _dueTodayVaccinations = _batchVaccinationEventBox.values.where((event) {
        final parentBatch = _birdBatchBox.values.firstWhere((b) => b.name == event.batchId, orElse: () => BirdBatch(name: '', quantity: 0, startDate: DateTime.now()));
        return !parentBatch.isDeleted && !event.isCompleted && event.scheduledDate.year == startOfToday.year && event.scheduledDate.month == startOfToday.month && event.scheduledDate.day == startOfToday.day;
      }).length;
      
      // LITTER
      final lastEnv = _tempHumidBox.values.isNotEmpty ? _tempHumidBox.values.reduce((a, b) => a.date.isAfter(b.date) ? a : b) : null;
      if (lastEnv != null) { final daysSince = DateTime.now().difference(lastEnv.date).inDays; _litterSuggestionStatus = "Last Checked: $daysSince days ago"; if (daysSince > 7) _litterSuggestionStatus = "Consider checking litter (Last: $daysSince days ago)"; } else { _litterSuggestionStatus = "No environment data yet"; }
      
      // LIGHTING PROGRAM
      final lightingRecordsInPeriod = _lightingRecordBox.values.where((r) => !r.date.isBefore(filterStart) && r.date.isBefore(filterEnd)).toList();
      LightingRecord? mostRecentToday;
      for (var rec in _lightingRecordBox.values.toList().reversed) {
          if (rec.date.year == today.year && rec.date.month == today.month && rec.date.day == today.day) {
            mostRecentToday = rec;
            break;
          }
      }
      if(mostRecentToday != null) {
          _todaysLightDuration = mostRecentToday.lightsOnHours;
      } else {
        _todaysLightDuration = 0.0;
      }
      if (lightingRecordsInPeriod.isNotEmpty) {
        final durations = lightingRecordsInPeriod.map((r) => r.lightsOnHours).toList();
        _avgLightDuration = durations.reduce((a, b) => a + b) / durations.length;
        if (durations.length > 1) {
            final mean = _avgLightDuration;
            final variance = durations.map((d) => pow(d - mean, 2)).reduce((a, b) => a + b) / (durations.length - 1);
            final stdDev = sqrt(variance);
            if (stdDev < 0.25) { _consistencyStatus = "Excellent"; _consistencyColor = Colors.green.shade700; } 
            else if (stdDev < 0.75) { _consistencyStatus = "Good"; _consistencyColor = Colors.orange.shade800; } 
            else { _consistencyStatus = "Poor"; _consistencyColor = Colors.red.shade700; }
        } else {
            _consistencyStatus = "Good"; _consistencyColor = Colors.orange.shade800;
        }
      } else {
        _avgLightDuration = 0;
        _consistencyStatus = "Not Enough Data";
        _consistencyColor = Colors.grey;
      }
    });
  }
  
  static Widget _buildCard(String title, {required Widget content, required IconData icon, VoidCallback? onTap}) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.deepOrange),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    content,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> get _metricCards => [
    _buildCard(
      "Flock Health",
      icon: Icons.favorite_border,
      content: Text(
        "Live Birds: $_totalLiveBirds in $_totalBatches Batches\n"
        "Mortality (${_filteredDaysCount}d): $_totalMortality (${_mortalityPercentage.toStringAsFixed(1)}%)\n"
        "Isolation (${_filteredDaysCount}d): $_totalIsolatedBirds (${_isolationPercentage.toStringAsFixed(1)}%)",
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black54),
      ),
    ),
    _buildCard(
      "Egg Productivity ($_batchForAnalytics)",
      icon: Icons.trending_up,
      content: Text(
        "Hen-Day Production (Today): ${_henDayEggProduction.toStringAsFixed(1)}%\n"
        "Eggs Per Hen Housed (Total): ${_eggsPerHenHoused.toStringAsFixed(1)}\n"
        "Collected (${_filteredDaysCount}d): $_totalEggsCollected",
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black54),
      ),
    ),
    _buildCard(
      "Feed & Supply",
      icon: Icons.conveyor_belt,
      content: Text(
        "Feed/Egg Ratio (${_filteredDaysCount}d): ${_kgFeedPerEgg.toStringAsFixed(2)} kg\n"
        "FCR (Egg Mass): ${_fcr.toStringAsFixed(2)}\n"
        "Shipped (${_filteredDaysCount}d): $_totalEggsShipped",
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black54),
      ),
    ),
    _buildCard(
      "Lighting Program",
      icon: Icons.lightbulb_outline,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LightingProgramScreen()),
        );
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Today: ${_todaysLightDuration.toStringAsFixed(1)} of ${_targetLightDuration.toStringAsFixed(1)} hrs",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: _targetLightDuration > 0 ? (_todaysLightDuration / _targetLightDuration).clamp(0.0, 1.0) : 0,
            backgroundColor: Colors.grey[300],
            color: Colors.amber.shade700,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
            Row(
            children: [
              Text("Consistency (${_filteredDaysCount}d): ", style: const TextStyle(fontSize: 13, color: Colors.black54)),
              Text(_consistencyStatus, style: TextStyle(fontSize: 13, color: _consistencyColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
    _buildCard(
      "Environment",
      icon: Icons.thermostat,
      content: Text(
        "Risky Days (${_filteredDaysCount}d): $_riskyTemperatureDays\n"
        "Avg Temp: ${_avgTemperature.toStringAsFixed(1)}°C\n"
        "Avg Humidity: ${_avgHumidity.toStringAsFixed(1)}%",
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black54),
      ),
    ),
    _buildCard(
      "Vaccination Schedule",
      icon: Icons.vaccines,
      content: Text(
        "Missed (${_filteredDaysCount}d): $_missedVaccinations\n"
        "Due Today: $_dueTodayVaccinations\n" 
        "Upcoming (14d): $_upcomingVaccinations", 
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black54),
      ),
    ),
    _buildCard(
      "Litter Status",
      icon: Icons.cleaning_services,
      content: Text(_litterSuggestionStatus, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black54)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Showing data for:\n${DateFormat.yMMMd().format(_selectedDateRange.start)} - ${DateFormat.yMMMd().format(_selectedDateRange.end)}',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.calendar_today,
                    size: 20, color: Colors.white),
                label: const Text('Change Filter',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 110, 110, 110),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _metricCards.length,
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _currentIndex = index);
              }
            },
            itemBuilder: (_, index) => _metricCards[index],
          ),
        ),
        SmoothPageIndicator(
          controller: _pageController,
          count: _metricCards.length,
          effect: const WormEffect(
            activeDotColor: Colors.deepOrange,
            dotHeight: 10,
            dotWidth: 10,
            spacing: 8,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5 / 2,
            children: [
              _buildDashboardTile(context, Icons.egg_alt, "Egg Collected", '/egg-collected-list'),
              _buildDashboardTile(context, Icons.delivery_dining, "Egg Supplied", '/egg-supplied-list'),
              _buildDashboardTile(context, Icons.attach_money, "Income", '/view-income'),
              _buildDashboardTile(context, Icons.receipt_long, "Expenses", '/expense-list'),
              _buildDashboardTile(context, Icons.vaccines, "Vaccination", '/vaccination'),
              _buildDashboardTile(context, Icons.batch_prediction, "Batches", '/view-batches'),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDashboardTile(
    BuildContext context,
    IconData icon,
    String label,
    String routeName,
  ) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.deepOrange.withOpacity(0.2),
        onTap: () => Navigator.pushNamed(context, routeName),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.deepOrange),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
