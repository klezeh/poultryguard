// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isolation_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IsolationRecordAdapter extends TypeAdapter<IsolationRecord> {
  @override
  final int typeId = 10;

  @override
  IsolationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IsolationRecord(
      batchName: fields[0] as String,
      numberOfBirds: fields[1] as int,
      reason: fields[2] as String,
      isolationDate: fields[3] as DateTime,
      firestoreDocId: fields[6] as String?,
      createdAt: fields[5] as DateTime?,
      isSynced: fields[4] as bool?,
      isDeleted: fields[7] as bool?,
      isActive: fields[8] as bool?,
      releaseDate: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, IsolationRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.batchName)
      ..writeByte(1)
      ..write(obj.numberOfBirds)
      ..writeByte(2)
      ..write(obj.reason)
      ..writeByte(3)
      ..write(obj.isolationDate)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.firestoreDocId)
      ..writeByte(7)
      ..write(obj.isDeleted)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.releaseDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IsolationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
