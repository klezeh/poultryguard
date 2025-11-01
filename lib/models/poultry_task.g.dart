// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poultry_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PoultryTaskAdapter extends TypeAdapter<PoultryTask> {
  @override
  final int typeId = 5;

  @override
  PoultryTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PoultryTask(
      name: fields[0] as String,
      category: fields[1] as String,
      dueDate: fields[2] as DateTime,
      isDone: fields[3] as bool,
      isAdhoc: fields[4] as bool,
      isSynced: fields[5] == null ? false : fields[5] as bool,
      firestoreDocId: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      isDeleted: fields[8] == null ? false : fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PoultryTask obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.isDone)
      ..writeByte(4)
      ..write(obj.isAdhoc)
      ..writeByte(5)
      ..write(obj.isSynced)
      ..writeByte(6)
      ..write(obj.firestoreDocId)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoultryTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
