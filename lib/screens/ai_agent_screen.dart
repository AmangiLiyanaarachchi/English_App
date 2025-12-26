import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'premium_screen.dart';

class AIAgentScreen extends StatefulWidget {
  const AIAgentScreen({super.key});

  @override
  State<AIAgentScreen> createState() => _AIAgentScreenState();
}

class _AIAgentScreenState extends State<AIAgentScreen>
    with WidgetsBindingObserver {
  // JotForm URL - Replace with your actual JotForm URL
  final String jotFormUrl =
      "https://agent.jotform.com/019ae53c76397cdd876e717ab286d62b9a36/voice";

  DateTime? startTime;
  bool isLoading = true;
  int remainingSeconds = 0;
  int totalSeconds = 0;
  String planType = "FREE";

  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccessAndStartTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveUsageTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App goes to background
      _saveUsageTime();
    }
  }

  /// Check if user has AI access and start timer
  Future<void> _checkAccessAndStartTimer() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorAndExit("Please login first");
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showErrorAndExit("User profile not found");
        return;
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
        return;
      }

      // Start timer
      startTime = DateTime.now();

      setState(() {
        isLoading = false;
      });

      // Start countdown timer
      _startCountdown();
    } catch (e) {
      _showErrorAndExit("Error: $e");
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("AI Agent"),
          backgroundColor: const Color(0xFF4A90A4),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _saveUsageTime();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "AI Agent",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF4A90A4),
          actions: [
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
                      Icon(
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
            LinearProgressIndicator(
              value: totalSeconds > 0 ? remainingSeconds / totalSeconds : 0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                remainingSeconds < 300 ? Colors.red : const Color(0xFF4A90A4),
              ),
              minHeight: 4,
            ),

            // JotForm iframe
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(jotFormUrl),
                ),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  debugPrint("Loading: $url");
                },
                onLoadStop: (controller, url) {
                  debugPrint("Loaded: $url");
                },
                onReceivedError: (controller, request, error) {
                  debugPrint("Error: ${error.description}");
                },
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  useHybridComposition: true,
                ),
              ),
            ),

            // Bottom info bar
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
}
