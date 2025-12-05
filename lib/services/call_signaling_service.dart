import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/call_model.dart';

class CallSignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _incomingCallSubscription;

  // Create a new call request
  Future<CallModel> createCall({
    required String receiverId,
    required String receiverName,
    required String receiverPhotoUrl,
    required String callerName,
    required String callerPhotoUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final callId =
        '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}';
    final agoraChannelId = _generateChannelId(currentUser.uid, receiverId);

    print('📞 CALL: Creating call with ID: $callId');
    print('📞 CALL: Caller: ${currentUser.uid}');
    print('📞 CALL: Receiver: $receiverId');
    print('📞 CALL: Agora Channel: "$agoraChannelId"');

    final call = CallModel(
      callId: callId,
      callerId: currentUser.uid,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverPhotoUrl: receiverPhotoUrl,
      agoraChannelId: agoraChannelId,
      status: 'calling',
      timestamp: DateTime.now(),
    );

    // Save to Firestore
    await _firestore.collection('calls').doc(callId).set(call.toMap());

    return call;
  }

  // Listen for incoming calls
  Stream<CallModel?> listenForIncomingCalls() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      // Return the most recent call only if it's within the last 30 seconds
      final doc = snapshot.docs.first;
      final call = CallModel.fromMap(doc.data());

      // Check if call is recent (within 30 seconds)
      final now = DateTime.now();
      final callAge = now.difference(call.timestamp).inSeconds;

      if (callAge > 30) {
        // Call is too old, mark as missed and don't show
        _firestore.collection('calls').doc(call.callId).update({
          'status': 'missed',
        });
        return null;
      }

      return call;
    });
  }

  // Accept a call
  Future<void> acceptCall(String callId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('calls').doc(callId).update({
      'status': 'accepted',
      'acceptedBy': currentUser.uid,
    });
  }

  // Reject a call
  Future<void> rejectCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'rejected',
    });
  }

  // End a call
  Future<void> endCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'ended',
    });
  }

  // Cancel a call (caller cancels before receiver answers)
  Future<void> cancelCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'cancelled',
    });
  }

  // Mark call as missed
  Future<void> markCallAsMissed(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'missed',
    });
  }

  // Listen for call status changes
  Stream<CallModel?> listenToCallStatus(String callId) {
    return _firestore
        .collection('calls')
        .doc(callId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return CallModel.fromMap(snapshot.data()!);
    });
  }

  // Delete a call document
  Future<void> deleteCall(String callId) async {
    await _firestore.collection('calls').doc(callId).delete();
  }

  // Generate channel ID for Agora
  String _generateChannelId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    final channelId = '${ids[0]}_${ids[1]}';
    print('🎬 CHANNEL: Generated channel ID: "$channelId"');
    print('🎬 CHANNEL: From users: $userId1 + $userId2');
    print('🎬 CHANNEL: Sorted: ${ids[0]} + ${ids[1]}');
    return channelId;
  }

  // Check if there's an active call for the user
  Future<CallModel?> getActiveCall() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    // Check if user is caller
    final callerQuery = await _firestore
        .collection('calls')
        .where('callerId', isEqualTo: currentUser.uid)
        .where('status', whereIn: ['calling', 'accepted'])
        .limit(1)
        .get();

    if (callerQuery.docs.isNotEmpty) {
      return CallModel.fromMap(callerQuery.docs.first.data());
    }

    // Check if user is receiver
    final receiverQuery = await _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('status', whereIn: ['calling', 'accepted'])
        .limit(1)
        .get();

    if (receiverQuery.docs.isNotEmpty) {
      return CallModel.fromMap(receiverQuery.docs.first.data());
    }

    return null;
  }

  // Clean up old calls (optional - can be called periodically)
  Future<void> cleanupOldCalls() async {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

    final oldCalls = await _firestore
        .collection('calls')
        .where('timestamp', isLessThan: oneHourAgo.toIso8601String())
        .get();

    for (var doc in oldCalls.docs) {
      await doc.reference.delete();
    }
  }

  // Dispose
  void dispose() {
    _incomingCallSubscription?.cancel();
  }
}
