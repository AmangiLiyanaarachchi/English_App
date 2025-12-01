import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, audio, image, system }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isEnglish;
  final List<String> readBy;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.type,
    required this.content,
    this.mediaUrl,
    required this.timestamp,
    this.isEnglish = true,
    this.readBy = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type.name,
      'content': content,
      'mediaUrl': mediaUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isEnglish': isEnglish,
      'readBy': readBy,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderPhotoUrl: json['senderPhotoUrl'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEnglish: json['isEnglish'] ?? true,
      readBy: List<String>.from(json['readBy'] ?? []),
    );
  }
}

class ChatRoom {
  final String id;
  final String name;
  final List<String> participants;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final bool isGroup;
  final String? groupPhotoUrl;
  final DateTime createdAt;
  final String createdBy;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants,
    this.lastMessage,
    required this.lastMessageTime,
    this.isGroup = false,
    this.groupPhotoUrl,
    required this.createdAt,
    required this.createdBy,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'isGroup': isGroup,
      'groupPhotoUrl': groupPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'unreadCount': unreadCount,
    };
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'],
      lastMessageTime:
          (json['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroup: json['isGroup'] ?? false,
      groupPhotoUrl: json['groupPhotoUrl'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
