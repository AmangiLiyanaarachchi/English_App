# 🎓 Firebase Student Database Setup - Quick Guide

## Step 1️⃣: Update Firestore Security Rules

✅ **Already Done!** The `firestore.rules` file has been updated.

### Deploy the rules:
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Click "Firestore Database" → "Rules"
4. Copy the content from `firestore.rules` file
5. Paste it in the Firebase Console
6. Click "Publish"

## Step 2️⃣: Create Students Collection with Dummy Data

### Option A: Using Firebase Console (Recommended for Testing)

#### 1. Navigate to Firestore
- Go to Firebase Console
- Click "Firestore Database"
- Click "Start collection" (if first time) or click the "+" next to an existing collection

#### 2. Create Collection
- **Collection ID**: `students`
- Click "Next"

#### 3. Add First Document (STU001 - Active Student)

**Document ID**: `STU001`

Click "Add field" for each field:

| Field Name | Type | Value |
|------------|------|-------|
| studentId | string | STU001 |
| startDate | timestamp | January 1, 2026, 12:00:00 AM UTC |
| endDate | timestamp | December 31, 2026, 11:59:59 PM UTC |
| instituteName | string | Test University |
| status | string | active |

Click "Save"

#### 4. Add Second Document (STU002 - Active Student)

Click "Add document" in students collection

**Document ID**: `STU002`

| Field Name | Type | Value |
|------------|------|-------|
| studentId | string | STU002 |
| startDate | timestamp | January 15, 2026, 12:00:00 AM UTC |
| endDate | timestamp | June 30, 2026, 11:59:59 PM UTC |
| instituteName | string | Sample College |
| status | string | active |

Click "Save"

#### 5. Add Third Document (STU003 - Expired Student for Testing)

Click "Add document" in students collection

**Document ID**: `STU003`

| Field Name | Type | Value |
|------------|------|-------|
| studentId | string | STU003 |
| startDate | timestamp | January 1, 2025, 12:00:00 AM UTC |
| endDate | timestamp | December 31, 2025, 11:59:59 PM UTC |
| instituteName | string | Old University |
| status | string | expired |

Click "Save"

#### 6. Add Fourth Document (STU004 - Future Student for Testing)

Click "Add document" in students collection

**Document ID**: `STU004`

| Field Name | Type | Value |
|------------|------|-------|
| studentId | string | STU004 |
| startDate | timestamp | March 1, 2026, 12:00:00 AM UTC |
| endDate | timestamp | August 31, 2026, 11:59:59 PM UTC |
| instituteName | string | Future Institute |
| status | string | pending |

Click "Save"

---

### Option B: Using Firebase Admin Script (For Bulk Import)

If you need to add many students, save this as `add_students.js`:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const students = [
  {
    studentId: 'STU001',
    startDate: new Date('2026-01-01T00:00:00Z'),
    endDate: new Date('2026-12-31T23:59:59Z'),
    instituteName: 'Test University',
    status: 'active'
  },
  {
    studentId: 'STU002',
    startDate: new Date('2026-01-15T00:00:00Z'),
    endDate: new Date('2026-06-30T23:59:59Z'),
    instituteName: 'Sample College',
    status: 'active'
  },
  {
    studentId: 'STU003',
    startDate: new Date('2025-01-01T00:00:00Z'),
    endDate: new Date('2025-12-31T23:59:59Z'),
    instituteName: 'Old University',
    status: 'expired'
  },
  {
    studentId: 'STU004',
    startDate: new Date('2026-03-01T00:00:00Z'),
    endDate: new Date('2026-08-31T23:59:59Z'),
    instituteName: 'Future Institute',
    status: 'pending'
  }
];

async function addStudents() {
  const batch = db.batch();
  
  students.forEach(student => {
    const docRef = db.collection('students').doc(student.studentId);
    batch.set(docRef, student);
  });
  
  await batch.commit();
  console.log('✅ All students added successfully!');
}

addStudents().catch(console.error);
```

Run with: `node add_students.js`

---

## Step 3️⃣: Verify Setup

### Check in Firebase Console:
1. Go to Firestore Database
2. You should see "students" collection
3. Click on it to see 4 documents: STU001, STU002, STU003, STU004

### Your database should look like this:
```
Firestore Database
├── students
│   ├── STU001 (Active ✅)
│   ├── STU002 (Active ✅)
│   ├── STU003 (Expired ❌)
│   └── STU004 (Future ⏰)
├── users
├── chatRooms
└── ... (other collections)
```

---

## Step 4️⃣: Test in App

1. **Run the app**
2. **Login** with your account
3. **Go to Profile** screen
4. **Scroll down** to "Other" section
5. **Tap "Student Verification"**
6. **Try these test cases:**

| Test Case | Student ID | Expected Result |
|-----------|------------|----------------|
| 1 | STU001 | ✅ Success - Community Plan activated |
| 2 | STU002 | ✅ Success - Community Plan activated |
| 3 | STU003 | ❌ Failed - Expired |
| 4 | STU004 | ❌ Failed - Not yet active (starts March 2026) |
| 5 | INVALID | ❌ Failed - Not found |
| 6 | (empty) | ❌ Failed - No input |

---

## 📊 Database Structure Reference

```
students/{studentId}
├── studentId: string           // Same as document ID
├── startDate: timestamp         // When access starts
├── endDate: timestamp           // When access expires
├── instituteName: string        // University/College name
└── status: string              // "active", "expired", "pending"
```

---

## 🔒 Security Rules Summary

✅ **Students Collection:**
- ✓ Any authenticated user can READ (for verification)
- ✗ NO ONE can WRITE (admin only via console)

✅ **Users Collection:**
- ✓ Can update student verification fields on own profile

---

## 🎯 Quick Checklist

- [ ] Deploy updated firestore.rules to Firebase Console
- [ ] Create "students" collection
- [ ] Add STU001 (active)
- [ ] Add STU002 (active)
- [ ] Add STU003 (expired)
- [ ] Add STU004 (future)
- [ ] Test in app with STU001
- [ ] Verify Community Plan activated
- [ ] Check Firebase to see user profile updated

---

## ❓ Troubleshooting

**Issue**: Can't see "Student Verification" button
- **Solution**: Make sure you're on your own profile and not already verified

**Issue**: "Permission denied" error
- **Solution**: Make sure you deployed the updated firestore.rules

**Issue**: "Invalid student ID"
- **Solution**: Check that document ID matches exactly (case-insensitive)

**Issue**: Student ID works but plan not activated
- **Solution**: Check console logs for errors, verify dates are in correct format

---

## 📝 Next Steps

After testing with dummy data:

1. ✅ Remove or update dummy data
2. ✅ Add real student IDs from your institution
3. ✅ Set appropriate date ranges
4. ✅ Monitor student verifications in Firebase Console
5. ✅ Set up automatic expiry notifications (optional)

---

**🎉 You're all set! The student verification system is ready to use!**
