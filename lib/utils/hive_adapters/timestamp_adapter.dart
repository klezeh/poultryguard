// lib/utils/hive_adapters/timestamp_adapter.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimestampAdapter extends TypeAdapter<Timestamp> {
  @override
  final int typeId = 17; // Assign a unique typeId, ensure no other model uses this

  @override
  Timestamp read(BinaryReader reader) {
    // Read the milliseconds since epoch as an int
    final milliseconds = reader.readInt();
    return Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  }

  @override
  void write(BinaryWriter writer, Timestamp obj) {
    // Write the milliseconds since epoch as an int
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}
