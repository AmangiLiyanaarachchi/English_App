class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerPhotoUrl;
  final String receiverId;
  final String receiverName;
  final String receiverPhotoUrl;
  final String agoraChannelId;
  final String
      status; // 'calling', 'ringing', 'accepted', 'ended', 'missed', 'rejected'
  final DateTime timestamp;
  final String? acceptedBy;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerPhotoUrl,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhotoUrl,
    required this.agoraChannelId,
    required this.status,
    required this.timestamp,
    this.acceptedBy,
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
      'agoraChannelId': agoraChannelId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'acceptedBy': acceptedBy,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callId: map['callId'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPhotoUrl: map['callerPhotoUrl'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverPhotoUrl: map['receiverPhotoUrl'] ?? '',
      agoraChannelId: map['agoraChannelId'] ?? '',
      status: map['status'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      acceptedBy: map['acceptedBy'],
    );
  }

  CallModel copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerPhotoUrl,
    String? receiverId,
    String? receiverName,
    String? receiverPhotoUrl,
    String? agoraChannelId,
    String? status,
    DateTime? timestamp,
    String? acceptedBy,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhotoUrl: callerPhotoUrl ?? this.callerPhotoUrl,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
      agoraChannelId: agoraChannelId ?? this.agoraChannelId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      acceptedBy: acceptedBy ?? this.acceptedBy,
    );
  }
}
