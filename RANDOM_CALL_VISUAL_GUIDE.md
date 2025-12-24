# 🎯 Random Call Limit System - Visual Flow

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     USER INTERFACE                          │
│  (HomeScreen - Random Call Button)                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│               PERMISSION CHECK                              │
│  RandomCallService.checkRandomCallPermission()              │
│                                                             │
│  ✅ randomCallEnabled == true?                             │
│  ✅ randomCallCount < 3?                                   │
└──────────┬─────────────────────────────┬────────────────────┘
           │                             │
      ❌ DENIED                      ✅ ALLOWED
           │                             │
           ▼                             ▼
   ┌──────────────┐            ┌──────────────────┐
   │ Show Dialog  │            │  Start Call      │
   │ "Limit       │            │  (VoiceCall      │
   │  Reached"    │            │   Screen)        │
   └──────────────┘            └────────┬─────────┘
                                        │
                                        ▼
                            ┌────────────────────────┐
                            │  START 3-MIN TIMER     │
                            │  (180 seconds)         │
                            └────────┬───────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
                    ▼                ▼                ▼
            ┌──────────────┐  ┌──────────┐  ┌──────────────┐
            │ User Ends    │  │ 3 Min    │  │ Call Failed  │
            │ Call Early   │  │ Reached  │  │ (No Answer)  │
            └──────┬───────┘  └────┬─────┘  └──────┬───────┘
                   │               │               │
                   └───────────────┼───────────────┘
                                   │
                                   ▼
                        ┌──────────────────────┐
                        │  END CALL            │
                        │  Check Duration > 0? │
                        └──────────┬───────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │                             │
              Duration > 0                  Duration = 0
                    │                             │
                    ▼                             ▼
        ┌────────────────────────┐    ┌──────────────────┐
        │ INCREMENT CALL COUNT   │    │ DON'T COUNT      │
        │ randomCallCount += 1   │    │ (Cancelled call) │
        └──────────┬─────────────┘    └──────────────────┘
                   │
                   ▼
        ┌────────────────────────┐
        │ UPDATE FIRESTORE       │
        │ randomCallCount: X     │
        │                        │
        │ IF count == 3:         │
        │   randomCallEnabled    │
        │   = false              │
        └────────────────────────┘
```

---

## 🔄 Call Flow Timeline

```
TIME:    0:00         0:30         1:00         2:00         3:00
         │            │            │            │            │
         ▼            ▼            ▼            ▼            ▼
┌────────┬────────────┬────────────┬────────────┬────────────┐
│ START  │  Talking   │  Talking   │  Talking   │ AUTO END  │
│ CALL   │            │            │            │           │
└────────┴────────────┴────────────┴────────────┴───────────┘
    │                                                  │
    ▼                                                  ▼
⏱️ Timer                                         ⏰ Timer
  Started                                          Expired
                                                      │
                                                      ▼
                                              🔚 Call Ends
                                              📊 Count += 1
```

---

## 📈 User Journey - 3 Calls Example

### Call #1
```
User: Clicks "Random Call"
App:  ✅ Check: randomCallCount = 0, randomCallEnabled = true
App:  💬 "Random calls remaining: 2"
User: Selects a user to call
App:  📞 Starts Agora call
App:  ⏱️ Starts 3-minute timer
...
3 minutes later OR user ends call
App:  🔚 Call ends
App:  📊 Firestore Update:
      - randomCallCount = 1
      - randomCallEnabled = true
```

### Call #2
```
User: Clicks "Random Call"
App:  ✅ Check: randomCallCount = 1, randomCallEnabled = true
App:  💬 "Random calls remaining: 1"
User: Selects a user to call
App:  📞 Starts Agora call
App:  ⏱️ Starts 3-minute timer
...
Call ends
App:  📊 Firestore Update:
      - randomCallCount = 2
      - randomCallEnabled = true
```

### Call #3 (Last Call)
```
User: Clicks "Random Call"
App:  ✅ Check: randomCallCount = 2, randomCallEnabled = true
App:  💬 "Random calls remaining: 0" (orange warning)
User: Selects a user to call
App:  📞 Starts Agora call
App:  ⏱️ Starts 3-minute timer
...
Call ends
App:  📊 Firestore Update:
      - randomCallCount = 3
      - randomCallEnabled = FALSE 🚫
```

### Call #4 (Blocked)
```
User: Clicks "Random Call"
App:  ❌ Check: randomCallCount = 3, randomCallEnabled = false
App:  🚫 Shows Dialog:
      "Random Call Limit Reached"
      "You have used all 3 random calls."
      "Random call feature is now disabled for your account."
User: Cannot proceed
```

---

## 🗄️ Firestore Data Structure

### Before Any Calls
```json
users/{userId}/
{
  "uid": "abc123",
  "displayName": "John Doe",
  "email": "john@example.com",
  "randomCallCount": 0,
  "randomCallEnabled": true
}
```

### After 1 Call
```json
users/{userId}/
{
  "uid": "abc123",
  "displayName": "John Doe",
  "email": "john@example.com",
  "randomCallCount": 1,  // ← Updated
  "randomCallEnabled": true
}
```

### After 3 Calls (Disabled)
```json
users/{userId}/
{
  "uid": "abc123",
  "displayName": "John Doe",
  "email": "john@example.com",
  "randomCallCount": 3,      // ← Max reached
  "randomCallEnabled": false  // ← Auto-disabled
}
```

---

## ⚙️ Component Interaction Diagram

```
┌──────────────────┐
│   HomeScreen     │
│                  │
│  [Random Call]   │◄──┐
│     Button       │   │
└────────┬─────────┘   │
         │              │
         │ onClick      │
         ▼              │
