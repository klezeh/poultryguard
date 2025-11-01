// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_checklist_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyChecklistRecordAdapter extends TypeAdapter<DailyChecklistRecord> {
  @override
  final int typeId = 19;

  @override
  DailyChecklistRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyChecklistRecord(
      batchKey: fields[0] as dynamic,
      date: fields[1] as DateTime,
      taskCompletions: (fields[2] as Map).cast<String, bool>(),
    )
      ..firestoreDocId = fields[100] as String?
      ..createdAt = fields[101] as DateTime?
      ..isSynced = fields[102] as bool
      ..isDeleted = fields[103] as bool;
  }

  @override
  void write(BinaryWriter writer, DailyChecklistRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.batchKey)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.taskCompletions)
      ..writeByte(100)
      ..write(obj.firestoreDocId)
      ..writeByte(101)
      ..write(obj.createdAt)
      ..writeByte(102)
      ..write(obj.isSynced)
      ..writeByte(103)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyChecklistRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
