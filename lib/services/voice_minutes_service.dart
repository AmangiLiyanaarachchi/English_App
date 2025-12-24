import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoiceMinutesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user has voice minutes available for Community Plan
  static Future<Map<String, dynamic>> checkVoiceMinutes(String userId) async {
    try {
      final userDoc = await _firestore.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        return {
          'hasAccess': false,
          'remainingMinutes': 0,
          'totalMinutes': 0,
          'usedMinutes': 0,
          'message': 'User not found'
        };
      }

      final data = userDoc.data()!;

      // Check if user has Community Plan
      final subscriptions = data['subscriptions'];
      bool hasCommunityPlan = false;
      DateTime? planExpiry;

      if (subscriptions != null &&
          subscriptions is Map &&
          subscriptions['community'] != null) {
        final commSub = subscriptions['community'];
        if (commSub['expiryDate'] != null) {
          planExpiry = (commSub['expiryDate'] as Timestamp).toDate();
          if (planExpiry.isAfter(DateTime.now())) {
            hasCommunityPlan = true;
          }
        }
      }

      if (!hasCommunityPlan) {
        return {
          'hasAccess': false,
          'remainingMinutes': 0,
          'totalMinutes': 0,
          'usedMinutes': 0,
          'message': 'No active Community Plan'
        };
      }

      // Get voice minutes data
      int totalMinutes = data['voiceTotalMinutes'] ?? 0;
      int usedMinutes = data['voiceUsedMinutes'] ?? 0;
      bool voiceEnabled = data['voiceEnabled'] ?? false;

      int remainingMinutes = totalMinutes - usedMinutes;

      // Check if voice is enabled and has minutes
      if (!voiceEnabled || remainingMinutes <= 0) {
        return {
          'hasAccess': false,
          'remainingMinutes': 0,
          'totalMinutes': totalMinutes,
          'usedMinutes': usedMinutes,
          'message': 'Voice minutes finished. Please buy a top-up package.'
        };
      }

      return {
        'hasAccess': true,
        'remainingMinutes': remainingMinutes,
        'totalMinutes': totalMinutes,
        'usedMinutes': usedMinutes,
        'planExpiry': planExpiry,
        'message': 'Access granted'
      };
    } catch (e) {
      print("Error checking voice minutes: $e");
      return {
        'hasAccess': false,
        'remainingMinutes': 0,
        'totalMinutes': 0,
        'usedMinutes': 0,
        'message': 'Error: $e'
      };
    }
  }

  /// Add voice call duration to user's used minutes
  static Future<void> addCallDuration(
      String userId, int durationInSeconds) async {
    try {
      final userDoc = await _firestore.collection("users").doc(userId).get();

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      int currentUsedMinutes = data['voiceUsedMinutes'] ?? 0;
      int totalMinutes = data['voiceTotalMinutes'] ?? 0;

      // Convert seconds to minutes (round up)
      int callMinutes = (durationInSeconds / 60).ceil();

      // Update used minutes
      int newUsedMinutes = currentUsedMinutes + callMinutes;

      // Check if should disable
      bool shouldDisable = newUsedMinutes >= totalMinutes;

      // Update Firestore
      await _firestore.collection("users").doc(userId).update({
        'voiceUsedMinutes': newUsedMinutes,
        'voiceEnabled': !shouldDisable,
      });

      print("✅ Voice call duration added: $callMinutes minutes");
    } catch (e) {
      print("❌ Error adding call duration: $e");
    }
  }

  /// Get voice minutes info for display
  static Future<String> getVoiceMinutesDisplay(String userId) async {
    final result = await checkVoiceMinutes(userId);

    if (!result['hasAccess']) {
      return "No voice minutes available";
    }

    int remaining = result['remainingMinutes'];
    return "Voice: $remaining min left";
  }
}
