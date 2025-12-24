# 🧠 AI Agent Premium Plan - Complete Setup Guide

## 📋 Overview

This guide explains how the AI Agent premium plan works with time control using Firebase and JotForm.

## 🔹 Premium Plan Structure

### Community Plan
- Chats, calls, group activities, and community access
- ❌ No AI Agent minutes

### AI Agent Plan
| Plan | Credits | Total AI Time | Price (LKR) |
|------|---------|---------------|-------------|
| Basic | 1000 | 20 minutes | 1500 |
| Pro | 2500 | 45 minutes | 3000 |

## ⚠️ Important Architecture

**JotForm** = AI brain (provides the AI agent interface)  
**Your App** = Police 👮‍♂️ (controls access and time limits)

- ❌ JotForm **cannot** control minutes for you
- ❌ JotForm **cannot** stop user automatically based on time
- ✅ **YOU** must control access + time in Flutter + Firebase

## 🔹 1. Firestore Database Design

### Users Collection Structure

```javascript
users/{userId}
  ├── planType: "AI_1000" | "AI_2500" | "FREE"
  ├── aiTotalSeconds: 1200 or 2700 (20 min = 1200 sec, 45 min = 2700 sec)
  ├── aiUsedSeconds: 0 to aiTotalSeconds
  ├── aiEnabled: true/false
  ├── package: "AI Agent" | "Community Plan" | "Community + AI Agent"
  └── subscriptions:
      └── ai_agent:
          ├── expiryDate: Timestamp
          ├── plan: "AI Agent"
          ├── duration: "1000 Credits" or "2500 Credits"
          ├── price: 1500 or 3000
          ├── aiTotalSeconds: 1200 or 2700
          └── planType: "AI_1000" or "AI_2500"
```

### Time Conversion
- **20 minutes** = 1200 seconds
- **45 minutes** = 2700 seconds

## 🔹 2. When User Buys a Plan

After successful payment (via PayHere):

### If user selects 1000 Credits:
```dart
{
  'planType': 'AI_1000',
  'aiTotalSeconds': 1200,
  'aiUsedSeconds': 0,
  'aiEnabled': true,
  'package': 'AI Agent'
}
```

### If user selects 2500 Credits:
```dart
{
  'planType': 'AI_2500',
  'aiTotalSeconds': 2700,
  'aiUsedSeconds': 0,
  'aiEnabled': true,
  'package': 'AI Agent'
}
```

## 🔹 3. Before Opening AI Agent (Access Control)

### Flow in `ai_agent_screen.dart`:

```dart
_checkAccessAndStartTimer() {
  1. Check if aiEnabled == false
     → Show "Your AI minutes are finished"
     → EXIT
  
  2. Calculate remainingTime = aiTotalSeconds - aiUsedSeconds
  
  3. If remainingTime <= 0
     → Set aiEnabled = false
     → EXIT
  
  4. ✅ Only then → open JotForm iframe
  5. Start time tracking
}
```

## 🔹 4. Time Tracking (Core Feature)

### Start Timer:
```dart
startTime = DateTime.now();
```

### Live Countdown:
- Shows remaining time in AppBar
- Updates every second
- Warning when < 5 minutes (red color)

### Save Usage:
```dart
When user:
  - Presses back button
  - App goes to background
  - Time finishes
  - App closes

endTime = DateTime.now();
usedSeconds = endTime - startTime;

// Update Firestore
aiUsedSeconds += usedSeconds

// Auto-disable if finished
if (aiUsedSeconds >= aiTotalSeconds) {
  aiEnabled = false
}
```

## 🔹 5. Auto Disable When Time Finished

```dart
IF aiUsedSeconds >= aiTotalSeconds
   aiEnabled = false
```

### UI Result:
- ❌ Disable AI Agent button in bottom navigation
- Show message: "Your AI Agent minutes are completed. Upgrade to continue."

## 🔹 6. Files Modified/Created

### ✅ Created Files:
1. **`lib/screens/ai_agent_screen.dart`** - New AI Agent screen with time tracking

### ✅ Modified Files:
1. **`firestore.rules`** - Added AI agent field permissions
2. **`lib/models/user_model.dart`** - Added AI agent fields
3. **`lib/screens/premium_screen.dart`** - Updated to show AI plan options with subtitles
4. **`lib/screens/payment_screen.dart`** - Added AI plan payment processing
5. **`lib/screens/home_screen.dart`** - Updated to use new AIAgentScreen

## 🔹 7. How It Works (Complete Flow)

### Step 1: User Purchases AI Plan
1. User opens Premium Plans screen
2. Selects "AI Agent" plan
3. Chooses "1000 Credits" or "2500 Credits"
4. Makes payment via PayHere
5. Payment success → Firestore updated with AI fields

### Step 2: User Opens AI Agent
1. User taps "AIagent" in bottom navigation
2. App checks:
   - Is user logged in?
   - Does user have package?
   - Does user have AI access (_hasAI)?
3. If YES → Open `AIAgentScreen`
4. If NO → Show `PremiumScreen`

