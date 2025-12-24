import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/call_model.dart';
import '../services/call_signaling_service.dart';
import '../services/agora_service.dart';
import '../services/call_history_service.dart';
import '../services/random_call_service.dart';
import '../services/voice_minutes_service.dart';
import '../models/call_history_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoiceCallScreen extends StatefulWidget {
  final CallModel call;
  final bool isOutgoing;
  final bool isRandomCall; // NEW: Track if this is a random call

  const VoiceCallScreen({
    Key? key,
    required this.call,
    required this.isOutgoing,
    this.isRandomCall = false, // Default to false
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final CallSignalingService _signalingService = CallSignalingService();
  final AgoraService _agoraService = AgoraService();
  final CallHistoryService _historyService = CallHistoryService();
  final RandomCallService _randomCallService = RandomCallService(); // NEW

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  String _callStatus = 'Connecting...';
  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _timeoutTimer;
  Timer? _maxCallTimer; // NEW: Timer for 3-minute limit
  StreamSubscription? _callStatusSubscription;
  StreamSubscription? _userJoinedSubscription;
  bool _isCallConnected = false;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      // Listen to call status changes
      _callStatusSubscription = _signalingService
          .listenToCallStatus(widget.call.callId)
          .listen((updatedCall) {
        if (updatedCall == null) return;

        if (updatedCall.status == 'accepted' && !_isCallConnected) {
          setState(() {
            _callStatus = 'Connected';
            _isCallConnected = true;
          });
          _startDurationTimer();
        } else if (updatedCall.status == 'ended' ||
            updatedCall.status == 'rejected' ||
            updatedCall.status == 'cancelled') {
          _endCall(wasRejected: updatedCall.status == 'rejected');
        }
      });

      // Listen to Agora user joined event
      _userJoinedSubscription = _agoraService.onUserJoined.listen((_) {
        if (!_isCallConnected) {
          setState(() {
            _callStatus = 'Connected';
            _isCallConnected = true;
          });
          _startDurationTimer();
          // Enable speaker after connection with proper delay
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _agoraService.setSpeakerOn(true);
              setState(() {
                _isSpeakerOn = true;
              });
            }
          });
        }
      });

      // Set initial audio route to speaker immediately after initialization
      await Future.delayed(const Duration(milliseconds: 500));
      await _agoraService.setSpeakerOn(true);

      // Set initial status
      if (widget.isOutgoing) {
        setState(() {
          _callStatus = 'Calling...';
        });
        // Set timeout for outgoing calls (60 seconds)
        _timeoutTimer = Timer(const Duration(seconds: 60), () {
          if (!_isCallConnected && mounted) {
            print('Call timeout - no answer');
            _endCall();
          }
        });
      } else {
        setState(() {
          _callStatus = 'Connected';
          _isCallConnected = true;
        });
        _startDurationTimer();
      }
    } catch (e) {
      print('Error initializing call: $e');
      _showError('Failed to initialize call');
      // End the call and close the screen
      await _endCall();
    }
  }

  void _startDurationTimer() async {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });

    // NEW: Start timer for random calls based on remaining time
    if (widget.isRandomCall) {
      // Get remaining time for this user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final permission =
            await _randomCallService.checkRandomCallPermission(currentUser.uid);
        final remainingSeconds = permission['remainingSeconds'] as int;

        if (remainingSeconds > 0) {
          _maxCallTimer = Timer(
            Duration(seconds: remainingSeconds),
            () {
              if (mounted && !_isEnding) {
                print('⏰ Random call time limit reached - auto ending call');
                _showTimeLimitMessage();
                _endCall();
              }
            },
          );
          print(
              '⏱️ Timer started for random call - $remainingSeconds seconds remaining');
        } else {
          // No time left, end immediately
          print('⏰ No random call time remaining - ending call');
          _endCall();
        }
      }
    }
  }

  void _showTimeLimitMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call ended - time limit reached'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    try {
      await _agoraService.toggleMute();
      setState(() {
        _isMuted = !_isMuted;
      });
    } catch (e) {
      print('Error toggling mute: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    try {
      final newSpeakerState = !_isSpeakerOn;
      await _agoraService.setSpeakerOn(newSpeakerState);
      setState(() {
        _isSpeakerOn = newSpeakerState;
      });
    } catch (e) {
      print('Error toggling speaker: $e');
    }
  }

  Future<void> _endCall({bool wasRejected = false}) async {
    // Prevent multiple calls to _endCall
    if (_isEnding) return;
    _isEnding = true;

    try {
      // Stop timers
      _durationTimer?.cancel();
      _timeoutTimer?.cancel();
      _maxCallTimer?.cancel(); // NEW: Cancel 3-minute timer

      // Update call status in Firestore
      // If call was never connected and caller is ending, mark as cancelled
      print(
          '📞 ENDING CALL: isConnected=$_isCallConnected, isOutgoing=${widget.isOutgoing}');
      if (!_isCallConnected && widget.isOutgoing) {
        print(
            '📞 CANCELLING CALL: Caller ending before connection - setting status to cancelled');
        await _signalingService.cancelCall(widget.call.callId);
        print('✅ Call status updated to CANCELLED in Firestore');
      } else {
        print('📞 ENDING CALL: Normal end - setting status to ended');
        await _signalingService.endCall(widget.call.callId);
      }

      // Leave Agora channel
      await _agoraService.leaveChannel();

      // NEW: Add call duration to user's total time if this was a random call
      final currentUser = FirebaseAuth.instance.currentUser;
      if (widget.isRandomCall && currentUser != null && _callDuration > 0) {
        // Only count if call was connected (duration > 0)
        await _randomCallService.addCallDuration(
            currentUser.uid, _callDuration);
        print(
            '📊 Random call duration added: $_callDuration seconds for user: ${currentUser.uid}');
      }

      // NEW: Add call duration to voice minutes for Community Plan users
      if (!widget.isRandomCall && currentUser != null && _callDuration > 0) {
        // Track voice minutes for regular calls (not random calls)
        await VoiceMinutesService.addCallDuration(
            currentUser.uid, _callDuration);
        print(
            '🎤 Voice call duration added: $_callDuration seconds for user: ${currentUser.uid}');
      }

      // Save to call history
      if (currentUser != null) {
        final callType =
            widget.call.callerId == currentUser.uid ? 'outgoing' : 'incoming';

        final status = wasRejected
            ? 'rejected'
            : (_callDuration > 0 ? 'completed' : 'cancelled');

        final callHistory = CallHistoryModel(
          callId: widget.call.callId,
          callerId: widget.call.callerId,
          callerName: widget.call.callerName,
          callerPhotoUrl: widget.call.callerPhotoUrl,
          receiverId: widget.call.receiverId,
          receiverName: widget.call.receiverName,
          receiverPhotoUrl: widget.call.receiverPhotoUrl,
          callType: callType,
          status: status,
          duration: _callDuration,
          timestamp: widget.call.timestamp,
        );
        await _historyService.saveCall(callHistory);
      }

      // Close the screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error ending call: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    print('VoiceCallScreen disposing...');
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();
    _maxCallTimer?.cancel(); // NEW: Cancel 3-minute timer
    _callStatusSubscription?.cancel();
    _userJoinedSubscription?.cancel();
    // Call leaveChannel without await - it will complete asynchronously
    // This is necessary because dispose cannot be async
    _agoraService.leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserCaller = widget.call.callerId == currentUser?.uid;
    final otherUserName =
        isCurrentUserCaller ? widget.call.receiverName : widget.call.callerName;
    final otherUserPhoto = isCurrentUserCaller
        ? widget.call.receiverPhotoUrl
        : widget.call.callerPhotoUrl;

    return WillPopScope(
      onWillPop: () async {
        // When user presses back, end the call properly
        await _endCall();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _callStatus,
                      style: TextStyle(
                        color: _isCallConnected
                            ? Colors.green[400]
                            : Colors.orange[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // User profile picture
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.teal[400]!,
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: otherUserPhoto.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: otherUserPhoto,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.teal[700],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.teal[700],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.teal[700],
                          child: const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // User name
              Text(
                otherUserName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // Call duration
              Text(
                _formatDuration(_callDuration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                ),
              ),

              const Spacer(),

              // Control buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute button
                    _CallControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      isActive: _isMuted,
                      onPressed: _toggleMute,
                    ),

                    // End call button
                    GestureDetector(
                      onTap: () => _endCall(),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    // Speaker button
                    _CallControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                      isActive: _isSpeakerOn,
                      onPressed: _toggleSpeaker,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _CallControlButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? Colors.teal : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
