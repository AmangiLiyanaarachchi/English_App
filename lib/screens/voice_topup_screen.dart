import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'payment_screen.dart';

class VoiceTopupScreen extends StatefulWidget {
  const VoiceTopupScreen({super.key});

  @override
  State<VoiceTopupScreen> createState() => _VoiceTopupScreenState();
}

class _VoiceTopupScreenState extends State<VoiceTopupScreen> {
  final Color mainColor = const Color(0xFF4A90A4);
  String selectedPackage = "";
  double selectedPrice = 0;
  int selectedMinutes = 0;
  bool isLoading = true;
  int currentVoiceMinutes = 0;
  int usedVoiceMinutes = 0;
  bool hasCommunityPlan = false;

  @override
  void initState() {
    super.initState();
    _loadUserVoiceData();
  }

  Future<void> _loadUserVoiceData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          final subscriptions = data?['subscriptions'];

          // Check if user has active Community Plan
          if (subscriptions != null &&
              subscriptions is Map &&
              subscriptions['community'] != null) {
            final commSub = subscriptions['community'];
            if (commSub['expiryDate'] != null) {
              DateTime expiry = (commSub['expiryDate'] as Timestamp).toDate();
              if (expiry.isAfter(DateTime.now())) {
                setState(() {
                  hasCommunityPlan = true;
                  currentVoiceMinutes = data?['voiceTotalMinutes'] ?? 0;
                  usedVoiceMinutes = data?['voiceUsedMinutes'] ?? 0;
                });
              }
            }
          }

          // Check if user is a verified student with active Community Plan
          final isStudentVerified = data?['studentIdVerified'] ?? false;
          final studentPlanEndDate = data?['studentPlanEndDate'];

          if (isStudentVerified && studentPlanEndDate != null) {
            DateTime expiry = (studentPlanEndDate as Timestamp).toDate();
            if (expiry.isAfter(DateTime.now())) {
              setState(() {
                hasCommunityPlan = true;
                currentVoiceMinutes = data?['voiceTotalMinutes'] ?? 0;
                usedVoiceMinutes = data?['voiceUsedMinutes'] ?? 0;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading voice data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _selectPackage(String packageName, double price, int minutes) {
    setState(() {
      if (selectedPackage == packageName) {
        selectedPackage = "";
        selectedPrice = 0;
        selectedMinutes = 0;
      } else {
        selectedPackage = packageName;
        selectedPrice = price;
        selectedMinutes = minutes;
      }
    });
  }

  void _purchaseTopup() {
    if (selectedPackage.isEmpty) return;

    // Navigate to payment screen with top-up details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceTopupPaymentScreen(
          packageName: selectedPackage,
          price: selectedPrice,
          minutes: selectedMinutes,
        ),
      ),
    ).then((_) {
      // Reload data after returning from payment
      _loadUserVoiceData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Voice Minutes Top-Up",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!hasCommunityPlan) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Voice Minutes Top-Up",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Active Community Plan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Voice minute top-ups are only available for users with an active Community Plan subscription.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Premium Plans',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    int remainingMinutes = currentVoiceMinutes - usedVoiceMinutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Voice Minutes Top-Up",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainColor, mainColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Voice Minutes Remaining",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "$remainingMinutes",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "minutes",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Used: $usedVoiceMinutes min  •  Total: $currentVoiceMinutes min",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              "Add More Minutes",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose a top-up package to add voice call minutes to your account",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // Top-up Package 1: LKR 300 = 300 minutes
            _buildTopupCard(
              packageName: "Small Top-Up",
              minutes: 300,
              price: 300,
              icon: Icons.add_circle_outline,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Top-up Package 2: LKR 500 = 750 minutes
            _buildTopupCard(
              packageName: "Large Top-Up",
              minutes: 750,
              price: 500,
              icon: Icons.add_circle,
              color: Colors.green,
              isBestValue: true,
            ),

            const SizedBox(height: 32),

            // Purchase Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: selectedPackage.isEmpty ? null : _purchaseTopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedPackage.isEmpty ? Colors.grey : mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  selectedPackage.isEmpty
                      ? "SELECT A PACKAGE"
                      : "PURCHASE — LKR ${selectedPrice.toInt()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Top-up minutes are valid until your Community Plan expires.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
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

  Widget _buildTopupCard({
    required String packageName,
    required int minutes,
    required double price,
    required IconData icon,
    required Color color,
    bool isBestValue = false,
  }) {
    bool isSelected = selectedPackage == packageName;

    return GestureDetector(
      onTap: () => _selectPackage(packageName, price, minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? mainColor : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mainColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            packageName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? mainColor : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$minutes minutes",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "LKR $price",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? mainColor : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (isBestValue) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star,
                            size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Text(
                          "Best Value - Save 25%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: mainColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Voice Top-up Payment Screen
class VoiceTopupPaymentScreen extends StatelessWidget {
  final String packageName;
  final double price;
  final int minutes;

  const VoiceTopupPaymentScreen({
    super.key,
    required this.packageName,
    required this.price,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    // For now, redirect to the existing payment screen with a special flag
    // In a real implementation, you would create a separate payment flow
    return PaymentScreen(
      selectedPlan: "Voice Top-Up - $packageName",
      selectedDuration: "$minutes minutes",
      price: price,
    );
  }
}
