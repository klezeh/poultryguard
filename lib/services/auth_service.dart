// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Helper method to create the user document in Firestore ---
  // --- CHANGE #1: Added 'name' parameter ---
  Future<void> _createUserDocument(User user, String name) async {
    final String userId = user.uid;
    final String? userEmail = user.email;
    final DocumentReference userDocRef = _firestore.collection('users').doc(userId);

    try {
      // Set the initial data for the user.
      await userDocRef.set({
        'uid': userId,
        'email': userEmail,
        'name': name, // <-- ADDED: Save the name to Firestore
        'role': 'unassigned',
        'farmId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If creating the document fails, delete the auth user
      await user.delete();
      if (kDebugMode) {
        print("Firestore document creation failed, so the auth user was deleted. Error: $e");
      }
      throw Exception("Failed to set up user profile. Please try again.");
    }
  }

  // --- Main sign-up method for the UI to call ---
  // --- CHANGE #2: Added 'name' parameter ---
  Future<User?> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      // Step 1: Create the user with Firebase Authentication
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? newUser = userCredential.user;

      // Step 2: If auth creation is successful, create the Firestore user document
      if (newUser != null) {
        // Pass the name to the helper method
        await _createUserDocument(newUser, name);
        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("FirebaseAuthException on sign up: ${e.code}");
      }
      throw Exception(e.message ?? "An unknown sign-up error occurred.");
    } catch (e) {
      if (kDebugMode) {
        print("An unexpected error occurred during sign up: $e");
      }
      throw Exception("An unexpected error occurred. Please try again.");
    }
  }

  // You can add other methods like signIn, signOut etc. here
  Future<void> signOut() async {
    await _auth.signOut();
  }
}