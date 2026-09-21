// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsRecordAdapter extends TypeAdapter<SettingsRecord> {
  @override
  final int typeId = 2;

  @override
  SettingsRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsRecord(
      themeMode: fields[0] as String,
      autoOpenLinks: fields[3] as bool,
      saveHistory: fields[4] as bool,
      defaultQRStyle: fields[5] as String,
      defaultExportQuality: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(3)
      ..write(obj.autoOpenLinks)
      ..writeByte(4)
      ..write(obj.saveHistory)
      ..writeByte(5)
      ..write(obj.defaultQRStyle)
      ..writeByte(6)
      ..write(obj.defaultExportQuality);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
