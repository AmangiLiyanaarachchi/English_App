import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:english_circle/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import '../services/payhere_service.dart';

class PaymentScreen extends StatefulWidget {
  final String selectedPlan;
  final String selectedDuration;
  final double price;

  const PaymentScreen({
    super.key,
    required this.selectedPlan,
    required this.selectedDuration,
    required this.price,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String selectedCountryCode = "+94";
  String selectedFlag = "🇱🇰";
  bool isProcessing = false;

  final Color paleBlue = const Color(0xFFE9F1F4);
  final Color blueColor = const Color(0xFF4A90A4);

  final Map<String, String?> errorMessages = {
    "firstName": null,
    "lastName": null,
    "email": null,
    "cardNumber": null,
    "expiry": null,
    "cvv": null,
    "phone": null,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          firstNameController.text = data?['firstName'] ?? '';
          lastNameController.text = data?['lastName'] ?? '';
          emailController.text = user.email ?? '';

          if (data?['phone'] != null && data!['phone'].toString().isNotEmpty) {
            String phone = data['phone'].toString();
            if (phone.startsWith('+94')) {
              selectedCountryCode = '+94';
              contactNumberController.text = phone.substring(3);
            } else {
              contactNumberController.text = phone;
            }
          }
        });
      }
    }
  }

  // -----------------------------------------------------
  //                   VALIDATIONS
  // -----------------------------------------------------
  bool validateCardNumber(String number) {
    number = number.replaceAll(" ", "");
    if (number.length != 16) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  bool validateExpiry(String expiry) {
    if (!RegExp(r'^\d\d/\d\d$').hasMatch(expiry)) return false;

    final parts = expiry.split('/');
    int month = int.parse(parts[0]);
    int year = 2000 + int.parse(parts[1]);

    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0);

    return expiryDate.isAfter(now);
  }

  bool validateCVV(String cvv) => cvv.length == 3;

  bool validatePhone(String phone) => phone.length >= 7;

  // -----------------------------------------------------
  //       STYLED TEXTBOX WITH FOCUS BORDER
  // -----------------------------------------------------
  Widget styledTextboxWithFocus({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final focusNode = FocusNode();

    return StatefulBuilder(
      builder: (context, setState) {
        focusNode.addListener(() {
          setState(() {});
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: paleBlue,
            borderRadius: BorderRadius.circular(16),
            border: focusNode.hasFocus
                ? Border.all(color: blueColor, width: 2)
                : null,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
            ),
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: inputFormatters,
          ),
        );
      },
    );
  }

  // -----------------------------------------------------
  //       LABEL + FIELD + ERROR (below textbox)
  // -----------------------------------------------------
  Widget buildInputField({
    required String label,
    required String keyName,
    required Widget inputWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.bold, color: blueColor)),
        const SizedBox(height: 8),
        inputWidget,
        if (errorMessages[keyName] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorMessages[keyName]!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  // -----------------------------------------------------
  //                       BUILD UI
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Payment",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // SELECTED PLAN CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: paleBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.selectedPlan,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: blueColor)),
                        const SizedBox(height: 6),
                        Text(widget.selectedDuration,
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Text("LKR ${widget.price.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: blueColor)),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // CARD DETAILS WHITE BOX
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  // First Name
                  buildInputField(
                    label: "First Name",
                    keyName: "firstName",
                    inputWidget: styledTextboxWithFocus(
                      controller: firstNameController,
                      hint: "Enter first name",
                    ),
                  ),

                  // Last Name
                  buildInputField(
                    label: "Last Name",
                    keyName: "lastName",
                    inputWidget: styledTextboxWithFocus(
                      controller: lastNameController,
                      hint: "Enter last name",
                    ),
                  ),

                  // Email
                  buildInputField(
                    label: "Email",
                    keyName: "email",
                    inputWidget: styledTextboxWithFocus(
                      controller: emailController,
                      hint: "example@email.com",
                    ),
                  ),

                  // Card Number
                  buildInputField(
                    label: "Card Number",
                    keyName: "cardNumber",
                    inputWidget: styledTextboxWithFocus(
                      controller: cardNumberController,
                      hint: "XXXX XXXX XXXX XXXX",
                      isNumber: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        CardNumberInputFormatter(),
                      ],
                    ),
                  ),

                  // Expiry
                  buildInputField(
                    label: "Expiry (MM/YY)",
                    keyName: "expiry",
                    inputWidget: styledTextboxWithFocus(
                      controller: expiryController,
                      hint: "MM/YY",
                      isNumber: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        ExpiryDateFormatter(),
                      ],
                    ),
                  ),

                  // CVV
                  buildInputField(
                    label: "CVV",
                    keyName: "cvv",
                    inputWidget: styledTextboxWithFocus(
                      controller: cvvController,
                      hint: "123",
                      isNumber: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                    ),
                  ),

                  // Phone + Country
                  buildInputField(
                    label: "Contact Number",
                    keyName: "phone",
                    inputWidget: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: true,
                              onSelect: (country) {
                                setState(() {
                                  selectedCountryCode = "+${country.phoneCode}";
                                  selectedFlag = country.flagEmoji;
                                });
                              },
                            );
                          },
                          child: Row(
                            children: [
                              Text(selectedFlag,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 6),
                              Text(selectedCountryCode,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: styledTextboxWithFocus(
                            controller: contactNumberController,
                            hint: "Mobile number",
                            isNumber: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // PAY BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isProcessing ? Colors.grey : blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isProcessing ? null : processPayment,
                      child: isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("PAY NOW",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
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

  // -----------------------------------------------------
  //                 FINAL PAYMENT LOGIC
  // -----------------------------------------------------
  void processPayment() async {
    if (isProcessing) return;

    setState(() {
      errorMessages.updateAll((key, value) => null);
    });

    // Validate all fields
    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();
    String email = emailController.text.trim();
    String phone = contactNumberController.text.trim();

    bool valid = true;

    if (firstName.isEmpty) {
      errorMessages["firstName"] = "First name is required";
      valid = false;
    }

    if (lastName.isEmpty) {
      errorMessages["lastName"] = "Last name is required";
      valid = false;
    }

    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errorMessages["email"] = "Enter a valid email";
      valid = false;
    }

    if (!validatePhone(phone)) {
      errorMessages["phone"] = "Enter a valid phone number";
      valid = false;
    }

    setState(() {});

    if (!valid) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not logged in"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    String userId = user.uid;
    String orderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";
    String fullPhone = "$selectedCountryCode$phone";

    // 🧪 TEST MODE: Bypassing PayHere due to Merchant ID verification issues
    // PayHere sandbox requires merchant account activation for mobile SDK
    // Test mode: Saves to Firestore, unlocks features, fully functional for development
    const bool testMode =
        true; // Set to false when using verified live PayHere account

    if (testMode) {
      // Simulate payment delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful payment
      String testPaymentId = "TEST_${DateTime.now().millisecondsSinceEpoch}";
      await _handlePaymentSuccess(userId, orderId, testPaymentId);
      return;
    }

    try {
      // Create PayHere payment request
      Map<String, dynamic> paymentObject = PayHereService.createPaymentRequest(
        orderId: orderId,
        customerFirstName: firstName,
        customerLastName: lastName,
        customerEmail: email,
        customerPhone: fullPhone,
        planName: widget.selectedPlan,
        amount: widget.price,
        currency: "LKR",
      );

      // Debug: Print payment object
      debugPrint("💳 Payment Object: $paymentObject");

      // Start payment using PayHere SDK
      PayHere.startPayment(
        paymentObject,
        (paymentId) async {
          // Payment success callback
          debugPrint("Payment Success. Payment Id: $paymentId");
          await _handlePaymentSuccess(userId, orderId, paymentId);
        },
        (error) {
          // Payment error callback
          debugPrint("Payment Error: $error");
          setState(() {
            isProcessing = false;
          });
          _showErrorDialog("Payment Failed", error);
        },
        () {
          // Payment dismissed callback
          debugPrint("Payment Dismissed");
          setState(() {
            isProcessing = false;
          });
        },
      );
    } catch (e) {
      debugPrint("Error initiating payment: $e");
      setState(() {
        isProcessing = false;
      });
      _showErrorDialog("Error", "Failed to initiate payment: $e");
    }
  }

  // Handle successful payment
  Future<void> _handlePaymentSuccess(
      String userId, String orderId, String paymentId) async {
    try {
      // Check if this is a voice top-up purchase
      bool isVoiceTopup = widget.selectedPlan.contains("Voice Top-Up");

      if (isVoiceTopup) {
        // Handle voice minute top-up
        await _handleVoiceTopupPurchase(userId, orderId, paymentId);
        return;
      }

      DateTime expiryDate;

      if (widget.selectedDuration.toLowerCase().contains("week")) {
        expiryDate = DateTime.now().add(const Duration(days: 7));
      } else {
        expiryDate = DateTime.now().add(const Duration(days: 30));
      }

      // Get unlocked features based on plan
      List<String> unlockedFeatures =
          PayHereService.getUnlockedFeatures(widget.selectedPlan);

      // --- Read existing subscriptions ---
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();
      final existingData = userDoc.data() ?? {};

      // Get existing subscriptions map or create new one
      Map<String, dynamic> subscriptions = {};
      if (existingData['subscriptions'] != null &&
          existingData['subscriptions'] is Map) {
        subscriptions =
            Map<String, dynamic>.from(existingData['subscriptions']);
      }

      // Add/Update this plan's subscription with its expiry date
      // Check which features this plan includes
      List<String> currentPurchaseFeatures = [];

      if (widget.selectedPlan.contains("Community")) {
        // Calculate voice minutes based on duration
        int voiceTotalMinutes = 0;
        if (widget.selectedDuration == "1 Month") {
          voiceTotalMinutes = 20; // 20 minutes for 1 month
        } else if (widget.selectedDuration == "6 Months") {
          voiceTotalMinutes = 540; // 540 minutes for 6 months
        }

        subscriptions['community'] = {
          'expiryDate': expiryDate,
          'plan': widget.selectedPlan,
          'duration': widget.selectedDuration,
          'price': widget.price,
          'voiceTotalMinutes': voiceTotalMinutes,
        };
        currentPurchaseFeatures.add('community');
      }
      if (widget.selectedPlan.contains("AI Agent")) {
        subscriptions['ai_agent'] = {
          'expiryDate': expiryDate,
          'plan': widget.selectedPlan,
          'duration': widget.selectedDuration,
          'price': widget.price,
        };
        currentPurchaseFeatures.add('ai_agent');

        // Calculate AI minutes based on credits
        int aiTotalSeconds = 0;
        String planType = "";

        if (widget.selectedDuration == "1000 Credits") {
          aiTotalSeconds = 1200; // 20 minutes = 1200 seconds
          planType = "AI_1000";
        } else if (widget.selectedDuration == "2500 Credits") {
          aiTotalSeconds = 2700; // 45 minutes = 2700 seconds
          planType = "AI_2500";
        }

        // Store AI minutes data
        subscriptions['ai_agent']['aiTotalSeconds'] = aiTotalSeconds;
        subscriptions['ai_agent']['planType'] = planType;
      }

      // Build complete unlocked features list from all active subscriptions
      List<String> allUnlockedFeatures = [];
      subscriptions.forEach((key, value) {
        if (value is Map && value['expiryDate'] != null) {
          // Handle both Timestamp (from Firestore) and DateTime (from current session)
          DateTime expiry;
          if (value['expiryDate'] is Timestamp) {
            expiry = (value['expiryDate'] as Timestamp).toDate();
          } else if (value['expiryDate'] is DateTime) {
            expiry = value['expiryDate'] as DateTime;
          } else {
            return; // Skip if not a valid date type
          }

          if (expiry.isAfter(DateTime.now())) {
            // This subscription is still active
            if (key == 'community' &&
                !allUnlockedFeatures.contains('community')) {
              allUnlockedFeatures.add('community');
            }
            if (key == 'ai_agent' &&
                !allUnlockedFeatures.contains('ai_agent')) {
              allUnlockedFeatures.add('ai_agent');
            }
          }
        }
      });

      // Ensure current purchase features are included (safety check)
      for (var feature in currentPurchaseFeatures) {
        if (!allUnlockedFeatures.contains(feature)) {
          allUnlockedFeatures.add(feature);
        }
      }

      print('🔥 Current purchase: ${widget.selectedPlan}');
      print('🔥 Current purchase features: $currentPurchaseFeatures');
      print('🔥 All subscriptions: ${subscriptions.keys.toList()}');
      print('🔥 All unlocked features: $allUnlockedFeatures');

      // Determine display package name
      String packageName = widget.selectedPlan;
      if (allUnlockedFeatures.contains('community') &&
          allUnlockedFeatures.contains('ai_agent')) {
        packageName = "Community + AI Agent";
      } else if (allUnlockedFeatures.contains('community')) {
        packageName = "Community Plan";
      } else if (allUnlockedFeatures.contains('ai_agent')) {
        packageName = "AI Agent";
      }

      // Prepare AI Agent data
      Map<String, dynamic> aiAgentData = {};
      if (subscriptions.containsKey('ai_agent')) {
        aiAgentData = {
          'planType': subscriptions['ai_agent']['planType'],
          'aiTotalSeconds': subscriptions['ai_agent']['aiTotalSeconds'],
          'aiUsedSeconds': 0, // Reset when new plan purchased
          'aiEnabled': true,
        };
      }

      // Prepare Community voice call data
      Map<String, dynamic> communityVoiceData = {};
      if (subscriptions.containsKey('community')) {
        communityVoiceData = {
          'voiceTotalMinutes': subscriptions['community']['voiceTotalMinutes'],
          'voiceUsedMinutes': 0, // Reset when new plan purchased
          'voiceEnabled': true,
          'communityPlan':
              widget.selectedDuration == "1 Month" ? "1_MONTH" : "6_MONTH",
        };
      }

      // --- Update USERS table ---
      Map<String, dynamic> updateData = {
        "package": packageName, // Display package name
        "subscriptions": subscriptions, // Individual subscription tracking
        "duration": widget.selectedDuration,
        "price": widget.price,
        "paymentStatus": "paid",
        "expiryDate": expiryDate, // Latest expiry date
        "phone": "$selectedCountryCode${contactNumberController.text}",
        "unlockedFeatures": allUnlockedFeatures, // All active features
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      // Add AI Agent fields if applicable
      if (aiAgentData.isNotEmpty) {
        updateData.addAll(aiAgentData);
      }

      // Add Community voice call fields if applicable
      if (communityVoiceData.isNotEmpty) {
        updateData.addAll(communityVoiceData);
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .update(updateData);

      // --- Add PAYMENT record ---
      await FirebaseFirestore.instance.collection("payments").add({
        "userId": userId,
        "orderId": orderId,
        "paymentId": paymentId,
        "plan": widget.selectedPlan,
        "duration": widget.selectedDuration,
        "amount": widget.price,
        "currency": "LKR",
        "status": "paid",
        "unlockedFeatures": unlockedFeatures,
        "createdAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        isProcessing = false;
      });

      // --- SHOW SUCCESS DIALOG ---
      _showSuccessDialog(allUnlockedFeatures);
    } catch (e) {
      debugPrint("Error saving payment data: $e");
      setState(() {
        isProcessing = false;
      });
      _showErrorDialog(
          "Error", "Payment successful but failed to update records: $e");
    }
  }

  // Handle voice top-up purchase
  Future<void> _handleVoiceTopupPurchase(
      String userId, String orderId, String paymentId) async {
    try {
      // Extract minutes from selected duration (e.g., "300 minutes" -> 300)
      int minutesToAdd =
          int.parse(widget.selectedDuration.replaceAll(RegExp(r'[^0-9]'), ''));

      // Get current user data
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception("User not found");
      }

      final data = userDoc.data()!;
      int currentTotal = data['voiceTotalMinutes'] ?? 0;

      // Add new minutes to total
      int newTotal = currentTotal + minutesToAdd;

      // Update user document
      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        'voiceTotalMinutes': newTotal,
        'voiceEnabled': true, // Re-enable if it was disabled
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add payment record
      await FirebaseFirestore.instance.collection("payments").add({
        "userId": userId,
        "orderId": orderId,
        "paymentId": paymentId,
        "plan": widget.selectedPlan,
        "duration": widget.selectedDuration,
        "amount": widget.price,
        "currency": "LKR",
        "status": "paid",
        "type": "voice_topup",
        "minutesAdded": minutesToAdd,
        "createdAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        isProcessing = false;
      });

      // Show success dialog for voice top-up
      _showVoiceTopupSuccessDialog(minutesToAdd, newTotal);
    } catch (e) {
      debugPrint("Error processing voice top-up: $e");
      setState(() {
        isProcessing = false;
      });
      _showErrorDialog(
          "Error", "Payment successful but failed to update voice minutes: $e");
    }
  }

  // Show voice top-up success dialog
  void _showVoiceTopupSuccessDialog(int minutesAdded, int newTotal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text("Top-Up Successful! 🎉"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your voice minutes have been added!",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F1F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Minutes Added:",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        "+$minutesAdded min",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("New Total:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "$newTotal min",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90A4),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close payment screen
              Navigator.pop(context); // Close voice top-up screen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Show success dialog
  void _showSuccessDialog(List<String> unlockedFeatures) {
    String featuresText = unlockedFeatures.map((feature) {
      if (feature == "community") return "Community Plan";
      if (feature == "ai_agent") return "AI Agent";
      return feature;
    }).join(" + ");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Payment Successful! 🎉"),
        content: Text(
          "Congratulations! You now have access to:\n\n$featuresText\n\nEnjoy your premium features!",
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
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
}

// -----------------------------------------------------
//             EXPIRY FORMATTER MM/YY
// -----------------------------------------------------
class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = "";

    if (digits.length >= 3) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else {
      formatted = digits;
    }

    if (formatted.length > 5) {
      formatted = formatted.substring(0, 5);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// -----------------------------------------------------
//         CARD NUMBER FORMATTER XXXX XXXX XXXX XXXX
// -----------------------------------------------------
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';

    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
