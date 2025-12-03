# Firestore Security Rules Deployment Guide

## Critical: Deploy These Rules to Fix Permission Errors

Your app is currently experiencing **permission denied** errors because the Firestore security rules need to be updated.

## Step-by-Step Instructions

### Option 1: Deploy via Firebase Console (Recommended)

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com/
   - Select your project

2. **Navigate to Firestore Rules**
   - Click on **Firestore Database** in the left sidebar
   - Click on the **Rules** tab

3. **Replace Existing Rules**
   - Delete all existing rules
   - Copy and paste the rules below
   - Click **Publish**

### Option 2: Deploy via Firebase CLI

1. **Install Firebase CLI** (if not already installed)
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

3. **Initialize Firebase in your project** (if not already done)
   ```bash
   firebase init firestore
   ```

4. **Update firestore.rules file**
   - The rules are already in your `firestore.rules` file
   - Just deploy them:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Firestore Security Rules

Copy these rules to your Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      // Anyone authenticated can read user profiles
      allow read: if isAuthenticated();
      // Users can only update their own profile
      allow write: if isAuthenticated() && isOwner(userId);
    }
    
    // Chats collection
    match /chats/{chatId} {
      // Users can read/write chats they are participants in
      allow read, write: if isAuthenticated() && 
        (request.auth.uid in resource.data.participants || 
         request.auth.uid in request.resource.data.participants);
    }
    
    // Messages subcollection
    match /chats/{chatId}/messages/{messageId} {
      // Users can read messages in chats they are participants in
      allow read: if isAuthenticated() && 
        request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
      // Users can create messages in chats they are participants in
      allow create: if isAuthenticated() && 
        request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants &&
        request.resource.data.senderId == request.auth.uid;
    }
    
    // Calls collection - for voice calling
    match /calls/{callId} {
      // Users can read calls where they are caller or receiver
      allow read: if isAuthenticated() && 
        (request.auth.uid == resource.data.callerId || 
         request.auth.uid == resource.data.receiverId);
      
      // Users can create calls where they are the caller
      allow create: if isAuthenticated() && 
        request.resource.data.callerId == request.auth.uid;
      
      // Users can update calls where they are caller or receiver
      allow update: if isAuthenticated() && 
        (request.auth.uid == resource.data.callerId || 
         request.auth.uid == resource.data.receiverId);
      
      // Users can delete calls where they are caller or receiver
      allow delete: if isAuthenticated() && 
        (request.auth.uid == resource.data.callerId || 
         request.auth.uid == resource.data.receiverId);
    }
  }
}
```

## What These Rules Do

1. **Users Collection**: 
   - All authenticated users can read any user profile (needed for user lists and calling)
   - Users can only modify their own profile

2. **Chats Collection**: 
   - Users can only access chats they are participants in

3. **Messages Subcollection**: 
   - Users can only read/write messages in chats they are part of
   - Ensures sender ID matches authenticated user

4. **Calls Collection** (NEW):
   - Users can see calls where they are caller or receiver
   - Only the caller can create a call
   - Both caller and receiver can update call status (accept, reject, end)
   - Both can delete the call record

## Verify Deployment

After deploying, you can verify the rules are active:

1. Go to Firebase Console > Firestore Database > Rules
2. You should see the rules above
3. Check the "Published" timestamp to confirm recent deployment

## Testing

After deployment:
1. Close your app completely
2. Restart the app
3. Try making a call
4. The "permission denied" errors should be gone

## Troubleshooting

**Still getting permission denied?**
- Make sure you're logged in with a Firebase user
- Check that the rules were actually published (not just saved as draft)
- Try signing out and signing back in to the app
- Check Firebase Console > Firestore Database > Rules tab for any syntax errors

**Rules won't deploy?**
- Check for syntax errors in the Firebase Console
- Make sure you have owner/editor permissions on the Firebase project
- Try using Firebase CLI instead of the console
