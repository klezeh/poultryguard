// lib/screens/profile_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:poultryguard/providers/farm_provider.dart';
import 'package:poultryguard/providers/provider.dart'; // Imports the new lastSyncTimeProvider
import 'package:poultryguard/providers/theme_provider.dart';
import 'package:poultryguard/providers/settings_provider.dart';
import 'package:poultryguard/services/data_sync_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:poultryguard/models/user_profile.dart';
import 'package:poultryguard/providers/user_session_provider.dart'; // Import user session provider

// You will need to add these packages to your pubspec.yaml:
// image_picker: ^1.0.7
// firebase_storage: ^11.7.0

// Provider to get app version info
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

// REMOVED: The StateProvider was moved to provider.dart
// final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);


class ProfileAndSettingsScreen extends ConsumerWidget {
  const ProfileAndSettingsScreen({super.key});
  
  // Helper widget for section titles
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Helper to show the dialog for editing the user's name
  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Your Name'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // Here you would call a function to update the name in Firestore
                // For example: ref.read(userServiceProvider).updateName(nameController.text.trim());
                print('New name: ${nameController.text.trim()}');
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSession = ref.watch(userSessionProvider);
    final farmDetails = ref.watch(farmDetailsProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final settings = ref.watch(settingsProvider);
    final appVersionInfo = ref.watch(packageInfoProvider);
    // This line now reads the new NotifierProvider from provider.dart
    final lastSyncTime = ref.watch(lastSyncTimeProvider);

    final userName = userSession.name ?? 'User';
    final userRole = userSession.role.name.toUpperCase();
    final memberSince = userSession.createdAt != null 
        ? DateFormat.yMMMMd().format(userSession.createdAt!) 
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          // --- USER PROFILE HEADER ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      // You would load the user's profile picture URL here
                      // backgroundImage: NetworkImage(userSession.profilePictureUrl),
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Theme.of(context).cardColor,
                        child: IconButton(
                          iconSize: 15,
                          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                          onPressed: () {
                            // Logic to pick and upload image
                            print('Change profile picture tapped');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _showEditNameDialog(context, ref, userName),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit, size: 16, color: Theme.of(context).hintColor),
                            ],
                          ),
                        ),
                      ),
                      Text(userSession.email ?? 'No email', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- ACCOUNT & FARM DETAILS ---
          _buildSectionTitle(context, "Account Details"),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Role'),
                  trailing: Text(userRole),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: const Text('Member Since'),
                  trailing: Text(memberSince),
                ),
                 const Divider(height: 1, indent: 16, endIndent: 16),
                farmDetails.when(
                  data: (farm) => ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('Farm Name'),
                    subtitle: Text(farm?.farmName ?? 'No farm assigned'),
                  ),
                  loading: () => const ListTile(title: Text('Farm Name'), subtitle: Text('Loading...')),
                  error: (e, s) => const ListTile(title: Text('Farm Name'), subtitle: Text('Error')),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: const Text('User ID'),
                  subtitle: SelectableText(userSession.uid ?? 'N/A', style: const TextStyle(fontSize: 12)),
                ),
              ],
            )
          ),

          // --- APP SETTINGS ---
          _buildSectionTitle(context, "App Settings"),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (bool value) => ref.read(themeNotifierProvider.notifier).toggleTheme(),
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  value: settings.notificationsEnabled,
                  onChanged: (bool value) => ref.read(settingsProvider.notifier).setNotificationsEnabled(value),
                  secondary: const Icon(Icons.notifications_active_outlined),
                ),
              ],
            ),
          ),

          // --- ABOUT SECTION ---
          _buildSectionTitle(context, "About & Sync"),
           Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync_outlined),
                  title: const Text('Last Synced'),
                  subtitle: Text(lastSyncTime != null ? DateFormat.yMMMd().add_jm().format(lastSyncTime) : 'Never'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Sync Now',
                    onPressed: () => ref.read(dataSyncServiceProvider).triggerManualSync(),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: appVersionInfo.when(
                    data: (info) => Text('${info.version} (Build ${info.buildNumber})'),
                    loading: () => const Text('...'),
                    error: (err, stack) => const Text('N/A'),
                  ),
                ),
              ],
            )
          ),
        ],
      ),
    );
  }
}
