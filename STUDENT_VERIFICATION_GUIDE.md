# Student ID Verification System - Setup Guide

## Overview
This system allows students to verify their student ID and automatically get access to the Community Plan for a specific period.

## 📋 Features
- ✅ Student ID verification against Firebase database
- ✅ Date range validation (start date and end date)
- ✅ Automatic Community Plan activation
- ✅ Student status tracking
- ✅ Secure verification process

## 🚀 Setup Instructions

### Step 1: Create Firebase Collection

1. **Go to Firebase Console**
   - Open: https://console.firebase.google.com/
   - Select your project
   - Navigate to: Firestore Database

2. **Create "students" Collection**
   - Click "Start collection" or "Add collection"
   - Collection ID: `students`

### Step 2: Add Test Student Records

Add these test documents (for testing):

#### **Document 1: STU001** (Active Student)
```
Document ID: STU001

Fields:
- studentId: "STU001" (string)
- startDate: 2026-01-01T00:00:00.000Z (timestamp)
- endDate: 2026-12-31T23:59:59.999Z (timestamp)
- instituteName: "Test University" (string)
- status: "active" (string)
```

#### **Document 2: STU002** (Active Student)
```
Document ID: STU002

Fields:
- studentId: "STU002" (string)
- startDate: 2026-01-15T00:00:00.000Z (timestamp)
- endDate: 2026-06-30T23:59:59.999Z (timestamp)
- instituteName: "Sample College" (string)
- status: "active" (string)
```

#### **Document 3: STU003** (Expired - for testing)
```
Document ID: STU003

Fields:
- studentId: "STU003" (string)
- startDate: 2025-01-01T00:00:00.000Z (timestamp)
- endDate: 2025-12-31T23:59:59.999Z (timestamp)
- instituteName: "Old University" (string)
- status: "expired" (string)
```

### Step 3: Update Firestore Security Rules

Add these rules to your `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Students collection - read-only for authenticated users
    match /students/{studentId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin can write
    }
    
    // Users collection - allow students to update their own profile
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ... your other rules
  }
}
```

## 📱 How to Use

### For Students:

1. **Open the App**
2. **Go to Profile Screen**
3. **Scroll down to "Other" section**
4. **Tap on "Student Verification"**
5. **Enter your Student ID** (e.g., STU001)
6. **Tap "Verify"**
7. **If valid**: Community Plan will be activated automatically! 🎉

### Student ID Format:
- Must match exactly with the Document ID in Firebase
- Case-insensitive (STU001 = stu001)
- Automatically converted to uppercase

## 🧪 Testing

### Test Cases:

| Student ID | Expected Result | Reason |
|------------|----------------|--------|
| STU001 | ✅ Success | Valid and active |
| STU002 | ✅ Success | Valid and active |
| STU003 | ❌ Failed | Expired (end date passed) |
| INVALID | ❌ Failed | Not found in database |
| (empty) | ❌ Failed | No input provided |

### What Happens After Verification:

1. ✅ **Student ID verified**
2. ✅ **Community Plan activated**
3. ✅ **User profile updated** with:
   - `package`: "Community Plan"
   - `studentId`: "STU001"
   - `studentIdVerified`: true
   - `studentPlanStartDate`: (from students table)
   - `studentPlanEndDate`: (from students table)
   - `studentVerifiedAt`: (current timestamp)

### After Expiry:

When the end date passes:
- The student can still see their verified status
- You can add logic to automatically disable the plan
- Admin can manually deactivate if needed

## 🔧 Adding New Students

### Method 1: Firebase Console (Manual)

1. Go to Firestore → students collection
2. Click "Add document"
3. Document ID: `[STUDENT_ID]` (e.g., "STU005")
4. Add fields:
   - `studentId`: "[STUDENT_ID]" (same as document ID)
   - `startDate`: [select date]
   - `endDate`: [select date]
   - `instituteName`: "University Name"
   - `status`: "active"
5. Click "Save"

### Method 2: Bulk Import (Advanced)

For importing many students at once, you can use:
- Firebase Admin SDK
- Cloud Functions
- Import/Export tool in Firebase Console

## 📊 Monitoring

### Check Student Status:

```dart
// In your code
final isActive = await StudentVerificationService().isStudentPlanActive(userId);
```

### View All Students:

Go to Firebase Console → Firestore → students collection

## 🛡️ Security Features

- ✅ Read-only access to students collection
- ✅ Only authenticated users can verify
- ✅ Automatic date validation
- ✅ User can only update their own profile
- ✅ Admin controls student database

## ❓ FAQ

**Q: Can students verify multiple times?**
A: Yes, but once verified, the "Student Verification" button won't show in the profile.

**Q: What if student ID is expired?**
A: The system will show an error message with the expiry date.

**Q: Can I change the validity period?**
A: Yes, edit the document in Firebase Console and update the `endDate`.

**Q: How do I deactivate a student?**
A: Use the deactivate function or update the `endDate` to a past date.

## 📝 Notes for Admins

- Always use UPPERCASE for student IDs (system auto-converts)
- Set realistic date ranges
- Monitor expiring students
- Regular cleanup of expired records
- Keep backup of student data

## 🎯 Next Steps

1. ✅ Create the students collection in Firebase
2. ✅ Add test student records (STU001, STU002)
3. ✅ Update security rules
4. ✅ Test with the app
5. ✅ Add real student data

---

**Need Help?** Check the Firebase Console for error logs or contact support.
