import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class PayHereService {
  // Defaults keep local sandbox testing easy. Live values should come from --dart-define.
  static const String _defaultSandboxMerchantId = "1233181";
  static const String _defaultSandboxMerchantSecret =
  "NDAxMTQ0OTcyMjEwMDkzODIwODIzMzU3MTA2NDgxNTQ5NzM4MjE0";

  static const String _envMerchantId =
      String.fromEnvironment("PAYHERE_MERCHANT_ID", defaultValue: "");
  static const String _envMerchantSecret =
      String.fromEnvironment("PAYHERE_MERCHANT_SECRET", defaultValue: "");
  static const String _envNotifyUrl =
      String.fromEnvironment("PAYHERE_NOTIFY_URL", defaultValue: "");

  static const bool isSandbox =
      bool.fromEnvironment("PAYHERE_SANDBOX", defaultValue: true);

  static String get merchantId {
    final fromEnv = _envMerchantId.trim();
    return fromEnv.isNotEmpty ? fromEnv : _defaultSandboxMerchantId;
  }

  static String get merchantSecret {
    final fromEnv = _envMerchantSecret.trim();
    return fromEnv.isNotEmpty ? fromEnv : _defaultSandboxMerchantSecret;
  }

  static String get notifyUrl {
    final fromEnv = _envNotifyUrl.trim();
    return fromEnv.isNotEmpty ? fromEnv : "https://webhook.site/unique-id";
  }

  static bool get isConfiguredForLive =>
      merchantId.trim().isNotEmpty && merchantSecret.trim().isNotEmpty;

  static String? validateConfiguration() {
    if (!isSandbox && !isConfiguredForLive) {
      return "PayHere live mode is enabled but merchant credentials are missing."
          " Pass PAYHERE_MERCHANT_ID and PAYHERE_MERCHANT_SECRET via --dart-define.";
    }

    if (!isSandbox && notifyUrl == "https://webhook.site/unique-id") {
      return "PayHere live mode requires a real PAYHERE_NOTIFY_URL webhook."
          " Replace the default webhook.site URL using --dart-define.";
    }

    return null;
  }

  // PayHere secrets may be provided as plain text or base64-encoded.
  static String _normalizeMerchantSecret(String rawSecret) {
    try {
      final decoded = utf8.decode(base64.decode(rawSecret));
      return decoded.trim().isEmpty ? rawSecret : decoded;
    } catch (_) {
      return rawSecret;
    }
  }

  /// Generate MD5 hash for PayHere
  static String generateHash({
    required String orderId,
    required double amount,
    required String currency,
  }) {
    String decodedSecret = _normalizeMerchantSecret(merchantSecret);
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
      "notify_url": notifyUrl,
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
          return duration.toLowerCase().contains("6") ? 2500.00 : 900.00;
        case "AI Agent":
          return 0.00;
        case "Community + AI Agent":
          return 0.00;
        default:
          return 0.00;
      }
    } else if (duration.toLowerCase().contains("credit")) {
      switch (planName) {
        case "AI Agent":
          return duration.contains("2500") ? 3000.00 : 1500.00;
        default:
          return 0.00;
      }
    }
    return 0.00;
  }

  /// ✅ DEBUG: Print PayHere Configuration & Payment Details
  static void printDebugInfo(Map<String, dynamic> paymentObject) {
    if (kDebugMode) {
      print("=============== PAYHERE PAYMENT DEBUG ===============");
      print("🔹 CONFIGURATION:");
      print("   Sandbox Mode: $isSandbox");
      print("   Merchant ID: $merchantId");
      print("   Notify URL: $notifyUrl");
      print(
          "   Merchant Secret (first 10 chars): ${merchantSecret.substring(0, (merchantSecret.length > 10 ? 10 : merchantSecret.length))}...");
      print("");
      print("🔹 PAYMENT OBJECT BEING SENT TO PAYHERE:");
      paymentObject.forEach((key, value) {
        if (key == "hash") {
          print("   $key: ${value.toString().substring(0, 10)}...");
        } else if (key == "notify_url" || key == "merchant_id") {
          print("   $key: $value ⭐ (CRITICAL)");
        } else {
          print("   $key: $value");
        }
      });
      print("====================================================");
    }
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
