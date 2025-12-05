package com.example.english_app

import android.media.RingtoneManager
import android.media.Ringtone
import android.media.AudioManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val RINGTONE_CHANNEL = "com.example.english_app/ringtone"
    private val AUDIO_CHANNEL = "com.example.english_app/audio"
    private val WEBVIEW_PERMISSIONS_CHANNEL = "com.example.english_app/webview_permissions"
    private var ringtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // WebView Permissions channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WEBVIEW_PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableWebViewPermissions" -> {
                    try {
                        // This will be handled by the WebView configuration
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WEBVIEW_ERROR", "Failed to enable WebView permissions", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Ringtone channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playRingtone" -> {
                    try {
                        val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        ringtone = RingtoneManager.getRingtone(applicationContext, ringtoneUri)
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            ringtone?.isLooping = true
                        }
                        ringtone?.play()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("RINGTONE_ERROR", "Failed to play ringtone", e.message)
                    }
                }
                "stopRingtone" -> {
                    try {
                        ringtone?.stop()
                        ringtone = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("RINGTONE_ERROR", "Failed to stop ringtone", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Audio Manager channel for speaker control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSpeakerOn" -> {
                    try {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        
                        // Set audio mode for communication
                        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                        
                        // Enable/disable speakerphone
                        audioManager.isSpeakerphoneOn = enabled
                        
                        // Also set stream volume to ensure it's audible
                        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_VOICE_CALL)
                        if (currentVolume == 0) {
                            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
                            audioManager.setStreamVolume(AudioManager.STREAM_VOICE_CALL, maxVolume / 2, 0)
                        }
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AUDIO_ERROR", "Failed to set speaker", e.message)
                    }
                }
                "isSpeakerOn" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        result.success(audioManager.isSpeakerphoneOn)
                    } catch (e: Exception) {
                        result.error("AUDIO_ERROR", "Failed to get speaker state", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

