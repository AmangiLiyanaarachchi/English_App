import 'package:cloud_firestore/cloud_firestore.dart';

class RandomCallService {
  static final RandomCallService _instance = RandomCallService._internal();
  factory RandomCallService() => _instance;
  RandomCallService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Maximum TOTAL duration allowed per user (3 minutes in seconds)
  static const int maxTotalDurationSeconds = 180; // 3 minutes TOTAL

  /// Check if user can make a random call
  Future<Map<String, dynamic>> checkRandomCallPermission(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        // Initialize user data if not exists
        await _initializeUserRandomCallData(userId);
        return {
          'canCall': true,
          'remainingSeconds': maxTotalDurationSeconds,
          'totalSecondsUsed': 0,
          'randomCallEnabled': true,
        };
      }

      final data = userDoc.data()!;
      final totalSecondsUsed = data['randomCallTotalSeconds'] ?? 0;
      final randomCallEnabled = data['randomCallEnabled'] ?? true;
      final remainingSeconds = maxTotalDurationSeconds - totalSecondsUsed;

      return {
        'canCall':
            randomCallEnabled && totalSecondsUsed < maxTotalDurationSeconds,
        'remainingSeconds': remainingSeconds > 0 ? remainingSeconds : 0,
        'totalSecondsUsed': totalSecondsUsed,
        'randomCallEnabled': randomCallEnabled,
      };
    } catch (e) {
      print('❌ Error checking random call permission: $e');
      rethrow;
    }
  }

  /// Initialize random call data for a new user
  Future<void> _initializeUserRandomCallData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'randomCallTotalSeconds': 0,
        'randomCallEnabled': true,
      }, SetOptions(merge: true));
      print('✅ Initialized random call data for user: $userId');
    } catch (e) {
      print('❌ Error initializing random call data: $e');
      rethrow;
    }
  }

  /// Add call duration to user's total time
  Future<void> addCallDuration(String userId, int durationSeconds) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          // Initialize if not exists
          transaction.set(
              userRef,
              {
                'randomCallTotalSeconds': durationSeconds,
                'randomCallEnabled': durationSeconds < maxTotalDurationSeconds,
              },
              SetOptions(merge: true));
          return;
        }

        final currentTotal = snapshot.data()?['randomCallTotalSeconds'] ?? 0;
        final newTotal = currentTotal + durationSeconds;

        // Update total
        transaction.update(userRef, {
          'randomCallTotalSeconds': newTotal,
          'randomCallEnabled': newTotal < maxTotalDurationSeconds,
        });

        print(
            '✅ Random call time updated: $newTotal/$maxTotalDurationSeconds seconds');

        // Disable if limit reached
        if (newTotal >= maxTotalDurationSeconds) {
          print('🚫 Random call time limit reached for user: $userId');
        }
      });
    } catch (e) {
      print('❌ Error adding call duration: $e');
      rethrow;
    }
  }

  /// Reset random call time (admin function or for testing)
  Future<void> resetRandomCallCount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'randomCallTotalSeconds': 0,
        'randomCallEnabled': true,
      });
      print('✅ Random call time reset for user: $userId');
    } catch (e) {
      print('❌ Error resetting random call time: $e');
      rethrow;
    }
  }

  /// Get current random call status
  Stream<Map<String, dynamic>> watchRandomCallStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return {
          'totalSecondsUsed': 0,
          'randomCallEnabled': true,
          'remainingSeconds': maxTotalDurationSeconds,
        };
      }

      final data = snapshot.data()!;
      final totalSeconds = data['randomCallTotalSeconds'] ?? 0;
      final enabled = data['randomCallEnabled'] ?? true;
      final remaining = maxTotalDurationSeconds - totalSeconds;

      return {
        'totalSecondsUsed': totalSeconds,
        'randomCallEnabled': enabled,
        'remainingSeconds': remaining > 0 ? remaining : 0,
      };
    });
  }
}
