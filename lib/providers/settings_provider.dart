// lib/providers/settings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A simple class to hold all our settings in one place.
class AppSettings {
  final bool notificationsEnabled;
  final bool mortalityAlertsEnabled;

  AppSettings({
    this.notificationsEnabled = true, // Default to true
    this.mortalityAlertsEnabled = true, // Default to true
  });

  // Helper method to create a copy of the settings with updated values.
  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? mortalityAlertsEnabled,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      mortalityAlertsEnabled: mortalityAlertsEnabled ?? this.mortalityAlertsEnabled,
    );
  }
}

// The StateNotifier that will manage our AppSettings state.
// Changed from StateNotifier to Notifier
class SettingsNotifier extends Notifier<AppSettings> {
  // Removed super() constructor
  
  // build() method replaces constructor
  @override
  AppSettings build() {
    _loadSettings();
    return AppSettings(); // Return default initial state
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Update state when settings are loaded
    state = AppSettings(
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      mortalityAlertsEnabled: prefs.getBool('mortalityAlertsEnabled') ?? true,
    );
  }

  // Methods to update individual settings and save them to the device.
  Future<void> setNotificationsEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', isEnabled);
    // Read and update state
    state = state.copyWith(notificationsEnabled: isEnabled);
  }

  Future<void> setMortalityAlertsEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mortalityAlertsEnabled', isEnabled);
    // Read and update state
    state = state.copyWith(mortalityAlertsEnabled: isEnabled);
  }
}

// The final provider that our UI will interact with.
// Changed from StateNotifierProvider to NotifierProvider
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
