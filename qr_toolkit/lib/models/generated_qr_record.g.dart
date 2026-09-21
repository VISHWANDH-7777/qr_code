// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_qr_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GeneratedQRRecordAdapter extends TypeAdapter<GeneratedQRRecord> {
  @override
  final int typeId = 1;

  @override
  GeneratedQRRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeneratedQRRecord(
      id: fields[0] as String,
      type: fields[1] as String,
      name: fields[2] as String,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime,
      qrStyle: fields[5] as String?,
      qrColor: fields[6] as int?,
      backgroundColor: fields[7] as int?,
      logoPath: fields[8] as String?,
      caption: fields[9] as String?,
      isFavorite: fields[10] as bool,
      imagePath: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GeneratedQRRecord obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.qrStyle)
      ..writeByte(6)
      ..write(obj.qrColor)
      ..writeByte(7)
      ..write(obj.backgroundColor)
      ..writeByte(8)
      ..write(obj.logoPath)
      ..writeByte(9)
      ..write(obj.caption)
      ..writeByte(10)
      ..write(obj.isFavorite)
      ..writeByte(11)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedQRRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
