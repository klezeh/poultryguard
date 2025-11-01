// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vaccination_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaccinationRecordAdapter extends TypeAdapter<VaccinationRecord> {
  @override
  final int typeId = 2;

  @override
  VaccinationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VaccinationRecord(
      batchName: fields[0] as String,
      vaccineName: fields[1] as String,
      dateGiven: fields[2] as DateTime,
      quantity: fields[3] as int,
      notes: fields[4] as String,
      firestoreDocId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      isSynced: fields[7] as bool,
      isDeleted: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VaccinationRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.batchName)
      ..writeByte(1)
      ..write(obj.vaccineName)
      ..writeByte(2)
      ..write(obj.dateGiven)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.firestoreDocId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isSynced)
      ..writeByte(8)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaccinationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
