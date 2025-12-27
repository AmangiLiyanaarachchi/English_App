import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/status_model.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Create text status
  Future<void> createTextStatus(String text) async {
    if (currentUser == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    final status = StatusModel(
      statusId: '',
      ownerId: currentUser!.uid,
      ownerName: currentUser!.displayName ?? 'User',
      ownerPhoto: currentUser!.photoURL ?? '',
      type: 'text',
      text: text,
      createdAt: now,
      expiresAt: expiresAt,
    );

    await _firestore.collection('status').add(status.toFirestore());
  }

  // Create image status
  Future<void> createImageStatus(File imageFile) async {
    if (currentUser == null) throw Exception('User not logged in');

    // Upload image to Firebase Storage
    final fileName =
        '${currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = _storage.ref().child('status_images/$fileName');

    await storageRef.putFile(imageFile);
    final imageUrl = await storageRef.getDownloadURL();

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    final status = StatusModel(
      statusId: '',
      ownerId: currentUser!.uid,
      ownerName: currentUser!.displayName ?? 'User',
      ownerPhoto: currentUser!.photoURL ?? '',
      type: 'image',
      imageUrl: imageUrl,
      createdAt: now,
      expiresAt: expiresAt,
    );

    await _firestore.collection('status').add(status.toFirestore());
  }

  // Get all active statuses (not expired)
  Stream<List<StatusModel>> getActiveStatuses() {
    return _firestore
        .collection('status')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StatusModel.fromFirestore(doc))
          .toList();
    });
  }

  // Add view to status
  Future<void> addView(String statusId) async {
    if (currentUser == null) return;

    final statusRef = _firestore.collection('status').doc(statusId);
    final statusDoc = await statusRef.get();

    if (!statusDoc.exists) return;

    final status = StatusModel.fromFirestore(statusDoc);

    // Check if user already viewed
    final alreadyViewed = status.views.any((v) => v.uid == currentUser!.uid);
    if (alreadyViewed) return;

    await statusRef.update({
      'views': FieldValue.arrayUnion([
        {
          'uid': currentUser!.uid,
          'viewedAt': Timestamp.now(),
        }
      ])
    });
  }

  // Add comment to status
  Future<void> addComment(String statusId, String comment) async {
  if (currentUser == null) throw Exception('User not logged in');

  final statusRef = _firestore.collection('status').doc(statusId);

  await statusRef.update({
    'comments': FieldValue.arrayUnion([
      {
        'uid': currentUser!.uid,
        'comment': comment,
        'userName': currentUser!.displayName ?? 'User',
        'userPhoto': currentUser!.photoURL ?? '',
        'commentedAt': Timestamp.now(),
      }
    ]),
    'commentCount': FieldValue.increment(1), // ✅ ADD THIS
  });
}


  // Delete status
  Future<void> deleteStatus(String statusId) async {
    if (currentUser == null) return;

    final statusDoc = await _firestore.collection('status').doc(statusId).get();
    if (!statusDoc.exists) return;

    final status = StatusModel.fromFirestore(statusDoc);

    // Only owner can delete
    if (status.ownerId != currentUser!.uid) return;

    // Delete image from storage if exists
    if (status.type == 'image' && status.imageUrl != null) {
      try {
        final ref = _storage.refFromURL(status.imageUrl!);
        await ref.delete();
      } catch (e) {
        // Image already deleted or doesn't exist
      }
    }

    await _firestore.collection('status').doc(statusId).delete();
  }

  // Client-side cleanup of expired statuses (called periodically)
  Future<void> cleanupExpiredStatuses() async {
    final now = Timestamp.now();
    final expiredDocs = await _firestore
        .collection('status')
        .where('expiresAt', isLessThanOrEqualTo: now)
        .get();

    for (var doc in expiredDocs.docs) {
      final status = StatusModel.fromFirestore(doc);

      // Delete image from storage if exists
      if (status.type == 'image' && status.imageUrl != null) {
        try {
          final ref = _storage.refFromURL(status.imageUrl!);
          await ref.delete();
        } catch (e) {
          // Image already deleted
        }
      }

      await doc.reference.delete();
    }
  }

  // Get user's own statuses
  Stream<List<StatusModel>> getUserStatuses(String userId) {
    return _firestore
        .collection('status')
        .where('ownerId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StatusModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> updateUserInfoInStatuses({
  required String userId,
  required String newName,
  required String newPhoto,
}) async {
  final snapshot = await _firestore
      .collection('status') // ✅ CORRECT
      .where('ownerId', isEqualTo: userId)
      .get();

  if (snapshot.docs.isEmpty) {
    print('⚠️ No statuses found for user');
    return;
  }

 
  final batch = _firestore.batch();

  for (final doc in snapshot.docs) {
    batch.update(doc.reference, {
      'ownerName': newName,
      'ownerPhoto': newPhoto,
    });
  }

  await batch.commit();
  print('✅ Updated ${snapshot.docs.length} statuses');
}

}
