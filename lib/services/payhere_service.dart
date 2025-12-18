import 'dart:convert';
import 'package:crypto/crypto.dart';

class PayHereService {
  // PayHere Sandbox Credentials - Mobile SDK requires numeric Merchant ID
  static const String merchantId = "1233181";
  static const String merchantSecret =
      "MzA5MjE2Mjk3MjY1NzI0OTg1Mzk0OTQwMjMwMTIyODQzNTY2Mjc=";
  static const bool isSandbox = true; // Set to false for production

  /// Generate MD5 hash for PayHere
  static String generateHash({
    required String orderId,
    required double amount,
    required String currency,
  }) {
    // Decode the base64 merchant secret first
    String decodedSecret = utf8.decode(base64.decode(merchantSecret));
    String merchantSecretMD5 =
        md5.convert(utf8.encode(decodedSecret)).toString().toUpperCase();

    String amountFormatted = amount.toStringAsFixed(2);
    String hashString =
        "$merchantId$orderId$amountFormatted${currency.toUpperCase()}$merchantSecretMD5";

    return md5.convert(utf8.encode(hashString)).toString().toUpperCase();
  }

  /// Initialize PayHere Payment Request
  static Map<String, dynamic> createPaymentRequest({
    required String orderId,
    required String customerFirstName,
    required String customerLastName,
    required String customerEmail,
    required String customerPhone,
    required String planName,
    required double amount,
    required String currency,
  }) {
    // Generate hash
    String hash = generateHash(
      orderId: orderId,
      amount: amount,
      currency: currency,
    );

    // Create payment request
    Map<String, dynamic> paymentObject = {
      "sandbox": isSandbox,
      "merchant_id": merchantId,
      "notify_url": "https://webhook.site/unique-id", // Required field
      "order_id": orderId,
      "items": planName,
      "amount": amount.toStringAsFixed(2),
      "currency": currency,
      "hash": hash,
      "first_name": customerFirstName,
      "last_name": customerLastName,
      "email": customerEmail,
      "phone": customerPhone,
      "address": "N/A",
      "city": "Colombo",
      "country": "Sri Lanka",
      "delivery_address": "N/A",
      "delivery_city": "Colombo",
      "delivery_country": "Sri Lanka",
    };

    return paymentObject;
  }

  /// Get plan price based on plan name and duration
  static double getPlanPrice(String planName, String duration) {
    // Define your plan prices here
    if (duration.toLowerCase().contains("week")) {
      switch (planName) {
        case "Community Plan":
          return 100.00;
        case "AI Agent":
          return 100.00;
        case "Community + AI Agent":
          return 100.00;
        default:
          return 0.00;
      }
    } else if (duration.toLowerCase().contains("month")) {
      switch (planName) {
        case "Community Plan":
          return 400.00;
        case "AI Agent":
          return 500.00;
        case "Community + AI Agent":
          return 800.00;
        default:
          return 0.00;
      }
    }
    return 0.00;
  }

  /// Get unlocked features based on plan
  static List<String> getUnlockedFeatures(String planName) {
    switch (planName) {
      case "Community Plan":
        return ["community"];
      case "AI Agent":
        return ["ai_agent"];
      case "Community + AI Agent":
        return ["community", "ai_agent"];
      default:
        return [];
    }
  }

  /// Check if a specific feature is unlocked for the user
  static bool isFeatureUnlocked(List<String> userFeatures, String feature) {
    return userFeatures.contains(feature);
  }
}
