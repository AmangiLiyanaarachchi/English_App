import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  // TODO: Replace with your actual Agora App ID from https://console.agora.io
  static const String appId = 'YOUR_AGORA_APP_ID';

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

    // Request microphone permission
    await Permission.microphone.request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Register event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('Successfully joined channel: ${connection.channelId}');
          _isJoined = true;
          _joinedController.add(true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('Remote user $remoteUid joined');
          _userJoinedController.add(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          print('Remote user $remoteUid left channel');
          _userLeftController.add(remoteUid);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('Left channel');
          _isJoined = false;
          _currentChannel = null;
          _joinedController.add(false);
        },
        onError: (ErrorCodeType err, String msg) {
          print('Agora Error: $err - $msg');
        },
      ),
    );

    // Enable audio
    await _engine!.enableAudio();
  }

  // Join channel
  Future<void> joinChannel(String channelName,
      {String? token, int uid = 0}) async {
    if (_engine == null) {
      await initialize();
    }

    if (_isJoined) {
      await leaveChannel();
    }

    _currentChannel = channelName;

    // Join channel
    await _engine!.joinChannel(
      token: token ??
          '', // Use null for testing, implement token server for production
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  // Leave channel
  Future<void> leaveChannel() async {
    if (_engine == null || !_isJoined) return;

    await _engine!.leaveChannel();
    _isJoined = false;
    _currentChannel = null;
  }

  // Toggle mute
  Future<void> toggleMute() async {
    if (_engine == null) return;

    _isMuted = !_isMuted;
    await _engine!.muteLocalAudioStream(_isMuted);
  }

  // Set speaker on/off
  Future<void> setSpeakerOn(bool isOn) async {
    if (_engine == null) return;
    await _engine!.setEnableSpeakerphone(isOn);
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
