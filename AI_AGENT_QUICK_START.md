# 🚀 AI Agent Quick Start Guide

## Step 1: Update JotForm URL

Open `lib/screens/ai_agent_screen.dart` and update line 11:

```dart
final String jotFormUrl = "https://form.jotform.com/YOUR_FORM_ID";
```

Replace with your actual JotForm AI Agent URL.

## Step 2: Deploy Firestore Rules

```powershell
cd "D:\English app argent\amangii new\English_App"
firebase deploy --only firestore:rules
```

## Step 3: Test the Flow

### 3.1 Test Premium Screen
```powershell
flutter run -d <your-device>
```

1. Open app
2. Go to bottom navigation → "AIagent"
3. Should show Premium Plans screen
4. See "AI Agent" plan with "1000 Credits" and "2500 Credits"

### 3.2 Test Payment (Sandbox)
1. Click "AI Agent" plan
2. Select "1000 Credits (20 minutes)" or "2500 Credits (45 minutes)"
3. Click "Continue"
4. Fill payment form
5. Use PayHere sandbox test cards:
   - Card: `5200000000001096`
   - Expiry: `12/25`
   - CVV: `123`
6. Complete payment

### 3.3 Verify Firestore
Go to Firebase Console → Firestore → `users/{userId}`

Should see:
```javascript
{
  planType: "AI_1000" or "AI_2500"
  aiTotalSeconds: 1200 or 2700
  aiUsedSeconds: 0
  aiEnabled: true
  package: "AI Agent"
  subscriptions: {
    ai_agent: {
      expiryDate: <Timestamp>
      plan: "AI Agent"
      duration: "1000 Credits" or "2500 Credits"
      price: 1500 or 3000
      aiTotalSeconds: 1200 or 2700
      planType: "AI_1000" or "AI_2500"
    }
  }
}
```

### 3.4 Test AI Agent Access
1. After successful payment
2. Go to bottom navigation → "AIagent"
3. Should now open AI Agent screen (not Premium screen)
4. See timer in top-right corner
5. See progress bar
6. JotForm should load in iframe

### 3.5 Test Time Tracking
1. Use AI Agent for 30 seconds
2. Press back button
3. Check Firestore → `users/{userId}/aiUsedSeconds`
4. Should show ~30 seconds

### 3.6 Test Time Limit
**Option A: Manual Test (Wait 20/45 minutes)**
- Just use it until time runs out

**Option B: Quick Test (Modify for testing)**

Temporarily edit `lib/screens/ai_agent_screen.dart` for testing:

```dart
// Line 47: Change total seconds for quick test
remainingSeconds = 30; // Test with 30 seconds instead
```

Then:
1. Open AI Agent
2. Wait 30 seconds
3. Should show "Time Finished" dialog
4. Try to open again → Should show "Your AI minutes are finished"

**Remember to revert this change for production!**

## Step 4: Test Edge Cases

### Test 1: App Background
1. Open AI Agent
2. Press home button (app goes background)
3. Come back
4. Check Firestore → `aiUsedSeconds` should be updated

### Test 2: Multiple Sessions
1. Use AI Agent for 1 minute
2. Exit
3. Open again
4. Timer should show reduced time

### Test 3: No Time Left
1. After time runs out
2. Check Firestore:
   - `aiEnabled` should be `false`
   - `aiUsedSeconds` should equal `aiTotalSeconds`
3. Try to open AI Agent → Should show error

## Step 5: Monitor Usage

### Check Current Usage:
```javascript
// Firebase Console → Firestore
users/{userId}
  aiTotalSeconds: 1200
  aiUsedSeconds: 450  // User used 7.5 minutes
  // Remaining: 12.5 minutes
```

### Reset User for Testing:
```javascript
// Firebase Console → Firestore
users/{userId}
  aiUsedSeconds: 0
  aiEnabled: true
```

## Common Commands

### Run App:
```powershell
cd "D:\English app argent\amangii new\English_App"
flutter run -d <device>
```

### Deploy Rules:
```powershell
firebase deploy --only firestore:rules
```

### Clear App Data (for fresh test):
```powershell
flutter clean
flutter pub get
```

## Expected Behavior Checklist

✅ **Before Purchase:**
- [ ] AIagent tab shows Premium screen
- [ ] Can see AI Agent plan with credits

✅ **During Purchase:**
- [ ] Can select 1000 or 2500 credits
- [ ] Payment processes successfully
- [ ] Firestore updated with AI fields

✅ **After Purchase:**
- [ ] AIagent tab opens AI Agent screen
- [ ] Timer shows in AppBar
- [ ] JotForm loads correctly
- [ ] Progress bar shows

✅ **During Usage:**
- [ ] Timer counts down
- [ ] Turns red at < 5 minutes
- [ ] Time saves on exit
- [ ] Time saves on background

✅ **When Time Finishes:**
- [ ] Shows "Time Finished" dialog
- [ ] `aiEnabled` set to false
- [ ] Can't access AI Agent anymore
- [ ] Shows "minutes are finished" error

## Troubleshooting

### Problem: Premium screen shows instead of AI Agent
**Check:**
1. Is user logged in?
2. Does user have `package` field in Firestore?
3. Is package "AI Agent" or "Community + AI Agent"?
4. Is `aiEnabled` true?

### Problem: Timer not showing
**Check:**
1. Is `aiTotalSeconds` set in Firestore?
2. Is `aiUsedSeconds` less than `aiTotalSeconds`?
3. Check console for errors

### Problem: Time not saving
**Check:**
1. Firestore rules deployed?
2. Internet connection?
3. Check console logs for errors

### Problem: JotForm not loading
**Check:**
1. Is JotForm URL correct?
2. Internet connection?
3. Is `flutter_inappwebview` package installed?

## Next Steps

1. ✅ Test the complete flow
2. 📱 Update JotForm URL to your actual URL
3. 🚀 Deploy to production
4. 📊 Monitor usage in Firestore

**Ready to go! 🎉**