┌────────────────────────────┐
│  RandomCallService         │
│  checkRandomCallPermission │
│  ────────────────────────  │
│  • Check randomCallCount   │
│  • Check randomCallEnabled │
│  • Return permission       │
└────────┬───────────────────┘
         │
         ▼
    Permission?
         │
    ┌────┴────┐
    │         │
   NO        YES
    │         │
    ▼         ▼
 [Dialog]  [User Selection]
 "Limit         │
 Reached"       │
                ▼
        ┌──────────────────┐
        │ VoiceCallScreen  │
        │                  │
        │ • Join Agora     │
        │ • Start Timer    │
        │ • Handle Call    │
        └────────┬─────────┘
                 │
                 │ onCallEnd
                 ▼
        ┌────────────────────────┐
        │  RandomCallService     │
        │  incrementCallCount    │
        │  ──────────────────── │
        │  • count += 1          │
        │  • If count == 3:      │
        │    enabled = false     │
        └────────────────────────┘
```

---

## 🎨 UI States

### State 1: Available (0-2 calls made)
```
┌─────────────────────────┐
│  Random Call            │
│  ┌───────────────────┐  │
│  │   📞              │  │
│  │   Random Call     │  │ ← GREEN, Active
│  │                   │  │
│  └───────────────────┘  │
│  💬 X calls remaining   │
└─────────────────────────┘
```

### State 2: Last Call (2 calls made)
```
┌─────────────────────────┐
│  Random Call            │
│  ┌───────────────────┐  │
│  │   📞              │  │
│  │   Random Call     │  │ ← ORANGE, Warning
│  │                   │  │
│  └───────────────────┘  │
│  ⚠️ 1 call remaining    │
└─────────────────────────┘
```

### State 3: Disabled (3 calls made)
```
┌─────────────────────────┐
│  Random Call            │
│  ┌───────────────────┐  │
│  │   🚫              │  │
│  │   Random Call     │  │ ← RED/GRAY, Disabled
│  │   (Disabled)      │  │
│  └───────────────────┘  │
│  ❌ Limit reached       │
└─────────────────────────┘
```

---

## 🔒 Firestore Security Rules

```javascript
match /users/{userId} {
  // Read access for authenticated users
  allow read: if request.auth != null;
  
  // Write access for own profile
  allow write: if request.auth != null 
    && request.auth.uid == userId;
  
  // Special rule for random call fields
  allow update: if request.auth != null 
    && request.auth.uid == userId
    && request.resource.data.keys()
       .hasAny(['randomCallCount', 'randomCallEnabled']);
}
```

---

## 📱 Code Structure

```
lib/
├── services/
│   ├── random_call_service.dart        ← NEW: Core logic
│   ├── agora_service.dart              ← Existing: Agora calls
│   └── call_signaling_service.dart     ← Existing: Call management
│
├── screens/
│   ├── home_screen.dart                ← UPDATED: Permission check
│   └── voice_call_screen.dart          ← UPDATED: 3-min timer
│
└── models/
    └── user.dart                        ← May need update for fields
```

---

## 🎯 Key Functions

### 1. Check Permission
```dart
RandomCallService().checkRandomCallPermission(userId)
  ↓
Returns:
{
  'canCall': true/false,
  'remainingCalls': 0-3,
  'randomCallCount': 0-3,
  'randomCallEnabled': true/false
}
```

### 2. Start Call with Timer
```dart
VoiceCallScreen(
  call: call,
  isOutgoing: true,
  isRandomCall: true  ← Triggers 3-min timer
)
```

### 3. Increment Count
```dart
RandomCallService().incrementRandomCallCount(userId)
  ↓
Updates Firestore:
- randomCallCount += 1
- If count == 3: randomCallEnabled = false
```

---

## 📊 Metrics to Monitor

- **Total random calls made**: Sum of all users' randomCallCount
- **Users at limit**: Count of users where randomCallEnabled = false
- **Average call duration**: Track actual call durations
- **Early terminations**: Calls ended before 3 minutes

---

## 🎓 Best Practices

✅ **DO:**
- Check permissions before starting call
- Only count connected calls (duration > 0)
- Show clear messages to users
- Test with multiple users

❌ **DON'T:**
- Count cancelled/failed calls
- Allow bypassing the 3-call limit
- Forget to cancel timers on dispose
- Hard-code user IDs for testing

---

## 🚀 Future Enhancements

Possible improvements:
1. **Premium users**: Unlimited random calls
2. **Daily reset**: Reset count every 24 hours
3. **Call quality**: Track and improve call quality
4. **Extended time**: Premium users get 5-minute calls
5. **Analytics**: Dashboard showing usage patterns
