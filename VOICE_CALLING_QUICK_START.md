# Quick Start Guide - Voice Calling

## 🚀 How to Use the Voice Calling System

### 1. Random Call (Home Screen)
1. Open the app
2. Tap **"Connect with Co-learners"** button
3. Select a user from the list
4. Wait for them to answer
5. Start talking!

### 2. Call from Chat
1. Open a chat with someone
2. Tap the **📞 phone icon** in the top-right
3. Wait for them to answer
4. Start talking!

### 3. Receiving Calls
- When someone calls you, an incoming call screen will appear automatically
- Tap **Accept (green)** to answer
- Tap **Reject (red)** to decline

### 4. During a Call
- **🎤 Mute/Unmute**: Toggle your microphone
- **🔊 Speaker**: Switch between speaker and earpiece
- **❌ Red button**: End the call

### 5. View Call History
- Go to the Call History screen (add navigation to it)
- See all past calls
- Tap clear icon to delete all history

---

## 🎯 Important Features

### ✅ What Works
- Individual voice calls only
- One-to-one calling
- Call history saved locally
- Incoming call notifications
- Real-time call status

### ❌ What Doesn't Work (By Design)
- No video calls
- No group calls
- No conference calls

---

## 🔑 Agora Configuration

Your app is configured with:
- **App ID**: `ea75dc54a4aa480db3f7d5cb6eef54ed`
- Located in: `lib/services/agora_service.dart`

---

## 📱 How to Add Call History to Navigation

You have several options:

### Option 1: Add to Home Screen Bottom Navigation
Edit `lib/screens/home_screen.dart`:

```dart
// In the bottomNavigationBar items, add:
BottomNavigationBarItem(
  icon: Icon(Icons.history),
  label: 'Calls',
),

// In the screens list, add:
const CallHistoryScreen(),
```

### Option 2: Add to Drawer
If you have a drawer menu, add:

```dart
ListTile(
  leading: Icon(Icons.call),
  title: Text('Call History'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CallHistoryScreen()),
    );
  },
),
```

### Option 3: Add to Profile Screen
Add a button in the profile screen to view call history.

---

## 🧪 Testing Checklist

- [ ] Can make a call from home screen
- [ ] Can make a call from chat screen
- [ ] Can receive incoming calls
- [ ] Can accept/reject calls
- [ ] Can mute/unmute during call
- [ ] Can switch speaker on/off
- [ ] Call duration shows correctly
- [ ] Call history saves correctly
- [ ] Can clear call history

---

## 🐛 Common Issues

### "No users available for calling"
- Make sure you have other users in your Firestore database
- Check that you're signed in

### "Failed to initiate call"
- Check internet connection
- Verify Firestore permissions
- Check Agora App ID is correct

### Can't hear audio
- Enable microphone permissions
- Check speaker is on
- Restart the app

---

## 📞 Next Steps

1. **Test the calling system** with 2 devices
2. **Add Call History to navigation** (choose one of the options above)
3. **Test on real devices** for best audio quality
4. **Optional**: Implement push notifications for incoming calls when app is closed

---

**Enjoy your new voice calling system! 🎉**
