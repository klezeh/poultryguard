// Add these imports at the top
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/models/farm.dart';
import 'package:poultryguard/providers/user_role_provider.dart';

// ... your existing providers (userSessionProvider, etc.) ...

// NEW: Provider to fetch the current farm's details
final farmDetailsProvider = StreamProvider.autoDispose<Farm?>((ref) {
  final farmId = ref.watch(currentFarmIdProvider);

  if (farmId == null || farmId.isEmpty) {
    return Stream.value(null);
  }

  final docRef = FirebaseFirestore.instance.collection('farms').doc(farmId);
  return docRef.snapshots().map((snapshot) {
    if (snapshot.exists) {
      return Farm.fromFirestore(snapshot.data()!, snapshot.id);
    }
    return null;
  });
});