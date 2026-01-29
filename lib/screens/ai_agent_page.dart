import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:global_gate/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final bool _termsAccepted = false;
  final bool _checkingTerms = true;

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
  // Future<void> _checkAccessAndPermissions() async {
  //   // First check AI access
  //   final accessGranted = await _checkAIAccess();

  //   if (!accessGranted) {
  //     return; // Exit if no AI access
  //   }

  //   // Then check microphone permission
  //   await _checkPermission();
  // }
  Future<void> _checkAccessAndPermissions() async {
    final accepted = await _checkAndHandleTerms();

    if (!accepted) {
      return; // Stop everything until accepted
    }

    final accessGranted = await _checkAIAccess();
    if (!accessGranted) return;

    await _checkPermission();
  }

  /// Check if user has AI access and start timer
  // Future<bool> _checkAIAccess() async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) {
  //       _showErrorAndExit("Please login first");
  //       return false;
  //     }

  //     final userDoc = await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(user.uid)
  //         .get();

  //     if (!userDoc.exists) {
  //       _showErrorAndExit("User profile not found");
  //       return false;
  //     }

  //     final data = userDoc.data()!;
  //     bool aiEnabled = data['aiEnabled'] ?? false;
  //     int aiTotalSeconds = data['aiTotalSeconds'] ?? 0;
  //     int aiUsedSeconds = data['aiUsedSeconds'] ?? 0;
  //     planType = data['planType'] ?? "FREE";

  //     // Calculate remaining time
  //     remainingSeconds = aiTotalSeconds - aiUsedSeconds;
  //     totalSeconds = aiTotalSeconds;

  //     // Check if user can access
  //     if (!aiEnabled || remainingSeconds <= 0) {
  //       _showErrorAndExit(
  //           "Your AI Agent minutes are finished.\nUpgrade to continue.");
  //       return false;
  //     }

  //     // Access granted - start timer
  //     startTime = DateTime.now();
  //     hasAIAccess = true;

  //     // Start countdown timer
  //     _startCountdown();

  //     return true;
  //   } catch (e) {
  //     _showErrorAndExit("Error: $e");
  //     return false;
  //   }
  // }
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

      remainingSeconds = aiTotalSeconds - aiUsedSeconds;
      totalSeconds = aiTotalSeconds;

      if (!aiEnabled || remainingSeconds <= 0) {
        _showErrorAndExit(
            "Your AI Agent minutes are finished.\nUpgrade to continue.");
        return false;
      }

      startTime = DateTime.now();
      hasAIAccess = true;

      _startCountdown();

      return true;
    } catch (e) {
      _showErrorAndExit("Error: $e");
      return false;
    }
  }

  Future<bool> _checkAndHandleTerms() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};
      final accepted = data['aiTermsAccepted'] ?? false;

      if (accepted == true) {
        return true;
      }

      // ⛔ Wait for user decision
      final agreed = await _showTermsDialog(user.uid);
      return agreed;
    } catch (e) {
      _showErrorAndExit("Failed to load terms");
      return false;
    }
  }

  /// Show error dialog and exit
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
              Navigator.pop(context); // Exit screen
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
              Navigator.pop(context); // Exit screen
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
          //backgroundColor: const Color(0xFF4A90A4),
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
          actions: [
            if (hasAIAccess)
              Row(
                children: [
                  // ⏱ Timer UI
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: remainingSeconds < 300
                          ? Colors.red.shade700
                          : const Color(0xFF4A90A4),
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

                  // 🛑 END Button (UI only)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, false);

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      }, // UI ONLY
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "END",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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

  Future<bool> _showTermsDialog(String uid) async {
    bool isChecked = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "AI Agent – Terms & Conditions",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Before using the AI English Coach, please read and agree:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    _buildBullet("AI conversations may be recorded."),
                    _buildBullet("Do not share sensitive information."),
                    _buildBullet("AI responses are for learning support only."),
                    _buildBullet(
                      "Your usage time will be deducted. Before leaving the AI Agent, please press the End button. Your limited time will be deducted if you don’t press the End button.",
                    ),
                    _buildBullet("Misuse may restrict access."),

                    const SizedBox(height: 16),

                    // ✅ Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: (value) {
                            setState(() {
                              isChecked = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            "I have read and agree to the Terms & Conditions",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("Decline"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isChecked ? const Color(0xFF4A90A4) : Colors.grey,
                  ),
                  onPressed: isChecked
                      ? () async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({'aiTermsAccepted': true});

                          Navigator.pop(context, true);
                        }
                      : null,
                  child: const Text("I Agree"),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
