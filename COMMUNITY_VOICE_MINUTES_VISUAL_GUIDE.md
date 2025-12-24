# 🎤 Community Voice Minutes - Visual Guide

## 📱 User Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    USER PURCHASES                           │
│                   COMMUNITY PLAN                            │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │   Plan Duration?   │
        └────────┬───────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
   ┌─────────┐       ┌──────────┐
   │ 1 Month │       │ 6 Months │
   │ LKR 900 │       │ LKR 2500 │
   │ 90 mins │       │ 540 mins │
   └────┬────┘       └────┬─────┘
        │                 │
        └────────┬────────┘
                 │
                 ▼
        ┌────────────────────┐
        │ Firestore Updated: │
        │ voiceTotalMinutes  │
        │ voiceUsedMinutes:0 │
        │ voiceEnabled:true  │
        └────────┬───────────┘
                 │
                 ▼
        ┌────────────────────┐
        │  USER MAKES CALL   │
        └────────┬───────────┘
                 │
                 ▼
        ┌────────────────────┐
        │ Check Voice Access │
        └────────┬───────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
   ┌─────────┐       ┌──────────┐
   │ Has     │       │ No       │
   │ Minutes │       │ Minutes  │
   └────┬────┘       └────┬─────┘
        │                 │
        ▼                 ▼
   ┌─────────┐       ┌──────────────┐
   │  Call   │       │ Show Dialog  │
   │ Proceeds│       │ "Buy Minutes"│
   └────┬────┘       └────┬─────────┘
        │                 │
        ▼                 ▼
   ┌─────────┐       ┌──────────────┐
   │ Track   │       │   Navigate   │
   │Duration │       │  to Top-Up   │
   └────┬────┘       │    Screen    │
        │            └────┬─────────┘
        ▼                 │
   ┌─────────┐            ▼
   │  Call   │       ┌──────────────┐
   │  Ends   │       │Select Package│
   └────┬────┘       │ LKR 300/500  │
        │            └────┬─────────┘
        ▼                 │
   ┌──────────────┐       ▼
   │ Add Duration │  ┌──────────────┐
   │ to Used Mins │  │   Payment    │
   └────┬─────────┘  └────┬─────────┘
        │                 │
        ▼                 ▼
   ┌──────────────┐  ┌──────────────┐
   │ Check Total  │  │ Add Minutes  │
   └────┬─────────┘  │  to Total    │
        │            └────┬─────────┘
   ┌────┴────┐            │
   │         │            │
   ▼         ▼            │
┌─────┐  ┌─────┐         │
│ OK  │  │Full │         │
└──┬──┘  └──┬──┘         │
   │        │            │
   │        ▼            │
   │   ┌─────────┐      │
   │   │ Disable │      │
   │   │ Voice   │      │
   │   └─────────┘      │
   │                    │
   └────────┬───────────┘
            │
            ▼
   ┌────────────────┐
   │  User Can Make │
   │  Calls Again   │
   └────────────────┘
```

---

## 🎯 Voice Minutes Calculation Logic

```
┌─────────────────────────────────────────┐
│         COMMUNITY PLAN PURCHASED        │
├─────────────────────────────────────────┤
│                                         │
│  1 Month:  voiceTotalMinutes = 90      │
│  6 Month:  voiceTotalMinutes = 540     │
│            voiceUsedMinutes = 0        │
│            voiceEnabled = true         │
│                                         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│          USER MAKES VOICE CALL          │
├─────────────────────────────────────────┤
│                                         │
│  Before Call:                          │
│  ───────────                           │
│  remaining = total - used              │
│  if (remaining <= 0) → BLOCK CALL     │
│                                         │
│  During Call:                          │
│  ────────────                          │
│  Track duration in seconds            │
│                                         │
│  After Call:                           │
│  ───────────                           │
│  callMinutes = (seconds / 60).ceil()  │
│  used += callMinutes                   │
│  if (used >= total) → disable         │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📊 Example Scenarios

