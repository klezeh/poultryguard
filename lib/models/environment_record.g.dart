// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnvironmentRecordAdapter extends TypeAdapter<EnvironmentRecord> {
  @override
  final int typeId = 8;

  @override
  EnvironmentRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnvironmentRecord(
      date: fields[0] as DateTime,
      temperatureC: fields[1] as double,
      humidityPercent: fields[2] as double,
      firestoreDocId: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      isSynced: fields[3] as bool?,
      isDeleted: fields[6] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, EnvironmentRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.temperatureC)
      ..writeByte(2)
      ..write(obj.humidityPercent)
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
      other is EnvironmentRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
