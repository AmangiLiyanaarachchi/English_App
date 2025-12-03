import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/call_history_model.dart';
import '../services/call_history_service.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({Key? key}) : super(key: key);

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final CallHistoryService _historyService = CallHistoryService();
  List<CallHistoryModel> _callHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    try {
      final history = await _historyService.getAllCalls();
      if (mounted) {
        setState(() {
          _callHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading call history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Call History'),
        content:
            const Text('Are you sure you want to delete all call history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearAllHistory();
      _loadCallHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call history cleared')),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  IconData _getCallIcon(CallHistoryModel call) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOutgoing = call.callerId == currentUser?.uid;

    if (call.status == 'missed' && !isOutgoing) {
      return Icons.call_missed;
    } else if (isOutgoing) {
      return Icons.call_made;
    } else {
      return Icons.call_received;
    }
  }

  Color _getCallIconColor(CallHistoryModel call) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOutgoing = call.callerId == currentUser?.uid;

    if (call.status == 'missed' && !isOutgoing) {
      return Colors.red;
    } else if (call.status == 'rejected') {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getOtherUserName(CallHistoryModel call) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (call.callerId == currentUser?.uid) {
      return call.receiverName;
    } else {
      return call.callerName;
    }
  }

  String _getOtherUserPhoto(CallHistoryModel call) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (call.callerId == currentUser?.uid) {
      return call.receiverPhotoUrl;
    } else {
      return call.callerPhotoUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        actions: [
          if (_callHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear History',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _callHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_disabled,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No call history',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCallHistory,
                  child: ListView.builder(
                    itemCount: _callHistory.length,
                    itemBuilder: (context, index) {
                      final call = _callHistory[index];
                      final otherUserName = _getOtherUserName(call);
                      final otherUserPhoto = _getOtherUserPhoto(call);

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF4A90A4),
                          backgroundImage: otherUserPhoto.isNotEmpty
                              ? CachedNetworkImageProvider(otherUserPhoto)
                              : null,
                          child: otherUserPhoto.isEmpty
                              ? Text(
                                  otherUserName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          otherUserName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              _getCallIcon(call),
                              size: 16,
                              color: _getCallIconColor(call),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              call.status == 'missed'
                                  ? 'Missed'
                                  : call.status == 'rejected'
                                      ? 'Rejected'
                                      : call.status == 'cancelled'
                                          ? 'Cancelled'
                                          : _formatDuration(call.duration),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTimestamp(call.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Could navigate to user profile or initiate new call
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
