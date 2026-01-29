// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:english_circle/models/status_model.dart';
// import 'package:english_circle/screens/ai_agent_page.dart';
// import 'package:english_circle/screens/premium_screen.dart';
// import 'package:english_circle/services/status_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:permission_handler/permission_handler.dart';

// import '../models/user.dart' as models;
// import '../services/agora_service.dart';
// import '../services/call_signaling_service.dart';
// import '../services/firebase_service.dart';
// import '../services/random_call_service.dart';
// import 'audio_chat_screen.dart';
// import 'chats_list_screen.dart';
// import 'incoming_call_screen.dart';
// import 'profile_screen.dart';
// import 'status_screen.dart';
// import 'voice_call_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _firebaseService = FirebaseService();
//   final _agoraService = AgoraService();
//   final _callSignalingService = CallSignalingService();
//   final _randomCallService = RandomCallService(); // NEW
//   int _currentIndex = 0;
//   models.UserModel? _currentUser;
//   bool _isLoading = false;
//   bool _isLoadingProfile = true;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   StreamSubscription? _incomingCallSubscription;
//   bool _hasAI(models.UserModel user) {
//     return user.package == "AI Agent" || user.package == "Community + AI Agent";
//   }

//   bool _hasCommunity(models.UserModel user) {
//     return user.package == "Community Plan" ||
//         user.package == "Community + AI Agent";
//   }

//   bool _hasPackage(models.UserModel user) {
//     return user.package != null && user.package!.isNotEmpty;
//   }

//   bool _isDayCompleted(DateTime day, int streakDays) {
//     final today = DateUtils.dateOnly(DateTime.now());
//     final checkDay = DateUtils.dateOnly(day);

//     // If streakDays > 0 → normal logic
//     if (streakDays > 0) {
//       final diff = today.difference(checkDay).inDays;
//       return diff >= 0 && diff < streakDays;
//     }

//     // If streakDays == 0 → highlight today only
//     return today == checkDay;
//   }

//   List<DateTime> _getCurrentWeekDates() {
//     final now = DateTime.now();

//     // ISO week starts on Monday (1)
//     final int currentWeekday = now.weekday;
//     final monday = now.subtract(Duration(days: currentWeekday - 1));

//     return List.generate(7, (index) {
//       return monday.add(Duration(days: index));
//     });
//   }

//   // Handle tab navigation - no dialogs, just show premium screen in-tab
//   void _handleTabNavigation(int index) {
//     setState(() => _currentIndex = index);
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile();
//     _listenForIncomingCalls();
//   }

//   Future<void> _loadUserProfile() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       print('🔍 [HomeScreen] Loading profile for user: ${user.uid}');
//       try {
//         final profile = await _firebaseService.getUserProfile(user.uid);
//         print(
//             '📄 [HomeScreen] Profile loaded: ${profile?.displayName ?? "null"}');

//         if (mounted) {
//           setState(() {
//             _currentUser = profile;
//             _isLoadingProfile = false;
//           });
//         }

//         // Update online status
//         await _firebaseService.updateUserStatus(user.uid, true);
//         print('✅ [HomeScreen] User status updated');
//       } catch (e) {
//         print('❌ [HomeScreen] Error loading profile: $e');
//         if (mounted) {
//           setState(() => _isLoadingProfile = false);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error loading profile: ${e.toString()}')),
//           );
//         }
//       }
//     } else {
//       if (mounted) {
//         setState(() => _isLoadingProfile = false);
//       }
//     }
//   }

//   Future<void> _startAudioPair() async {
//     if (_currentUser == null) return;

//     setState(() => _isLoading = true);

//     try {
//       // Find matching partner
//       final partner = await _firebaseService.findMatchingPartner(_currentUser!);

//       if (partner == null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content:
//                   Text('No partners available right now. Try again later!'),
//               duration: Duration(seconds: 2),
//             ),
//           );
//         }
//         return;
//       }

//       // Navigate to audio chat
//       if (mounted) {
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (_) => AudioChatScreen(
//               partner: partner,
//               currentUser: _currentUser!,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   // Listen for incoming calls
//   void _listenForIncomingCalls() {
//     _incomingCallSubscription =
//         _callSignalingService.listenForIncomingCalls().listen((call) {
//       if (call != null && mounted) {
//         // Show incoming call screen
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (context) => IncomingCallScreen(call: call),
//           ),
//         );
//       }
//     });
//   }

//   // Start random voice call
//   Future<void> _startRandomCall() async {
//     // Get current Firebase user
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please log in to make calls')),
//         );
//       }
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       // NEW: Check random call permission first
//       final permission =
//           await _randomCallService.checkRandomCallPermission(currentUser.uid);

//       if (!permission['canCall']) {
//         final totalSeconds = permission['totalSecondsUsed'] as int;
//         final totalMinutes = (totalSeconds / 60).toStringAsFixed(1);

//         if (mounted) {
//           showDialog(
//             context: context,
//             barrierDismissible: false,
//             builder: (context) => Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               elevation: 0,
//               backgroundColor: Colors.transparent,
//               child: Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Icon
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.timer_off,
//                         size: 50,
//                         color: Colors.red.shade400,
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     // Title
//                     const Text(
//                       'Time Limit Reached',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF2C3E50),
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),

//                     // Message
//                     Text(
//                       'You have used all your random call time ($totalMinutes minutes).',
//                       style: TextStyle(
//                         fontSize: 15,
//                         color: Colors.grey[700],
//                         height: 1.5,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 12),

