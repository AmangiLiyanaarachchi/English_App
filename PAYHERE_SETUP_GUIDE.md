# PayHere Payment Gateway Integration Guide

## 🎯 Overview
This guide explains the PayHere payment gateway integration for the English Circle app with sandbox testing for premium subscriptions.

## 📋 Features Implemented

### Premium Plans
1. **Community Plan** - Unlocks community chat and group activities
2. **AI Agent** - Unlocks AI-powered English support
3. **Community + AI Agent** - Unlocks both features

### Payment Flow
- PayHere Sandbox integration for testing
- Real-time feature unlocking after successful payment
- Subscription expiry tracking
- Payment history in Firestore

## 🔧 Configuration

### PayHere Credentials (Sandbox)
```
Merchant ID: 1233181
Merchant Secret: MzA5MjE2Mjk3MjY1NzI0OTg1Mzk0OTQwMjMwMTIyODQzNTY2Mjc=
Mode: Sandbox (for testing)
```

**⚠️ Important:** Change `isSandbox` to `false` in `payhere_service.dart` for production.

## 🧪 Testing with Sandbox

### Test Card Details
PayHere sandbox accepts these test cards:

#### Visa
- Card Number: `4916217501611292`
- Expiry: Any future date (e.g., `12/25`)
- CVV: Any 3 digits (e.g., `123`)

#### MasterCard
- Card Number: `5413 3194 8802 2428`
- Expiry: Any future date
- CVV: Any 3 digits

### Testing Steps
1. Open the app and navigate to **Premium** tab
2. Select a plan (Community Plan, AI Agent, or Community + AI Agent)
3. Choose duration (1 Week or 6 Months)
4. Click **CONTINUE** button
5. Fill in payment details:
   - First Name
   - Last Name
   - Email
   - Contact Number
6. Click **PAY NOW**
7. PayHere payment gateway will open
8. Use test card details above
9. Complete payment
10. Features will be unlocked automatically

## 📁 File Structure

### New Files Created
```
lib/
├── services/
│   ├── payhere_service.dart         # PayHere integration logic
│   └── premium_access_service.dart  # Feature access control
```

### Modified Files
```
lib/
├── screens/
│   ├── payment_screen.dart          # Updated with PayHere integration
│   └── home_screen.dart             # Added access control for tabs
├── pubspec.yaml                     # Added PayHere SDK
```

## 🔒 Access Control

### Feature Unlocking Logic

When a user completes payment:
1. `unlockedFeatures` array is saved to user document in Firestore
2. Features are checked using `PremiumAccessService.hasFeatureAccess()`
3. Tabs show premium screen if feature is not unlocked

### Feature Keys
- `community` - For Community Plan features
- `ai_agent` - For AI Agent features

### Checking Access (Example)
```dart
bool hasAIAccess = await PremiumAccessService.hasFeatureAccess('ai_agent');
if (!hasAIAccess) {
  PremiumAccessService.showAccessDeniedDialog(context, 'AI Agent');
}
```

## 💳 Payment Data Structure

### Users Collection Update
```json
{
  "package": "Community + AI Agent",
  "duration": "1 Week",
  "price": 100,
  "paymentStatus": "paid",
  "expiryDate": "2025-12-22T10:43:00.000Z",
  "unlockedFeatures": ["community", "ai_agent"],
  "phone": "+94771234567",
  "firstName": "John",
  "lastName": "Doe",
  "updatedAt": "Timestamp"
}
```

### Payments Collection
```json
{
  "userId": "user_uid",
  "orderId": "ORDER_1702636980000",
  "paymentId": "payhere_payment_id",
  "plan": "Community + AI Agent",
  "duration": "1 Week",
  "amount": 100,
  "currency": "LKR",
  "status": "paid",
  "unlockedFeatures": ["community", "ai_agent"],
  "createdAt": "Timestamp"
}
```

## 🔄 Subscription Expiry

The system automatically:
- Calculates expiry date (7 days for weekly, 30 days for monthly)
- Checks expiry before granting feature access
- Updates `paymentStatus` to `expired` when subscription ends
- Blocks access to premium features when expired

## 🚀 Deployment Steps

### Before Going Live
1. **Get Production Credentials**
   - Login to PayHere merchant account
   - Get production Merchant ID and Secret

2. **Update Configuration**
   ```dart
   // In lib/services/payhere_service.dart
   static const String merchantId = "YOUR_PRODUCTION_MERCHANT_ID";
   static const String merchantSecret = "YOUR_PRODUCTION_SECRET";
   static const bool isSandbox = false; // Change to false
   ```

3. **Update Notify URL**
   ```dart
   "notify_url": "https://your-backend.com/payhere/notify"
   ```
   Set up a backend endpoint to handle PayHere notifications.

4. **Test Thoroughly**
   - Test all three plans
   - Test subscription expiry
   - Test feature access control
   - Test payment failure scenarios

## 🐛 Troubleshooting

### Payment Not Processing
- Check internet connection
- Verify PayHere credentials are correct
- Check Firestore security rules allow writes
- View logs in Android Studio/Xcode

### Features Not Unlocking
- Verify `unlockedFeatures` array is saved in Firestore
- Check subscription hasn't expired
- Ensure `paymentStatus` is "paid"

### PayHere SDK Issues
- Run `flutter pub get` after adding dependency
- Clean build: `flutter clean && flutter pub get`
- Rebuild app completely

## 📱 Platform-Specific Setup

### Android
No additional setup required. PayHere SDK handles everything.

### iOS
No additional setup required. PayHere SDK handles everything.

## 📊 Plan Pricing

Current pricing structure (can be modified in `payhere_service.dart`):

### Weekly Plans
- Community Plan: LKR 100
- AI Agent: LKR 100
- Community + AI Agent: LKR 100

### Monthly Plans
- Community Plan: LKR 400
- AI Agent: LKR 500
- Community + AI Agent: LKR 800

## 🔐 Security Notes

1. **Never commit sensitive credentials** to version control
2. Store production credentials in environment variables
3. Use backend server for payment verification in production
4. Implement webhook verification for PayHere notifications
5. Add rate limiting to prevent payment spam
6. Validate all payment data server-side

## 📞 Support

For PayHere support:
- Documentation: https://support.payhere.lk/
- Merchant Support: https://www.payhere.lk/support

## ✅ Checklist

- [x] PayHere SDK added to pubspec.yaml
- [x] PayHere service created with sandbox credentials
- [x] Payment screen updated with PayHere integration
- [x] Premium access service created for feature control
- [x] Home screen updated with access control
- [x] Plan unlocking logic implemented
- [x] Payment data saved to Firestore
- [x] Subscription expiry tracking added
- [ ] Test all three plans with sandbox
- [ ] Verify feature unlocking works correctly
- [ ] Test subscription expiry behavior
- [ ] Update to production credentials before launch
- [ ] Set up backend notification handler
- [ ] Deploy to production

## 🎉 Ready to Test!

Run the app and test the payment flow with sandbox credentials. All payments will be simulated and no real money will be charged.

```bash
flutter pub get
flutter run
```

---

**Note:** Remember to switch to production credentials and set `isSandbox = false` before releasing to production!
