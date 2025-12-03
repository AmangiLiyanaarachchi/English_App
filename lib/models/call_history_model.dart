import 'package:hive/hive.dart';

part 'call_history_model.g.dart';

@HiveType(typeId: 2)
class CallHistoryModel extends HiveObject {
  @HiveField(0)
  final String callId;

  @HiveField(1)
  final String callerId;

  @HiveField(2)
  final String callerName;

  @HiveField(3)
  final String callerPhotoUrl;

  @HiveField(4)
  final String receiverId;

  @HiveField(5)
  final String receiverName;

  @HiveField(6)
  final String receiverPhotoUrl;

  @HiveField(7)
  final String callType; // 'outgoing', 'incoming', 'missed'

  @HiveField(8)
  final String status; // 'completed', 'missed', 'rejected', 'cancelled'

  @HiveField(9)
  final int duration; // in seconds

  @HiveField(10)
  final DateTime timestamp;

  CallHistoryModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerPhotoUrl,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhotoUrl,
    required this.callType,
    required this.status,
    required this.duration,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'callType': callType,
      'status': status,
      'duration': duration,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CallHistoryModel.fromMap(Map<String, dynamic> map) {
    return CallHistoryModel(
      callId: map['callId'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPhotoUrl: map['callerPhotoUrl'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverPhotoUrl: map['receiverPhotoUrl'] ?? '',
      callType: map['callType'] ?? '',
      status: map['status'] ?? '',
      duration: map['duration'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
