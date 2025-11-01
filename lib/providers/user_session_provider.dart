// lib/providers/user_session_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:poultryguard/models/user_profile.dart';
import 'package:poultryguard/models/user_role.dart';

// UserSession class definition remains the same
class UserSession {
  final String? uid;
  final String? name;
  final String? email;
  final UserRole role;
  final String? farmId;
  final DateTime? createdAt; // <-- ADDED
  final bool isLoading;

  bool get isAuthenticated => uid != null;

  UserSession({
    this.uid,
    this.name,
    this.email,
    this.role = UserRole.unassigned,
    this.farmId,
    this.createdAt, // <-- ADDED
    this.isLoading = true,
  });

  static UserSession unauthenticated() => UserSession(
        uid: null,
        name: null,
        email: null,
        role: UserRole.unassigned,
        farmId: null,
        createdAt: null, // <-- ADDED
        isLoading: false,
      );

  UserSession copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    String? farmId,
    DateTime? createdAt, // <-- ADDED
    bool? isLoading,
  }) {
    return UserSession(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      farmId: farmId ?? this.farmId,
      createdAt: createdAt ?? this.createdAt, // <-- ADDED
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// StateNotifier for managing the UserSession
// Changed from StateNotifier to Notifier
class UserSessionNotifier extends Notifier<UserSession> {
  StreamSubscription? _authSubscription;
  StreamSubscription? _firestoreSubscription;

  // Removed (Ref ref) from constructor
  // Removed super() call
  
  // build() method replaces constructor
  @override
  UserSession build() {
    _initializeSessionListener();
    return UserSession(isLoading: true); // Initial state
  }

  void _initializeSessionListener() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _firestoreSubscription?.cancel();

      if (user == null) {
        state = UserSession.unauthenticated();
      } else {
        state = state.copyWith(isLoading: true, uid: user.uid, email: user.email);
        
        _firestoreSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((userDoc) {
          if (userDoc.exists) {
            final userProfile = UserProfile.fromFirestore(userDoc);
            // --- FIX: Populate the UserSession with all fields ---
            state = UserSession(
              uid: userProfile.uid,
              name: userProfile.name,
              email: userProfile.email,
              role: userProfile.role,
              farmId: userProfile.farmId,
              createdAt: userProfile.createdAt, // <-- FIX
              isLoading: false,
            );
          } else {
            // If user exists in Auth but not Firestore (should be rare)
            // Keep loading and let Auth service (on sign up) create the doc.
            // Or handle new user creation logic here if needed.
            state = state.copyWith(isLoading: true, role: UserRole.unassigned, farmId: null); 
          }
        });
      }
    });
  }

  // dispose() is automatically handled by Riverpod for Notifiers
  // when using ref.onDispose
  // We can remove the manual override, but let's keep it to be safe for subscriptions.
  @override
  void dispose() {
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
  }

  Future<void> refreshSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      state = state.copyWith(isLoading: true);
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userProfile = UserProfile.fromFirestore(userDoc);
        // --- FIX: Also refresh all fields ---
        state = UserSession(
          uid: userProfile.uid,
          name: userProfile.name,
          email: userProfile.email,
          role: userProfile.role,
          farmId: userProfile.farmId,
          createdAt: userProfile.createdAt, // <-- FIX
          isLoading: false,
        );
      } else {
        state = UserSession.unauthenticated();
      }
    } else {
      state = UserSession.unauthenticated();
    }
  }
}

// --- Your existing providers ---
// Changed from StateNotifierProvider to NotifierProvider
final userSessionProvider = NotifierProvider<UserSessionNotifier, UserSession>(
  () => UserSessionNotifier(), // Constructor no longer takes ref
);

final currentFarmIdProvider = Provider<String?>((ref) {
  final session = ref.watch(userSessionProvider);
  return session.farmId;
});

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final session = ref.watch(userSessionProvider);
  return session.role;
});
