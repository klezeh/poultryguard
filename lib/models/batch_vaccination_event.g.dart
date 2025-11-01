// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_vaccination_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BatchVaccinationEventAdapter extends TypeAdapter<BatchVaccinationEvent> {
  @override
  final int typeId = 13;

  @override
  BatchVaccinationEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BatchVaccinationEvent(
      batchId: fields[0] as String,
      vaccinationName: fields[1] as String,
      scheduledDate: fields[2] as DateTime,
      method: fields[3] as String,
      isCompleted: fields[4] as bool,
      firestoreDocId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      isSynced: fields[7] as bool,
      isDeleted: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BatchVaccinationEvent obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.batchId)
      ..writeByte(1)
      ..write(obj.vaccinationName)
      ..writeByte(2)
      ..write(obj.scheduledDate)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.firestoreDocId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isSynced)
      ..writeByte(8)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchVaccinationEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
