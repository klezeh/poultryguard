// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bird_batch.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BirdBatchAdapter extends TypeAdapter<BirdBatch> {
  @override
  final int typeId = 0;

  @override
  BirdBatch read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BirdBatch(
      name: fields[0] as String,
      quantity: fields[1] as int,
      startDate: fields[2] as DateTime,
      type: fields[3] as BirdType?,
      firestoreDocId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      isSynced: fields[4] as bool?,
      isDeleted: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, BirdBatch obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.type)
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
      other is BirdBatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BirdTypeAdapter extends TypeAdapter<BirdType> {
  @override
  final int typeId = 1;

  @override
  BirdType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BirdType.broilers;
      case 1:
        return BirdType.layers;
      default:
        return BirdType.broilers;
    }
  }

  @override
  void write(BinaryWriter writer, BirdType obj) {
    switch (obj) {
      case BirdType.broilers:
        writer.writeByte(0);
        break;
      case BirdType.layers:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BirdTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