### Scenario 1: Normal Usage
```
User: John
Plan: 1 Month (90 minutes)

Day 1:
  total: 90, used: 0
  Call 1: 15 min → used: 15, remaining: 75 ✅

Day 5:
  total: 90, used: 15
  Call 2: 30 min → used: 45, remaining: 45 ✅

Day 15:
  total: 90, used: 45
  Call 3: 40 min → used: 85, remaining: 5 ✅

Day 20:
  total: 90, used: 85
  Call 4: 10 min → BLOCKED ❌
  Message: "Voice minutes finished"
```

### Scenario 2: Top-Up Purchase
```
User: Sarah
Plan: 1 Month (90 minutes)

Current State:
  total: 90, used: 90, remaining: 0 ❌

Sarah buys Small Top-Up (LKR 300):
  ↓
  total: 390 (90 + 300)
  used: 90
  remaining: 300 ✅
  voiceEnabled: true

Sarah can make calls again! 🎉
```

### Scenario 3: Plan Expiry
```
User: Mike
Plan: 1 Month (expires 2025-02-23)

Current State (2025-02-20):
  total: 90, used: 30, remaining: 60
  Plan expires in 3 days
  Status: ✅ Can make calls

After Expiry (2025-02-24):
  total: 90, used: 30, remaining: 60
  But plan expired!
  Status: ❌ Cannot make calls
  
  voiceEnabled = false
  chatEnabled = false
  statusEnabled = false
  
  Must renew Community Plan first!
```

---

## 🎨 UI Screens

### 1. Premium Screen (with Voice Top-Up Button)
```
┌─────────────────────────────────────────┐
│  Premium Plans                          │
├─────────────────────────────────────────┤
│                                         │
│  ╔═══════════════════════════════════╗ │
│  ║  🎤  Add Voice Minutes            ║ │
│  ║      Top-up your voice call       ║ │
│  ║      minutes                   →  ║ │
│  ╚═══════════════════════════════════╝ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Choose a plan                    │ │
│  ├───────────────────────────────────┤ │
│  │  🏆 Community Plan                │ │
│  │     Chats, calls, group...     ▼  │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  🤖 AI Agent                      │ │
│  │     AI answers, grammar...     ▼  │ │
│  └───────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 2. Voice Top-Up Screen
```
┌─────────────────────────────────────────┐
│  ← Voice Minutes Top-Up                 │
├─────────────────────────────────────────┤
│                                         │
│  ╔═══════════════════════════════════╗ │
│  ║  Voice Minutes Remaining          ║ │
│  ║                                   ║ │
│  ║            45                     ║ │
│  ║          minutes                  ║ │
│  ║                                   ║ │
│  ║  Used: 45 min • Total: 90 min    ║ │
│  ╚═══════════════════════════════════╝ │
│                                         │
│  Add More Minutes                       │
│  Choose a top-up package to add...     │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  💙  Small Top-Up    LKR 300     │ │
│  │      300 minutes                  │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  💚  Large Top-Up    LKR 500     │ │
│  │      750 minutes                  │ │
│  │  ⭐ Best Value - Save 25%        │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  SELECT A PACKAGE                 │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ℹ️  Top-up minutes are valid until   │
│     your Community Plan expires        │
│                                         │
└─────────────────────────────────────────┘
```

### 3. Call Blocked Dialog
```
┌─────────────────────────────────────────┐
│                                         │
│  🚫 Voice Call Unavailable              │
│                                         │
│  Voice minutes finished. Please buy a  │
│  top-up package.                       │
│                                         │
│  ┌────────────┐  ┌─────────────────┐  │
│  │   Cancel   │  │  Buy Minutes    │  │
│  └────────────┘  └─────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

