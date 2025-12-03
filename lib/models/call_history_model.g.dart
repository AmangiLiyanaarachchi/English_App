// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CallHistoryModelAdapter extends TypeAdapter<CallHistoryModel> {
  @override
  final int typeId = 2;

  @override
  CallHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallHistoryModel(
      callId: fields[0] as String,
      callerId: fields[1] as String,
      callerName: fields[2] as String,
      callerPhotoUrl: fields[3] as String,
      receiverId: fields[4] as String,
      receiverName: fields[5] as String,
      receiverPhotoUrl: fields[6] as String,
      callType: fields[7] as String,
      status: fields[8] as String,
      duration: fields[9] as int,
      timestamp: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CallHistoryModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.callId)
      ..writeByte(1)
      ..write(obj.callerId)
      ..writeByte(2)
      ..write(obj.callerName)
      ..writeByte(3)
      ..write(obj.callerPhotoUrl)
      ..writeByte(4)
      ..write(obj.receiverId)
      ..writeByte(5)
      ..write(obj.receiverName)
      ..writeByte(6)
      ..write(obj.receiverPhotoUrl)
      ..writeByte(7)
      ..write(obj.callType)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.duration)
      ..writeByte(10)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
