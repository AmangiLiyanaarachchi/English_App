# 📱 Chat System Visual Flow Guide

## 🎯 User Journey Map

```
┌─────────────────────────────────────────────────────────────┐
│                     ENGLISH CIRCLE APP                       │
│                    (Bottom Navigation)                       │
└─────────────────────────────────────────────────────────────┘
           │
           │ User taps "Chat" tab (5th icon)
           ▼
┌─────────────────────────────────────────────────────────────┐
│                   CHATS LIST SCREEN                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  🔍 Search chats...                                   │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  Options:                                                    │
│  • "Chats" view (default) - Shows existing conversations    │
│  • "All Users" view - Shows all app users                   │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │ 👤 John Doe                           2m ago   │         │
│  │    ✓✓ Hey, how's your English?          [2]   │         │
│  ├────────────────────────────────────────────────┤         │
│  │ 👤 Jane Smith                     Yesterday    │         │
│  │    Let's practice idioms!                      │         │
│  ├────────────────────────────────────────────────┤         │
│  │ 👤 Mike Brown                        1 week    │         │
│  │    ✓ Thanks for the grammar tips!             │         │
│  └────────────────────────────────────────────────┘         │
│                                                              │
│                                              [💬] FAB        │
└─────────────────────────────────────────────────────────────┘
           │
           │ User taps a chat or FAB → All Users
           ▼
┌─────────────────────────────────────────────────────────────┐
│                  ALL USERS SCREEN                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  🔍 Search users...                                   │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │ 👤 Alice Chen               🟢 Online          │         │
│  │    alice@example.com                           │         │
│  ├────────────────────────────────────────────────┤         │
│  │ 👤 Bob Wilson                                  │         │
│  │    Last seen 5 minutes ago                     │         │
│  ├────────────────────────────────────────────────┤         │
│  │ 👤 Carol Davis              🟢 Online          │         │
│  │    carol@example.com                           │         │
│  └────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
           │
           │ User taps a user
           ▼
┌─────────────────────────────────────────────────────────────┐
│          INDIVIDUAL CHAT SCREEN                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ ← 👤 Alice Chen   🟢 Online                          │  │
│  │   💡 Grammar Drill: Try a conditional sentence        │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ─────────── Today ───────────                              │
│                                                              │
│  ┌────────────────────────────────┐                         │
│  │ Hi! Want to practice English?  │ ← Their message         │
│  │ 14:23                          │                         │
│  └────────────────────────────────┘                         │
│                                                              │
│                       ┌─────────────────────────────────┐   │
│                       │ Sure! Let's talk about idioms   │   │
│                       │ 💡 Tip: Excellent vocabulary!   │   │
│                       │ 14:25 ✓✓                        │   │
│                       └─────────────────────────────────┘   │
│        Your message (with English tip) →                    │
│                                                              │
│  ┌────────────────────────────────┐                         │
│  │ Break the ice?                 │                         │
│  │ 14:26                          │                         │
│  └────────────────────────────────┘                         │
│                                                              │
│                       ┌─────────────────────────────────┐   │
│                       │ To start a conversation!        │   │
│                       │ 💡 Tip: Great idiom usage! ✨   │   │
│                       │ 14:27 ✓                         │   │
│                       └─────────────────────────────────┘   │
│                                                              │
│  [Load more messages above...]                              │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Type your message...              [🎤] [➤]           │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Diagram

```
┌──────────────┐
│   USER APP   │
│  (Flutter)   │
└──────┬───────┘
       │
       │ 1. Send Message
       ▼
┌──────────────────────────────────────┐
│      CHAT SERVICE                    │
│  (chat_service.dart)                 │
│                                      │
│  • Generate message ID               │
│  • Add English tip                   │
│  • Create message object             │
└──────┬────────────────────┬──────────┘
       │                    │
       │ 2. Save            │ 2. Save
       │ (Real-time)        │ (Instant)
       ▼                    ▼
┌──────────────┐      ┌──────────────┐
│  FIRESTORE   │      │     HIVE     │
│   (Cloud)    │      │   (Local)    │
│              │      │              │
│ • Last 50    │      │ • All msgs   │
│   messages   │      │ • Unlimited  │
│ • Real-time  │      │ • Offline    │
│   sync       │      │   access     │
└──────┬───────┘      └──────┬───────┘
       │                     │
       │ 3. Stream           │ 3. Read
       │ (Updates)           │ (Cache)
       ▼                     ▼
┌──────────────────────────────────────┐
│      CHAT DETAIL SCREEN              │
│  (chat_detail_screen.dart)           │
│                                      │
│  • Merge Firestore + Hive            │
│  • Display messages                  │
│  • Handle pagination                 │
└──────────────────────────────────────┘
```

## 💾 Storage Strategy

```
╔═══════════════════════════════════════════════════════════╗
║                    MESSAGE STORAGE                         ║
╚═══════════════════════════════════════════════════════════╝

New Message → Firestore (Real-time) + Hive (Cache)
              │                        │
              ▼                        ▼
        ┌─────────────┐          ┌─────────────┐
        │  FIRESTORE  │          │    HIVE     │
        │             │          │             │
        │ Message 1   │          │ Message 1   │
        │ Message 2   │          │ Message 2   │
        │ Message 3   │          │ Message 3   │
        │    ...      │          │    ...      │
        │ Message 48  │          │ Message 48  │
        │ Message 49  │          │ Message 49  │
        │ Message 50  │          │ Message 50  │
        │             │          │ Message 51  │
        │  (Limit:    │          │ Message 52  │
        │   50 msgs)  │          │    ...      │
        │             │          │ Message 999 │
        │   AUTO      │          │             │
        │  CLEANUP    │          │ (Unlimited) │
        │  OLDEST     │          │  (Free!)    │
        └─────────────┘          └─────────────┘
              │                        │
              │                        │
        When online              When offline
              │                        │
              ▼                        ▼
        Real-time sync           Instant access
