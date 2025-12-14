import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();

  String selectedCountryCode = "+94";
  String selectedFlag = "🇱🇰";

  final Color paleBlue = const Color(0xFFE9F1F4);
  final Color blueColor = const Color(0xFF4A90A4);

  final Map<String, String?> errorMessages = {
    "cardNumber": null,
    "expiry": null,
    "cvv": null,
    "phone": null,
  };

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
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
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
                        backgroundColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: processPayment,
                      child: const Text("PAY NOW",
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
    setState(() {
      errorMessages.updateAll((key, value) => null);
    });

    String card = cardNumberController.text.replaceAll(" ", "");
    String expiry = expiryController.text.trim();
    String cvv = cvvController.text.trim();
    String phone = contactNumberController.text.trim();

    bool valid = true;

    if (!validateExpiry(expiry)) {
      errorMessages["expiry"] = "Invalid or expired date";
      valid = false;
    }

    if (!validateCVV(cvv)) {
      errorMessages["cvv"] = "CVV must be 3 digits";
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
        SnackBar(
          content: Text("User not logged in"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String userId = user.uid;

    DateTime expiryDate;

    if (widget.selectedDuration.toLowerCase().contains("week")) {
      expiryDate = DateTime.now().add(Duration(days: 7));
    } else {
      expiryDate = DateTime.now().add(Duration(days: 180));
    }

    // --- Update USERS table ---
    await FirebaseFirestore.instance.collection("users").doc(userId).update({
      "package": widget.selectedPlan,
      "duration": widget.selectedDuration,
      "price": widget.price,
      "paymentStatus": "paid",
      "expiryDate": expiryDate,
      "phone": "${selectedCountryCode}${contactNumberController.text}",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    // --- Add PAYMENT record ---
    await FirebaseFirestore.instance.collection("payments").add({
      "userId": userId,
      "plan": widget.selectedPlan,
      "duration": widget.selectedDuration,
      "amount": widget.price,
      "currency": "LKR",
      "status": "paid",
      "createdAt": FieldValue.serverTimestamp(),
    });

    // --- SHOW SUCCESS DIALOG ---
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Payment Successful"),
        content: Text(
          "Payment successfully. Now you have access for ${widget.selectedPlan}!",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close payment screen
            },
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
      formatted = digits.substring(0, 2) + "/" + digits.substring(2);
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
