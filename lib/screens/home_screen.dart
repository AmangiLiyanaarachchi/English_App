import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_circle/models/status_model.dart';
import 'package:english_circle/screens/ai_agent_page.dart';
import 'package:english_circle/screens/premium_screen.dart';
import 'package:english_circle/services/status_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user.dart' as models;
import '../services/agora_service.dart';
import '../services/call_signaling_service.dart';
import '../services/firebase_service.dart';
import 'audio_chat_screen.dart';
import 'chats_list_screen.dart';
import 'incoming_call_screen.dart';
import 'profile_screen.dart';
import 'status_screen.dart';
import 'voice_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  final _agoraService = AgoraService();
  final _callSignalingService = CallSignalingService();
  int _currentIndex = 0;
  models.UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _incomingCallSubscription;
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

  bool _isDayCompleted(DateTime day, int streakDays) {
    final today = DateUtils.dateOnly(DateTime.now());
    final checkDay = DateUtils.dateOnly(day);

    // If streakDays > 0 → normal logic
    if (streakDays > 0) {
      final diff = today.difference(checkDay).inDays;
      return diff >= 0 && diff < streakDays;
    }

    // If streakDays == 0 → highlight today only
    return today == checkDay;
  }

  List<DateTime> _getCurrentWeekDates() {
    final now = DateTime.now();

    // ISO week starts on Monday (1)
    final int currentWeekday = now.weekday;
    final monday = now.subtract(Duration(days: currentWeekday - 1));

    return List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });
  }

  // Handle tab navigation - no dialogs, just show premium screen in-tab
  void _handleTabNavigation(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _listenForIncomingCalls();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('🔍 [HomeScreen] Loading profile for user: ${user.uid}');
      try {
        final profile = await _firebaseService.getUserProfile(user.uid);
        print(
            '📄 [HomeScreen] Profile loaded: ${profile?.displayName ?? "null"}');

        if (mounted) {
          setState(() {
            _currentUser = profile;
            _isLoadingProfile = false;
          });
        }

        // Update online status
        await _firebaseService.updateUserStatus(user.uid, true);
        print('✅ [HomeScreen] User status updated');
      } catch (e) {
        print('❌ [HomeScreen] Error loading profile: $e');
        if (mounted) {
          setState(() => _isLoadingProfile = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: ${e.toString()}')),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _startAudioPair() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Find matching partner
      final partner = await _firebaseService.findMatchingPartner(_currentUser!);

      if (partner == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No partners available right now. Try again later!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Navigate to audio chat
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AudioChatScreen(
              partner: partner,
              currentUser: _currentUser!,
            ),
          ),
        );
      }
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

  // Listen for incoming calls
  void _listenForIncomingCalls() {
    _incomingCallSubscription =
        _callSignalingService.listenForIncomingCalls().listen((call) {
      if (call != null && mounted) {
        // Show incoming call screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => IncomingCallScreen(call: call),
          ),
        );
      }
    });
  }

  // Start random voice call
  Future<void> _startRandomCall() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
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

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                      onTap: () {
                        Navigator.of(context).pop();
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

  Widget _buildHomeTab() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    final weekDates = _getCurrentWeekDates();
    final streakDays = _currentUser?.streakDays ?? 0;
    final streak = _currentUser?.streakDays ?? 0;

    return Column(
      children: [
        // Header with avatar and online count
        SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF4A90A4),
                    backgroundImage: _currentUser?.photoUrl != null
                        ? NetworkImage(_currentUser!.photoUrl!)
                        : null,
                    child: _currentUser?.photoUrl == null
                        ? Text(
                            (_currentUser?.displayName != null &&
                                    _currentUser!.displayName.isNotEmpty)
                                ? _currentUser!.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.displayName ?? 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.green),
                        const SizedBox(width: 4),
                        StreamBuilder<int>(
                          stream: _onlineUsersCountStream(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Text(
                                '...',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              );
                            }

                            return Text(
                              '${snapshot.data} online',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // IconButton(
                //   icon: const Icon(Icons.notifications_outlined),
                //   onPressed: () {},
                // ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 👇 ADD THIS IN _buildHomeTab() after header & divider
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                    child: _buildHomeStatusRow(),
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today's Goal Card
                      // Container(
                      //   padding: const EdgeInsets.all(20),
                      //   decoration: BoxDecoration(
                      //     color: Colors.white,
                      //     borderRadius: BorderRadius.circular(16),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.black.withOpacity(0.05),
                      //         blurRadius: 10,
                      //         offset: const Offset(0, 2),
                      //       ),
                      //     ],
                      //   ),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       const Text(
                      //         "Today's Goal",
                      //         style: TextStyle(
                      //           fontSize: 18,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //       ),
                      //       const SizedBox(height: 8),
                      //       const Text(
                      //         'Practice for 5 minutes',
                      //         style: TextStyle(
                      //           fontSize: 15,
                      //           color: Colors.black87,
                      //         ),
                      //       ),
                      //       const SizedBox(height: 4),
                      //       const Row(
                      //         children: [
                      //           Icon(Icons.access_time,
                      //               size: 14, color: Colors.orange),
                      //           SizedBox(width: 4),
                      //           Text(
                      //             'In progress',
                      //             style: TextStyle(
                      //               fontSize: 13,
                      //               color: Colors.orange,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //       const SizedBox(height: 12),
                      //       Row(
                      //         children: [
                      //           Container(
                      //             height: 70,
                      //             width: 70,
                      //             decoration: BoxDecoration(
                      //               shape: BoxShape.circle,
                      //               border: Border.all(
                      //                 color: Colors.grey.shade300,
                      //                 width: 4,
                      //               ),
                      //             ),
                      //             child: Center(
                      //               child: Text(
                      //                 '${_currentUser?.totalMinutes ?? 0}m',
                      //                 style: const TextStyle(
                      //                   fontSize: 16,
                      //                   fontWeight: FontWeight.bold,
                      //                   color: Colors.orange,
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      //const SizedBox(height: 20),

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
                            // Row(
                            //   children: [
                            //     _buildFilterChip('Free', true),
                            //     const SizedBox(width: 8),
                            //     _buildFilterChip('Female', false),
                            //     const SizedBox(width: 8),
                            //     _buildFilterChip('Male', false),
                            //   ],
                            // ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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

                      // Quick Actions Grid
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: _buildQuickActionCard(
                      //         icon: Icons.podcasts,
                      //         label: 'Pod',
                      //         color: const Color(0xFF4A90A4),
                      //         onTap: () {},
                      //       ),
                      //     ),
                      //     const SizedBox(width: 12),
                      //     Expanded(
                      //       child: _buildQuickActionCard(
                      //         icon: Icons.local_fire_department,
                      //         label: '1D',
                      //         color: const Color(0xFF4A90A4),
                      //         onTap: () {},
                      //       ),
                      //     ),
                      //     const SizedBox(width: 12),
                      //     Expanded(
                      //       child: _buildQuickActionCard(
                      //         icon: Icons.history,
                      //         label: 'History',
                      //         color: const Color(0xFF4A90A4),
                      //         onTap: () {},
                      //       ),
                      //     ),
                      //     const SizedBox(width: 12),
                      //     Expanded(
                      //       child: _buildQuickActionCard(
                      //         icon: Icons.workspace_premium,
                      //         label: 'Premium',
                      //         color: const Color(0xFF4A90A4),
                      //         onTap: () {
                      //           // Navigate to premium screen
                      //         },
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      //const SizedBox(height: 20),

                      // Weekly Streak Card
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
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department,
                                    color: Colors.orange, size: 24),
                                const SizedBox(width: 8),
                                const Text(
                                  'Weekly Streak',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    streak == 0
                                        ? 'Start today'
                                        : '$streak/7 Days',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: weekDates.map((date) {
                                final dayLabel = DateFormat('EEE')
                                    .format(date); // Mon, Tue, etc.
                                final completed =
                                    _isDayCompleted(date, streakDays);

                                return _buildStreakDay(dayLabel, completed);
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // FAQs Section
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
                                Icon(Icons.help_outline,
                                    color: Color(0xFF4A90A4), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'FAQs',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildFAQItem(
                              'What is EnglishCircle?',
                              'EnglishCircle is a social learning platform where users practice English through real-time voice conversations, AI support, and community interaction.',
                            ),
                            const Divider(),
                            _buildFAQItem(
                              'How does EnglishCircle help improve fluency?',
                              'It improves fluency by connecting learners with real people for speaking practice, providing instant feedback, and encouraging daily speaking habits.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF4A90A4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFF4A90A4) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'Free')
            Icon(
              Icons.public,
              size: 16,
              color: selected ? Colors.white : Colors.grey,
            )
          else if (label == 'Female')
            Icon(
              Icons.female,
              size: 16,
              color: selected ? Colors.white : Colors.grey,
            )
          else if (label == 'Male')
            Icon(
              Icons.male,
              size: 16,
              color: selected ? Colors.white : Colors.grey,
            ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakDay(String day, bool completed) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? Colors.orange : Colors.grey.shade200,
          ),
          child: completed
              ? const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            color: completed ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),

      // 🔴 REMOVE DIVIDER LINES
      shape: const Border(),
      collapsedShape: const Border(),

      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      children: [
        Text(
          answer,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // final screens = [
    //   _buildHomeTab(),
    //   const StatusScreen(), // Status screen
    //   _currentUser != null
    //       ? ProfileScreen(userId: _currentUser!.uid)
    //       : const Center(child: CircularProgressIndicator()),
    //   const AIAgentPage(), // AI Agent screen
    //   //const PremiumScreen(),
    //   const ChatsListScreen(), // New comprehensive chat system
    // ];
    final screens = [
      // 0️⃣ Home → ALWAYS allowed
      _buildHomeTab(),

      // 1️⃣ Status → Community only + must have package
      _currentUser != null &&
              _hasPackage(_currentUser!) &&
              _hasCommunity(_currentUser!)
          ? const StatusScreen()
          : const PremiumScreen(),

      // 2️⃣ Profile → ALWAYS allowed
      _currentUser != null
          ? ProfileScreen(userId: _currentUser!.uid)
          : const Center(child: CircularProgressIndicator()),

      // 3️⃣ AI Agent → AI only + must have package
      _currentUser != null &&
              _hasPackage(_currentUser!) &&
              _hasAI(_currentUser!)
          ? const AIAgentPage()
          : const PremiumScreen(),

      // 4️⃣ Chat → Community only + must have package
      _currentUser != null &&
              _hasPackage(_currentUser!) &&
              _hasCommunity(_currentUser!)
          ? const ChatsListScreen()
          : const PremiumScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: Colors.grey.shade50,
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleTabNavigation,
        selectedItemColor: const Color(0xFF4A90A4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium),
            label: 'AIagent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF4A90A4),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage: _currentUser?.photoUrl != null
                            ? NetworkImage(_currentUser!.photoUrl!)
                            : null,
                        child: _currentUser?.photoUrl == null
                            ? Text(
                                (_currentUser?.displayName != null &&
                                        _currentUser!.displayName.isNotEmpty)
                                    ? _currentUser!.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFF4A90A4),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.dark_mode_outlined,
                            color: Colors.white),
                        onPressed: () {
                          // Toggle theme
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentUser?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _currentUser?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.home, 'Home', () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                }),
                _buildDrawerItem(Icons.person, 'Profile', () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                }),
                _buildDrawerItem(Icons.workspace_premium, 'AIagent', () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                }),
                _buildDrawerItem(Icons.chat, 'Chat', () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
                }),
                _buildDrawerItem(Icons.notifications, 'Notifications', () {
                  Navigator.pop(context);
                }),
                const Divider(),
                _buildDrawerItem(Icons.privacy_tip, 'Privacy policy', () {
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.help, 'Help Center', () {
                  Navigator.pop(context);
                }),
                const Divider(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'V 5.5.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                _buildDrawerItem(Icons.swap_horiz, 'Switch account', () async {
                  Navigator.pop(context);
                  await _firebaseService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4A90A4)),
      title: Text(title),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    _agoraService.dispose();
    super.dispose();
  }

  Widget _buildHomeStatusRow() {
    return SizedBox(
      height: 110,
      child: StreamBuilder<List<StatusModel>>(
        stream: StatusService().getActiveStatuses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          // Group by user → show only latest status per user
          final Map<String, StatusModel> latestByUser = {};
          for (final status in snapshot.data!) {
            latestByUser.putIfAbsent(status.ownerId, () => status);
          }

          final statuses = latestByUser.values.toList();

          // 👤 Move current user's status to first position
          final myUserId = StatusService().currentUser?.uid;

          if (myUserId != null) {
            final myIndex = statuses.indexWhere((s) => s.ownerId == myUserId);

            if (myIndex > 0) {
              final myStatus = statuses.removeAt(myIndex);
              statuses.insert(0, myStatus);
            }
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: statuses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final status = statuses[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatusDetailScreen(status: status),
                    ),
                  );
                },
                child: Column(
                  children: [
                    // 🔵 Avatar with ring
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4A90A4),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: status.ownerPhoto.isNotEmpty
                            ? NetworkImage(status.ownerPhoto)
                            : null,
                        child: status.ownerPhoto.isEmpty
                            ? Text(
                                status.ownerName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 👤 Name
                    SizedBox(
                      width: 60,
                      child: Text(
                        status.ownerName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<int> _onlineUsersCountStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
