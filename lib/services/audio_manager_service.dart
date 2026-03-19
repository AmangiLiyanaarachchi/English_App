import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class AudioManagerService {
  static const MethodChannel _channel =
          MethodChannel('com.example.english_app/audio');

  /// Force enable speaker (loudspeaker) mode on Android
  static Future<bool> setSpeakerOn(bool enabled) async {
    if (!Platform.isAndroid) {
      print('AudioManager: Not on Android platform');
      return false;
    }

    try {
      final bool result =
          await _channel.invokeMethod('setSpeakerOn', {'enabled': enabled});
      print(
          'AudioManager: Speaker ${enabled ? "enabled" : "disabled"} via native - result: $result');
      return result;
    } catch (e) {
      print('AudioManager: Error setting speaker: $e');
      return false;
    }
  }

  /// Get current speaker state
  static Future<bool> isSpeakerOn() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('isSpeakerOn');
      return result;
    } catch (e) {
      print('AudioManager: Error getting speaker state: $e');
      return false;
    }
  }
}