### Step 3: AI Agent Screen Loads
1. Check `aiEnabled` status
2. Calculate remaining time
3. If has time → Start timer & load JotForm
4. If no time → Show error and exit

### Step 4: User Uses AI Agent
1. Timer counts down in real-time
2. User interacts with JotForm AI
3. Time is tracked in background

### Step 5: User Exits or Time Finishes
1. Calculate used seconds
2. Update Firestore with `aiUsedSeconds`
3. If total time exceeded → Set `aiEnabled = false`
4. User sees "Time finished" message

## 🔹 8. JotForm Configuration

### Update JotForm URL:
In `ai_agent_screen.dart`, line 11:

```dart
final String jotFormUrl = "https://form.jotform.com/YOUR_FORM_ID";
```

**Replace with your actual JotForm AI Agent URL.**

### Example URLs:
- Voice AI: `https://agent.jotform.com/019ae53c76397cdd876e717ab286d62b9a36/voice`
- Chat AI: `https://agent.jotform.com/YOUR_AGENT_ID/chat`

## 🔹 9. Firestore Security Rules

```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
  
  // Allow AI agent field updates
  allow update: if request.auth != null && 
                   request.auth.uid == userId &&
                   (request.resource.data.keys().hasAny(['randomCallTotalSeconds', 'randomCallEnabled']) ||
                    request.resource.data.keys().hasAny(['aiTotalSeconds', 'aiUsedSeconds', 'aiEnabled', 'planType']));
}
```

## 🔹 10. Testing Checklist

### ✅ Test Purchase Flow:
- [ ] Can purchase 1000 Credits plan
- [ ] Can purchase 2500 Credits plan
- [ ] Firestore fields are set correctly
- [ ] Payment record is created

### ✅ Test Access Control:
- [ ] Without plan → Shows Premium screen
- [ ] With plan → Opens AI Agent screen
- [ ] No time left → Shows error message

### ✅ Test Time Tracking:
- [ ] Timer starts when screen opens
- [ ] Timer counts down correctly
- [ ] Timer shows in AppBar
- [ ] Red warning when < 5 minutes

### ✅ Test Time Saving:
- [ ] Saves time on back button
- [ ] Saves time on app background
- [ ] Saves time when time finishes
- [ ] Disables access when time exceeded

### ✅ Test Edge Cases:
- [ ] App closes during use
- [ ] Multiple users
- [ ] Subscription renewal
- [ ] Both Community + AI plans

## 🔹 11. Common Issues & Solutions

### Issue: "Your AI minutes are finished" immediately
**Solution:** Check if `aiEnabled` is set to `true` in Firestore

### Issue: Timer not counting down
**Solution:** Check if `_startCountdown()` is being called

### Issue: Time not saving
**Solution:** Check `_saveUsageTime()` function and Firestore permissions

### Issue: JotForm not loading
**Solution:** 
- Check internet connection
- Verify JotForm URL is correct
- Check `flutter_inappwebview` package is installed

## 🔹 12. Deployment Steps

### 1. Deploy Firestore Rules:
```bash
firebase deploy --only firestore:rules
```

### 2. Test Payment Flow:
```bash
flutter run -d <device>
# Test with PayHere sandbox mode
```

### 3. Update JotForm URL:
- Replace placeholder URL with actual JotForm URL
- Test iframe loading

### 4. Test Time Tracking:
- Purchase plan
- Use AI Agent
- Verify time is being saved

## 🔹 13. Monitoring & Analytics

### Track in Firestore Console:
- Number of AI plans sold
- Average usage time
- Users who exceeded time
- Active vs inactive AI users

### Query Examples:
```javascript
// Users with active AI
users.where('aiEnabled', '==', true)

// Users with finished time
users.where('aiEnabled', '==', false)
  .where('aiTotalSeconds', '>', 0)

// Total AI usage
SUM(users.aiUsedSeconds)
```

## 🔹 14. Future Enhancements

1. **Usage Statistics Dashboard**
   - Show user their remaining minutes
   - Usage history graph

2. **Top-up Credits**
   - Allow users to add more minutes without full renewal

3. **Pause/Resume Feature**
   - Pause timer during breaks

4. **Usage Notifications**
   - Alert when 5 minutes remaining
   - Alert when 1 minute remaining

5. **Family Plans**
   - Share minutes across multiple users

## ✅ Summary

✅ **Secure** - Firebase controls access  
✅ **Accurate** - Precise time tracking in seconds  
✅ **Safe** - Auto-disable when time finished  
✅ **Industry Standard** - Follows best practices  
✅ **Works with JotForm** - Iframe integration  

**Remember:** JotForm is just the AI tool. Your app is the gatekeeper that controls who can access it and for how long.

---

## 📞 Support

If you encounter issues:
1. Check Firestore rules are deployed
2. Verify user has correct fields in Firestore
3. Check console logs in `ai_agent_screen.dart`
4. Test payment flow in sandbox mode first

**Happy coding! 🚀**
