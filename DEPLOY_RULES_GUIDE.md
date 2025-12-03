# 🔥 Deploy Firestore Rules - Quick Guide

## ❌ Error You're Seeing:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## ✅ Solution: Deploy Updated Firestore Rules

---

## **Method 1: Via Firebase Console (Recommended - No Installation)**

### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com

### Step 2: Select Your Project
Choose your English app project

### Step 3: Navigate to Firestore Rules
1. Click **Firestore Database** in left menu
2. Click **Rules** tab at the top

### Step 4: Copy & Paste Rules
Replace everything with this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ================================
    // USERS COLLECTION
    // ================================
    match /users/{userId} {
      // Anyone authenticated can read user profiles
      allow read: if request.auth != null;
      
      // Users can only write to their own profile
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ================================
    // CHAT ROOMS COLLECTION
    // ================================
    match /chatRooms/{chatId} {
      // Can read/list if authenticated (needed for array-contains queries)
      allow read, list: if request.auth != null;
      
      // Can create a chat room if you're in participants
      allow create: if request.auth != null &&
                       request.auth.uid in request.resource.data.participants;
      
      // Can update chat room if chatId contains your UID
      allow update: if request.auth != null && 
                       (chatId.matches('.*' + request.auth.uid + '.*'));
      
      // ================================
      // MESSAGES SUBCOLLECTION
      // ================================
      match /messages/{messageId} {
        // Can read/list messages if the chatId contains your UID
        allow read, get, list: if request.auth != null &&
                                  (chatId.matches('.*' + request.auth.uid + '.*'));
        
        // Can create messages if you're the sender and chatId contains your UID
        allow create: if request.auth != null && 
                         (chatId.matches('.*' + request.auth.uid + '.*')) &&
                         request.auth.uid == request.resource.data.senderUid;
        
        // Can update messages for read receipts (only if you're the receiver)
        allow update: if request.auth != null &&
                         (chatId.matches('.*' + request.auth.uid + '.*')) &&
                         request.auth.uid == resource.data.receiverUid;
        
        // Can delete your own messages
        allow delete: if request.auth != null &&
                         (chatId.matches('.*' + request.auth.uid + '.*')) &&
                         request.auth.uid == resource.data.senderUid;
      }
    }
    
    // ================================
    // LEGACY CHAT COLLECTION (if exists)
    // ================================
    match /chats/{chatId} {
      allow read, write: if request.auth != null;
    }
    
    // ================================
    // CALLS COLLECTION (Voice Calling)
    // ================================
    match /calls/{callId} {
      // Can read if you're the caller or receiver
      allow read: if request.auth != null &&
                     (request.auth.uid == resource.data.callerId ||
                      request.auth.uid == resource.data.receiverId);
      
      // Can create if you're the caller
      allow create: if request.auth != null &&
                       request.auth.uid == request.resource.data.callerId;
      
      // Can update if you're the caller or receiver
      allow update: if request.auth != null &&
                       (request.auth.uid == resource.data.callerId ||
                        request.auth.uid == resource.data.receiverId);
      
      // Can delete if you're the caller
      allow delete: if request.auth != null &&
                       request.auth.uid == resource.data.callerId;
    }
    
    // ================================
    // STATUS COLLECTION (WhatsApp-style Status)
    // ================================
    match /status/{statusId} {
      // Anyone can read active statuses (not expired)
      allow read: if request.auth != null &&
                     request.time < resource.data.expiresAt;
      
      // Only authenticated users can create with proper data
      allow create: if request.auth != null && 
                       request.resource.data.ownerId == request.auth.uid &&
                       request.resource.data.expiresAt == request.resource.data.createdAt + duration.value(24, 'h');
      
      // Only owner can delete their status
      allow delete: if request.auth != null && 
                       resource.data.ownerId == request.auth.uid;
      
      // Anyone authenticated can update (for views and comments)
      allow update: if request.auth != null;
    }
  }
}
```

### Step 5: Publish Rules
Click **Publish** button

### Step 6: Test Your App
Run the app again - Status feature should work now!

---

## **Method 2: Install Firebase CLI (For Future)**

If you want to use command line in the future:

```powershell
# Install Node.js first (if not installed)
# Download from: https://nodejs.org

# Then install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy rules
firebase deploy --only firestore:rules
```

---

## ✅ After Deployment

The error will be fixed and you can:
- ✅ View all statuses
- ✅ Post text/image status
- ✅ Add comments
- ✅ Track views
- ✅ Auto-delete after 24 hours

---

## 📱 Test Status Feature

1. Open app
2. Go to **Status** tab
3. Tap **+** button
4. Post a status
5. It should work now! 🎉
