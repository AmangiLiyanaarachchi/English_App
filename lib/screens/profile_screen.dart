import 'dart:io';

import 'package:global_gate/screens/premium_screen.dart';
import 'package:global_gate/screens/voice_call_screen.dart';
import 'package:global_gate/services/status_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/recording.dart';
import '../models/user.dart' as models;
import '../services/firebase_service.dart';
import '../services/agora_service.dart';
import '../services/call_signaling_service.dart';
import '../services/firebase_service.dart';
import '../services/random_call_service.dart';
import '../services/student_verification_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  models.UserModel? _userProfile;
  final List<Recording> _recordings = [];
  TabController? _tabController;
  final _agoraService = AgoraService();
  final _callSignalingService = CallSignalingService();
  final _randomCallService = RandomCallService(); // NEW
  final _studentVerificationService = StudentVerificationService();
  int _currentIndex = 0;
  models.UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasAI(models.UserModel user) {
    return user.package == "AI Agent" || user.package == "Community + AI Agent";
  }

  bool _hasCommunity(models.UserModel user) {
    return user.package == "Community Plan" ||
        user.package == "Community + AI Agent";
  }

  bool _hasPackage(models.UserModel user) {
    return user.package != null && user.package!.isNotEmpty;
  }

  bool _shouldShowPremiumInProfile() {
    if (_userProfile == null) return false;
    if (!_hasPackage(_userProfile!)) {
      return true; // No package at all
    }
    // Show in profile if both community and AI are not active
    return !_hasCommunity(_userProfile!) && !_hasAI(_userProfile!);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
    print('🔍 [ProfileScreen] initState called with userId: ${widget.userId}');
  }

  Future<void> _loadProfile() async {
    print('📱 [ProfileScreen] _loadProfile started');

    // Load current user's profile for random calls
    final currentFirebaseUser = FirebaseAuth.instance.currentUser;
    if (currentFirebaseUser != null) {
      try {
        final currentUserProfile =
            await _firebaseService.getUserProfile(currentFirebaseUser.uid);
        if (mounted) {
          setState(() => _currentUser = currentUserProfile);
        }
      } catch (e) {
        print('⚠️ [ProfileScreen] Error loading current user profile: $e');
      }
    }

    if (widget.userId.isEmpty) {
      print('❌ [ProfileScreen] Cannot load profile: userId is empty');
      // Even with empty userId, create a basic profile from current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        print(
            '✅ [ProfileScreen] Creating profile from Firebase Auth (empty userId)');
        setState(() {
          _userProfile = models.UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            //instituteCode: '',
            createdAt: DateTime.now(),
            englishLevel: models.EnglishLevel.beginner,
            interests: [],
            badges: [],
            streakDays: 1,
            totalChats: 0,
            totalMinutes: 0,
            karmaPoints: 0,
            isOnline: true,
            lastActive: DateTime.now(),
          );
          _isLoadingProfile = false;
        });
      }
      return;
    }

    try {
      print('📡 [ProfileScreen] Fetching from Firestore...');
      final profile = await _firebaseService.getUserProfile(widget.userId);
      if (mounted && profile != null) {
        print('✅ [ProfileScreen] Profile loaded from Firestore');

        // Check if student plan has expired
        if (profile.studentIdVerified == true &&
            profile.studentPlanEndDate != null &&
            DateTime.now().isAfter(profile.studentPlanEndDate!)) {
          print('⏰ Student plan expired, deactivating...');
          await _studentVerificationService.deactivateStudentPlan(profile.uid);
          // Reload profile to get updated data
          final updatedProfile =
              await _firebaseService.getUserProfile(widget.userId);
          setState(() {
            _userProfile = updatedProfile;
            _isLoadingProfile = false;
          });
        } else {
          setState(() {
            _userProfile = profile;
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      print('⚠️ [ProfileScreen] Error loading from Firestore: $e');
      print('📱 [ProfileScreen] Using Firebase Auth data as fallback');

      // Fallback to Firebase Auth user data if Firestore fails
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        print(
            '✅ [ProfileScreen] Creating fallback profile for: ${user.displayName}');
        setState(() {
          _userProfile = models.UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            //instituteCode: '',
            createdAt: DateTime.now(),
            englishLevel: models.EnglishLevel.beginner,
            interests: [],
            badges: [],
            streakDays: 1,
            totalChats: 0,
            totalMinutes: 0,
            karmaPoints: 0,
            isOnline: true,
            lastActive: DateTime.now(),
          );
          _isLoadingProfile = false;
        });
      } else {
        print('❌ [ProfileScreen] No Firebase Auth user found');
        if (mounted) {
          setState(() => _isLoadingProfile = false);
        }
      }
    }
  }

  Future<void> _editDisplayName() async {
    final controller =
        TextEditingController(text: _userProfile?.displayName ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90A4),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              Navigator.pop(context);

              try {
                await _firebaseService.updateUserProfile(
                  _userProfile!.uid,
                  {'displayName': newName},
                );

// 🔥 ADD THIS
                await StatusService().updateUserInfoInStatuses(
                  userId: _userProfile!.uid,
                  newName: newName,
                  newPhoto: _userProfile!.photoUrl ?? '',
                );

                setState(() {
                  _userProfile = _userProfile!.copyWith(displayName: newName);
                });

                if (mounted) {
                  setState(() {
                    _userProfile = _userProfile!.copyWith(displayName: newName);
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update name')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    print('🚪 [ProfileScreen] Sign out button pressed');
    try {
      await _firebaseService.signOut();
      print('✅ [ProfileScreen] Sign out successful, navigating to login');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('❌ [ProfileScreen] Sign out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: ${e.toString()}')),
        );
      }
    }
  }

  // Start random voice call
  Future<void> _startRandomCall() async {
    // Get current Firebase user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to make calls')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // NEW: Check random call permission first
      final permission =
          await _randomCallService.checkRandomCallPermission(currentUser.uid);

      if (!permission['canCall']) {
        final totalSeconds = permission['totalSecondsUsed'] as int;
        final totalMinutes = (totalSeconds / 60).toStringAsFixed(1);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer_off,
                        size: 50,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Time Limit Reached',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Message
                    Text(
                      'You have used all your random call time ($totalMinutes minutes).',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Random call feature is now disabled',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OK Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498DB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return;
      }

      // Show remaining time info
      final remainingSeconds = permission['remainingSeconds'] as int;
      final remainingMinutes = (remainingSeconds / 60).toStringAsFixed(1);

      if (mounted && remainingSeconds < 180) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Random call time remaining: $remainingMinutes minutes'),
            backgroundColor:
                remainingSeconds < 60 ? Colors.orange : Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Show user selection dialog
      await _showUserSelectionDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Show dialog to select a user for voice call
  Future<void> _showUserSelectionDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Fetch all users except current user
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
        .limit(50)
        .get();

    if (usersSnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No users available for calling')),
        );
      }
      return;
    }

    final users = usersSnapshot.docs
        .map((doc) => models.UserModel.fromFirestore(doc))
        .toList();

    if (!mounted) return;

    // Save the parent context before showing dialog
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select User to Call',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : 'U',
                              )
                            : null,
                      ),
                      title: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName
                            : 'Unknown User',
                      ),
                      subtitle: Text(user.email),
                      onTap: () async {
                        // Close dialog first
                        Navigator.of(dialogContext).pop();
                        // Wait a bit for dialog to close
                        await Future.delayed(const Duration(milliseconds: 100));
                        // Then initiate call with parent context
                        _initiateCallWithUser(user);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Initiate call with selected user
  Future<void> _initiateCallWithUser(models.UserModel otherUser) async {
    try {
      if (_currentUser == null) return;

      // Request microphone permission first
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Microphone permission is required for voice calls'),
            ),
          );
        }
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create call
      final call = await _callSignalingService.createCall(
        receiverId: otherUser.uid,
        receiverName: otherUser.displayName,
        receiverPhotoUrl: otherUser.photoUrl ?? '',
        callerName: _currentUser!.displayName,
        callerPhotoUrl: _currentUser!.photoUrl ?? '',
      );

      print(
          '📤 HOME: Call created, joining Agora channel: ${call.agoraChannelId}');

      // Join Agora channel (initialize is handled internally)
      await _agoraService.joinChannel(call.agoraChannelId);

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to voice call screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VoiceCallScreen(
            call: call,
            isOutgoing: true,
            isRandomCall: true, // NEW: Mark this as a random call
          ),
        ),
      );
    } catch (e) {
      print('Error initiating call: $e');
      // Leave the channel if we joined it before the error
      await _agoraService.leaveChannel().catchError((err) {
        print('Error leaving channel after failed initiation: $err');
      });
      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate call: $e')),
        );
      }
    }
  }

  // Student ID Verification Dialog
  Future<void> _showStudentIdDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Verify Student ID',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your student ID to activate Community Plan',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., STU001',
                labelText: 'Student ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 20,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Contact your institute if you don\'t have a student ID',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90A4),
            ),
            onPressed: () async {
              final studentId = controller.text.trim().toUpperCase();
              if (studentId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a student ID')),
                );
                return;
              }

              Navigator.pop(context);
              await _verifyAndActivateStudentPlan(studentId);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  // Verify student ID and activate Community Plan
  Future<void> _verifyAndActivateStudentPlan(String studentId) async {
    print('🚀 Starting student verification for: $studentId');

    // Show loading
    if (!mounted) {
      print('❌ Widget not mounted, cannot show dialog');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('🔍 Verifying student ID: $studentId');
      final result =
          await _studentVerificationService.verifyStudentId(studentId);
      print('📊 Verification result: $result');

      if (!mounted) {
        print('❌ Widget unmounted during verification');
        return;
      }

      Navigator.of(context).pop(); // Close loading
      print('✅ Loading dialog closed');

      if (result['isValid']) {
        print('✅ Student ID is valid, activating Community Plan...');
        // Activate Community Plan
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('👤 User ID: ${user.uid}');
          await _studentVerificationService.activateCommunityPlanForStudent(
            user.uid,
            result['studentId'],
            result['startDate'],
            result['endDate'],
          );
          print('✅ Community Plan activated successfully');

          // Reload profile
          print('🔄 Reloading profile...');
          await _loadProfile();
          print('✅ Profile reloaded');

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 28),
                    const SizedBox(width: 8),
                    const Text('Success!'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your student ID has been verified!',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text('Student ID: ${result['studentId']}'),
                    const SizedBox(height: 8),
                    Text('Valid until: ${_formatDate(result['endDate'])}'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.celebration, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Community Plan has been activated!',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90A4),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Great!'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        // Show error
        print('❌ Verification failed: ${result['message']}');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade600, size: 28),
                  const SizedBox(width: 8),
                  const Text('Verification Failed'),
                ],
              ),
              content: Text(result['message']),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error during verification: $e');
      Navigator.of(context).pop(); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_userProfile == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Profile',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4A90A4),
          ),
        ),
      );
    }

    final isCurrentUser =
        widget.userId == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          // IconButton(
          //   icon: const Icon(Icons.settings),
          //   onPressed: () {
          //     // Settings
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Weekly Progress Chart
                  // Container(
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.grey.shade50,
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         children: [
                  //           const Text(
                  //             'You',
                  //             style: TextStyle(
                  //               fontSize: 16,
                  //               fontWeight: FontWeight.bold,
                  //               color: Color(0xFF4A90A4),
                  //             ),
                  //           ),
                  //           const Spacer(),
                  //           Text(
                  //             '${_userProfile!.totalMinutes}m',
                  //             style: const TextStyle(
                  //               fontSize: 14,
                  //               color: Color(0xFF4A90A4),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 12),
                  //       // Weekly chart
                  //       SizedBox(
                  //         height: 100,
                  //         child: Row(
                  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //           crossAxisAlignment: CrossAxisAlignment.end,
                  //           children: [
                  //             _buildChartBar('Tue', 0, 100),
                  //             _buildChartBar('Wed', 0, 100),
                  //             _buildChartBar('Thu', 0, 100),
                  //             _buildChartBar('Fri', 0, 100),
                  //             _buildChartBar('Sat', 0, 100),
                  //             _buildChartBar('Sun', 80, 100),
                  //             _buildChartBar('Mon', 0, 100),
                  //           ],
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //         children: const [
                  //           Text('Tue',
                  //               style: TextStyle(
                  //                   fontSize: 11, color: Colors.grey)),
                  //           Text('Wed',
                  //               style: TextStyle(
                  //                   fontSize: 11, color: Colors.grey)),
                  //           Text('Thu',
                  //               style: TextStyle(
                  //                   fontSize: 11, color: Colors.grey)),
                  //           Text('Fri',
                  //               style: TextStyle(
                  //                   fontSize: 11, color: Colors.grey)),
                  //           Text('Sat',
                  //               style: TextStyle(
                  //                   fontSize: 11, color: Colors.grey)),
                  //           Text('Sun',
                  //               style: TextStyle(
                  //                   fontSize: 11, color: Colors.grey)),
                  //           Text('Mon',
                  //               style: TextStyle(
                  //                   fontSize: 11, color: Colors.grey)),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 20),
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // Profile Picture and Edit Button
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF4A90A4),
                              backgroundImage: _userProfile!.photoUrl != null
                                  ? NetworkImage(_userProfile!.photoUrl!)
                                  : null,
                              child: _userProfile!.photoUrl == null
                                  ? Text(
                                      _userProfile!.displayName[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _updateProfilePicture,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Color(0xFF4A90A4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _userProfile!.displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: _editDisplayName,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Display current package if exists
                        if (_userProfile!.package != null &&
                            _userProfile!.package!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A90A4), Color(0xFF2A9D8F)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _userProfile!.package!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_userProfile!.studentIdVerified ==
                                    true) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.school,
                                      color: Colors.white, size: 16),
                                ],
                              ],
                            ),
                          ),
                        // const SizedBox(height: 8),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Text(
                        //       _userProfile!.uid.substring(0, 16),
                        //       style: const TextStyle(
                        //         fontSize: 12,
                        //         color: Colors.grey,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 4),
                        //     Icon(Icons.copy,
                        //         size: 14, color: Colors.grey.shade400),
                        //   ],
                        // ),
                        const SizedBox(height: 8),
                        Text(
                          'Sri Lanka',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Joined ${_userProfile!.createdAt.year} ${_getMonth(_userProfile!.createdAt.month)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //       horizontal: 16, vertical: 6),
                        //   decoration: BoxDecoration(
                        //     color: Colors.grey.shade200,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Text(
                        //     'male',
                        //     style: const TextStyle(
                        //       fontSize: 13,
                        //       color: Colors.black87,
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 16),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Text(
                        //       '0 Following',
                        //       style: TextStyle(
                        //         fontSize: 14,
                        //         color: const Color(0xFF4A90A4),
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 24),
                        //     Text(
                        //       '0 Followers',
                        //       style: TextStyle(
                        //         fontSize: 14,
                        //         color: const Color(0xFF4A90A4),
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            //const SizedBox(height: 16),

            // Statistics Section
            // Container(
            //   color: Colors.white,
            //   padding: const EdgeInsets.all(20),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text(
            //         'Statistic',
            //         style: TextStyle(
            //           fontSize: 20,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       const SizedBox(height: 16),
            //       Row(
            //         children: [
            //           Expanded(
            //             child: Container(
            //               padding: const EdgeInsets.all(16),
            //               decoration: BoxDecoration(
            //                 color: Colors.grey.shade50,
            //                 borderRadius: BorderRadius.circular(12),
            //               ),
            //               child: Column(
            //                 children: [
            //                   const Icon(Icons.local_fire_department,
            //                       color: Colors.orange, size: 32),
            //                   const SizedBox(height: 8),
            //                   const Text(
            //                     'Current streak',
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: Colors.grey,
            //                     ),
            //                   ),
            //                   const SizedBox(height: 4),
            //                   Text(
            //                     '${_userProfile!.streakDays} days',
            //                     style: const TextStyle(
            //                       fontSize: 18,
            //                       fontWeight: FontWeight.bold,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //           const SizedBox(width: 12),
            //           Expanded(
            //             child: Container(
            //               padding: const EdgeInsets.all(16),
            //               decoration: BoxDecoration(
            //                 color: Colors.grey.shade50,
            //                 borderRadius: BorderRadius.circular(12),
            //               ),
            //               child: Column(
            //                 children: [
            //                   const Icon(Icons.emoji_events,
            //                       color: Colors.amber, size: 32),
            //                   const SizedBox(height: 8),
            //                   const Text(
            //                     'Best streak',
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: Colors.grey,
            //                     ),
            //                   ),
            //                   const SizedBox(height: 4),
            //                   Text(
            //                     '${_userProfile!.streakDays} days',
            //                     style: const TextStyle(
            //                       fontSize: 18,
            //                       fontWeight: FontWeight.bold,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 16),
            //       Container(
            //         padding: const EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           color: Colors.grey.shade50,
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: Row(
            //           children: [
            //             const Icon(Icons.auto_awesome,
            //                 color: Colors.amber, size: 32),
            //             const SizedBox(width: 12),
            //             Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 const Text(
            //                   'Aura',
            //                   style: TextStyle(
            //                     fontSize: 12,
            //                     color: Colors.grey,
            //                   ),
            //                 ),
            //                 Text(
            //                   '${_userProfile!.karmaPoints}',
            //                   style: const TextStyle(
            //                     fontSize: 18,
            //                     fontWeight: FontWeight.bold,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Random Call Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone_in_talk,
                                color: Color(0xFF4A90A4), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Random Call',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Get instantly connected with another English learner for a real-time voice conversation. '
                          'Calls are randomly matched to help you practice speaking naturally and confidently.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _startRandomCall,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A90A4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.phone, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Connect with Co-learners',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Other Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Other',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Student ID Verification - Show only if not already a student
                  if (_userProfile?.studentIdVerified != true)
                    _buildMenuItem(
                      Icons.school,
                      'Student Verification',
                      'Verify your student ID to get Community Plan',
                      Icons.verified_user,
                      const Color(0xFF2196F3),
                    ),
                  // Only show "Join Premium Today" if premium should NOT be shown at bottom
                  if (!_shouldShowPremiumInProfile())
                    _buildMenuItem(
                      Icons.workspace_premium,
                      'Join Premium Today',
                      'Find your perfect match, feel the difference',
                      Icons.shopping_bag,
                      const Color(0xFF4A90A4),
                    ),
                  _buildMenuItem(
                    Icons.share,
                    'Share',
                    'Share with your friends and family',
                    Icons.share,
                    const Color(0xFF4A90A4),
                  ),
                  _buildMenuItem(
                    Icons.star,
                    'Rate us',
                    'Your review keep us motivated',
                    Icons.edit,
                    const Color(0xFF4A90A4),
                  ),
                  _buildMenuItem(
                    Icons.contact_support,
                    'Contact us',
                    'Your feedback matters to us, reach out today',
                    Icons.contact_page,
                    const Color(0xFF4A90A4),
                  ),
                  const Divider(height: 32),
                  _buildMenuItem(
                    Icons.logout,
                    'Sign Out',
                    'Log out of your account',
                    Icons.arrow_forward_ios,
                    Colors.red,
                    isSignOut: true,
                  ),
                ],
              ),
            ),

            // Premium Plan Details Section (show at bottom when both plans inactive)
            if (_shouldShowPremiumInProfile()) ...[
              const SizedBox(height: 16),
              _buildPremiumDetailsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String day, double value, double max) {
    final height = (value / max) * 80;
    final isActive = value > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: height > 10 ? height : 10,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4A90A4) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle,
      IconData trailingIcon, Color color,
      {bool isSignOut = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSignOut ? Colors.red.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isSignOut ? Colors.red : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(trailingIcon, color: color, size: 20),
      onTap: () {
        if (title == 'Sign Out') {
          _signOut();
        } else if (title == 'Student Verification') {
          _showStudentIdDialog();
        } else if (title == 'Contact us') {
          // Contact us
        } else if (title == 'Share') {
          // Share
        } else if (title == 'Rate us') {
          // Rate
        } else if (title == 'Join Premium Today') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PremiumScreen(),
            ),
          );
        }
      },
    );
  }

  Widget _buildPremiumDetailsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Color(0xFF4A90A4),
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Unlock Premium Features',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90A4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Get access to exclusive features and enhance your English learning experience!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Community Plan Features
          _buildPlanCard(
            'Community Plan',
            'Connect with learners worldwide',
            [
              'Access to Community Chat',
              'Connect with English learners',
              'Share your progress',
              'Post and view Status updates',
            ],
            Icons.people,
            const Color(0xFF2A9D8F),
          ),
          const SizedBox(height: 16),

          // AI Agent Features
          _buildPlanCard(
            'AI Agent',
            'Personal AI English coach',
            [
              'AI-powered English coach',
              'Personalized learning tips',
              'Grammar corrections',
              '24/7 AI assistance',
            ],
            Icons.smart_toy,
            const Color(0xFF4A90A4),
          ),
          const SizedBox(height: 24),

          // Call to action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PremiumScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90A4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Plans & Subscribe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String title,
    String subtitle,
    List<String> features,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    try {
      final imageUrl = await _firebaseService.uploadProfileImage(
        _userProfile!.uid,
        file,
      );

      await _firebaseService.updateUserProfile(
        _userProfile!.uid,
        {'photoUrl': imageUrl},
      );

// 🔥 ADD THIS
      await StatusService().updateUserInfoInStatuses(
        userId: _userProfile!.uid,
        newName: _userProfile!.displayName,
        newPhoto: imageUrl,
      );

      setState(() {
        _userProfile = _userProfile!.copyWith(photoUrl: imageUrl);
      });

      if (mounted) {
        setState(() {
          _userProfile = _userProfile!.copyWith(photoUrl: imageUrl);
        });
      }
    } catch (e, stack) {
      debugPrint('❌ Profile picture upload error: $e');
      debugPrintStack(stackTrace: stack);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }
}
