// lib/models/vaccination_event.dart
// This file defines the model for a vaccination event.
class VaccinationEvent {
  final String name;
  final int daysAfterBatchStart;
  final String method;
  bool isCompleted; // This property will be mutable for the checklist

  VaccinationEvent({
    required this.name,
    required this.daysAfterBatchStart,
    required this.method,
    this.isCompleted = false, // Default to false
  });

  // Optional: Add a copyWith method for immutability in more complex scenarios
  // This allows creating a new instance with updated values without
  // directly mutating the original object, which is often preferred
  // in Riverpod for better state change detection and predictability.
  VaccinationEvent copyWith({
    String? name,
    int? daysAfterBatchStart,
    String? method,
    bool? isCompleted,
  }) {
    return VaccinationEvent(
      name: name ?? this.name,
      daysAfterBatchStart: daysAfterBatchStart ?? this.daysAfterBatchStart,
      method: method ?? this.method,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
