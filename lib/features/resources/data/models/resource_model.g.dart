// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResourceModelAdapter extends TypeAdapter<ResourceModel> {
  @override
  final int typeId = 0;

  @override
  ResourceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResourceModel(
      id: fields[0] as String,
      title: fields[1] as String,
      url: fields[2] as String,
      platformType: fields[3] as String,
      tags: (fields[4] as List).cast<String>(),
      notes: fields[5] as String,
      isFavorite: fields[6] as bool,
      isRead: fields[7] as bool,
      progressPercentage: fields[8] as double,
      dateAdded: fields[9] as DateTime,
      lastUpdated: fields[10] as DateTime,
      learningStatus: fields[11] as String,
      isArchived: fields[12] as bool,
      queueIndex: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ResourceModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.platformType)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.isRead)
      ..writeByte(8)
      ..write(obj.progressPercentage)
      ..writeByte(9)
      ..write(obj.dateAdded)
      ..writeByte(10)
      ..write(obj.lastUpdated)
      ..writeByte(11)
      ..write(obj.learningStatus)
      ..writeByte(12)
      ..write(obj.isArchived)
      ..writeByte(13)
      ..write(obj.queueIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
