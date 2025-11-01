// lib/providers/user_session_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import 'package:poultryguard/models/user_profile.dart'; // Import UserProfile model
import 'package:poultryguard/models/user_role.dart'; // Import UserRole enum

// Represents the authenticated user's session details
class UserSession {
  final String? uid;
  final String? email;
  final UserRole role;
  final String? farmId;
  final bool isLoading; // NEW: To indicate if session data is being loaded

  UserSession({
    this.uid,
    this.email,
    this.role = UserRole.unassigned,
    this.farmId,
    this.isLoading = true, // Default to true on initialization
  });

  // Helper for when no user is logged in
  static UserSession unauthenticated() => UserSession(
        uid: null,
        email: null,
        role: UserRole.unassigned,
        farmId: null,
        isLoading: false, // Not loading when unauthenticated
      );

  // Helper for when loading (e.g., during auth state changes)
  UserSession copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? farmId,
    bool? isLoading,
  }) {
    return UserSession(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      farmId: farmId ?? this.farmId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// StateNotifier for managing the UserSession
// Changed from StateNotifier to Notifier
class UserSessionNotifier extends Notifier<UserSession> {
  // Removed (Ref ref) from constructor
  // Removed super() call

  // build() method replaces constructor
  @override
  UserSession build() {
    _initializeSessionListener();
    return UserSession(isLoading: true); // Initial state
  }


  // Listens to Firebase Auth state changes and updates the UserSession
  void _initializeSessionListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      // Update state directly
      state = state.copyWith(isLoading: true); // Start loading state

      if (user != null) {
        // Fetch user profile from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userProfile = UserProfile.fromFirestore(userDoc);
          // Update state directly
          state = UserSession(
            uid: userProfile.uid,
            email: userProfile.email,
            role: userProfile.role,
            farmId: userProfile.farmId,
            isLoading: false,
          );
          print('User session set: UID=${state.uid}, Role=${state.role.name}, FarmID=${state.farmId}');
        } else {
          // User document doesn't exist, create a basic profile and assign default role/no farm
          print('User document not found for ${user.uid}. Creating default profile.');
          final newUserProfile = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            role: UserRole.unassigned, // Default unassigned role
            farmId: null, // No farm assigned initially
          );
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(newUserProfile.toFirestore());
          // Update state directly
          state = UserSession(
            uid: newUserProfile.uid,
            email: newUserProfile.email,
            role: newUserProfile.role,
            farmId: newUserProfile.farmId,
            isLoading: false,
          );
        }
      } else {
        // No user logged in
        // Update state directly
        state = UserSession.unauthenticated();
        print('User session cleared (unauthenticated).');
      }
    });
  }

  // Method to manually refresh session data (e.g., after a farm change or role update)
  Future<void> refreshSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update state directly
      state = state.copyWith(isLoading: true);
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userProfile = UserProfile.fromFirestore(userDoc);
        // Update state directly
        state = UserSession(
          uid: userProfile.uid,
          email: userProfile.email,
          role: userProfile.role,
          farmId: userProfile.farmId,
          isLoading: false,
        );
      } else {
        // Update state directly
        state = UserSession.unauthenticated(); // Fallback if user doc disappears
      }
    } else {
      // Update state directly
      state = UserSession.unauthenticated();
    }
  }

  // Helper getters for convenience (already defined in your existing code)
  // Read state directly
  bool get isAdmin => state.role == UserRole.admin;
  bool get isMidLevel => state.role == UserRole.midLevel;
  bool get isLowLevel => state.role == UserRole.lowLevel;
  bool get isUnassigned => state.role == UserRole.unassigned;
  bool get isAuthenticated => state.uid != null;
}

// Main provider for the UserSessionNotifier
// Changed from StateNotifierProvider to NotifierProvider
final userSessionProvider = NotifierProvider<UserSessionNotifier, UserSession>(
  () => UserSessionNotifier(), // Constructor no longer takes ref
);

// Provider for the current Farm ID, derived from userSessionProvider
final currentFarmIdProvider = Provider<String?>((ref) {
  final session = ref.watch(userSessionProvider);
  return session.farmId;
});

// Provider for the current User Role, derived from userSessionProvider
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final session = ref.watch(userSessionProvider);
  return session.role;
});

