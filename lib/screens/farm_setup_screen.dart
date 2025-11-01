// lib/screens/farm_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poultryguard/models/user_profile.dart';
import 'package:poultryguard/models/user_role.dart'; // Import UserRole enum
import 'package:poultryguard/providers/user_session_provider.dart'; // Import UserSessionProvider

class FarmSetupScreen extends ConsumerStatefulWidget {
  const FarmSetupScreen({super.key});

  @override
  ConsumerState<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends ConsumerState<FarmSetupScreen> {
  // Separate GlobalKeys for each form section
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();

  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _joinFarmIdController = TextEditingController();

  bool _isCreatingFarm = false;
  bool _isJoiningFarm = false;

  final Color primaryColor = Colors.deepOrange;

  @override
  void dispose() {
    _farmNameController.dispose();
    _joinFarmIdController.dispose();
    super.dispose();
  }

  // --- Logic to Create a New Farm ---
  Future<void> _createNewFarm() async {
    // Validate ONLY the create farm form
    if (!_createFormKey.currentState!.validate()) return;

    setState(() { _isCreatingFarm = true; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Authentication error. Please log in again.');
      setState(() { _isCreatingFarm = false; });
      return;
    }

    try {
      final String farmName = _farmNameController.text.trim();
      final firestore = FirebaseFirestore.instance;

      // 1. Generate a unique farmId (Firestore document ID)
      final String newFarmId = firestore.collection('farms').doc().id;

      // 2. Create the new farm document
      await firestore.collection('farms').doc(newFarmId).set({
        'name': farmName,
        'ownerUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      }   );

      // 3. Update the user's UserProfile with the new farmId and 'admin' role
      await firestore.collection('users').doc(user.uid).update({
        'farmId': newFarmId,
        'role': UserRole.admin.name, // Set to admin role
      });

      // 4. Refresh the UserSessionNotifier state to reflect the new farmId and role
      // Await this refresh to ensure the session is updated before navigating
      await ref.read(userSessionProvider.notifier).refreshSession();

      _showSnackBar('Farm "$farmName" created successfully! Welcome.');
      if (mounted) {
        // Navigate to Dashboard after successful setup
        // Use pushReplacement to prevent going back to FarmSetupScreen
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }

    } catch (e) {
      _showSnackBar('Failed to create farm: $e');
      print('Error creating farm: $e');
    } finally {
      setState(() { _isCreatingFarm = false; });
    }
  }

  // --- Logic to Join an Existing Farm ---
  Future<void> _joinExistingFarm() async {
    // Validate ONLY the join farm form
    if (!_joinFormKey.currentState!.validate()) return;

    setState(() { _isJoiningFarm = true; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Authentication error. Please log in again.');
      setState(() { _isJoiningFarm = false; });
      return;
    }

    try {
      final String farmIdToJoin = _joinFarmIdController.text.trim();
      final firestore = FirebaseFirestore.instance;

      // 1. Verify if the farmId exists
      final farmDoc = await firestore.collection('farms').doc(farmIdToJoin).get();
      if (!farmDoc.exists) {
        _showSnackBar('Farm ID does not exist. Please check the code.');
        setState(() { _isJoiningFarm = false; });
        return;
      }

      // 2. Update the user's UserProfile with the farmId and a default role (e.g., lowLevel)
      await firestore.collection('users').doc(user.uid).update({
        'farmId': farmIdToJoin,
        'role': UserRole.lowLevel.name, // Assign a default role for new members
      });

      // 3. Refresh the UserSessionNotifier state
      // Await this refresh to ensure the session is updated before navigating
      await ref.read(userSessionProvider.notifier).refreshSession();

      _showSnackBar('Successfully joined farm: "$farmIdToJoin".');
      if (mounted) {
        // Navigate to Dashboard after successful setup
        // Use pushReplacement to prevent going back to FarmSetupScreen
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }

    } catch (e) {
      _showSnackBar('Failed to join farm: $e');
      print('Error joining farm: $e');
    } finally {
      setState(() { _isJoiningFarm = false; });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watching isLoadingSession here might cause rebuilds while creating/joining
    // Only fetch state that is stable or that triggers UI specifically
    final userSession = ref.watch(userSessionProvider);
    final isLoadingSession = userSession.isLoading; // Use direct property from session state

    if (isLoadingSession) {
      // Show SplashScreen with a message during session loading
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Loading user session..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Farm', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome! Let\'s set up your farm.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // --- Create New Farm Section ---
            _buildSectionTitle('Create a New Farm'),
            const SizedBox(height: 16),
            Form( // Separate Form for creating
              key: _createFormKey, // Assign separate form key
              child: TextFormField(
                controller: _farmNameController,
                decoration: InputDecoration(
                  labelText: 'Farm Name',
                  hintText: 'e.g., Farm Paradise',
                  prefixIcon: Icon(Icons.agriculture, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a farm name';
                  }
                  return null;
                },
                enabled: !_isCreatingFarm && !_isJoiningFarm,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: (_isCreatingFarm || _isJoiningFarm) ? null : _createNewFarm,
                icon: _isCreatingFarm ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.add_home_work, color: Colors.white),
                label: Text(
                  _isCreatingFarm ? 'Creating Farm...' : 'Create Farm',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 40),

            // --- Join Existing Farm Section ---
            _buildSectionTitle('Join an Existing Farm'),
            const SizedBox(height: 16),
            Form( // Separate Form for joining
              key: _joinFormKey, // Assign separate form key
              child: TextFormField(
                controller: _joinFarmIdController,
                decoration: InputDecoration(
                  labelText: 'Farm ID',
                  hintText: 'Enter the farm ID provided by your admin',
                  prefixIcon: Icon(Icons.vpn_key, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a farm ID';
                  }
                  return null;
                },
                enabled: !_isCreatingFarm && !_isJoiningFarm,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: (_isCreatingFarm || _isJoiningFarm) ? null : _joinExistingFarm,
                icon: _isJoiningFarm ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.group_add, color: Colors.white),
                label: Text(
                  _isJoiningFarm ? 'Joining Farm...' : 'Join Farm',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Colors.deepOrange.shade700,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
