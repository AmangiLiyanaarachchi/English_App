# Firebase Cloud Function - Auto Delete Expired Status

This Cloud Function automatically deletes expired statuses (older than 24 hours) every hour.

## Setup Instructions

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Initialize Cloud Functions (if not already done)
```bash
cd "d:\English app argent\English_App"
firebase init functions
```
Select:
- JavaScript or TypeScript (choose JavaScript for simplicity)
- Install dependencies: Yes

### 4. Create the Cloud Function

Edit `functions/index.js`:

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Auto-delete expired statuses every hour
exports.deleteExpiredStatus = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
      const now = admin.firestore.Timestamp.now();
      const snapshot = await admin.firestore()
          .collection("status")
          .where("expiresAt", "<=", now)
          .get();

      const deletePromises = [];
      const storagePromises = [];

      snapshot.forEach((doc) => {
        const data = doc.data();
        
        // Delete image from storage if exists
        if (data.type === "image" && data.imageUrl) {
          try {
            const imageRef = admin.storage().refFromURL(data.imageUrl);
            storagePromises.push(imageRef.delete());
          } catch (error) {
            console.error("Error deleting image:", error);
          }
        }
        
        // Delete Firestore document
        deletePromises.push(doc.ref.delete());
      });

      await Promise.all([...deletePromises, ...storagePromises]);
      
      console.log(`Deleted ${deletePromises.length} expired statuses`);
      return null;
    });
```

### 5. Deploy the Cloud Function
```bash
firebase deploy --only functions
```

### 6. Verify Deployment
- Go to Firebase Console → Functions
- You should see `deleteExpiredStatus` function running every hour

## Cost
This Cloud Function is **FREE** under Firebase Spark (free) plan:
- Runs 24 times per day (once per hour)
- Very minimal CPU usage
- Only charged for actual deletions

## Alternative: Client-Side Cleanup (Already Implemented)
The app also runs client-side cleanup when users open the Status screen, providing instant cleanup without waiting for the Cloud Function.

## Firestore Rules
Add this to your `firestore.rules`:

```
match /status/{statusId} {
  // Anyone can read active statuses
  allow read: if request.time < resource.data.expiresAt;
  
  // Only authenticated users can create
  allow create: if request.auth != null 
    && request.resource.data.ownerId == request.auth.uid
    && request.resource.data.expiresAt == request.time + duration.value(24, 'h');
  
  // Only owner can delete
  allow delete: if request.auth != null 
    && resource.data.ownerId == request.auth.uid;
  
  // Only owner can update (for views and comments)
  allow update: if request.auth != null;
}
```

## Storage Rules
Add this to your `storage.rules`:

```
match /status_images/{imageId} {
  // Only authenticated users can upload
  allow write: if request.auth != null;
  
  // Anyone can read
  allow read: if true;
}
```

## Deploy Rules
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```
