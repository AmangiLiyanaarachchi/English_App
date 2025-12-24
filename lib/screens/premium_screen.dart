import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'payment_screen.dart';
import 'voice_topup_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String selectedPlan = "";
  String selectedDuration = "";
  double selectedPrice = 0;

  final Color mainColor = const Color(0xFF4A90A4);

  final TextEditingController studentIdController = TextEditingController();
  bool isSubmitting = false;

  // Active subscription info
  String? activePackage;
  DateTime? expiryDate;
  bool isLoading = true;

  // Individual subscription tracking
  Map<String, dynamic>? activeSubscriptions;
  bool hasCommunity = false;
  bool hasAIAgent = false;
  DateTime? communityExpiry;
  DateTime? aiAgentExpiry;

  @override
  void initState() {
    super.initState();
    _loadActiveSubscription();
  }

  Future<void> _loadActiveSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          activePackage = data?['package'];

          // Check individual subscriptions
          final subscriptions = data?['subscriptions'];
          if (subscriptions != null && subscriptions is Map) {
            activeSubscriptions = Map<String, dynamic>.from(subscriptions);

            // Check Community subscription
            if (subscriptions['community'] != null) {
              final commSub = subscriptions['community'];
              if (commSub['expiryDate'] != null) {
                DateTime expiry = (commSub['expiryDate'] as Timestamp).toDate();
                if (expiry.isAfter(DateTime.now())) {
                  hasCommunity = true;
                  communityExpiry = expiry;
                }
              }
            }

            // Check AI Agent subscription
            if (subscriptions['ai_agent'] != null) {
              final aiSub = subscriptions['ai_agent'];
              if (aiSub['expiryDate'] != null) {
                DateTime expiry = (aiSub['expiryDate'] as Timestamp).toDate();
                if (expiry.isAfter(DateTime.now())) {
                  hasAIAgent = true;
                  aiAgentExpiry = expiry;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading subscription: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // bool _isPlanDisabled(String planName) {
  //   // If Community OR AI Agent is active → Disable "Community + AI Agent"
  //   if (planName == "Community + AI Agent") {
  //     return hasCommunity || hasAIAgent;
  //   }

  //   // If both Community AND AI Agent are active → Disable "Community Plan"
  //   if (planName == "Community Plan") {
  //     return hasCommunity && hasAIAgent;
  //   }

  //   // If both Community AND AI Agent are active → Disable "AI Agent"
  //   if (planName == "AI Agent") {
  //     return hasCommunity && hasAIAgent;
  //   }

  //   return false;
  // }
  bool _isPlanDisabled(String planName) {
    if (planName == "Community Plan") {
      return hasCommunity;
    }

    if (planName == "AI Agent") {
      return hasAIAgent;
    }

    return false;
  }

  // void _choosePlan(String plan) {
  //   if (_isPlanDisabled(plan)) {
  //     _showPlanDisabledDialog(plan);
  //     return;
  //   }

  //   setState(() {
  //     if (selectedPlan == plan) {
  //       selectedPlan = "";
  //       selectedDuration = "";
  //       selectedPrice = 0;
  //     } else {
  //       selectedPlan = plan;
  //       selectedDuration = "";
  //       selectedPrice = 0;
  //     }
  //   });
  // }
  void _choosePlan(String plan) {
    if (_isPlanDisabled(plan)) {
      _showPlanDisabledDialog(plan);
      return;
    }

    setState(() {
      if (selectedPlan == plan) {
        selectedPlan = "";
        selectedDuration = "";
        selectedPrice = 0;
      } else {
        selectedPlan = plan;
        selectedDuration = "";
        selectedPrice = 0;
      }
    });
  }

  // void _showPlanDisabledDialog(String planName) {
  //   String message = "";

  //   if (planName == "Community + AI Agent") {
  //     message = "You already have active subscription(s):\n\n";
  //     if (hasCommunity) {
  //       message +=
  //           "✓ Community Plan (expires: ${communityExpiry?.toString().split(' ')[0]})\n";
  //     }
  //     if (hasAIAgent) {
  //       message +=
  //           "✓ AI Agent (expires: ${aiAgentExpiry?.toString().split(' ')[0]})\n";
  //     }
  //     message +=
  //         "\nThe combo plan is disabled until your existing plans expire.";
  //   } else {
  //     message = "You already have both plans active:\n\n";
  //     message +=
  //         "✓ Community Plan (expires: ${communityExpiry?.toString().split(' ')[0]})\n";
  //     message +=
  //         "✓ AI Agent (expires: ${aiAgentExpiry?.toString().split(' ')[0]})\n\n";
  //     message +=
  //         "Individual plan purchase is disabled until one of them expires.";
  //   }

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("Plan Not Available"),
  //       content: Text(message),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("OK"),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  void _showPlanDisabledDialog(String planName) {
    String message = "";

    if (planName == "Community Plan" && hasCommunity) {
      message = "You already have an active Community Plan.\n\n"
          "Expiry date: ${communityExpiry?.toString().split(' ')[0]}\n\n"
          "You can renew or purchase this plan again after it expires.";
    } else if (planName == "AI Agent" && hasAIAgent) {
      message = "You already have an active AI Agent subscription.\n\n"
          "Expiry date: ${aiAgentExpiry?.toString().split(' ')[0]}\n\n"
          "You can renew or purchase this plan again after it expires.";
    } else {
      // Fallback (should not normally happen)
      message = "This plan is currently not available.";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Plan Not Available"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _chooseDuration(String plan, String duration, double price) {
    setState(() {
      selectedPlan = plan;
      selectedDuration = duration;
      selectedPrice = price;
    });
  }

  // 🔥 FIREBASE SAVE FUNCTION (update users collection)
  Future<void> submitStudentID() async {
    String studentID = studentIdController.text.trim();
    if (studentID.isEmpty) return;

    setState(() => isSubmitting = true);

    try {
      // Get current user UID
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Update instituteCode in users collection
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .update({"instituteCode": studentID});

      setState(() => isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student ID submitted successfully!")),
      );

      studentIdController.clear();
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking subscription
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Premium Plans",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Premium Plans",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Voice Top-Up Button (Only show if user has Community Plan)
            if (hasCommunity)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VoiceTopupScreen(),
                    ),
                  ).then((_) => _loadActiveSubscription());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [mainColor.withOpacity(0.8), mainColor],
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_call,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add Voice Minutes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Top-up your voice call minutes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Choose a plan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPlanBox(
                    planName: "Community Plan",
                    description:
                        "Chats, calls, group activities and community access.",
                  ),
                  const SizedBox(height: 12),
                  _buildPlanBox(
                    planName: "AI Agent",
                    description:
                        "AI answers, grammar help, 24/7 English support.",
                  ),
                  // const SizedBox(height: 12),
                  // _buildPlanBox(
                  //   planName: "Community + AI Agent",
                  //   description: "Full community access + AI Agent support.",
                  // ),
                  const SizedBox(height: 20),

                  // Continue button only for non-Community plans
                  // if (selectedPlan != "Community Plan")
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed:
                          (selectedPlan.isEmpty || selectedDuration.isEmpty)
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentScreen(
                                        selectedPlan: selectedPlan,
                                        price: selectedPrice,
                                        selectedDuration: selectedDuration,
                                      ),
                                    ),
                                  );
                                },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (selectedPlan.isEmpty || selectedDuration.isEmpty)
                                ? Colors.grey
                                : mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        (selectedPlan.isEmpty || selectedDuration.isEmpty)
                            ? "CONTINUE"
                            : "CONTINUE — $selectedDuration • LKR ${selectedPrice.toInt()}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
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

  Widget _buildPlanBox({
    required String planName,
    required String description,
  }) {
    bool isExpanded = selectedPlan == planName;
    bool isDisabled = _isPlanDisabled(planName);

    return GestureDetector(
      onTap: () => _choosePlan(planName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[200] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDisabled
                ? Colors.grey
                : (isExpanded ? mainColor : mainColor.withOpacity(0.6)),
            width: isExpanded ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium,
                    color: isDisabled ? Colors.grey : mainColor, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDisabled ? Colors.grey : mainColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Text(
                      //   isDisabled
                      //       ? "Active until ${expiryDate?.toString().split(' ')[0]}"
                      //       : description,
                      //   style: TextStyle(
                      //       fontSize: 13,
                      //       color:
                      //           isDisabled ? Colors.grey[600] : Colors.black54),
                      // ),
                      Text(
                        isDisabled
                            ? planName == "Community Plan"
                                ? "Active until ${communityExpiry?.toString().split(' ')[0]}"
                                : "Active until ${aiAgentExpiry?.toString().split(' ')[0]}"
                            : description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDisabled ? Colors.grey[600] : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isDisabled ? Colors.grey : mainColor,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              Row(
                children: planName == "Community Plan"
                    ? [
                        _buildInnerPackageBox(
                          label: "1 Month",
                          price: 900,
                          plan: planName,
                        ),
                        const SizedBox(width: 12),
                        _buildInnerPackageBox(
                          label: "6 Months",
                          price: 2500,
                          plan: planName,
                        ),
                      ]
                    : [
                        _buildInnerPackageBox(
                          label: "1000 Credits",
                          subtitle: "20 minutes",
                          price: 1500,
                          plan: planName,
                        ),
                        const SizedBox(width: 12),
                        _buildInnerPackageBox(
                          label: "2500 Credits",
                          subtitle: "45 minutes",
                          price: 3000,
                          plan: planName,
                        ),
                      ],
              ),

              // 🔥 SHOW STUDENT ID FIELD ONLY FOR COMMUNITY PLAN
              if (planName == "Community Plan")
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Student ID",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Student ID input
                    TextField(
                      controller: studentIdController,
                      onChanged: (value) {
                        setState(() {}); // refresh UI when user types
                      },
                      decoration: InputDecoration(
                        hintText: "Enter your student ID",
                        filled: true,
                        fillColor: const Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Submit button visible only if text exists
                    if (studentIdController.text.trim().isNotEmpty)
                      Center(
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : submitStudentID,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Submit Student ID",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInnerPackageBox({
    required String label,
    required double price,
    required String plan,
    String? subtitle,
  }) {
    bool isSelected = selectedPlan == plan && selectedDuration == label;

    return Expanded(
      child: GestureDetector(
        onTap: () => _chooseDuration(plan, label, price),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? mainColor.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? mainColor : Colors.black12,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? mainColor : Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? mainColor.withOpacity(0.8)
                        : Colors.black45,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                "LKR ${price.toInt()}",
                style: TextStyle(
                  color: isSelected ? mainColor : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
