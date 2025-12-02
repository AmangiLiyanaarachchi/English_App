import 'package:cloud_firestore/cloud_firestore.dart';

class Recording {
  final String id;
  final String userId;
  final String userName;
  final String audioUrl;
  final int duration; // in seconds
  final String? transcription;
  final double? fluencyScore;
  final String? feedback;
  final List<String> tags;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;
  final bool isPublic;

  Recording({
    required this.id,
    required this.userId,
    required this.userName,
    required this.audioUrl,
    required this.duration,
    this.transcription,
    this.fluencyScore,
    this.feedback,
    this.tags = const [],
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
    this.isPublic = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'audioUrl': audioUrl,
      'duration': duration,
      'transcription': transcription,
      'fluencyScore': fluencyScore,
      'feedback': feedback,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'likedBy': likedBy,
      'isPublic': isPublic,
    };
  }

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      duration: json['duration'] ?? 0,
      transcription: json['transcription'],
      fluencyScore: json['fluencyScore']?.toDouble(),
      feedback: json['feedback'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      isPublic: json['isPublic'] ?? true,
    );
  }

  Recording copyWith({
    String? id,
    String? userId,
    String? userName,
    String? audioUrl,
    int? duration,
    String? transcription,
    double? fluencyScore,
    String? feedback,
    List<String>? tags,
    DateTime? createdAt,
    int? likes,
    List<String>? likedBy,
    bool? isPublic,
  }) {
    return Recording(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      transcription: transcription ?? this.transcription,
      fluencyScore: fluencyScore ?? this.fluencyScore,
      feedback: feedback ?? this.feedback,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

class AudioSession {
  final String id;
  final String channelName;
  final List<String> participants;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in seconds
  final bool isActive;
  final String? topic;

  AudioSession({
    required this.id,
    required this.channelName,
    required this.participants,
    required this.startTime,
    this.endTime,
    this.duration = 0,
    this.isActive = true,
    this.topic,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelName': channelName,
      'participants': participants,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration,
      'isActive': isActive,
      'topic': topic,
    };
  }

  factory AudioSession.fromJson(Map<String, dynamic> json) {
    return AudioSession(
      id: json['id'] ?? '',
      channelName: json['channelName'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      startTime: (json['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (json['endTime'] as Timestamp?)?.toDate(),
      duration: json['duration'] ?? 0,
      isActive: json['isActive'] ?? true,
      topic: json['topic'],
    );
  }
}