//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.orange.shade50,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: Colors.orange.shade200,
//                           width: 1,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.info_outline,
//                             size: 20,
//                             color: Colors.orange.shade700,
//                           ),
//                           const SizedBox(width: 8),
//                           Flexible(
//                             child: Text(
//                               'Random call feature is now disabled',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.orange.shade900,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // OK Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF3498DB),
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 0,
//                         ),
//                         child: const Text(
//                           'OK',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }
//         return;
//       }

//       // Show remaining time info
//       final remainingSeconds = permission['remainingSeconds'] as int;
//       final remainingMinutes = (remainingSeconds / 60).toStringAsFixed(1);

//       if (mounted && remainingSeconds < 180) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content:
//                 Text('Random call time remaining: $remainingMinutes minutes'),
//             backgroundColor:
//                 remainingSeconds < 60 ? Colors.orange : Colors.blue,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }

//       // Show user selection dialog
//       await _showUserSelectionDialog();
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   // Show dialog to select a user for voice call
//   Future<void> _showUserSelectionDialog() async {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return;

//     // Fetch all users except current user
//     final usersSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
//         .limit(50)
//         .get();

//     if (usersSnapshot.docs.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No users available for calling')),
//         );
//       }
//       return;
//     }

//     final users = usersSnapshot.docs
//         .map((doc) => models.UserModel.fromFirestore(doc))
//         .toList();

//     if (!mounted) return;

//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           constraints: const BoxConstraints(maxHeight: 500),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Select User to Call',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Expanded(
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: users.length,
//                   itemBuilder: (context, index) {
//                     final user = users[index];
//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: user.photoUrl != null
//                             ? NetworkImage(user.photoUrl!)
//                             : null,
//                         child: user.photoUrl == null
//                             ? Text(
//                                 user.displayName.isNotEmpty
//                                     ? user.displayName[0].toUpperCase()
//                                     : 'U',
//                               )
//                             : null,
//                       ),
//                       title: Text(
//                         user.displayName.isNotEmpty
//                             ? user.displayName
//                             : 'Unknown User',
//                       ),
//                       subtitle: Text(user.email),
//                       onTap: () {
//                         Navigator.of(context).pop();
//                         _initiateCallWithUser(user);
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Initiate call with selected user
//   Future<void> _initiateCallWithUser(models.UserModel otherUser) async {
//     try {
//       if (_currentUser == null) return;

//       // Request microphone permission first
//       final micPermission = await Permission.microphone.request();
//       if (!micPermission.isGranted) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content:
//                   Text('Microphone permission is required for voice calls'),
//             ),
//           );
//         }
//         return;
//       }

//       // Show loading
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       // Create call
//       final call = await _callSignalingService.createCall(
//         receiverId: otherUser.uid,
//         receiverName: otherUser.displayName,
//         receiverPhotoUrl: otherUser.photoUrl ?? '',
//         callerName: _currentUser!.displayName,
//         callerPhotoUrl: _currentUser!.photoUrl ?? '',
//       );

//       print(
//           '📤 HOME: Call created, joining Agora channel: ${call.agoraChannelId}');

//       // Join Agora channel (initialize is handled internally)
//       await _agoraService.joinChannel(call.agoraChannelId);

//       // Close loading dialog
//       Navigator.of(context).pop();

