// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatRoomModelAdapter extends TypeAdapter<ChatRoomModel> {
  @override
  final int typeId = 1;

  @override
  ChatRoomModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatRoomModel(
      chatId: fields[0] as String,
      participants: (fields[1] as List).cast<String>(),
      lastMessage: fields[2] as String,
      lastMessageTime: fields[3] as DateTime,
      unreadCount: fields[4] as int,
      lastSenderUid: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChatRoomModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.chatId)
      ..writeByte(1)
      ..write(obj.participants)
      ..writeByte(2)
      ..write(obj.lastMessage)
      ..writeByte(3)
      ..write(obj.lastMessageTime)
      ..writeByte(4)
      ..write(obj.unreadCount)
      ..writeByte(5)
      ..write(obj.lastSenderUid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoomModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
