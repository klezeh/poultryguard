import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Define the Notifier
// Changed from StateNotifier to Notifier
class ThemeNotifier extends Notifier<ThemeMode> {
  // Removed super() constructor
  
  // The build method replaces the constructor for initial state
  @override
  ThemeMode build() {
    _loadTheme(); // Load theme asynchronously
    return ThemeMode.light; // Return initial state
  }

  // Load the saved theme from device storage
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    // Update state directly
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Toggle the theme and save the new preference
  Future<void> toggleTheme() async {
    // Read state, update, and save
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', state == ThemeMode.dark);
  }
}

// 2. Define the Provider
// Changed from StateNotifierProvider to NotifierProvider
final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
