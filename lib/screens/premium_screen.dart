import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'payment_screen.dart';

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

  void _choosePlan(String plan) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Plans"),
        backgroundColor: mainColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
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
                description: "AI answers, grammar help, 24/7 English support.",
              ),
              const SizedBox(height: 12),
              _buildPlanBox(
                planName: "Community + AI Agent",
                description: "Full community access + AI Agent support.",
              ),
              const SizedBox(height: 20),

              // Continue button only for non-Community plans
              // if (selectedPlan != "Community Plan")
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (selectedPlan.isEmpty || selectedDuration.isEmpty)
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
      ),
    );
  }

  Widget _buildPlanBox({
    required String planName,
    required String description,
  }) {
    bool isExpanded = selectedPlan == planName;

    return GestureDetector(
      onTap: () => _choosePlan(planName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded ? mainColor : mainColor.withOpacity(0.6),
            width: isExpanded ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium, color: mainColor, size: 26),
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
                          color: mainColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: mainColor,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInnerPackageBox(
                    label: "1 Week",
                    price: 100,
                    plan: planName,
                  ),
                  const SizedBox(width: 12),
                  _buildInnerPackageBox(
                    label: "6 Months",
                    price: 1000,
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
