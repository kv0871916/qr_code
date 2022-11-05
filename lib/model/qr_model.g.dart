// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QrResultsAdapter extends TypeAdapter<QrResults> {
  @override
  final int typeId = 0;

  @override
  QrResults read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QrResults(
      code: fields[0] as String?,
      format: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QrResults obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.format);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrResultsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
