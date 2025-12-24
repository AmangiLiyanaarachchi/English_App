# 🚀 Community Voice Minutes - Quick Start Guide

## 🎯 What Was Built?

A complete voice call minutes tracking system for Community Plan users with top-up packages.

---

## ⚡ Quick Reference

### Minutes by Plan:
- **1 Month Plan (LKR 900)**: 90 minutes
- **6 Month Plan (LKR 2500)**: 540 minutes

### Top-Up Packages:
- **Small (LKR 300)**: 300 minutes
- **Large (LKR 500)**: 750 minutes ⭐ Best Value

---

## 📱 User Journey

```
1. Buy Community Plan → Get 90 or 540 minutes
2. Make voice calls → Minutes deducted after each call
3. Run out of minutes → Call blocked, "Buy Minutes" dialog
4. Buy top-up → Minutes added, calls enabled again
5. Plan expires → All features locked (even if minutes remain)
```

---

## 🔑 Key Files

### New Files:
```
lib/screens/voice_topup_screen.dart       → Top-up UI
lib/services/voice_minutes_service.dart   → Minutes logic
```

### Modified Files:
```
lib/screens/payment_screen.dart           → Top-up payment
lib/screens/premium_screen.dart           → Top-up button
lib/screens/voice_call_screen.dart        → Track duration
lib/screens/chat_detail_screen.dart       → Check before call
```

---

## 🗄️ Firestore Structure

```json
{
  "voiceTotalMinutes": 90,
  "voiceUsedMinutes": 0,
  "voiceEnabled": true,
  "communityPlan": "1_MONTH",
  "subscriptions": {
    "community": {
      "voiceTotalMinutes": 90,
      "expiryDate": "2025-02-23"
    }
  }
}
```

---

## 🧪 Testing Steps

### ✅ Test Community Plan Purchase:
```bash
1. Open app → Navigate to Premium Plans
2. Select Community Plan → Choose 1 Month
3. Complete payment
4. Verify: voiceTotalMinutes = 90
```

### ✅ Test Voice Call:
```bash
1. Open chat → Click call button
2. If no minutes → See "Buy Minutes" dialog
3. If has minutes → Call proceeds
4. After call → Check voiceUsedMinutes updated
```

### ✅ Test Top-Up:
```bash
1. Premium screen → Click "Add Voice Minutes"
2. Select LKR 300 or LKR 500 package
3. Complete payment
4. Verify: voiceTotalMinutes increased
```

---

## 🎨 UI Access Points

### 1. Premium Screen
```
User has Community Plan → See "Add Voice Minutes" button at top
User clicks → Navigate to Voice Top-Up Screen
```

### 2. Chat Detail Screen
```
User clicks call button → System checks minutes
No minutes → Dialog with "Buy Minutes" button
Has minutes → Call proceeds
```

---

## ⚠️ Important Rules

```
1. Top-ups ONLY add minutes (don't extend plan)
2. Plan expiry disables ALL features
3. Random calls use separate tracking
4. Minutes rounded up (61 sec = 2 min)
5. Only Community Plan users can buy top-ups
```

---

## 📊 Business Logic

```dart
// Before Call
remaining = voiceTotalMinutes - voiceUsedMinutes;
canCall = voiceEnabled && remaining > 0 && planActive;

// After Call
callMinutes = (durationSeconds / 60).ceil();
voiceUsedMinutes += callMinutes;
if (voiceUsedMinutes >= voiceTotalMinutes) {
  voiceEnabled = false;
}

// Top-Up Purchase
voiceTotalMinutes += packageMinutes;
voiceEnabled = true;
```

---

## 🔍 Debugging

### Check User's Voice Status:
```bash
Firestore → users → [userId] → Check:
- voiceTotalMinutes
- voiceUsedMinutes
- voiceEnabled
- subscriptions.community.expiryDate
```

### Common Issues:

**Call blocked but user has minutes:**
- Check `voiceEnabled = true`
- Check plan not expired
- Check `voiceUsedMinutes < voiceTotalMinutes`

**Top-up not working:**
- Verify user has active Community Plan
- Check payment success callback
- Check Firestore update logs

**Minutes not deducting:**
- Check `VoiceMinutesService.addCallDuration()` called
- Verify call duration > 0
- Check Firestore update permissions

---

## 📝 Sample Data

### Fresh 1-Month Plan:
```json
{
  "communityPlan": "1_MONTH",
  "voiceTotalMinutes": 90,
  "voiceUsedMinutes": 0,
  "voiceEnabled": true
}
```

### After 15-Min Call:
```json
{
  "communityPlan": "1_MONTH",
  "voiceTotalMinutes": 90,
  "voiceUsedMinutes": 15,
  "voiceEnabled": true
}
```

### After Top-Up (LKR 300):
```json
{
  "communityPlan": "1_MONTH",
  "voiceTotalMinutes": 390,
  "voiceUsedMinutes": 90,
  "voiceEnabled": true
}
```

---

## 🎯 Success Indicators

✅ Community Plan purchase adds correct minutes  
✅ Voice calls deduct minutes after completion  
✅ Calls blocked when minutes = 0  
✅ Top-up adds minutes and re-enables calls  
✅ Plan expiry blocks all features  
✅ Random calls don't affect voice minutes  
✅ Beautiful UI matches app design  
✅ Payment integration works smoothly  

---

## 🚀 Deployment Checklist

- [ ] Test all payment flows
- [ ] Verify Firestore rules allow updates
- [ ] Test plan expiry behavior
- [ ] Verify minutes calculation accurate
- [ ] Test top-up packages
- [ ] Check UI on different screen sizes
- [ ] Test error handling
- [ ] Verify no impact on existing features

---

## 📞 Support

**Documentation:**
- Full Guide: `COMMUNITY_VOICE_MINUTES_COMPLETE.md`
- Visual Guide: `COMMUNITY_VOICE_MINUTES_VISUAL_GUIDE.md`
- This Quick Start: `COMMUNITY_VOICE_MINUTES_QUICK_START.md`

**Key Services:**
- `VoiceMinutesService` - All minutes logic
- `PaymentScreen` - Handles purchases
- `VoiceTopupScreen` - Top-up UI

---

## ✨ That's It!

Your Community Plan now has a complete voice minutes system with top-ups, just like the AI Agent credits! 🎉

**Remember:** Existing features (Random Call, AI Agent) remain completely unchanged.
