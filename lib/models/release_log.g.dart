// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReleaseLogAdapter extends TypeAdapter<ReleaseLog> {
  @override
  final int typeId = 15;

  @override
  ReleaseLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReleaseLog(
      batchName: fields[0] as String,
      numberOfBirds: fields[1] as int,
      notes: fields[2] as String?,
      releaseDate: fields[3] as DateTime,
      firestoreDocId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      isSynced: fields[4] as bool?,
      isDeleted: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, ReleaseLog obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.batchName)
      ..writeByte(1)
      ..write(obj.numberOfBirds)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.releaseDate)
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
      other is ReleaseLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
