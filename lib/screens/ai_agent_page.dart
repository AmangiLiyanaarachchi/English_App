import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'premium_screen.dart';

class AIAgentPage extends StatefulWidget {
  const AIAgentPage({super.key});

  @override
  State<AIAgentPage> createState() => _AIAgentPageState();
}

class _AIAgentPageState extends State<AIAgentPage> with WidgetsBindingObserver {
  final String aiAgentUrl =
      "https://agent.jotform.com/019ae53c76397cdd876e717ab286d62b9a36/voice";

  InAppWebViewController? webViewController;
  bool _isPermissionGranted = false;
  bool _isLoading = true;

  // Time tracking variables
  DateTime? startTime;
  int remainingSeconds = 0;
  int totalSeconds = 0;
  String planType = "FREE";
  bool hasAIAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccessAndPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (hasAIAccess && startTime != null) {
      _saveUsageTime();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App goes to background - save usage
      if (hasAIAccess && startTime != null) {
        _saveUsageTime();
      }
    }
  }

  /// Check AI access and permissions together
  Future<void> _checkAccessAndPermissions() async {
    // First check AI access
    final accessGranted = await _checkAIAccess();

    if (!accessGranted) {
      return; // Exit if no AI access
    }

    // Then check microphone permission
    await _checkPermission();
  }

  /// Check if user has AI access and start timer
  Future<bool> _checkAIAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorAndExit("Please login first");
        return false;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showErrorAndExit("User profile not found");
        return false;
      }

      final data = userDoc.data()!;
      bool aiEnabled = data['aiEnabled'] ?? false;
      int aiTotalSeconds = data['aiTotalSeconds'] ?? 0;
      int aiUsedSeconds = data['aiUsedSeconds'] ?? 0;
      planType = data['planType'] ?? "FREE";

      // Calculate remaining time
      remainingSeconds = aiTotalSeconds - aiUsedSeconds;
      totalSeconds = aiTotalSeconds;

      // Check if user can access
      if (!aiEnabled || remainingSeconds <= 0) {
        _showErrorAndExit(
            "Your AI Agent minutes are finished.\nUpgrade to continue.");
        return false;
      }

      // Access granted - start timer
      startTime = DateTime.now();
      hasAIAccess = true;

      // Start countdown timer
      _startCountdown();

      return true;
    } catch (e) {
      _showErrorAndExit("Error: $e");
      return false;
    }
  }

  /// Show error dialog and redirect to premium
  void _showErrorAndExit(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Access Denied"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit AI Agent screen
              // Navigate to Premium Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Start countdown timer
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });

        if (remainingSeconds <= 0) {
          _handleTimeFinished();
        } else {
          _startCountdown();
        }
      }
    });
  }

  /// Handle when time is finished
  void _handleTimeFinished() {
    _saveUsageTime();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Time Finished"),
        content: const Text(
          "Your AI Agent minutes are completed.\nUpgrade to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit AI Agent screen
              // Navigate to Premium Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Save usage time to Firestore
  Future<void> _saveUsageTime() async {
    if (startTime == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Calculate used time
      DateTime endTime = DateTime.now();
      int usedSeconds = endTime.difference(startTime!).inSeconds;

      // Get current usage
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      int currentUsedSeconds = data['aiUsedSeconds'] ?? 0;
      int totalAllowedSeconds = data['aiTotalSeconds'] ?? 0;

      // Update usage
      int newUsedSeconds = currentUsedSeconds + usedSeconds;

      // Check if finished
      bool shouldDisable = newUsedSeconds >= totalAllowedSeconds;

      // Update Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        'aiUsedSeconds': newUsedSeconds,
        'aiEnabled': !shouldDisable,
      });

      debugPrint("✅ AI Agent usage saved: $usedSeconds seconds");
    } catch (e) {
      debugPrint("❌ Error saving usage: $e");
    }
  }

  /// Format seconds to MM:SS
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Microphone permission is required for AI voice chat'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("English AI Coach"),
          backgroundColor: const Color(0xFF4A90A4),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "English AI Coach",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
        ),
        body: _buildPermissionScreen(),
      );
    }

    // Main AI Agent screen with timer
    return WillPopScope(
      onWillPop: () async {
        if (hasAIAccess && startTime != null) {
          _saveUsageTime();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "English AI Coach",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF4A90A4),
          actions: [
            // Timer display
            if (hasAIAccess)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: remainingSeconds < 300
                          ? Colors.red.shade700
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(remainingSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Progress bar
            if (hasAIAccess)
              LinearProgressIndicator(
                value: totalSeconds > 0 ? remainingSeconds / totalSeconds : 0,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  remainingSeconds < 300 ? Colors.red : const Color(0xFF4A90A4),
                ),
                minHeight: 4,
              ),

            // WebView
            Expanded(child: _buildWebView()),

            // Bottom info bar
            if (hasAIAccess)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Plan: ${planType == 'AI_1000' ? '1000 Credits (20 min)' : planType == 'AI_2500' ? '2500 Credits (45 min)' : 'No Plan'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mic,
              size: 100,
              color: Color(0xFF4A90A4),
            ),
            const SizedBox(height: 30),
            const Text(
              'Microphone Permission Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              'To speak with your AI English coach, please allow microphone access.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.mic, color: Colors.white),
              label: const Text(
                'Allow Microphone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90A4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(aiAgentUrl),
      ),
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        useHybridComposition: true,
        useShouldOverrideUrlLoading: true,
      ),
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onPermissionRequest: (controller, request) async {
        // Auto-grant microphone permission to the webpage
        return PermissionResponse(
          resources: request.resources,
          action: PermissionResponseAction.GRANT,
        );
      },
      onLoadStart: (controller, url) {
        debugPrint("Page started loading: $url");
      },
      onLoadStop: (controller, url) async {
        debugPrint("Page finished loading: $url");
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint("Console: ${consoleMessage.message}");
      },
    );
  }
}
