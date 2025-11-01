class Farm {
  final String id;
  final String farmName;
  final String ownerName;
  // Add any other fields you have in your 'farms' documents
  final String location;

  Farm({
    required this.id,
    required this.farmName,
    required this.ownerName,
    required this.location,
  });

  factory Farm.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Farm(
      id: documentId,
      farmName: data['farmName'] ?? 'Unnamed Farm',
      ownerName: data['ownerName'] ?? 'Unknown Owner',
      location: data['location'] ?? 'Unknown Location',
    );
  }
}