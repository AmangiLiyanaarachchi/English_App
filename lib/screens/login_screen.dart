import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _instituteCodeController = TextEditingController();
  final _firebaseService = FirebaseService();

  bool _isLogin = true;
  bool _isLoading = false;
  EnglishLevel _selectedLevel = EnglishLevel.beginner;
  List<String> _selectedInterests = [];

  final List<String> _interestOptions = [
    'Debate',
    'Movies',
    'Music',
    'Technology',
    'Sports',
    'Travel',
    'Food',
    'Books',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _instituteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    print('🚀 [LoginScreen] Starting auth process - isLogin: $_isLogin');
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Login
        print('🔑 [LoginScreen] Logging in...');
        await _firebaseService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        print('✅ [LoginScreen] Login successful, navigating to home');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        // Register
        print('📝 [LoginScreen] Registering new user...');
        final credential = await _firebaseService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        print('👤 [LoginScreen] Creating user profile...');
        // Create user profile
        final user = UserModel(
          uid: credential.user!.uid,
          email: _emailController.text.trim(),
          displayName: _nameController.text.trim(),
          //instituteCode: _instituteCodeController.text.trim().toUpperCase(),
          englishLevel: _selectedLevel,
          interests: _selectedInterests,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          isOnline: true,
        );

        await _firebaseService.createUserProfile(user);
        print('✅ [LoginScreen] Registration complete, navigating to home');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('❌ [LoginScreen] FirebaseAuthException: ${e.code} - ${e.message}');
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email already registered';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      print('❌ [LoginScreen] General error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      print('🏁 [LoginScreen] Auth process completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A9D8F),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Title
                  const Icon(
                    Icons.language,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EnglishCircle',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Welcome Back!' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Name field (only for registration)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (!_isLogin && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Institute code (only for registration)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _instituteCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Institute Code',
                                prefixIcon: Icon(Icons.school),
                                hintText: 'e.g., ENGL101',
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter institute code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // English Level
                            DropdownButtonFormField<EnglishLevel>(
                              value: _selectedLevel,
                              decoration: const InputDecoration(
                                labelText: 'English Level',
                                prefixIcon: Icon(Icons.bar_chart),
                              ),
                              items: EnglishLevel.values.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level.name.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedLevel = value!);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Interests
                            const Text(
                              'Select Interests (Optional)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _interestOptions.map((interest) {
                                final isSelected =
                                    _selectedInterests.contains(interest);
                                return FilterChip(
                                  label: Text(interest),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedInterests.add(interest);
                                      } else {
                                        _selectedInterests.remove(interest);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A9D8F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      _isLogin ? 'LOG IN' : 'SIGN UP',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Toggle login/register
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? 'Don\'t have an account? Sign up'
                                  : 'Already have an account? Log in',
                              style: const TextStyle(color: Color(0xFF2A9D8F)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
