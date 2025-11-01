// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ObservationRecordAdapter extends TypeAdapter<ObservationRecord> {
  @override
  final int typeId = 14;

  @override
  ObservationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ObservationRecord(
      date: fields[0] as DateTime,
      observationText: fields[1] as String,
      batchName: fields[2] as String,
      firestoreDocId: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      isSynced: fields[3] as bool?,
      isDeleted: fields[6] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, ObservationRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.observationText)
      ..writeByte(2)
      ..write(obj.batchName)
      ..writeByte(3)
      ..write(obj.isSynced)
      ..writeByte(4)
      ..write(obj.firestoreDocId)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
