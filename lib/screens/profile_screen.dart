import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user.dart' as models;
import '../models/recording.dart';

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
  List<Recording> _recordings = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
    print('🔍 [ProfileScreen] initState called with userId: ${widget.userId}');
  }

  Future<void> _loadProfile() async {
    print('📱 [ProfileScreen] _loadProfile started');
    
    if (widget.userId.isEmpty) {
      print('❌ [ProfileScreen] Cannot load profile: userId is empty');
      // Even with empty userId, create a basic profile from current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        print('✅ [ProfileScreen] Creating profile from Firebase Auth (empty userId)');
        setState(() {
          _userProfile = models.UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            instituteCode: '',
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
        });
      }
      return;
    }
    
    try {
      print('📡 [ProfileScreen] Fetching from Firestore...');
      final profile = await _firebaseService.getUserProfile(widget.userId);
      if (mounted) {
        print('✅ [ProfileScreen] Profile loaded from Firestore');
        setState(() => _userProfile = profile);
      }
    } catch (e) {
      print('⚠️ [ProfileScreen] Error loading from Firestore: $e');
      print('📱 [ProfileScreen] Using Firebase Auth data as fallback');
      
      // Fallback to Firebase Auth user data if Firestore fails
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        print('✅ [ProfileScreen] Creating fallback profile for: ${user.displayName}');
        setState(() {
          _userProfile = models.UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            instituteCode: '',
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
        });
      } else {
        print('❌ [ProfileScreen] No Firebase Auth user found');
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings
            },
          ),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A90A4),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_userProfile!.totalMinutes}m',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A90A4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Weekly chart
                        SizedBox(
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildChartBar('Tue', 0, 100),
                              _buildChartBar('Wed', 0, 100),
                              _buildChartBar('Thu', 0, 100),
                              _buildChartBar('Fri', 0, 100),
                              _buildChartBar('Sat', 0, 100),
                              _buildChartBar('Sun', 80, 100),
                              _buildChartBar('Mon', 0, 100),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Text('Tue',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text('Wed',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text('Thu',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text('Fri',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text('Sat',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text('Sun',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text('Mon',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 20, color: Colors.grey),
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
                              onPressed: () {
                                // Edit name
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _userProfile!.uid.substring(0, 16),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy,
                                size: 14, color: Colors.grey.shade400),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sri Lanka | Western Province',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'male',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '0 Following',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF4A90A4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Text(
                              '0 Followers',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF4A90A4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistic',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.local_fire_department,
                                  color: Colors.orange, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Current streak',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_userProfile!.streakDays} days',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: Colors.amber, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Best streak',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_userProfile!.streakDays} days',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.amber, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Aura',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${_userProfile!.karmaPoints}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
      IconData trailingIcon, Color color, {bool isSignOut = false}) {
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
        } else if (title == 'Contact us') {
          // Contact us
        } else if (title == 'Share') {
          // Share
        } else if (title == 'Rate us') {
          // Rate
        } else if (title == 'Join Premium Today') {
          // Premium
        }
      },
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
}
