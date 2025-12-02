import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final User googleUser;

  const OnboardingScreen({
    super.key,
    required this.googleUser,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _firebaseService = FirebaseService();
  final _pageController = PageController();
  final _instituteCodeController = TextEditingController();

  int _currentPage = 0;
  EnglishLevel? _selectedLevel;
  int _quizScore = 0;
  int _currentQuiz = 0;
  List<String> _selectedInterests = [];

  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'What is the past tense of "go"?',
      'options': ['goed', 'went', 'gone', 'goes'],
      'correct': 1,
      'difficulty': 'beginner',
    },
    {
      'question': 'Choose the correct sentence:',
      'options': [
        'She don\'t like pizza',
        'She doesn\'t likes pizza',
        'She doesn\'t like pizza',
        'She not like pizza'
      ],
      'correct': 2,
      'difficulty': 'beginner',
    },
    {
      'question': 'Which word is a synonym for "happy"?',
      'options': ['sad', 'joyful', 'angry', 'tired'],
      'correct': 1,
      'difficulty': 'intermediate',
    },
  ];

  final List<Map<String, dynamic>> _interestOptions = [
    {'icon': Icons.forum, 'label': 'Debate', 'color': Color(0xFFE76F51)},
    {'icon': Icons.movie, 'label': 'Movies', 'color': Color(0xFFE9C46A)},
    {'icon': Icons.music_note, 'label': 'Music', 'color': Color(0xFF2A9D8F)},
    {'icon': Icons.computer, 'label': 'Technology', 'color': Color(0xFF264653)},
    {
      'icon': Icons.sports_soccer,
      'label': 'Sports',
      'color': Color(0xFFF4A261)
    },
    {'icon': Icons.flight, 'label': 'Travel', 'color': Color(0xFF8AB17D)},
    {'icon': Icons.restaurant, 'label': 'Food', 'color': Color(0xFFE76F51)},
    {'icon': Icons.book, 'label': 'Books', 'color': Color(0xFF577590)},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _instituteCodeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleQuizAnswer(int selectedIndex) {
    if (selectedIndex == _quizQuestions[_currentQuiz]['correct']) {
      _quizScore++;
    }

    if (_currentQuiz < _quizQuestions.length - 1) {
      setState(() => _currentQuiz++);
    } else {
      // Quiz complete - determine level
      EnglishLevel level;
      if (_quizScore >= 3) {
        level = EnglishLevel.advanced;
      } else if (_quizScore >= 2) {
        level = EnglishLevel.intermediate;
      } else {
        level = EnglishLevel.beginner;
      }
      setState(() => _selectedLevel = level);
      _nextPage();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_instituteCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your institute code')),
      );
      return;
    }

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    try {
      final user = UserModel(
        uid: widget.googleUser.uid,
        email: widget.googleUser.email!,
        displayName: widget.googleUser.displayName ?? 'User',
        photoUrl: widget.googleUser.photoURL,
        instituteCode: _instituteCodeController.text.trim().toUpperCase(),
        englishLevel: _selectedLevel ?? EnglishLevel.beginner,
        interests: _selectedInterests,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        isOnline: true,
      );

      await _firebaseService.createUserProfile(user);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF264653)),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF2A9D8F)),
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildWelcomePage(),
                _buildQuizPage(),
                _buildInterestsPage(),
                _buildInstituteCodePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: widget.googleUser.photoURL != null
                ? NetworkImage(widget.googleUser.photoURL!)
                : null,
            child: widget.googleUser.photoURL == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome, ${widget.googleUser.displayName?.split(' ').first ?? 'there'}! 👋',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF264653),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s set up your English learning profile.\nThis will help us match you with the right practice partners!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Let\'s Get Started!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizPage() {
    if (_selectedLevel != null) {
      // Quiz completed, show result
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2A9D8F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 80,
                color: Color(0xFF2A9D8F),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Great Job!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF264653),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You scored $_quizScore out of ${_quizQuestions.length}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A9D8F), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedLevel == EnglishLevel.advanced
                        ? Icons.star
                        : _selectedLevel == EnglishLevel.intermediate
                            ? Icons.star_half
                            : Icons.star_border,
                    color: const Color(0xFF2A9D8F),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedLevel!.name[0].toUpperCase()}${_selectedLevel!.name.substring(1)} Level',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF264653),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A9D8F),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    // Show quiz question
    final question = _quizQuestions[_currentQuiz];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${_currentQuiz + 1}/${_quizQuestions.length}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            question['question'],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF264653),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ...List.generate(
            (question['options'] as List).length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ElevatedButton(
                onPressed: () => _handleQuizAnswer(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF264653),
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  question['options'][index],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'What interests you?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF264653),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select topics you\'d like to discuss in English',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _interestOptions.length,
              itemBuilder: (context, index) {
                final interest = _interestOptions[index];
                final isSelected =
                    _selectedInterests.contains(interest['label']);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest['label']);
                      } else {
                        _selectedInterests.add(interest['label']);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2A9D8F)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2A9D8F)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          interest['icon'],
                          size: 40,
                          color: isSelected ? Colors.white : interest['color'],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          interest['label'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF264653),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedInterests.isNotEmpty ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A9D8F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                'Continue (${_selectedInterests.length} selected)',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstituteCodePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter Institute Code',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF264653),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'This code connects you with your institute community',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _instituteCodeController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'INST-2024',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                letterSpacing: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2A9D8F), width: 2),
              ),
              contentPadding: const EdgeInsets.all(24),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ask your institute for the code if you don\'t have it',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _completeOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Complete Setup',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
