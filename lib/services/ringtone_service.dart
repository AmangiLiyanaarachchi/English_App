import 'package:flutter/services.dart';

class RingtoneService {
  static const _platform = MethodChannel('com.example.english_app/ringtone');

  // Play default ringtone
  static Future<void> playRingtone() async {
    try {
      await _platform.invokeMethod('playRingtone');
      // Also play haptic feedback
      _playVibrationPattern();
    } catch (e) {
      print('Error playing ringtone: $e');
      // Fallback to vibration only
      _playVibrationPattern();
    }
  }

  // Stop ringtone
  static Future<void> stopRingtone() async {
    try {
      await _platform.invokeMethod('stopRingtone');
    } catch (e) {
      print('Error stopping ringtone: $e');
    }
  }

  // Play vibration pattern for incoming call
  static void _playVibrationPattern() {
    // Initial vibration burst
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 400), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      HapticFeedback.mediumImpact();
    });
  }
}
