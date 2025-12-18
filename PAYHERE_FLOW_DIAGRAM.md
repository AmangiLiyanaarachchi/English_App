# 🎯 PayHere Payment Gateway - Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                      ENGLISH CIRCLE APP                              │
│                   PayHere Payment Integration                        │
└─────────────────────────────────────────────────────────────────────┘

╔═══════════════════════════════════════════════════════════════════╗
║                     1. USER SELECTS PLAN                           ║
╚═══════════════════════════════════════════════════════════════════╝

┌─────────────────┐   ┌─────────────────┐   ┌─────────────────────┐
│  Community Plan │   │    AI Agent     │   │ Community + AI Agent │
│                 │   │                 │   │                     │
│ Unlocks: Chat   │   │ Unlocks: AI     │   │ Unlocks: Both       │
│ Price: LKR 100  │   │ Price: LKR 100  │   │ Price: LKR 100      │
└─────────────────┘   └─────────────────┘   └─────────────────────┘
         │                      │                       │
         └──────────────────────┴───────────────────────┘
                                │
                                ▼
╔═══════════════════════════════════════════════════════════════════╗
║                  2. CHOOSE DURATION & CONTINUE                     ║
╚═══════════════════════════════════════════════════════════════════╝

        ┌──────────────┐              ┌──────────────┐
        │   1 Week     │              │  6 Months    │
        │  LKR 100     │              │  LKR 1000    │
        └──────────────┘              └──────────────┘
                │                              │
                └──────────────┬───────────────┘
                               │
                               ▼
╔═══════════════════════════════════════════════════════════════════╗
║                    3. PAYMENT SCREEN                               ║
╚═══════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│  Selected Plan: Community + AI Agent                             │
│  Duration: 1 Week                              Price: LKR 100   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  First Name:  [_________________]                                │
│  Last Name:   [_________________]                                │
│  Email:       [_________________]                                │
│  Phone:       🇱🇰 +94 [_________]                               │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
                        [  PAY NOW  ]
                               │
                               ▼
╔═══════════════════════════════════════════════════════════════════╗
║                  4. PAYHERE GATEWAY OPENS                          ║
╚═══════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│                     PayHere Payment                              │
│                                                                   │
│  Merchant: English Circle                                        │
│  Amount: LKR 100.00                                              │
│  Order ID: ORDER_1702636980000                                   │
│                                                                   │
│  Card Number:  [____-____-____-____]                            │
│  Expiry:       [__/__]    CVV: [___]                            │
│                                                                   │
│  [ Complete Payment ]                                            │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
        ┌──────────────────────┴───────────────────────┐
        │                                               │
        ▼                                               ▼
   ┌─────────┐                                    ┌──────────┐
   │ SUCCESS │                                    │  CANCEL  │
   └─────────┘                                    └──────────┘
        │                                               │
        ▼                                               ▼
╔════════════════════════╗                    Return to Payment
║  5. FEATURE UNLOCKING  ║                         Screen
╚════════════════════════╝                              │
        │                                               │
        ▼                                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    UPDATE FIRESTORE                              │
│                                                                   │
│  Users Collection:                                               │
│  ├─ package: "Community + AI Agent"                             │
│  ├─ paymentStatus: "paid"                                       │
│  ├─ unlockedFeatures: ["community", "ai_agent"]                │
│  ├─ expiryDate: 2025-12-22                                      │
│  └─ price: 100                                                  │
│                                                                   │
│  Payments Collection:                                            │
│  ├─ orderId: "ORDER_1702636980000"                              │
│  ├─ paymentId: "payhere_xxxxx"                                  │
│  ├─ status: "paid"                                              │
│  └─ amount: 100                                                 │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
╔═══════════════════════════════════════════════════════════════════╗
║                  6. SUCCESS DIALOG SHOWS                           ║
╚═══════════════════════════════════════════════════════════════════╝

        ┌────────────────────────────────────────┐
        │     Payment Successful! 🎉            │
        │                                        │
        │  You now have access to:              │
        │  • Community Plan                     │
        │  • AI Agent                           │
        │                                        │
        │  Enjoy your premium features!         │
        │                                        │
        │            [    OK    ]                │
        └────────────────────────────────────────┘
                        │
                        ▼
╔═══════════════════════════════════════════════════════════════════╗
║                  7. FEATURES UNLOCKED                              ║
╚═══════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│                      HOME SCREEN                                 │
│                                                                   │
│  [Home] [Status] [Profile] [Premium] [Chat]                     │
│                                          ▲       ▲               │
│                                          │       │               │
│                                    ✅ UNLOCKED ✅ UNLOCKED        │
└─────────────────────────────────────────────────────────────────┘

        User can now access:
        ✅ Community Chat
        ✅ AI Agent
        ✅ All premium features!


