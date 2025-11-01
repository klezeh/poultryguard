// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lighting_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LightingRecordAdapter extends TypeAdapter<LightingRecord> {
  @override
  final int typeId = 12;

  @override
  LightingRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LightingRecord(
      date: fields[0] as DateTime,
      lightsOnHours: fields[1] as double,
      lightsOffHours: fields[2] as double,
      batchName: fields[3] as String,
      firestoreDocId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      isSynced: fields[4] as bool?,
      isDeleted: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, LightingRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.lightsOnHours)
      ..writeByte(2)
      ..write(obj.lightsOffHours)
      ..writeByte(3)
      ..write(obj.batchName)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.firestoreDocId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LightingRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
