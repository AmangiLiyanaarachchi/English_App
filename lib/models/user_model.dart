// class UserModel {
//   final String uid;
//   final String email;
//   final String displayName;
//   final String? photoUrl;
//   final bool isOnline;
//   final DateTime? lastSeen;

//   UserModel({
//     required this.uid,
//     required this.email,
//     required this.displayName,
//     this.photoUrl,
//     this.isOnline = false,
//     this.lastSeen,
//   });

//   factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
//     return UserModel(
//       uid: uid,
//       email: map['email'] ?? '',
//       displayName: map['displayName'] ?? 'User',
//       photoUrl: map['photoUrl'],
//       isOnline: map['isOnline'] ?? false,
//       lastSeen: map['lastSeen'] != null
//           ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
//           : null,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'email': email,
//       'displayName': displayName,
//       'photoUrl': photoUrl,
//       'isOnline': isOnline,
//       'lastSeen': lastSeen?.millisecondsSinceEpoch,
//     };
//   }
// }
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  // Premium package
  final String? package;

  // AI Agent fields
  final String? planType; // "AI_1000" | "AI_2500" | "FREE"
  final int? aiTotalSeconds; // Total allowed seconds (1200 or 2700)
  final int? aiUsedSeconds; // Already used seconds
  final bool? aiEnabled; // Can access AI Agent or not

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,

    // Premium package
    this.package,

    // AI Agent fields
    this.planType,
    this.aiTotalSeconds,
    this.aiUsedSeconds,
    this.aiEnabled,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'User',
      photoUrl: map['photoUrl'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : null,

      // Read from Firestore
      package: map['package'],

      // AI Agent fields
      planType: map['planType'],
      aiTotalSeconds: map['aiTotalSeconds'],
      aiUsedSeconds: map['aiUsedSeconds'],
      aiEnabled: map['aiEnabled'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,

      // Write to Firestore
      'package': package,

      // AI Agent fields
      'planType': planType,
      'aiTotalSeconds': aiTotalSeconds,
      'aiUsedSeconds': aiUsedSeconds,
      'aiEnabled': aiEnabled,
    };
  }
}