═══════════════════════════════════════════════════════════════════

                     ACCESS CONTROL LOGIC

═══════════════════════════════════════════════════════════════════

WHEN USER TAPS AI AGENT TAB:
┌────────────────────────────────────────────────────────────────┐
│  PremiumAccessService.hasFeatureAccess('ai_agent')            │
│            │                                                    │
│            ▼                                                    │
│  Check Firestore: unlockedFeatures contains 'ai_agent'?       │
│            │                                                    │
│     ┌──────┴──────┐                                           │
│     │             │                                           │
│     ▼             ▼                                           │
│   YES            NO                                           │
│     │             │                                           │
│     │             ▼                                           │
│     │    Show Premium Dialog 🔒                              │
│     │    "Subscribe to access AI Agent"                      │
│     │                                                         │
│     ▼                                                         │
│  Show AI Agent Page ✅                                        │
└────────────────────────────────────────────────────────────────┘


WHEN USER TAPS CHAT TAB:
┌────────────────────────────────────────────────────────────────┐
│  PremiumAccessService.hasFeatureAccess('community')           │
│            │                                                    │
│            ▼                                                    │
│  Check Firestore: unlockedFeatures contains 'community'?      │
│            │                                                    │
│     ┌──────┴──────┐                                           │
│     │             │                                           │
│     ▼             ▼                                           │
│   YES            NO                                           │
│     │             │                                           │
│     │             ▼                                           │
│     │    Show Premium Dialog 🔒                              │
│     │    "Subscribe to access Community Chat"                │
│     │                                                         │
│     ▼                                                         │
│  Show Chat Page ✅                                            │
└────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════

                     FEATURE MATRIX

═══════════════════════════════════════════════════════════════════

┌────────────────────┬─────────────┬───────────┬─────────────────┐
│       PLAN         │    CHAT     │ AI AGENT  │     PRICE       │
├────────────────────┼─────────────┼───────────┼─────────────────┤
│ Community Plan     │     ✅      │    ❌     │  LKR 100/week   │
├────────────────────┼─────────────┼───────────┼─────────────────┤
│ AI Agent           │     ❌      │    ✅     │  LKR 100/week   │
├────────────────────┼─────────────┼───────────┼─────────────────┤
│ Community + AI     │     ✅      │    ✅     │  LKR 100/week   │
└────────────────────┴─────────────┴───────────┴─────────────────┘


═══════════════════════════════════════════════════════════════════

                  SUBSCRIPTION LIFECYCLE

═══════════════════════════════════════════════════════════════════

Day 0 (Payment)
│
├─ Payment successful ✅
├─ Features unlocked
├─ expiryDate = Day 7
├─ paymentStatus = "paid"
│
Day 1-6
│
├─ Features accessible ✅
├─ Expiry checked on each access
│
Day 7 (Expiry)
│
├─ Subscription expires
├─ paymentStatus = "expired"
├─ Features locked 🔒
├─ User must renew
│
└─ User purchases again → Cycle repeats


═══════════════════════════════════════════════════════════════════

                    TESTING WITH SANDBOX

═══════════════════════════════════════════════════════════════════

Test Cards (Always Succeed):

┌──────────────────────────────────────────────────────────┐
│  Visa                                                     │
│  Card: 4916 2175 0161 1292                               │
│  Expiry: 12/25          CVV: 123                         │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  MasterCard                                               │
│  Card: 5413 3194 8802 2428                               │
│  Expiry: 12/25          CVV: 123                         │
└──────────────────────────────────────────────────────────┘

⚠️ Important: Sandbox mode = NO REAL MONEY charged!


═══════════════════════════════════════════════════════════════════

                  DEPLOYMENT CHECKLIST

═══════════════════════════════════════════════════════════════════

Before Production:

┌────────────────────────────────────────────────────────┐
│  [ ] Test all plans in sandbox                        │
│  [ ] Verify feature unlocking works                   │
│  [ ] Check Firestore data structure                   │
│  [ ] Test subscription expiry                         │
│  [ ] Get production credentials from PayHere          │
│  [ ] Update merchantId & merchantSecret               │
│  [ ] Set isSandbox = false                            │
│  [ ] Set up backend notification handler              │
│  [ ] Test with real payment (small amount)            │
│  [ ] Deploy to production                             │
│  [ ] Monitor PayHere dashboard                        │
└────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════

                     READY TO TEST! 🚀

═══════════════════════════════════════════════════════════════════

Run: flutter run

Test with: 4916 2175 0161 1292

Enjoy! 🎉
```

---

**Visual Flow Complete!**  
*This diagram shows the complete payment and feature unlocking flow*
