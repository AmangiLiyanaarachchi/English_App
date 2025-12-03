import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'chat_room_model.g.dart';

@HiveType(typeId: 1)
class ChatRoomModel extends HiveObject {
  @HiveField(0)
  final String chatId;

  @HiveField(1)
  final List<String> participants;

  @HiveField(2)
  final String lastMessage;

  @HiveField(3)
  final DateTime lastMessageTime;

  @HiveField(4)
  final int unreadCount;

  @HiveField(5)
  final String lastSenderUid;

  ChatRoomModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.lastSenderUid,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      lastSenderUid: data['lastSenderUid'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'lastSenderUid': lastSenderUid,
    };
  }

  ChatRoomModel copyWith({
    String? chatId,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? lastSenderUid,
  }) {
    return ChatRoomModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      lastSenderUid: lastSenderUid ?? this.lastSenderUid,
    );
  }
}
