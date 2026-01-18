import 'package:flutter/material.dart';
import 'dart:async';
import '../services/agora_service.dart';
import '../services/firebase_service.dart';
import '../models/user.dart' as models;
import '../models/recording.dart';

class AudioChatScreen extends StatefulWidget {
  final models.UserModel partner;
  final models.UserModel currentUser;

  const AudioChatScreen({
    super.key,
    required this.partner,
    required this.currentUser,
  });

  @override
  State<AudioChatScreen> createState() => _AudioChatScreenState();
}

class _AudioChatScreenState extends State<AudioChatScreen> {
  final _agoraService = AgoraService();
  final _firebaseService = FirebaseService();
  bool _isMuted = false;
  bool _isJoined = false;
  int _duration = 0;
  Timer? _timer;
  String? _sessionId;
  final int _maxDuration = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await _agoraService.initialize();

      // Generate channel name
      final channelName = AgoraService.generateChannelName(
        widget.currentUser.uid,
        widget.partner.uid,
      );

      // Create audio session
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firebaseService.createAudioSession(
        AudioSession(
          id: _sessionId!,
          channelName: channelName,
          participants: [widget.currentUser.uid, widget.partner.uid],
          startTime: DateTime.now(),
        ),
      );

      // Join channel
      await _agoraService.joinChannel(channelName);

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _duration++;
            if (_duration >= _maxDuration) {
              _endCall();
            }
          });
        }
      });

      setState(() => _isJoined = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting call: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _agoraService.toggleMute();
  }

  Future<void> _endCall() async {
    _timer?.cancel();

    // Update session
    if (_sessionId != null) {
      await _firebaseService.updateAudioSession(_sessionId!, {
        'endTime': DateTime.now(),
        'duration': _duration,
        'isActive': false,
      });

      // Update user stats
      final minutes = (_duration / 60).round();
      await _firebaseService.incrementUserStats(
        widget.currentUser.uid,
        chats: 1,
        minutes: minutes,
        karma: minutes * 2,
      );

      // Check for badges
      if (widget.currentUser.totalChats + 1 >= 10) {
        await _firebaseService.awardBadge(widget.currentUser.uid, 'Chatty');
      }
      if ((widget.currentUser.totalMinutes + minutes) >= 100) {
        await _firebaseService.awardBadge(widget.currentUser.uid, 'Fluent Fox');
      }
    }

    await _agoraService.leaveChannel();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A9D8F),
      appBar: AppBar(
        title: const Text('Audio Chat'),
        backgroundColor: const Color(0xFF264653),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Partner Info
              Column(
                children: [
                  const SizedBox(height: 32),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: widget.partner.photoUrl != null
                        ? NetworkImage(widget.partner.photoUrl!)
                        : null,
                    child: widget.partner.photoUrl == null
                        ? Text(
                            widget.partner.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              color: Color(0xFF2A9D8F),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.partner.displayName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.partner.englishLevel.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  LinearProgressIndicator(
                    value: _duration / _maxDuration,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_maxDuration - _duration} seconds remaining',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),

              // Controls
              Column(
                children: [
                  // English reminder
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Remember: English only! 😊',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Call controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      FloatingActionButton(
                        onPressed: _toggleMute,
                        backgroundColor: _isMuted ? Colors.red : Colors.white,
                        child: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color:
                              _isMuted ? Colors.white : const Color(0xFF2A9D8F),
                        ),
                      ),

                      // End call button
                      FloatingActionButton.extended(
                        onPressed: _endCall,
                        backgroundColor: Colors.red,
                        icon: const Icon(Icons.call_end, color: Colors.white),
                        label: const Text(
                          'End Call',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _agoraService.dispose();
    super.dispose();
  }
}
