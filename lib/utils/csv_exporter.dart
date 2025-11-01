// utils/csv_exporter.dart
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poultryguard/models/temperature_humidity_record.dart';
import 'package:share_plus/share_plus.dart';

// Import all models that need CSV export functionality
import '../models/egg_collected.dart';
import '../models/egg_supplied.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/mortality_record.dart'; // Import MortalityRecord
import '../models/isolation_record.dart'; // Import IsolationRecord
import '../models/lighting_record.dart'; // Import LightingRecord
import '../models/feed_used.dart'; // Import FeedUsed
import '../models/observation_record.dart'; // Import ObservationRecord


class CsvExporter {
  /// Exports a list of EggCollected records to a CSV file and shares it.
  static Future<String> exportEggCollectedToCsv(List<EggCollected> records) async {
    final buffer = StringBuffer();
    // CSV Header for EggCollected
    buffer.writeln('Date,Batch Name,Quantity,Notes');

    // CSV Data for EggCollected
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.date)}",'
          '"${record.batchName.replaceAll('"', '""')}",' // Escape quotes in batch name
          '"${record.count}",' // Access 'count' field as per updated model
          '"${record.notes?.replaceAll('"', '""') ?? ''}"' // Escape quotes in notes, handle null
      );
    }

    return _writeAndShareCsv(buffer.toString(), 'egg_collected_report');
  }

  /// Exports a list of EggSupplied records to a CSV file and shares it.
  static Future<String> exportEggSuppliedToCsv(List<EggSupplied> records) async {
    final buffer = StringBuffer();
    // CSV Header for EggSupplied
    buffer.writeln('Date,Customer Name,Quantity,Notes');

    // CSV Data for EggSupplied
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.date)}",'
          '"${record.customerName.replaceAll('"', '""')}",' // Use customerName, escape quotes
          '"${record.quantity}",'
          '"${record.notes?.replaceAll('"', '""') ?? ''}"' // Escape quotes in notes, handle null
      );
    }

    return _writeAndShareCsv(buffer.toString(), 'egg_supplied_report');
  }

  /// Exports a list of Expense records to a CSV file and shares it.
  static Future<String> exportExpensesToCsv(List<Expense> records) async {
    final buffer = StringBuffer();
    // CSV Header for Expense
    buffer.writeln('Date,Category,Amount,Description,Is Flagged');

    // CSV Data for Expense
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.date)}",'
          // Use null-aware access and null-coalescing for 'category'
          '"${record.category?.replaceAll('"', '""') ?? ''}",'
          '"${record.amount.toStringAsFixed(2)}",'
          '"${record.description.replaceAll('"', '""')}",'
          '"${record.isFlagged ? 'Yes' : 'No'}"'
      );
    }
    return _writeAndShareCsv(buffer.toString(), 'expenses_report');
  }

  /// Exports a list of Income records to a CSV file and shares it.
  static Future<String> exportIncomeToCsv(List<Income> records) async {
    final buffer = StringBuffer();
    // CSV Header for Income
    buffer.writeln('Date,Source,Amount,Note');

    // CSV Data for Income
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.date)}",'
          '"${record.source?.replaceAll('"', '""') ?? ''}",' // Handle null source
          '"${record.amount.toStringAsFixed(2)}",'
          '"${record.note?.replaceAll('"', '""') ?? ''}"' // Handle null note
      );
    }
    return _writeAndShareCsv(buffer.toString(), 'income_report');
  }

  /// Exports a list of MortalityRecord records to a CSV file and shares it.
  static Future<String> exportMortalityRecordsToCsv(List<MortalityRecord> records) async {
    final buffer = StringBuffer();
    // CSV Header for MortalityRecord
    buffer.writeln('Date,Batch Name,Number of Birds,Reason');

    // CSV Data for MortalityRecord
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.date)}",'
          '"${record.batchName.replaceAll('"', '""')}",'
          '"${record.numberOfBirds}",'
          '"${record.reason.replaceAll('"', '""')}"'
      );
    }
    return _writeAndShareCsv(buffer.toString(), 'mortality_report');
  }

  /// Exports a list of IsolationRecord records to a CSV file and shares it.
  static Future<String> exportIsolationRecordsToCsv(List<IsolationRecord> records) async {
    final buffer = StringBuffer();
    // CSV Header for IsolationRecord
    buffer.writeln('Date,Batch Name,Number of Birds,Reason');

    // CSV Data for IsolationRecord
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.isolationDate)}",' // Use isolationDate
          '"${record.batchName.replaceAll('"', '""')}",'
          '"${record.numberOfBirds}",'
          '"${record.reason.replaceAll('"', '""')}"'
      );
    }
    return _writeAndShareCsv(buffer.toString(), 'isolation_report');
  }

  /// Exports a list of LightingRecord records to a CSV file and shares it.
  static Future<String> exportLightingRecordsToCsv(List<LightingRecord> records) async {
    final buffer = StringBuffer();
    // CSV Header for LightingRecord
    buffer.writeln('Date,Batch Name,Lights On (Hours),Lights Off (Hours)');

    // CSV Data for LightingRecord
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.date)}",'
          '"${record.batchName.replaceAll('"', '""')}",'
          '"${record.lightsOnHours.toStringAsFixed(2)}",'
          '"${record.lightsOffHours.toStringAsFixed(2)}"'
      );
    }
    return _writeAndShareCsv(buffer.toString(), 'lighting_report');
  }

  /// Exports a list of TemperatureHumidityRecord records to a CSV file and shares it.
  static Future<String> exportTemperatureHumidityRecordsToCsv(List<TemperatureHumidityRecord> records) async {
    final buffer = StringBuffer();
    // CSV Header for TemperatureHumidityRecord
    buffer.writeln('Date,Batch Name,Temperature (°C),Humidity (%)');

    // CSV Data for TemperatureHumidityRecord
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.date)}",'
          '"${record.batchName.replaceAll('"', '""')}",'
          '"${record.temperatureC.toStringAsFixed(2)}",'
          '"${record.humidityPercent.toStringAsFixed(2)}"'
      );
    }
    return _writeAndShareCsv(buffer.toString(), 'temperature_humidity_report');
  }

  /// Exports a list of FeedUsed records to a CSV file and shares it.
  static Future<String> exportFeedUsedToCsv(List<FeedUsed> records) async {
    final buffer = StringBuffer();
    // CSV Header for FeedUsed
    buffer.writeln('Date,Batch Name,Quantity (kg),Notes');

    // CSV Data for FeedUsed
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.date)}",'
          '"${record.batchName.replaceAll('"', '""')}",'
          '"${record.quantityKg.toStringAsFixed(2)}",'
          '"${record.notes?.replaceAll('"', '""') ?? ''}"'
      );
    }
    return _writeAndShareCsv(buffer.toString(), 'feed_used_report');
  }

  /// Exports a list of ObservationRecord records to a CSV file and shares it.
  static Future<String> exportObservationRecordsToCsv(List<ObservationRecord> records) async {
    final buffer = StringBuffer();
    // CSV Header for ObservationRecord
    buffer.writeln('Date,Batch Name,Observation');

    // CSV Data for ObservationRecord
    for (final record in records) {
      buffer.writeln(
          '"${DateFormat.yMMMd().format(record.date)}",'
          '"${record.batchName.replaceAll('"', '""')}",'
          '"${record.observationText.replaceAll('"', '""')}"'
      );
    }
    return _writeAndShareCsv(buffer.toString(), 'observation_report');
  }


  /// Internal helper to write the CSV string to a file and trigger sharing.
  static Future<String> _writeAndShareCsv(String csvContent, String filenamePrefix) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filenamePrefix-${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File(filePath);
      await file.writeAsString(csvContent);

      await Share.shareXFiles([XFile(file.path)], text: 'Exported data from PoultryGuard.');
      return filePath;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }
}
