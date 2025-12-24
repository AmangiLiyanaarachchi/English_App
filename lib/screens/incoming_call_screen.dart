import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/call_model.dart';
import '../services/call_signaling_service.dart';
import '../services/agora_service.dart';
import '../services/call_history_service.dart';
import '../services/ringtone_service.dart';
import '../models/call_history_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'voice_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final CallModel call;

  const IncomingCallScreen({
    Key? key,
    required this.call,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallSignalingService _signalingService = CallSignalingService();
  final AgoraService _agoraService = AgoraService();
  final CallHistoryService _historyService = CallHistoryService();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Play ringtone
    RingtoneService.playRingtone();

    // Listen for call status changes (e.g., caller cancels)
    _listenToCallStatus();
  }

  void _listenToCallStatus() {
    _signalingService
        .listenToCallStatus(widget.call.callId)
        .listen((updatedCall) {
      if (updatedCall != null &&
          (updatedCall.status == 'cancelled' ||
              updatedCall.status == 'ended')) {
        // Caller cancelled or ended the call before receiver picked up
        print(
            '📱 INCOMING: Call status changed to ${updatedCall.status}, closing screen');
        RingtoneService.stopRingtone();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    RingtoneService.stopRingtone();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Stop ringtone
      RingtoneService.stopRingtone();

      // Request microphone permission before accepting
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Microphone permission is required for voice calls'),
            ),
          );
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Accept the call in Firestore
      await _signalingService.acceptCall(widget.call.callId);

      print(
          '📥 INCOMING: Call accepted, joining Agora channel: ${widget.call.agoraChannelId}');

      // Join Agora channel (initialize is handled internally)
      await _agoraService.joinChannel(widget.call.agoraChannelId);

      // Navigate to voice call screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
              call: widget.call,
              isOutgoing: false,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error accepting call: $e');
      // Leave the channel if we joined it before the error
      await _agoraService.leaveChannel().catchError((err) {
        print('Error leaving channel after failed accept: $err');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept call: $e')),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _rejectCall() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Stop ringtone
      RingtoneService.stopRingtone();

      // Reject the call
      await _signalingService.rejectCall(widget.call.callId);

      // Save to call history as rejected
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final callHistory = CallHistoryModel(
          callId: widget.call.callId,
          callerId: widget.call.callerId,
          callerName: widget.call.callerName,
          callerPhotoUrl: widget.call.callerPhotoUrl,
          receiverId: widget.call.receiverId,
          receiverName: widget.call.receiverName,
          receiverPhotoUrl: widget.call.receiverPhotoUrl,
          callType: 'incoming',
          status: 'rejected',
          duration: 0,
          timestamp: widget.call.timestamp,
        );
        await _historyService.saveCall(callHistory);
      }

      // Close the screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error rejecting call: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Incoming Call',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.call_received,
                    color: Colors.green[400],
                    size: 24,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Caller profile picture with animation
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.teal[400]!,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.call.callerPhotoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.call.callerPhotoUrl,
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
                );
              },
            ),

            const SizedBox(height: 30),

            // Caller name
            Text(
              widget.call.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Call status
            Text(
              'Voice Call...',
              style: TextStyle(
                color: Colors.teal[300],
                fontSize: 16,
              ),
            ),

            const Spacer(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  _CallActionButton(
                    icon: Icons.call_end,
                    label: 'Reject',
                    backgroundColor: Colors.red,
                    onPressed: _isProcessing ? null : _rejectCall,
                  ),

                  // Accept button
                  _CallActionButton(
                    icon: Icons.call,
                    label: 'Accept',
                    backgroundColor: Colors.green,
                    onPressed: _isProcessing ? null : _acceptCall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  const _CallActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: onPressed == null
                  ? backgroundColor.withOpacity(0.5)
                  : backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
