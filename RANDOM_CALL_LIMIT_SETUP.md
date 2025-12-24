# Random Call Limit System - Setup Guide

## 🎯 What Was Implemented

A complete system to limit random calls with:
- **3-minute maximum** per random call
- **3 random calls total** per user
- **Auto-disable** after 3 calls are used

---

## 📋 Features Implemented

### 1️⃣ **RandomCallService** (`lib/services/random_call_service.dart`)
- Tracks random call count per user
- Checks if user can make random calls
- Automatically disables feature after 3 calls
- Provides real-time status updates

### 2️⃣ **VoiceCallScreen** Updates
- Added 3-minute auto-end timer for random calls
- Automatically increments call count when call ends
- Shows "time limit reached" message
- Only counts connected calls (duration > 0)

### 3️⃣ **HomeScreen** Updates
- Checks permission before allowing random call
- Shows remaining calls to user
- Displays "limit reached" dialog when disabled
- Prevents calls after limit is reached

---

## 🗄️ Firestore Database Structure

### New Fields Added to `users` Collection:

```javascript
users/{userId}/
{
  // ... existing fields ...
  
  // NEW Random Call Fields
  "randomCallCount": 0,        // How many random calls user has made
  "randomCallEnabled": true    // Whether random call feature is enabled
}
```

---

## 🚀 Setup Instructions

### Step 1: Update Firestore Rules

Add these fields to your Firestore security rules in `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Allow updates to random call fields
      allow update: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.data.keys().hasAny(['randomCallCount', 'randomCallEnabled']);
    }
  }
}
```

### Step 2: Deploy Firestore Rules

Run this command in your terminal:

```powershell
firebase deploy --only firestore:rules
```

### Step 3: Initialize Existing Users (Optional)

If you have existing users, you can run this script to initialize their random call data:

```javascript
// Run in Firebase Console > Firestore > Create Query
const users = await db.collection('users').get();
const batch = db.batch();

users.forEach(doc => {
  batch.update(doc.ref, {
    randomCallCount: 0,
    randomCallEnabled: true
  });
});

await batch.commit();
```

Or create a Cloud Function:

```javascript
exports.initializeRandomCallData = functions.https.onRequest(async (req, res) => {
  const usersRef = admin.firestore().collection('users');
  const snapshot = await usersRef.get();
  
  const batch = admin.firestore().batch();
  
  snapshot.forEach(doc => {
    batch.update(doc.ref, {
      randomCallCount: 0,
      randomCallEnabled: true
    });
  });
  
  await batch.commit();
  res.send('Initialized random call data for all users');
});
```

---

## 📊 How It Works

### Flow Diagram:

```
User clicks "Random Call"
        ↓
Check randomCallEnabled & randomCallCount
        ↓
   randomCallCount >= 3?
        ↓
    YES → Show "Limit Reached" Dialog
        ↓ NO
Start Agora Call
        ↓
Start 3-Minute Timer
        ↓
Call Auto-Ends at 3 Minutes OR User Ends Manually
        ↓
randomCallCount += 1
        ↓
Update Firestore
        ↓
If randomCallCount == 3 → randomCallEnabled = false
```

---

## 🎮 Usage

### User Experience:

1. **First Call**: User starts random call, sees "2 calls remaining"
2. **Second Call**: "1 call remaining"
3. **Third Call**: "0 calls remaining" (last call)
4. **After Third Call**: "Random Call Limit Reached" dialog, button disabled

### 3-Minute Timer:
- Timer starts when call connects
- At 2:59, call shows "Call ended - 3 minute limit reached"
- Call automatically ends and counts toward limit

---

## 🔧 Configuration

You can customize the limits in `random_call_service.dart`:

```dart
class RandomCallService {
  // Change these values:
  static const int maxRandomCalls = 3;           // Number of calls allowed
  static const int maxCallDurationSeconds = 180; // 3 minutes in seconds
}
```

---

## 🧪 Testing

### Test the 3-Minute Limit:
1. Start a random call
2. Wait 3 minutes
3. Call should auto-end with message

### Test the 3-Call Limit:
1. Make 3 random calls
2. Try to start 4th call
3. Should see "Limit Reached" dialog

### Reset User's Call Count (for testing):
```dart
// In your Flutter app (debug mode)
await RandomCallService().resetRandomCallCount(userId);
```

---

## 📱 UI Changes

### Random Call Button Behavior:
- ✅ **Before limit**: Button works normally
- ⚠️ **Near limit**: Shows "X calls remaining" snackbar
- ❌ **After limit**: Shows dialog "Random call feature is now disabled"

---

## 🔍 Monitoring

### Check User's Random Call Status:
```dart
final status = await RandomCallService().checkRandomCallPermission(userId);
print(status);
// Output:
// {
//   'canCall': true/false,
//   'remainingCalls': 2,
//   'randomCallCount': 1,
//   'randomCallEnabled': true
// }
```

### Real-time Status Monitoring:
```dart
RandomCallService().watchRandomCallStatus(userId).listen((status) {
  print('Remaining calls: ${status['remainingCalls']}');
  print('Enabled: ${status['randomCallEnabled']}');
});
```

---

## 🆘 Admin Functions

### Reset a User's Call Count:
```dart
await RandomCallService().resetRandomCallCount(userId);
```

This is useful for:
- Testing
- Customer support (reset limits)
- Premium users (unlimited calls)

---

## 📝 Notes

- **New Users**: Automatically get `randomCallCount: 0` and `randomCallEnabled: true`
- **Cancelled Calls**: Don't count toward limit (only connected calls with duration > 0)
- **Timer Precision**: Uses Dart Timer, accurate to ~1 second
- **Background Calls**: Timer continues even if app goes to background

---

## ✅ Checklist

- [x] RandomCallService created
- [x] 3-minute timer implemented
- [x] Call counting logic added
- [x] UI permission checks added
- [x] Auto-disable feature implemented
- [ ] Deploy Firestore rules
- [ ] Initialize existing users (if needed)
- [ ] Test with real users

---

## 🐛 Troubleshooting

### Call count not incrementing:
- Check Firestore rules allow updates
- Verify user is authenticated
- Check console for errors

### Timer not working:
- Ensure `isRandomCall: true` is passed to VoiceCallScreen
- Check if timer is cancelled prematurely

### Button still enabled after 3 calls:
- Check Firestore data for user
- Verify `randomCallEnabled` field is set correctly
- Try restarting the app

---

## 📞 Support

If you encounter issues:
1. Check Firebase console for errors
2. Review app logs
3. Verify Firestore rules are deployed
4. Test with a fresh user account
