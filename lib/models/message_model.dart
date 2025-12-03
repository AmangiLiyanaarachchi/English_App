import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'message_model.g.dart';

@HiveType(typeId: 0)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final String senderUid;

  @HiveField(3)
  final String receiverUid;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String type; // 'text', 'voice', 'image'

  @HiveField(6)
  final bool isRead;

  @HiveField(7)
  final String? mediaUrl;

  @HiveField(8)
  final String? englishTip;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderUid,
    required this.receiverUid,
    required this.timestamp,
    this.type = 'text',
    this.isRead = false,
    this.mediaUrl,
    this.englishTip,
  });

  // Convert Firestore document to MessageModel
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      text: data['text'] ?? '',
      senderUid: data['senderUid'] ?? '',
      receiverUid: data['receiverUid'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? 'text',
      isRead: data['isRead'] ?? false,
      mediaUrl: data['mediaUrl'],
      englishTip: data['englishTip'],
    );
  }

  // Convert MessageModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'isRead': isRead,
      'mediaUrl': mediaUrl,
      'englishTip': englishTip,
    };
  }

  // Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? text,
    String? senderUid,
    String? receiverUid,
    DateTime? timestamp,
    String? type,
    bool? isRead,
    String? mediaUrl,
    String? englishTip,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      senderUid: senderUid ?? this.senderUid,
      receiverUid: receiverUid ?? this.receiverUid,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      englishTip: englishTip ?? this.englishTip,
    );
  }
}
