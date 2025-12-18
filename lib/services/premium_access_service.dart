import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PremiumAccessService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user has access to a specific feature
  static Future<bool> hasFeatureAccess(String feature) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection("users").doc(user.uid).get();

      if (!userDoc.exists) return false;

      final data = userDoc.data();

      // NEW: Check individual subscription expiry dates
      final subscriptions = data?['subscriptions'];
      if (subscriptions != null && subscriptions is Map) {
        // Check specific feature subscription
        if (feature == 'community' && subscriptions['community'] != null) {
          final communitySub = subscriptions['community'];
          if (communitySub['expiryDate'] != null) {
            DateTime expiry = (communitySub['expiryDate'] as Timestamp).toDate();
            if (expiry.isAfter(DateTime.now())) {
              return true; // Community subscription is active
            }
          }
        }
        
        if (feature == 'ai_agent' && subscriptions['ai_agent'] != null) {
          final aiSub = subscriptions['ai_agent'];
          if (aiSub['expiryDate'] != null) {
            DateTime expiry = (aiSub['expiryDate'] as Timestamp).toDate();
            if (expiry.isAfter(DateTime.now())) {
              return true; // AI Agent subscription is active
            }
          }
        }
      }

      // Fallback: Check old unlocked features method (for backward compatibility)
      final unlockedFeatures = data?['unlockedFeatures'];
      if (unlockedFeatures != null && unlockedFeatures is List) {
        if (unlockedFeatures.contains(feature)) {
          // Still check global expiry date for old subscriptions
          final expiryDate = data?['expiryDate'];
          if (expiryDate != null) {
            DateTime expiry = (expiryDate as Timestamp).toDate();
            if (expiry.isAfter(DateTime.now())) {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      print("Error checking feature access: $e");
      return false;
    }
  }

  /// Get all unlocked features for current user
  static Future<List<String>> getUnlockedFeatures() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection("users").doc(user.uid).get();

      if (!userDoc.exists) return [];

      final data = userDoc.data();
      List<String> activeFeatures = [];

      // NEW: Check individual subscriptions
      final subscriptions = data?['subscriptions'];
      if (subscriptions != null && subscriptions is Map) {
        // Check community subscription
        if (subscriptions['community'] != null) {
          final communitySub = subscriptions['community'];
          if (communitySub['expiryDate'] != null) {
            DateTime expiry = (communitySub['expiryDate'] as Timestamp).toDate();
            if (expiry.isAfter(DateTime.now())) {
              activeFeatures.add('community');
            }
          }
        }
        
        // Check AI agent subscription
        if (subscriptions['ai_agent'] != null) {
          final aiSub = subscriptions['ai_agent'];
          if (aiSub['expiryDate'] != null) {
            DateTime expiry = (aiSub['expiryDate'] as Timestamp).toDate();
            if (expiry.isAfter(DateTime.now())) {
              activeFeatures.add('ai_agent');
            }
          }
        }
      }

      // If we found active features from subscriptions, return them
      if (activeFeatures.isNotEmpty) {
        return activeFeatures;
      }

      // Fallback: Check old unlocked features (backward compatibility)
      final unlockedFeatures = data?['unlockedFeatures'];
      if (unlockedFeatures is List) {
        return List<String>.from(unlockedFeatures);
      }

      return [];
    } catch (e) {
      print("Error getting unlocked features: $e");
      return [];
    }
  }

  /// Check if user has any active subscription
  static Future<bool> hasActiveSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection("users").doc(user.uid).get();

      if (!userDoc.exists) return false;

      final data = userDoc.data();
      final paymentStatus = data?['paymentStatus'] ?? '';

      if (paymentStatus != 'paid') return false;

      // Check expiry date
      final expiryDate = data?['expiryDate'];
      if (expiryDate != null) {
        DateTime expiry = (expiryDate as Timestamp).toDate();
        if (expiry.isBefore(DateTime.now())) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print("Error checking subscription: $e");
      return false;
    }
  }

  /// Get subscription info
  static Future<Map<String, dynamic>?> getSubscriptionInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection("users").doc(user.uid).get();

      if (!userDoc.exists) return null;

      final data = userDoc.data();

      return {
        'package': data?['package'] ?? 'None',
        'duration': data?['duration'] ?? '',
        'price': data?['price'] ?? 0,
        'paymentStatus': data?['paymentStatus'] ?? 'unpaid',
        'expiryDate': data?['expiryDate'],
        'unlockedFeatures': data?['unlockedFeatures'] ?? [],
      };
    } catch (e) {
      print("Error getting subscription info: $e");
      return null;
    }
  }

  /// Show access denied dialog
  static void showAccessDeniedDialog(BuildContext context, String featureName,
      {VoidCallback? onNavigateToPremium}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Premium Feature 🔒"),
        content: Text(
          "You need to subscribe to access $featureName.\n\nPlease upgrade your plan from the Premium tab.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              // Call the callback to navigate to Premium tab
              if (onNavigateToPremium != null) {
                onNavigateToPremium();
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
