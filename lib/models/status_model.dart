// import 'package:cloud_firestore/cloud_firestore.dart';

// class StatusModel {
//   final String statusId;
//   final String ownerId;
//   final String ownerName;
//   final String ownerPhoto;
//   final String type; // 'image' or 'text'
//   final String? text;
//   final String? imageUrl;
//   final DateTime createdAt;
//   final DateTime expiresAt;
//   final List<StatusView> views;
//   final List<StatusComment> comments;
//   String get mediaUrl => imageUrl ?? '';
//   String get caption => text ?? '';


//   StatusModel({
//     required this.statusId,
//     required this.ownerId,
//     required this.ownerName,
//     required this.ownerPhoto,
//     required this.type,
//     this.text,
//     this.imageUrl,
//     required this.createdAt,
//     required this.expiresAt,
//     this.views = const [],
//     this.comments = const [],
//   });

//   factory StatusModel.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return StatusModel(
//       statusId: doc.id,
//       ownerId: data['ownerId'] ?? '',
//       ownerName: data['ownerName'] ?? '',
//       ownerPhoto: data['ownerPhoto'] ?? '',
//       type: data['type'] ?? 'text',
//       text: data['text'],
//       imageUrl: data['imageUrl'],
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//       expiresAt: (data['expiresAt'] as Timestamp).toDate(),
//       views: (data['views'] as List<dynamic>?)
//               ?.map((v) => StatusView.fromMap(v as Map<String, dynamic>))
//               .toList() ??
//           [],
//       comments: (data['comments'] as List<dynamic>?)
//               ?.map((c) => StatusComment.fromMap(c as Map<String, dynamic>))
//               .toList() ??
//           [],
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'ownerId': ownerId,
//       'ownerName': ownerName,
//       'ownerPhoto': ownerPhoto,
//       'type': type,
//       'text': text,
//       'imageUrl': imageUrl,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'expiresAt': Timestamp.fromDate(expiresAt),
//       'views': views.map((v) => v.toMap()).toList(),
//       'comments': comments.map((c) => c.toMap()).toList(),
//     };
//   }

//   int get viewCount => views.length;
//   int get commentCount => comments.length;
// }

// class StatusView {
//   final String uid;
//   final DateTime viewedAt;

//   StatusView({
//     required this.uid,
//     required this.viewedAt,
//   });

//   factory StatusView.fromMap(Map<String, dynamic> map) {
//     return StatusView(
//       uid: map['uid'] ?? '',
//       viewedAt: (map['viewedAt'] as Timestamp).toDate(),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'viewedAt': Timestamp.fromDate(viewedAt),
//     };
//   }
// }

// class StatusComment {
//   final String uid;
//   final String comment;
//   final DateTime commentedAt;
//   final String userName;
//   final String userPhoto;

//   StatusComment({
//     required this.uid,
//     required this.comment,
//     required this.commentedAt,
//     required this.userName,
//     required this.userPhoto,
//   });

//   factory StatusComment.fromMap(Map<String, dynamic> map) {
//     return StatusComment(
//       uid: map['uid'] ?? '',
//       comment: map['comment'] ?? '',
//       commentedAt: (map['commentedAt'] as Timestamp).toDate(),
//       userName: map['userName'] ?? '',
//       userPhoto: map['userPhoto'] ?? '',
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'comment': comment,
//       'commentedAt': Timestamp.fromDate(commentedAt),
//       'userName': userName,
//       'userPhoto': userPhoto,
//     };
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String statusId;
  final String ownerId;
  final String ownerName;
  final String ownerPhoto;
  final String type; // 'image' or 'text'
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<StatusView> views;
  final List<StatusComment> comments;

  // ✅ Safe convenience getters (so UI can use status.caption / status.mediaUrl)
  String get mediaUrl => imageUrl ?? '';
  String get caption => text ?? '';

  StatusModel({
    required this.statusId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhoto,
    required this.type,
    this.text,
    this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.views = const [],
    this.comments = const [],
  });

  factory StatusModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    return StatusModel(
      statusId: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerPhoto: data['ownerPhoto'] ?? '',
      type: data['type'] ?? 'text',
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,

      // ✅ crash-safe timestamps
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),

      // ✅ crash-safe list parsing
      views: (data['views'] as List<dynamic>?)
              ?.map((v) => StatusView.fromMap((v as Map).cast<String, dynamic>()))
              .toList() ??
          [],
      comments: (data['comments'] as List<dynamic>?)
              ?.map((c) =>
                  StatusComment.fromMap((c as Map).cast<String, dynamic>()))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhoto': ownerPhoto,
      'type': type,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'views': views.map((v) => v.toMap()).toList(),
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }

  int get viewCount => views.length;
  int get commentCount => comments.length;
}

class StatusView {
  final String uid;
  final DateTime viewedAt;

  StatusView({
    required this.uid,
    required this.viewedAt,
  });

  factory StatusView.fromMap(Map<String, dynamic> map) {
    return StatusView(
      uid: map['uid'] ?? '',
      viewedAt: (map['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'viewedAt': Timestamp.fromDate(viewedAt),
    };
  }
}

class StatusComment {
  final String uid;
  final String comment;
  final DateTime commentedAt;
  final String userName;
  final String userPhoto;

  StatusComment({
    required this.uid,
    required this.comment,
    required this.commentedAt,
    required this.userName,
    required this.userPhoto,
  });

  factory StatusComment.fromMap(Map<String, dynamic> map) {
    return StatusComment(
      uid: map['uid'] ?? '',
      comment: map['comment'] ?? '',
      commentedAt:
          (map['commentedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'comment': comment,
      'commentedAt': Timestamp.fromDate(commentedAt),
      'userName': userName,
      'userPhoto': userPhoto,
    };
  }
}
