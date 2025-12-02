import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../models/recording.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();
  final _firebaseService = FirebaseService();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isRecorderInitialized = false;
  String? _recordingPath;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    await _player.openPlayer();

    setState(() => _isRecorderInitialized = true);
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(toFile: path);
    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordDuration = 0;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;

    await _player.startPlayer(
      fromURI: _recordingPath,
      whenFinished: () {
        setState(() => _isPlaying = false);
      },
    );
    setState(() => _isPlaying = true);
  }

  Future<void> _stopPlaying() async {
    await _player.stopPlayer();
    setState(() => _isPlaying = false);
  }

  Future<void> _saveRecording() async {
    if (_recordingPath == null) return;

    try {
      // TODO: Upload to Firebase Storage
      final file = File(_recordingPath!);
      final bytes = await file.readAsBytes();

      // For now, create a simple recording entry
      final recording = Recording(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        userName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
        audioUrl: _recordingPath!, // TODO: Replace with Firebase Storage URL
        duration: _recordDuration,
        createdAt: DateTime.now(),
        feedback: 'Recording saved successfully!',
      );

      await _firebaseService.saveRecording(recording);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  void _discardRecording() {
    if (_recordingPath != null) {
      File(_recordingPath!).deleteSync();
    }
    setState(() {
      _recordingPath = null;
      _recordDuration = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Audio'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Recording Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? Colors.red.withOpacity(0.2)
                      : const Color(0xFF2A9D8F).withOpacity(0.2),
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  size: 100,
                  color: _isRecording ? Colors.red : const Color(0xFF2A9D8F),
                ),
              ),
              const SizedBox(height: 32),

              // Status Text
              Text(
                _isRecording
                    ? 'Recording...'
                    : _recordingPath != null
                        ? 'Recording Ready'
                        : 'Tap to start recording',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isRecording || _recordDuration > 0)
                Text(
                  '${_recordDuration ~/ 60}:${(_recordDuration % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 48),
                ),
              const SizedBox(height: 48),

              // Controls
              if (!_isRecording && _recordingPath == null)
                FloatingActionButton.extended(
                  onPressed: _startRecording,
                  backgroundColor: const Color(0xFF2A9D8F),
                  icon: const Icon(Icons.mic, color: Colors.white),
                  label: const Text(
                    'Start Recording',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              if (_isRecording)
                FloatingActionButton.extended(
                  onPressed: _stopRecording,
                  backgroundColor: Colors.red,
                  icon: const Icon(Icons.stop, color: Colors.white),
                  label: const Text(
                    'Stop',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              if (_recordingPath != null && !_isRecording) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: _isPlaying ? _stopPlaying : _playRecording,
                      backgroundColor: const Color(0xFF2A9D8F),
                      child: Icon(
                        _isPlaying ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      onPressed: _discardRecording,
                      backgroundColor: Colors.grey,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _saveRecording,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Save Recording',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Tips for Better Recording',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Find a quiet place'),
                    Text('• Speak clearly in English'),
                    Text('• Record 30-60 seconds'),
                    Text('• Share for feedback!'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }
}
