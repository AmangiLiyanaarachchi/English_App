# 🚀 Random Call Limit - Quick Start

## ⚡ 30-Second Setup

```powershell
# 1. Deploy Firestore rules
firebase deploy --only firestore:rules

# 2. Run your app
flutter run
```

Done! ✅

---

## 🎯 What You Got

✅ **3-minute limit** per random call  
✅ **3 calls maximum** per user  
✅ **Auto-disable** after 3 calls used

---

## 📋 Quick Commands

### Deploy
```bash
firebase deploy --only firestore:rules
```

### Test
```bash
flutter run -d <device_id>
```

### Reset User (Testing)
```dart
await RandomCallService().resetRandomCallCount(userId);
```

---

## 🗄️ Firestore Structure

```javascript
users/{userId}/
{
  "randomCallCount": 0,      // 0 to 3
  "randomCallEnabled": true  // true or false
}
```

---

## 🎮 How It Works

```
Call 1 → 3 min max → Count = 1 ✅
Call 2 → 3 min max → Count = 2 ✅
Call 3 → 3 min max → Count = 3 ✅
Call 4 → ❌ BLOCKED (limit reached)
```

---

## 🔧 Change Limits

Edit `lib/services/random_call_service.dart`:

```dart
static const int maxRandomCalls = 3;           // ← Change to 5, 10, etc.
static const int maxCallDurationSeconds = 180; // ← Change to 300 (5 min)
```

---

## 📁 Files Changed

- ✅ `lib/services/random_call_service.dart` (NEW)
- ✅ `lib/screens/voice_call_screen.dart` (UPDATED)
- ✅ `lib/screens/home_screen.dart` (UPDATED)
- ✅ `firestore.rules` (UPDATED)

---

## 🐛 Quick Troubleshooting

**Timer not working?**
→ Check `isRandomCall: true` in VoiceCallScreen

**Count not updating?**
→ Deploy Firestore rules: `firebase deploy --only firestore:rules`

**Still can call after 3?**
→ Check Firestore: `randomCallEnabled` should be `false`

---

## 📖 Full Documentation

- 📘 `RANDOM_CALL_IMPLEMENTATION_COMPLETE.md` - Full summary
- 📗 `RANDOM_CALL_LIMIT_SETUP.md` - Detailed setup
- 📙 `RANDOM_CALL_VISUAL_GUIDE.md` - Visual diagrams
- 🔧 `setup_random_call_limit.ps1` - Auto setup
- 🧪 `test_random_call_limit.ps1` - Testing guide

---

## ✅ Test Checklist

- [ ] Call auto-ends at 3:00
- [ ] Shows "X calls remaining"
- [ ] After 3 calls, shows "limit reached"
- [ ] Cancelled calls don't count

---

**🎉 You're ready! Start testing!**