### 4. Top-Up Success Dialog
```
┌─────────────────────────────────────────┐
│                                         │
│  ✅ Top-Up Successful! 🎉              │
│                                         │
│  Your voice minutes have been added!   │
│                                         │
│  ╔═══════════════════════════════════╗ │
│  ║  Minutes Added:    +300 min       ║ │
│  ║  ──────────────────────────────   ║ │
│  ║  New Total:        390 min        ║ │
│  ╚═══════════════════════════════════╝ │
│                                         │
│              ┌────────┐                │
│              │   OK   │                │
│              └────────┘                │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🔄 State Management

```javascript
// User State in Firestore
{
  // Community Plan Info
  "communityPlan": "1_MONTH" | "6_MONTH",
  
  // Voice Minutes
  "voiceTotalMinutes": 90 | 540 | (90 + top-ups),
  "voiceUsedMinutes": 0..N,
  "voiceEnabled": true | false,
  
  // Subscription Tracking
  "subscriptions": {
    "community": {
      "expiryDate": Timestamp,
      "voiceTotalMinutes": 90 | 540,
      "plan": "Community Plan",
      "duration": "1 Month" | "6 Months",
      "price": 900 | 2500
    }
  },
  
  // Access Control
  "unlockedFeatures": ["community"],
  "expiryDate": Timestamp
}
```

---

## ⚙️ Configuration Values

```dart
// Community Plan Minutes
const COMMUNITY_1_MONTH_MINUTES = 90;
const COMMUNITY_6_MONTH_MINUTES = 540;

// Top-Up Packages
const TOPUP_SMALL_PRICE = 300;  // LKR
const TOPUP_SMALL_MINUTES = 300;

const TOPUP_LARGE_PRICE = 500;  // LKR
const TOPUP_LARGE_MINUTES = 750;

// Conversion
const SECONDS_PER_MINUTE = 60;
// Call duration rounded UP
// 61 seconds = 2 minutes billed
```

---

## 🧪 Test Cases

### ✅ Test 1: Community Plan Purchase
```
Input: User buys 1 Month Plan
Expected:
  - voiceTotalMinutes = 90
  - voiceUsedMinutes = 0
  - voiceEnabled = true
  - communityPlan = "1_MONTH"
```

### ✅ Test 2: Voice Call Tracking
```
Input: User makes 15-minute call
State Before: total=90, used=0
Expected After: total=90, used=15, remaining=75
```

### ✅ Test 3: Minutes Exhaustion
```
Input: User makes call with 0 remaining minutes
Expected: Call blocked, dialog shown
```

### ✅ Test 4: Top-Up Purchase
```
Input: User buys LKR 300 package
State Before: total=90, used=90
Expected After: total=390, used=90, voiceEnabled=true
```

### ✅ Test 5: Plan Expiry
```
Input: Community Plan expires
State: total=90, used=30, remaining=60
Expected:
  - voiceEnabled = false (despite 60 minutes remaining)
  - All Community features disabled
  - Top-up screen shows "No Active Plan"
```

---

## 📝 Database Queries

### Check Voice Access
```dart
// Query user voice status
final userDoc = await FirebaseFirestore.instance
    .collection("users")
    .doc(userId)
    .get();

final data = userDoc.data()!;
int total = data['voiceTotalMinutes'] ?? 0;
int used = data['voiceUsedMinutes'] ?? 0;
bool enabled = data['voiceEnabled'] ?? false;

int remaining = total - used;
bool hasAccess = enabled && remaining > 0;
```

### Add Call Duration
```dart
// Update after call
int callMinutes = (durationSeconds / 60).ceil();
int newUsed = currentUsed + callMinutes;
bool shouldDisable = newUsed >= total;

await FirebaseFirestore.instance
    .collection("users")
    .doc(userId)
    .update({
      'voiceUsedMinutes': newUsed,
      'voiceEnabled': !shouldDisable,
    });
```

---

## 🎯 Key Differences from AI Agent System

| Feature | AI Agent | Community Voice |
|---------|----------|----------------|
| **Measurement** | Seconds | Minutes |
| **Purchase Options** | 1000/2500 credits | 1 Month/6 Months |
| **Top-Ups** | ❌ No | ✅ Yes (LKR 300/500) |
| **Auto-Disable** | ✅ Yes | ✅ Yes |
| **Plan Expiry** | N/A | ✅ Blocks all features |
| **Usage Tracking** | Real-time countdown | Post-call update |
| **Display** | MM:SS timer | Minutes remaining |

---

## ✨ Summary

**Voice Minutes System** is now fully implemented with:
- ✅ 90 or 540 minutes for Community Plans
- ✅ LKR 300 and LKR 500 top-up packages
- ✅ Real-time access checking
- ✅ Post-call duration tracking
- ✅ Beautiful UI for top-ups
- ✅ Payment integration
- ✅ Plan expiry control
- ✅ Seamless user experience

**All existing features remain unchanged!** 🎉