```

## 🎨 Message Bubble Anatomy

```
┌─────────────────────────────────────────────────────┐
│ Your Message (Sent by You)                          │
│                                                      │
│                    ┌──────────────────────────────┐ │
│                    │ Hi! Let's practice English!  │ │ ← Message text
│                    │                              │ │
│                    │ ┌──────────────────────────┐ │ │
│                    │ │ 💡 Tip: Great start!     │ │ │ ← English tip
│                    │ └──────────────────────────┘ │ │
│                    │                              │ │
│                    │ 14:23 ✓✓                     │ │ ← Time + Status
│                    └──────────────────────────────┘ │
│                                                      │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Their Message (Received)                             │
│                                                      │
│ ┌──────────────────────────────┐                    │
│ │ Absolutely! What topic?       │                    │ ← Message text
│ │                               │                    │
│ │ 14:24                         │                    │ ← Time only
│ └──────────────────────────────┘                    │
│                                                      │
└─────────────────────────────────────────────────────┘

Status Icons:
✓   = Sent to server
✓✓  = Delivered & Read (gray)
✓✓  = Delivered & Read (blue) - emphasized read
```

## 🔔 Real-time Update Flow

```
User A                         Firebase                      User B
  │                               │                            │
  │ 1. Send "Hello"              │                            │
  ├─────────────────────────────>│                            │
  │                               │                            │
  │ 2. Save to Firestore          │                            │
  │                               ├──────────────────────────> │
  │                               │ 3. Real-time notification  │
  │                               │                            │
  │                               │ 4. Fetch message           │
  │                               │<───────────────────────────┤
  │                               │                            │
  │                               │ 5. Display "Hello"         │
  │                               │                            ▼
  │                               │                    [Message appears]
  │                               │                            │
  │                               │ 6. Mark as read            │
  │                               │<───────────────────────────┤
  │                               │                            │
  │ 7. Update read receipt        │                            │
  │<──────────────────────────────┤                            │
  │                               │                            │
  ▼                               ▼                            ▼
[✓✓ appears]                                           [Message marked]
```

## 📊 Screen State Diagram

```
              ┌──────────────┐
              │   Loading    │
              │      ⏳      │
              └──────┬───────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌────────────────┐      ┌────────────────┐
│  Empty State   │      │  Has Messages  │
│                │      │                │
│  💬 No chats   │      │  📝 Chat list  │
│  Start chat!   │      │  with preview  │
└────────────────┘      └────────┬───────┘
                                 │
                     ┌───────────┴────────────┐
                     │                        │
                     ▼                        ▼
            ┌─────────────────┐      ┌─────────────────┐
            │  Online Mode    │      │  Offline Mode   │
            │                 │      │                 │
            │  🟢 Real-time   │      │  ⚫ Cached only │
            │  ✓ Send/Receive │      │  📚 Read-only   │
            └─────────────────┘      └─────────────────┘
```

## 🎯 Feature Status Legend

```
Feature               Status      Location
─────────────────────────────────────────────────────
Real-time messages    ✅ Done     chat_service.dart
Local caching         ✅ Done     Hive integration
Offline support       ✅ Done     connectivity_plus
User list             ✅ Done     chats_list_screen.dart
Chat search           ✅ Done     Search TextField
Read receipts         ✅ Done     Message bubbles
Last message          ✅ Done     Chat preview
Pagination            ✅ Done     ScrollController
Unread counter        ✅ Done     Chat badges
English tips          ✅ Done     chat_service.dart
Challenge mode        ✅ Done     App bar chip
Date separators       ✅ Done     Message list
Online status         ✅ Done     User avatars
Voice messages        🔮 Future   To be implemented
Image sharing         🔮 Future   To be implemented
Group chats           🔮 Future   To be implemented
```

## 🌟 Key Components Map

```
┌────────────────────────────────────────────────────┐
│                   MAIN APP                          │
│                  (main.dart)                        │
│  • Initialize Firebase                             │
│  • Initialize Hive                                 │
│  • Register adapters                               │
└────────────────┬───────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────┐
│               HOME SCREEN                           │
│            (home_screen.dart)                       │
│  • Bottom navigation                               │
│  • Tab 5: Chat                                     │
└────────────────┬───────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────┐
│           CHATS LIST SCREEN                         │
│        (chats_list_screen.dart)                     │
│  • Stream of chat rooms                            │
│  • Search functionality                            │
│  • Toggle users view                               │
└────────────────┬───────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────┐
│          CHAT DETAIL SCREEN                         │
│       (chat_detail_screen.dart)                     │
│  • Message list (paginated)                        │
│  • Input field                                     │
│  • English challenges                              │
└────────────────┬───────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────┐
│             CHAT SERVICE                            │
│          (chat_service.dart)                        │
│  • Send/receive messages                           │
│  • Firestore operations                            │
│  • Hive caching                                    │
│  • English tip generation                          │
└────────────────────────────────────────────────────┘
```

---

**This visual guide helps you understand the complete chat system flow! 🎨**
