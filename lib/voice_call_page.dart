import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

const String appId = "YOUR_APP_ID";
const String token = "YOUR_TOKEN"; // can be null/"" for testing
const String channelName = "testchannel";

class VoiceCallPage extends StatefulWidget {
  const VoiceCallPage({super.key});

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  late final RtcEngine _engine;
  final Set<int> _remoteUsers = {};

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // Request microphone permission
    await Permission.microphone.request();

    // Create engine
    _engine = createAgoraRtcEngine();

    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
      ),
    );

    // Event Handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print("Local user joined: ${connection.localUid}");
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUsers.add(remoteUid));
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUsers.remove(remoteUid));
        },
      ),
    );

    // Enable audio
    await _engine.enableAudio();

    // Join channel
    await _engine.joinChannel(
      token: token, // if token = "", it's OK for testing
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
      ),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agora Voice Call")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Channel: $channelName"),
          const SizedBox(height: 16),
          Text("Remote users: ${_remoteUsers.join(", ")}"),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _engine.leaveChannel(),
            child: const Text("Leave Call"),
          ),
        ],
      ),
    );
  }
}
