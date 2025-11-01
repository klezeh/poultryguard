// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'egg_supplied.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EggSuppliedAdapter extends TypeAdapter<EggSupplied> {
  @override
  final int typeId = 7;

  @override
  EggSupplied read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EggSupplied(
      date: fields[0] as DateTime,
      quantity: fields[1] as int,
      customerName: fields[2] as String,
      notes: fields[3] as String?,
      firestoreDocId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      isSynced: fields[4] as bool?,
      isDeleted: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, EggSupplied obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.notes)
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
      other is EggSuppliedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
