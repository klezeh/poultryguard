// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'egg_collected.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EggCollectedAdapter extends TypeAdapter<EggCollected> {
  @override
  final int typeId = 6;

  @override
  EggCollected read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EggCollected(
      date: fields[0] as DateTime,
      count: fields[1] as int,
      notes: fields[2] as String?,
      batchName: fields[3] as String,
      firestoreDocId: fields[6] as String?,
      createdAt: fields[5] as DateTime?,
      isSynced: fields[4] as bool?,
      isDeleted: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, EggCollected obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.count)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.batchName)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.firestoreDocId)
      ..writeByte(7)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EggCollectedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
