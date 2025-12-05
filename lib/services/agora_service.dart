import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'audio_manager_service.dart';

class AgoraService {
  // Singleton instance
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  // Agora App ID - NEW PROJECT (Certificate Disabled)
  static const String appId = '588136a75db4448aa06dd979e14275d0';

  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  String? _currentChannel;

  final StreamController<bool> _joinedController =
      StreamController<bool>.broadcast();
  final StreamController<int> _userJoinedController =
      StreamController<int>.broadcast();
  final StreamController<int> _userLeftController =
      StreamController<int>.broadcast();

  Stream<bool> get onJoined => _joinedController.stream;
  Stream<int> get onUserJoined => _userJoinedController.stream;
  Stream<int> get onUserLeft => _userLeftController.stream;

  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  String? get currentChannel => _currentChannel;

  // Initialize Agora engine
  Future<void> initialize() async {
    if (_engine != null) return;

    // Request microphone permission and check if granted
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      throw Exception('Microphone permission is required for voice calls');
    }

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Register event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print(
              '✅ AGORA EVENT: onJoinChannelSuccess - Channel: ${connection.channelId}, UID: ${connection.localUid}, Elapsed: ${elapsed}ms');
          _isJoined = true;
          _joinedController.add(true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print(
              '👤 AGORA EVENT: onUserJoined - Remote UID: $remoteUid joined channel ${connection.channelId}, Elapsed: ${elapsed}ms');
          print(
              '👤 AGORA EVENT: Remote user is now in the channel! Audio should work now.');
          _userJoinedController.add(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          print(
              '👋 AGORA EVENT: onUserOffline - Remote UID: $remoteUid left channel ${connection.channelId}, Reason: $reason');
          _userLeftController.add(remoteUid);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print(
              '👋 AGORA EVENT: onLeaveChannel - Channel: ${connection.channelId}');
          _isJoined = false;
          _currentChannel = null;
          _joinedController.add(false);
        },
        onConnectionStateChanged: (RtcConnection connection,
            ConnectionStateType state, ConnectionChangedReasonType reason) {
          print(
              '🔗 AGORA EVENT: Connection state changed - State: $state, Reason: $reason, Channel: ${connection.channelId}');
        },
        onAudioVolumeIndication: (RtcConnection connection,
            List<AudioVolumeInfo> speakers,
            int speakerNumber,
            int totalVolume) {
          if (speakers.isNotEmpty) {
            print(
                '🎤 AGORA EVENT: Audio detected - ${speakers.length} speakers, Total volume: $totalVolume');
          }
        },
        onError: (ErrorCodeType err, String msg) {
          // Only log non-token errors or provide helpful message
          if (err == ErrorCodeType.errInvalidToken) {
            print(
                '⚠️ AGORA ERROR: Using test mode without token. For production, implement token server.');
          } else {
            print('❌ AGORA ERROR: $err - $msg');
          }
        },
      ),
    );

    // Enable audio
    await _engine!.enableAudio();

    // Enable audio volume indication to detect when users are speaking
    await _engine!.enableAudioVolumeIndication(
      interval: 500, // Report every 500ms
      smooth: 3,
      reportVad: true,
    );

    // Set audio scenario for voice calls
    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
  }

  // Join channel
  Future<void> joinChannel(String channelName,
      {String? token, int uid = 0}) async {
    if (_engine == null) {
      await initialize();
    }

    // If already in a channel, leave it first
    if (_isJoined) {
      print('Already in channel, leaving first...');
      await leaveChannel();
      // Add small delay to ensure clean disconnect
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _currentChannel = channelName;

    print('🔊 AGORA: Attempting to join channel: "$channelName"');
    print('🔊 AGORA: UID: $uid');
    print('🔊 AGORA: Token: ${token ?? "(empty - test mode)"}');

    try {
      // Set audio profile before joining for better quality
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
      print('🔊 AGORA: Audio profile set');

      // Set default audio route to speaker BEFORE joining
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      print('🔊 AGORA: Default route set to speaker');

      // Join channel
      print('🔊 AGORA: Calling joinChannel now...');
      print(
          '⚠️ CRITICAL: If connection fails, disable "App Certificate" in Agora Console');
      print('⚠️ Or implement token server: https://console.agora.io');
      await _engine!.joinChannel(
        token:
            token ?? '', // Empty for test mode - requires App Certificate OFF
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
        ),
      );
      // Set joined flag immediately after successful join call
      _isJoined = true;
      print('✅ AGORA: Successfully initiated join to channel: $channelName');
      print(
          '✅ AGORA: Waiting for onJoinChannelSuccess and onUserJoined events...');

      // Force speaker on after joining with multiple attempts
      _enableSpeakerWithRetry();

      print(
          '⚠️ AGORA: Using test mode without token. For production, implement token server.');
    } catch (e) {
      print('Error joining channel: $e');
      _currentChannel = null;
      _isJoined = false;
      rethrow;
    }
  }

  // Helper method to enable speaker with retry logic
  Future<void> _enableSpeakerWithRetry() async {
    // Try multiple times with increasing delays to ensure speaker is enabled
    final delays = [300, 700, 1200];

    for (final delay in delays) {
      await Future.delayed(Duration(milliseconds: delay));
      if (_engine != null && _isJoined) {
        try {
          await _engine!.setEnableSpeakerphone(true);
          print('Speaker enabled after ${delay}ms delay');
        } catch (e) {
          print('Speaker enable attempt at ${delay}ms: $e');
        }
      }
    }
  }

  // Leave channel
  Future<void> leaveChannel() async {
    if (_engine == null) {
      print('Cannot leave channel: Engine is null');
      return;
    }

    if (!_isJoined) {
      print('Cannot leave channel: Not currently in a channel');
      return;
    }

    try {
      print('Leaving channel: $_currentChannel');
      await _engine!.leaveChannel();
      _isJoined = false;
      _currentChannel = null;
      print('Successfully left channel');
    } catch (e) {
      print('Error leaving channel: $e');
      // Reset state even on error to allow rejoining
      _isJoined = false;
      _currentChannel = null;
    }
  }

  // Toggle mute
  Future<void> toggleMute() async {
    if (_engine == null) return;

    _isMuted = !_isMuted;
    await _engine!.muteLocalAudioStream(_isMuted);
  }

  // Set speaker on/off
  Future<void> setSpeakerOn(bool isOn) async {
    if (_engine == null) {
      print('Cannot set speaker: Engine not initialized');
      return;
    }

    try {
      // Set audio scenario first for better audio routing control
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      // Set default audio route - this is critical for Android
      await _engine!.setDefaultAudioRouteToSpeakerphone(isOn);

      // Try using Agora's method first
      bool agoraSuccess = false;
      for (int i = 0; i < 3; i++) {
        try {
          await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
          await _engine!.setEnableSpeakerphone(isOn);
          print(
              'Speaker ${isOn ? "enabled" : "disabled"} via Agora - attempt ${i + 1} completed');
          agoraSuccess = true;
          break; // If successful, exit loop
        } catch (e) {
          // Error -3 is expected, continue to native fallback
          if (i == 2) {
            print(
                'Agora speaker control not ready (error -3), using native AudioManager');
          }
        }
      }

      // If Agora method fails, use native Android AudioManager
      if (!agoraSuccess) {
        await AudioManagerService.setSpeakerOn(isOn);
      }

      print('Audio route set to ${isOn ? "speaker" : "earpiece"}');
    } catch (e) {
      print('Error setting audio route: $e');
      // Final fallback to native
      try {
        await AudioManagerService.setSpeakerOn(isOn);
      } catch (nativeError) {
        print('Native audio manager also failed: $nativeError');
      }
    }
  }

  // Dispose engine
  Future<void> dispose() async {
    if (_engine != null) {
      await leaveChannel();
      await _engine!.release();
      _engine = null;
    }
    await _joinedController.close();
    await _userJoinedController.close();
    await _userLeftController.close();
  }

  // Generate channel name
  static String generateChannelName(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'audio_${ids[0]}_${ids[1]}';
  }
}