//       // Navigate to voice call screen
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => VoiceCallScreen(
//             call: call,
//             isOutgoing: true,
//             isRandomCall: true, // NEW: Mark this as a random call
//           ),
//         ),
//       );
//     } catch (e) {
//       print('Error initiating call: $e');
//       // Leave the channel if we joined it before the error
//       await _agoraService.leaveChannel().catchError((err) {
//         print('Error leaving channel after failed initiation: $err');
//       });
//       Navigator.of(context).pop();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to initiate call: $e')),
//         );
//       }
//     }
//   }

//   Widget _buildHomeTab() {
//     if (_isLoadingProfile) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     final weekDates = _getCurrentWeekDates();
//     final streakDays = _currentUser?.streakDays ?? 0;
//     final streak = _currentUser?.streakDays ?? 0;

//     return Column(
//       children: [
//         // Header with avatar and online count
//         SafeArea(
//           bottom: false,
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.white,
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => _scaffoldKey.currentState?.openDrawer(),
//                   child: CircleAvatar(
//                     radius: 24,
//                     backgroundColor: const Color(0xFF4A90A4),
//                     backgroundImage: _currentUser?.photoUrl != null
//                         ? NetworkImage(_currentUser!.photoUrl!)
//                         : null,
//                     child: _currentUser?.photoUrl == null
//                         ? Text(
//                             (_currentUser?.displayName != null &&
//                                     _currentUser!.displayName.isNotEmpty)
//                                 ? _currentUser!.displayName[0].toUpperCase()
//                                 : 'U',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           )
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _currentUser?.displayName ?? 'User',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Row(
//                       children: [
//                         const Icon(Icons.circle, size: 8, color: Colors.green),
//                         const SizedBox(width: 4),
//                         StreamBuilder<int>(
//                           stream: _onlineUsersCountStream(),
//                           builder: (context, snapshot) {
//                             if (!snapshot.hasData) {
//                               return const Text(
//                                 '...',
//                                 style:
//                                     TextStyle(fontSize: 12, color: Colors.grey),
//                               );
//                             }

//                             return Text(
//                               '${snapshot.data} online',
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//                 // IconButton(
//                 //   icon: const Icon(Icons.notifications_outlined),
//                 //   onPressed: () {},
//                 // ),
//               ],
//             ),
//           ),
//         ),
//         const Divider(height: 1),
//         Expanded(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 // 👇 ADD THIS IN _buildHomeTab() after header & divider
//                 const SizedBox(height: 12),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: _buildStatusWall(),
//                   ),
//                 ),

//                 const SizedBox(height: 8),

//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Today's Goal Card
//                       // Container(
//                       //   padding: const EdgeInsets.all(20),
//                       //   decoration: BoxDecoration(
//                       //     color: Colors.white,
//                       //     borderRadius: BorderRadius.circular(16),
//                       //     boxShadow: [
//                       //       BoxShadow(
//                       //         color: Colors.black.withOpacity(0.05),
//                       //         blurRadius: 10,
//                       //         offset: const Offset(0, 2),
//                       //       ),
//                       //     ],
//                       //   ),
//                       //   child: Column(
//                       //     crossAxisAlignment: CrossAxisAlignment.start,
//                       //     children: [
//                       //       const Text(
//                       //         "Today's Goal",
//                       //         style: TextStyle(
//                       //           fontSize: 18,
//                       //           fontWeight: FontWeight.bold,
//                       //         ),
//                       //       ),
//                       //       const SizedBox(height: 8),
//                       //       const Text(
//                       //         'Practice for 5 minutes',
//                       //         style: TextStyle(
//                       //           fontSize: 15,
//                       //           color: Colors.black87,
//                       //         ),
//                       //       ),
//                       //       const SizedBox(height: 4),
//                       //       const Row(
//                       //         children: [
//                       //           Icon(Icons.access_time,
//                       //               size: 14, color: Colors.orange),
//                       //           SizedBox(width: 4),
//                       //           Text(
//                       //             'In progress',
//                       //             style: TextStyle(
//                       //               fontSize: 13,
//                       //               color: Colors.orange,
//                       //             ),
//                       //           ),
//                       //         ],
//                       //       ),
//                       //       const SizedBox(height: 12),
//                       //       Row(
//                       //         children: [
//                       //           Container(
//                       //             height: 70,
//                       //             width: 70,
//                       //             decoration: BoxDecoration(
//                       //               shape: BoxShape.circle,
//                       //               border: Border.all(
//                       //                 color: Colors.grey.shade300,
//                       //                 width: 4,
//                       //               ),
//                       //             ),
//                       //             child: Center(
//                       //               child: Text(
//                       //                 '${_currentUser?.totalMinutes ?? 0}m',
//                       //                 style: const TextStyle(
//                       //                   fontSize: 16,
//                       //                   fontWeight: FontWeight.bold,
//                       //                   color: Colors.orange,
//                       //                 ),
//                       //               ),
//                       //             ),
//                       //           ),
//                       //         ],
//                       //       ),
//                       //     ],
//                       //   ),
//                       // ),
//                       //const SizedBox(height: 20),

//                       // Random Call Card
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 10,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Row(
//                               children: [
//                                 Icon(Icons.phone_in_talk,
//                                     color: Color(0xFF4A90A4), size: 24),
//                                 SizedBox(width: 8),
//                                 Text(
//                                   'Random Call',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             const Text(
//                               'Get instantly connected with another English learner for a real-time voice conversation. '
//                               'Calls are randomly matched to help you practice speaking naturally and confidently.',
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.grey,
//                                 height: 1.4,
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             // Row(
//                             //   children: [
//                             //     _buildFilterChip('Free', true),
//                             //     const SizedBox(width: 8),
//                             //     _buildFilterChip('Female', false),
//                             //     const SizedBox(width: 8),
//                             //     _buildFilterChip('Male', false),
//                             //   ],
//                             // ),
//                             const SizedBox(height: 16),
//                             SizedBox(
//                               width: double.infinity,
//                               height: 50,
//                               child: ElevatedButton(
//                                 onPressed: _isLoading ? null : _startRandomCall,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF4A90A4),
//                                   foregroundColor: Colors.white,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   elevation: 0,
//                                 ),
//                                 child: _isLoading
//                                     ? const SizedBox(
//                                         height: 20,
//                                         width: 20,
//                                         child: CircularProgressIndicator(
//                                           color: Colors.white,
//                                           strokeWidth: 2,
//                                         ),
//                                       )
//                                     : const Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Icon(Icons.phone, size: 20),
//                                           SizedBox(width: 8),
//                                           Text(
//                                             'Connect with Co-learners',
//                                             style: TextStyle(
//                                               fontSize: 15,
//                                               fontWeight: FontWeight.w600,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // Quick Actions Grid
//                       // Row(
//                       //   children: [
//                       //     Expanded(
//                       //       child: _buildQuickActionCard(
//                       //         icon: Icons.podcasts,
//                       //         label: 'Pod',
//                       //         color: const Color(0xFF4A90A4),
//                       //         onTap: () {},
//                       //       ),
//                       //     ),
//                       //     const SizedBox(width: 12),
//                       //     Expanded(
//                       //       child: _buildQuickActionCard(
//                       //         icon: Icons.local_fire_department,
//                       //         label: '1D',
//                       //         color: const Color(0xFF4A90A4),
//                       //         onTap: () {},
//                       //       ),
//                       //     ),
//                       //     const SizedBox(width: 12),
//                       //     Expanded(
//                       //       child: _buildQuickActionCard(
//                       //         icon: Icons.history,
//                       //         label: 'History',
//                       //         color: const Color(0xFF4A90A4),
//                       //         onTap: () {},
//                       //       ),
//                       //     ),
//                       //     const SizedBox(width: 12),
//                       //     Expanded(
//                       //       child: _buildQuickActionCard(
//                       //         icon: Icons.workspace_premium,
//                       //         label: 'Premium',
//                       //         color: const Color(0xFF4A90A4),
//                       //         onTap: () {
//                       //           // Navigate to premium screen
//                       //         },
//                       //       ),
//                       //     ),
//                       //   ],
//                       // ),
//                       //const SizedBox(height: 20),

//                       // Weekly Streak Card
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 10,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           children: [
//                             const Row(
//                               children: [
//                                 Icon(Icons.local_fire_department,
//                                     color: Colors.orange, size: 24),
//                                 SizedBox(width: 8),
//                                 Text(
//                                   'Weekly Streak',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Spacer(),
//                                 // Container(
//                                 //   padding: const EdgeInsets.symmetric(
//                                 //     horizontal: 12,
//                                 //     vertical: 4,
//                                 //   ),
//                                 //   decoration: BoxDecoration(
//                                 //     color: Colors.orange.shade50,
//                                 //     borderRadius: BorderRadius.circular(12),
//                                 //   ),
//                                 //   // child: Text(
//                                 //   //   streak == 0
//                                 //   //       ? 'Start today'
//                                 //   //       : '$streak/7 Days',
//                                 //   //   style: TextStyle(
//                                 //   //     fontSize: 12,
//                                 //   //     color: Colors.orange.shade800,
//                                 //   //     fontWeight: FontWeight.w600,
//                                 //   //   ),
//                                 //   // ),
//                                 // ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceAround,
//                               children: weekDates.map((date) {
//                                 final dayLabel = DateFormat('EEE')
//                                     .format(date); // Mon, Tue, etc.
//                                 final completed =
//                                     _isDayCompleted(date, streakDays);

//                                 return _buildStreakDay(dayLabel, completed);
//                               }).toList(),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // FAQs Section
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 10,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Row(
//                               children: [
//                                 Icon(Icons.help_outline,
//                                     color: Color(0xFF4A90A4), size: 24),
//                                 SizedBox(width: 8),
//                                 Text(
//                                   'FAQs',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),
//                             _buildFAQItem(
//                               'What is EnglishCircle?',
//                               'EnglishCircle is a social learning platform where users practice English through real-time voice conversations, AI support, and community interaction.',
//                             ),
//                             const Divider(),
//                             _buildFAQItem(
//                               'How does EnglishCircle help improve fluency?',
//                               'It improves fluency by connecting learners with real people for speaking practice, providing instant feedback, and encouraging daily speaking habits.',
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFilterChip(String label, bool selected) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: selected ? const Color(0xFF4A90A4) : Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: selected ? const Color(0xFF4A90A4) : Colors.grey.shade300,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (label == 'Free')
//             Icon(
//               Icons.public,
//               size: 16,
//               color: selected ? Colors.white : Colors.grey,
//             )
//           else if (label == 'Female')
//             Icon(
//               Icons.female,
//               size: 16,
//               color: selected ? Colors.white : Colors.grey,
//             )
//           else if (label == 'Male')
//             Icon(
//               Icons.male,
//               size: 16,
//               color: selected ? Colors.white : Colors.grey,
//             ),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 13,
//               color: selected ? Colors.white : Colors.grey.shade700,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActionCard({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 28, color: color),
//             const SizedBox(height: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 13,
//                 color: color,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStreakDay(String day, bool completed) {
//     return Column(
//       children: [
//         Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: completed ? Colors.orange : Colors.grey.shade200,
//           ),
//           child: completed
//               ? const Icon(
//                   Icons.local_fire_department,
//                   color: Colors.white,
//                   size: 20,
//                 )
//               : null,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           day,
//           style: TextStyle(
//             fontSize: 11,
//             color: completed ? Colors.black : Colors.grey,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFAQItem(String question, String answer) {
//     return ExpansionTile(
//       tilePadding: EdgeInsets.zero,
//       childrenPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),

//       // 🔴 REMOVE DIVIDER LINES
//       shape: const Border(),
//       collapsedShape: const Border(),

//       title: Text(
//         question,
//         style: const TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//           color: Colors.black87,
//         ),
//       ),
//       children: [
//         Text(
//           answer,
//           style: TextStyle(
//             fontSize: 13,
//             color: Colors.grey.shade700,
//             height: 1.4,
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // final screens = [
//     //   _buildHomeTab(),
//     //   const StatusScreen(), // Status screen
//     //   _currentUser != null
//     //       ? ProfileScreen(userId: _currentUser!.uid)
//     //       : const Center(child: CircularProgressIndicator()),
//     //   const AIAgentPage(), // AI Agent screen
//     //   //const PremiumScreen(),
//     //   const ChatsListScreen(), // New comprehensive chat system
//     // ];
//     final screens = [
//       // 0️⃣ Home → ALWAYS allowed
//       _buildHomeTab(),

//       // 1️⃣ Status → Community only + must have package
//       _currentUser != null &&
//               _hasPackage(_currentUser!) &&
//               _hasCommunity(_currentUser!)
//           ? const StatusScreen()
//           : const PremiumScreen(),

//       // 2️⃣ Profile → ALWAYS allowed
//       _currentUser != null
//           ? ProfileScreen(userId: _currentUser!.uid)
//           : const Center(child: CircularProgressIndicator()),

//       // 3️⃣ AI Agent → AI only + must have package
//       _currentUser != null &&
//               _hasPackage(_currentUser!) &&
//               _hasAI(_currentUser!)
//           ? const AIAgentPage()
//           : const PremiumScreen(),

//       // 4️⃣ Chat → Community only + must have package
//       _currentUser != null &&
//               _hasPackage(_currentUser!) &&
//               _hasCommunity(_currentUser!)
//           ? const ChatsListScreen()
//           : const PremiumScreen(),
//     ];

//     return Scaffold(
//       key: _scaffoldKey,
//       drawer: _buildDrawer(),
//       backgroundColor: Colors.grey.shade50,
//       body: screens[_currentIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: _handleTabNavigation,
//         selectedItemColor: const Color(0xFF4A90A4),
//         unselectedItemColor: Colors.grey,
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.white,
//         elevation: 8,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.photo_library),
//             label: 'Status',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.workspace_premium),
//             label: 'AIagent',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat_bubble_outline),
//             label: 'Chat',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             color: const Color(0xFF4A90A4),
//             child: SafeArea(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 30,
//                         backgroundColor: Colors.white,
//                         backgroundImage: _currentUser?.photoUrl != null
//                             ? NetworkImage(_currentUser!.photoUrl!)
//                             : null,
//                         child: _currentUser?.photoUrl == null
//                             ? Text(
//                                 (_currentUser?.displayName != null &&
//                                         _currentUser!.displayName.isNotEmpty)
//                                     ? _currentUser!.displayName[0].toUpperCase()
//                                     : 'U',
//                                 style: const TextStyle(
//                                   fontSize: 24,
//                                   color: Color(0xFF4A90A4),
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               )
//                             : null,
//                       ),
//                       const SizedBox(width: 16),
//                       IconButton(
//                         icon: const Icon(Icons.dark_mode_outlined,
//                             color: Colors.white),
//                         onPressed: () {
//                           // Toggle theme
//                         },
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     _currentUser?.displayName ?? 'User',
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   Text(
//                     _currentUser?.email ?? '',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Colors.white70,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 _buildDrawerItem(Icons.home, 'Home', () {
//                   Navigator.pop(context);
//                   setState(() => _currentIndex = 0);
//                 }),
//                 _buildDrawerItem(Icons.person, 'Profile', () {
//                   Navigator.pop(context);
//                   setState(() => _currentIndex = 2);
//                 }),
//                 _buildDrawerItem(Icons.workspace_premium, 'AIagent', () {
//                   Navigator.pop(context);
//                   setState(() => _currentIndex = 3);
//                 }),
//                 _buildDrawerItem(Icons.chat, 'Chat', () {
//                   Navigator.pop(context);
//                   setState(() => _currentIndex = 4);
//                 }),
//                 _buildDrawerItem(Icons.notifications, 'Notifications', () {
//                   Navigator.pop(context);
//                 }),
//                 const Divider(),
//                 _buildDrawerItem(Icons.privacy_tip, 'Privacy policy', () {
//                   Navigator.pop(context);
//                 }),
//                 _buildDrawerItem(Icons.help, 'Help Center', () {
//                   Navigator.pop(context);
//                 }),
//                 const Divider(),
//                 Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Text(
//                     'V 5.5.0',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ),
//                 _buildDrawerItem(Icons.swap_horiz, 'Switch account', () async {
//                   Navigator.pop(context);
//                   await _firebaseService.signOut();
//                   if (mounted) {
//                     Navigator.of(context).pushReplacementNamed('/login');
//                   }
//                 }),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
//     return ListTile(
//       leading: Icon(icon, color: const Color(0xFF4A90A4)),
//       title: Text(title),
//       onTap: onTap,
//     );
//   }

//   @override
//   void dispose() {
//     _incomingCallSubscription?.cancel();
//     _agoraService.dispose();
//     super.dispose();
//   }

//   Widget _buildStatusWall() {
//     return StreamBuilder<List<StatusModel>>(
//       stream:
//           StatusService().getActiveStatuses(), // ideally already time-ordered
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         final data = snapshot.data!;
//         if (data.isEmpty) return const SizedBox.shrink();

//         // If your stream returns multiple statuses per user and you want ALL posts,
//         // then DO NOT group by user. Facebook wall shows all posts.
//         // If you want only latest per user, keep grouping.
//         final statuses = data; // show all

//         return ListView.separated(
//           physics: const NeverScrollableScrollPhysics(),
//           shrinkWrap: true,
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           itemCount: statuses.length,
//           separatorBuilder: (_, __) => const SizedBox(height: 12),
//           itemBuilder: (context, index) {
//             final status = statuses[index];
//             return _buildStatusPostCard(context, status);
//           },
//         );
//       },
//     );
//   }

//   // Widget _buildHomeStatusRow() {
//   //   return SizedBox(
//   //     height: 110,
//   //     child: StreamBuilder<List<StatusModel>>(
//   //       stream: StatusService().getActiveStatuses(),
//   //       builder: (context, snapshot) {
//   //         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//   //           return const SizedBox.shrink();
//   //         }

//   //         // Group by user → show only latest status per user
//   //         final Map<String, StatusModel> latestByUser = {};
//   //         for (final status in snapshot.data!) {
//   //           latestByUser.putIfAbsent(status.ownerId, () => status);
//   //         }

//   //         final statuses = latestByUser.values.toList();

//   //         // 👤 Move current user's status to first position
//   //         final myUserId = StatusService().currentUser?.uid;

//   //         if (myUserId != null) {
//   //           final myIndex = statuses.indexWhere((s) => s.ownerId == myUserId);

//   //           if (myIndex > 0) {
//   //             final myStatus = statuses.removeAt(myIndex);
//   //             statuses.insert(0, myStatus);
//   //           }
//   //         }

//   //         return ListView.separated(
//   //           scrollDirection: Axis.horizontal,
//   //           padding: const EdgeInsets.symmetric(horizontal: 16),
//   //           itemCount: statuses.length,
//   //           separatorBuilder: (_, __) => const SizedBox(width: 14),
//   //           itemBuilder: (context, index) {
//   //             final status = statuses[index];

//   //             return GestureDetector(
//   //               onTap: () {
//   //                 final userStatuses = snapshot.data!
//   //                     .where((s) => s.ownerId == status.ownerId)
//   //                     .toList();

//   //                 if (userStatuses.isEmpty) return;

//   //                 Navigator.push(
//   //                   context,
//   //                   MaterialPageRoute(
//   //                     builder: (_) => StatusDetailScreen(
//   //                       statuses: userStatuses,
//   //                       initialIndex: 0, otherUserId: status.ownerId, // 👈 start from latest
//   //                     ),
//   //                   ),
//   //                 );
//   //               },
//   //               child: Column(
//   //                 children: [
//   //                   // 🔵 Avatar with ring
//   //                   Container(
//   //                     padding: const EdgeInsets.all(3),
//   //                     decoration: const BoxDecoration(
//   //                       shape: BoxShape.circle,
//   //                       color: Color(0xFF4A90A4),
//   //                     ),
//   //                     child: CircleAvatar(
//   //                       radius: 30,
//   //                       backgroundImage: status.ownerPhoto.isNotEmpty
//   //                           ? NetworkImage(status.ownerPhoto)
//   //                           : null,
//   //                       child: status.ownerPhoto.isEmpty
//   //                           ? Text(
//   //                               status.ownerName[0].toUpperCase(),
//   //                               style: const TextStyle(
//   //                                 fontSize: 20,
//   //                                 color: Colors.white,
//   //                                 fontWeight: FontWeight.bold,
//   //                               ),
//   //                             )
//   //                           : null,
//   //                     ),
//   //                   ),

//   //                   const SizedBox(height: 6),

//   //                   // 👤 Name
//   //                   SizedBox(
//   //                     width: 60,
//   //                     child: Text(
//   //                       status.ownerName,
//   //                       textAlign: TextAlign.center,
//   //                       maxLines: 1,
//   //                       overflow: TextOverflow.ellipsis,
//   //                       style: const TextStyle(
//   //                         fontSize: 12,
//   //                         fontWeight: FontWeight.w500,
//   //                       ),
//   //                     ),
//   //                   ),
//   //                 ],
//   //               ),
//   //             );
//   //           },
//   //         );
//   //       },
//   //     ),
//   //   );
//   // }

//   Stream<int> _onlineUsersCountStream() {
//     return FirebaseFirestore.instance
//         .collection('users')
//         .where('isOnline', isEqualTo: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length);
//   }
// }

// Widget _buildStatusPostCard(BuildContext context, StatusModel status) {
//   final String text = (status.text ?? '').trim();
//   final String media = (status.imageUrl ?? '').trim();
//   final bool hasImage = status.type == 'image' && media.isNotEmpty;

//   return Container(
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.05),
//           blurRadius: 10,
//           offset: const Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 22,
//                 backgroundImage: status.ownerPhoto.isNotEmpty
//                     ? NetworkImage(status.ownerPhoto)
//                     : null,
//                 child: status.ownerPhoto.isEmpty
//                     ? Text(status.ownerName.isNotEmpty
//                         ? status.ownerName[0].toUpperCase()
//                         : 'U')
//                     : null,
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       status.ownerName,
//                       style: const TextStyle(fontWeight: FontWeight.w700),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       _formatTimeAgo(status.createdAt),
//                       style:
//                           TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                     ),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.more_horiz),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//         ),

//         // Text
//         if (text.isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Text(text, style: const TextStyle(fontSize: 14)),
//           ),

//         if (text.isNotEmpty && hasImage) const SizedBox(height: 10),

//         // Image
//         if (hasImage)
//           GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => StatusDetailScreen(
//                     statuses: [status],
//                     initialIndex: 0,
//                     otherUserId: status.ownerId,
//                   ),
//                 ),
//               );
//             },
//             child: ClipRRect(
//               borderRadius:
//                   const BorderRadius.vertical(bottom: Radius.circular(16)),
//               child: AspectRatio(
//                 aspectRatio: 1,
//                 child: Image.network(
//                   media,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => Container(
//                     color: Colors.grey.shade200,
//                     alignment: Alignment.center,
//                     child: const Icon(Icons.broken_image),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     ),
//   );
// }



// String _formatTimeAgo(dynamic createdAt) {
//   // createdAt can be Timestamp or DateTime depending on your model
//   DateTime dt;
//   if (createdAt is Timestamp) {
//     dt = createdAt.toDate();
//   } else if (createdAt is DateTime) {
//     dt = createdAt;
//   } else {
//     return '';
//   }

//   final diff = DateTime.now().difference(dt);

//   if (diff.inMinutes < 1) return 'Just now';
//   if (diff.inMinutes < 60) return '${diff.inMinutes}m';
//   if (diff.inHours < 24) return '${diff.inHours}h';
//   return '${diff.inDays}d';
// }

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
import '../services/random_call_service.dart';
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
  final _randomCallService = RandomCallService();

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

    if (streakDays > 0) {
      final diff = today.difference(checkDay).inDays;
      return diff >= 0 && diff < streakDays;
    }

    return today == checkDay;
  }

  List<DateTime> _getCurrentWeekDates() {
    final now = DateTime.now();
    final int currentWeekday = now.weekday;
    final monday = now.subtract(Duration(days: currentWeekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

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
      try {
        final profile = await _firebaseService.getUserProfile(user.uid);

        if (mounted) {
          setState(() {
            _currentUser = profile;
            _isLoadingProfile = false;
          });
        }

        await _firebaseService.updateUserStatus(user.uid, true);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingProfile = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: ${e.toString()}')),
          );
        }
      }
    } else {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _startAudioPair() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final partner = await _firebaseService.findMatchingPartner(_currentUser!);

      if (partner == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No partners available right now. Try again later!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

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

  void _listenForIncomingCalls() {
    _incomingCallSubscription =
        _callSignalingService.listenForIncomingCalls().listen((call) {
      if (call != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => IncomingCallScreen(call: call),
          ),
        );
      }
    });
  }

  Future<void> _startRandomCall() async {
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

      final remainingSeconds = permission['remainingSeconds'] as int;
      final remainingMinutes = (remainingSeconds / 60).toStringAsFixed(1);

      if (mounted && remainingSeconds < 180) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Random call time remaining: $remainingMinutes minutes'),
            backgroundColor: remainingSeconds < 60 ? Colors.orange : Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

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

  Future<void> _showUserSelectionDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

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
                        backgroundImage:
                            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : 'U',
                              )
                            : null,
                      ),
                      title: Text(
                        user.displayName.isNotEmpty ? user.displayName : 'Unknown User',
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

  Future<void> _initiateCallWithUser(models.UserModel otherUser) async {
    try {
      if (_currentUser == null) return;

      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required for voice calls'),
            ),
          );
        }
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final call = await _callSignalingService.createCall(
        receiverId: otherUser.uid,
        receiverName: otherUser.displayName,
        receiverPhotoUrl: otherUser.photoUrl ?? '',
        callerName: _currentUser!.displayName,
        callerPhotoUrl: _currentUser!.photoUrl ?? '',
      );

      await _agoraService.joinChannel(call.agoraChannelId);

      Navigator.of(context).pop();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VoiceCallScreen(
            call: call,
            isOutgoing: true,
            isRandomCall: true,
          ),
        ),
      );
    } catch (e) {
      await _agoraService.leaveChannel().catchError((_) {});
      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate call: $e')),
        );
      }
    }
  }

  // ✅ FACEBOOK WALL: build home tab
  Widget _buildHomeTab() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    final weekDates = _getCurrentWeekDates();
    final streakDays = _currentUser?.streakDays ?? 0;

    return Column(
      children: [
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
                                style: TextStyle(fontSize: 12, color: Colors.grey),
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
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ✅ Just place wall directly (avoid extra white container inside white container)
                _buildStatusWall(),

                const SizedBox(height: 12),

                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: Column(
                //     children: [
                //       // Random Call Card
                //       Container(
                //         padding: const EdgeInsets.all(20),
                //         decoration: BoxDecoration(
                //           color: Colors.white,
                //           borderRadius: BorderRadius.circular(16),
                //           boxShadow: [
                //             BoxShadow(
                //               color: Colors.black.withOpacity(0.05),
                //               blurRadius: 10,
                //               offset: const Offset(0, 2),
                //             ),
                //           ],
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             const Row(
                //               children: [
                //                 Icon(Icons.phone_in_talk,
                //                     color: Color(0xFF4A90A4), size: 24),
                //                 SizedBox(width: 8),
                //                 Text(
                //                   'Random Call',
                //                   style: TextStyle(
                //                     fontSize: 18,
                //                     fontWeight: FontWeight.bold,
                //                   ),
                //                 ),
                //               ],
                //             ),
                //             const SizedBox(height: 16),
                //             const Text(
                //               'Get instantly connected with another English learner for a real-time voice conversation. '
                //               'Calls are randomly matched to help you practice speaking naturally and confidently.',
                //               style: TextStyle(
                //                 fontSize: 13,
                //                 color: Colors.grey,
                //                 height: 1.4,
                //               ),
                //             ),
                //             const SizedBox(height: 16),
                //             SizedBox(
                //               width: double.infinity,
                //               height: 50,
                //               child: ElevatedButton(
                //                 onPressed: _isLoading ? null : _startRandomCall,
                //                 style: ElevatedButton.styleFrom(
                //                   backgroundColor: const Color(0xFF4A90A4),
                //                   foregroundColor: Colors.white,
                //                   shape: RoundedRectangleBorder(
                //                     borderRadius: BorderRadius.circular(12),
                //                   ),
                //                   elevation: 0,
                //                 ),
                //                 child: _isLoading
                //                     ? const SizedBox(
                //                         height: 20,
                //                         width: 20,
                //                         child: CircularProgressIndicator(
                //                           color: Colors.white,
                //                           strokeWidth: 2,
                //                         ),
                //                       )
                //                     : const Row(
                //                         mainAxisAlignment: MainAxisAlignment.center,
                //                         children: [
                //                           Icon(Icons.phone, size: 20),
                //                           SizedBox(width: 8),
                //                           Text(
                //                             'Connect with Co-learners',
                //                             style: TextStyle(
                //                               fontSize: 15,
                //                               fontWeight: FontWeight.w600,
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),

                //       const SizedBox(height: 20),

                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ FACEBOOK WALL BUILDER
  Widget _buildStatusWall() {
    return StreamBuilder<List<StatusModel>>(
      stream: StatusService().getActiveStatuses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final all = snapshot.data ?? [];
        if (all.isEmpty) return const SizedBox.shrink();

        all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          children: [
            _buildCreatePostBox(),
            const SizedBox(height: 12),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 6),
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final status = all[index];
                return _buildFeedPostCard(
                  context: context,
                  status: status,
                  allStatuses: all,
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ✅ MUST be inside class (uses setState + _currentUser)
  Widget _buildCreatePostBox() {
    final canOpenStatusTab = _currentUser != null &&
        _hasPackage(_currentUser!) &&
        _hasCommunity(_currentUser!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
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
              CircleAvatar(
                radius: 18,
                backgroundImage: _currentUser?.photoUrl != null
                    ? NetworkImage(_currentUser!.photoUrl!)
                    : null,
                child: _currentUser?.photoUrl == null
                    ? Text(
                        (_currentUser?.displayName ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
                backgroundColor: const Color(0xFF4A90A4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // both go to tab 1; if no access -> PremiumScreen already there
                    setState(() => _currentIndex = 1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      canOpenStatusTab ? "What's on your mind?" : "Upgrade to post a status",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: const Icon(Icons.text_fields, color: Color(0xFF4A90A4)),
                  label: const Text("Text",
                      style: TextStyle(color: Color(0xFF4A90A4))),
                ),
              ),
              Container(width: 1, height: 22, color: Colors.grey.shade300),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: const Icon(Icons.photo, color: Color(0xFF4A90A4)),
                  label: const Text("Photo",
                      style: TextStyle(color: Color(0xFF4A90A4))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ MUST be inside class (uses helper + navigation)
  Widget _buildFeedPostCard({
    required BuildContext context,
    required StatusModel status,
    required List<StatusModel> allStatuses,
  }) {
    final caption = (status.text ?? '').trim();
    final image = (status.imageUrl ?? '').trim();
    final hasImage = status.type == 'image' && image.isNotEmpty;

    void openViewer() {
      final userStatuses = allStatuses.where((s) => s.ownerId == status.ownerId).toList();

      // viewer uses same StatusDetailScreen (no change)
      userStatuses.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final idx = userStatuses.indexWhere((s) => s.statusId == status.statusId);
      final initialIndex = idx >= 0 ? idx : 0;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatusDetailScreen(
            statuses: userStatuses,
            initialIndex: initialIndex,
            otherUserId: status.ownerId,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: status.ownerPhoto.isNotEmpty
                      ? NetworkImage(status.ownerPhoto)
                      : null,
                  backgroundColor: const Color(0xFF4A90A4),
                  child: status.ownerPhoto.isEmpty
                      ? Text(
                          status.ownerName.isNotEmpty
                              ? status.ownerName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.ownerName.isNotEmpty ? status.ownerName : 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimeAgo(status.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              
              ],
            ),
          ),

          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                caption,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),

          if (caption.isNotEmpty && hasImage) const SizedBox(height: 10),

          if (hasImage)
            GestureDetector(
              onTap: openViewer,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // TextButton.icon(
                //   onPressed: () {},
                //   icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                //   label: const Text('Like'),
                // ),
                TextButton.icon(
                  onPressed: openViewer,
                  icon: const Icon(Icons.mode_comment_outlined, size: 18),
                  label: const Text('Comment'),
                ),
                const Spacer(),
                IconButton(
                  onPressed: openViewer,
                  icon: const Icon(Icons.open_in_full, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ✅ helper inside class
  String _formatTimeAgo(dynamic createdAt) {
    DateTime dt;
    if (createdAt is Timestamp) {
      dt = createdAt.toDate();
    } else if (createdAt is DateTime) {
      dt = createdAt;
    } else {
      return '';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
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
              ? const Icon(Icons.local_fire_department, color: Colors.white, size: 20)
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

  Stream<int> _onlineUsersCountStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeTab(),
      _currentUser != null && _hasPackage(_currentUser!) && _hasCommunity(_currentUser!)
          ? const StatusScreen()
          : const PremiumScreen(),
      _currentUser != null
          ? ProfileScreen(userId: _currentUser!.uid)
          : const Center(child: CircularProgressIndicator()),
      _currentUser != null && _hasPackage(_currentUser!) && _hasAI(_currentUser!)
          ? const AIAgentPage()
          : const PremiumScreen(),
      _currentUser != null && _hasPackage(_currentUser!) && _hasCommunity(_currentUser!)
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'AIagent'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
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
                        icon: const Icon(Icons.dark_mode_outlined, color: Colors.white),
                        onPressed: () {},
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'V 5.5.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
}
