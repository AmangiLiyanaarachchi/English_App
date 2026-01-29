import 'package:cloud_firestore/cloud_firestore.dart';

enum EnglishLevel { beginner, intermediate, advanced }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  //final String instituteCode;
  final EnglishLevel englishLevel;
  final List<String> interests;
  final String? photoUrl;
  final int karmaPoints;
  final int streakDays;
  final int totalChats;
  final int totalMinutes;
  final List<String> badges;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isOnline;

  // 🔥 ADD THIS
  final String? package;

  // Student verification fields
  final String? studentId;
  final bool? studentIdVerified;
  final DateTime? studentPlanStartDate;
  final DateTime? studentPlanEndDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    //required this.instituteCode,
    required this.englishLevel,
    required this.interests,
    this.photoUrl,
    this.karmaPoints = 0,
    this.streakDays = 0,
    this.totalChats = 0,
    this.totalMinutes = 0,
    this.badges = const [],
    required this.createdAt,
    required this.lastActive,
    this.isOnline = false,

    // 🔥 ADD THIS
    this.package,

    // Student verification fields
    this.studentId,
    this.studentIdVerified,
    this.studentPlanStartDate,
    this.studentPlanEndDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      //'instituteCode': instituteCode,
      'englishLevel': englishLevel.name,
      'interests': interests,
      'photoUrl': photoUrl,
      'karmaPoints': karmaPoints,
      'streakDays': streakDays,
      'totalChats': totalChats,
      'totalMinutes': totalMinutes,
      'badges': badges,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'isOnline': isOnline,

      // 🔥 ADD THIS
      'package': package,

      // Student verification fields
      'studentId': studentId,
      'studentIdVerified': studentIdVerified,
      'studentPlanStartDate': studentPlanStartDate != null
          ? Timestamp.fromDate(studentPlanStartDate!)
          : null,
      'studentPlanEndDate': studentPlanEndDate != null
          ? Timestamp.fromDate(studentPlanEndDate!)
          : null,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      //instituteCode: json['instituteCode'] ?? '',
      englishLevel: EnglishLevel.values.firstWhere(
        (e) => e.name == json['englishLevel'],
        orElse: () => EnglishLevel.beginner,
      ),
      interests: List<String>.from(json['interests'] ?? []),
      photoUrl: json['photoUrl'],
      karmaPoints: json['karmaPoints'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      totalChats: json['totalChats'] ?? 0,
      totalMinutes: json['totalMinutes'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive:
          (json['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: json['isOnline'] ?? false,

      // 🔥 READ FROM FIRESTORE
      package: json['package'],

      // Student verification fields
      studentId: json['studentId'],
      studentIdVerified: json['studentIdVerified'],
      studentPlanStartDate:
          (json['studentPlanStartDate'] as Timestamp?)?.toDate(),
      studentPlanEndDate: (json['studentPlanEndDate'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    return UserModel.fromJson({...data, 'uid': doc.id});
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? instituteCode,
    EnglishLevel? englishLevel,
    List<String>? interests,
    String? photoUrl,
    int? karmaPoints,
    int? streakDays,
    int? totalChats,
    int? totalMinutes,
    List<String>? badges,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isOnline,

    // 🔥 ADD THIS
    String? package,

    // Student verification fields
    String? studentId,
    bool? studentIdVerified,
    DateTime? studentPlanStartDate,
    DateTime? studentPlanEndDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      //instituteCode: instituteCode ?? this.instituteCode,
      englishLevel: englishLevel ?? this.englishLevel,
      interests: interests ?? this.interests,
      photoUrl: photoUrl ?? this.photoUrl,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      streakDays: streakDays ?? this.streakDays,
      totalChats: totalChats ?? this.totalChats,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,

      // 🔥 COPY
      package: package ?? this.package,

      // Student verification fields
      studentId: studentId ?? this.studentId,
      studentIdVerified: studentIdVerified ?? this.studentIdVerified,
      studentPlanStartDate: studentPlanStartDate ?? this.studentPlanStartDate,
      studentPlanEndDate: studentPlanEndDate ?? this.studentPlanEndDate,
    );
  }
}
