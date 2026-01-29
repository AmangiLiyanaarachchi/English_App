# Firebase Student ID Setup Guide

## Step 1: Create Students Collection in Firebase

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Click on "Firestore Database" in the left menu
4. Click "Start collection"
5. Collection ID: `students`

## Step 2: Add Dummy Student Records

Add these documents to test the system:

### Document 1: Active Student
- **Document ID**: `STU001`
- Fields:
  ```
  studentId: "STU001" (string)
  startDate: January 1, 2026 (timestamp)
  endDate: December 31, 2026 (timestamp)
  instituteName: "Test University" (string)
  status: "active" (string)
  ```

### Document 2: Active Student
- **Document ID**: `STU002`
- Fields:
  ```
  studentId: "STU002" (string)
  startDate: January 15, 2026 (timestamp)
  endDate: June 30, 2026 (timestamp)
  instituteName: "Sample College" (string)
  status: "active" (string)
  ```

### Document 3: Expired Student (for testing)
- **Document ID**: `STU003`
- Fields:
  ```
  studentId: "STU003" (string)
  startDate: January 1, 2025 (timestamp)
  endDate: December 31, 2025 (timestamp)
  instituteName: "Old University" (string)
  status: "expired" (string)
  ```

### Document 4: Future Student (for testing)
- **Document ID**: `STU004`
- Fields:
  ```
  studentId: "STU004" (string)
  startDate: March 1, 2026 (timestamp)
  endDate: August 31, 2026 (timestamp)
  instituteName: "Future Institute" (string)
  status: "pending" (string)
  ```

## Step 3: Add More Students (Template)

For each new student, create a document with this structure:

```
Document ID: [STUDENT_ID] (e.g., "STU005", "STUDENT123")

Fields:
- studentId: [STUDENT_ID] (string) - Same as Document ID
- startDate: [START_DATE] (timestamp) - When access begins
- endDate: [END_DATE] (timestamp) - When access expires
- instituteName: [INSTITUTE_NAME] (string) - Optional
- status: "active" (string)
```

## Step 4: Firestore Rules (Security)

Update your Firestore rules to protect student data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Students collection - read-only for authenticated users
    match /students/{studentId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin can write via Firebase Console
    }
    
    // Your other rules...
  }
}
```

## Testing

Use these student IDs to test:
- ✅ **STU001** - Should work (valid until Dec 2026)
- ✅ **STU002** - Should work (valid until June 2026)
- ❌ **STU003** - Should fail (expired)
- ❌ **STU004** - Should fail (not yet active - starts March 2026)
- ❌ **INVALID** - Should fail (doesn't exist)

## How to Add Students via Firebase Console

1. Click on the "students" collection
2. Click "Add document"
3. Enter the Document ID (student ID in uppercase)
4. Add fields one by one:
   - Click "Add field"
   - Enter field name and select type
   - For dates: select "timestamp" and choose date/time
5. Click "Save"

## How to Bulk Import (Advanced)

If you have many students, you can use Firebase Admin SDK or a script to import them.
