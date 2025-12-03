import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/call_history_model.dart';

class CallHistoryService {
  static const String _boxName = 'call_history';
  Box<CallHistoryModel>? _callHistoryBox;

  // Initialize Hive box
  Future<void> initialize() async {
    if (_callHistoryBox != null && _callHistoryBox!.isOpen) {
      return;
    }
    _callHistoryBox = await Hive.openBox<CallHistoryModel>(_boxName);
  }

  // Save call to history
  Future<void> saveCall(CallHistoryModel call) async {
    await initialize();
    await _callHistoryBox!.put(call.callId, call);
  }

  // Get all call history (sorted by timestamp, newest first)
  Future<List<CallHistoryModel>> getAllCalls() async {
    await initialize();
    final calls = _callHistoryBox!.values.toList();
    calls.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return calls;
  }

  // Get call history for a specific user
  Future<List<CallHistoryModel>> getCallsWithUser(String userId) async {
    await initialize();
    final currentUserId = await _getCurrentUserId();

    final calls = _callHistoryBox!.values.where((call) {
      return (call.callerId == currentUserId && call.receiverId == userId) ||
          (call.receiverId == currentUserId && call.callerId == userId);
    }).toList();

    calls.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return calls;
  }

  // Get recent calls (last N calls)
  Future<List<CallHistoryModel>> getRecentCalls({int limit = 50}) async {
    await initialize();
    final calls = _callHistoryBox!.values.toList();
    calls.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return calls.take(limit).toList();
  }

  // Get missed calls count
  Future<int> getMissedCallsCount() async {
    await initialize();
    final currentUserId = await _getCurrentUserId();

    return _callHistoryBox!.values.where((call) {
      return call.receiverId == currentUserId &&
          call.status == 'missed' &&
          call.callType == 'incoming';
    }).length;
  }

  // Delete a specific call
  Future<void> deleteCall(String callId) async {
    await initialize();
    await _callHistoryBox!.delete(callId);
  }

  // Clear all call history
  Future<void> clearAllHistory() async {
    await initialize();
    await _callHistoryBox!.clear();
  }

  // Delete old calls (older than specified days)
  Future<void> deleteOldCalls({int daysToKeep = 30}) async {
    await initialize();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    final keysToDelete = <String>[];
    for (var call in _callHistoryBox!.values) {
      if (call.timestamp.isBefore(cutoffDate)) {
        keysToDelete.add(call.callId);
      }
    }

    for (var key in keysToDelete) {
      await _callHistoryBox!.delete(key);
    }
  }

  // Get call statistics
  Future<Map<String, int>> getCallStatistics() async {
    await initialize();
    final currentUserId = await _getCurrentUserId();

    int totalCalls = 0;
    int outgoingCalls = 0;
    int incomingCalls = 0;
    int missedCalls = 0;
    int totalDuration = 0;

    for (var call in _callHistoryBox!.values) {
      if (call.callerId == currentUserId || call.receiverId == currentUserId) {
        totalCalls++;
        totalDuration += call.duration;

        if (call.callType == 'outgoing') {
          outgoingCalls++;
        } else if (call.callType == 'incoming') {
          incomingCalls++;
          if (call.status == 'missed') {
            missedCalls++;
          }
        }
      }
    }

    return {
      'total': totalCalls,
      'outgoing': outgoingCalls,
      'incoming': incomingCalls,
      'missed': missedCalls,
      'totalDuration': totalDuration,
    };
  }

  // Helper method to get current user ID
  Future<String> _getCurrentUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.uid ?? '';
  }

  // Listen to call history changes
  Stream<List<CallHistoryModel>> watchCallHistory() {
    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      return _callHistoryBox?.values.toList() ?? [];
    });
  }

  // Close the box
  Future<void> close() async {
    await _callHistoryBox?.close();
  }
}
