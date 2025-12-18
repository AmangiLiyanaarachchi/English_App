# PayHere Payment Testing Checklist

## 🧪 Testing Instructions

### Test Environment
- Mode: **Sandbox** (No real money charged)
- Merchant ID: 1233181
- Test Cards Available (Use any of these)

### 📝 Test Scenarios

#### ✅ Test 1: Community Plan (1 Week - LKR 100)
1. Navigate to Premium tab
2. Select "Community Plan"
3. Select "1 Week" duration
4. Click CONTINUE
5. Fill payment form:
   - First Name: Test
   - Last Name: User
   - Email: test@example.com
   - Phone: 771234567
6. Click PAY NOW
7. Use test card:
   - Card: `4916 2175 0161 1292`
   - Expiry: `12/25`
   - CVV: `123`
8. Complete payment
9. **Expected Result:**
   - ✅ Payment success dialog shows
   - ✅ Navigate to home screen
   - ✅ Chat tab is accessible
   - ✅ AI Agent tab shows "Premium Feature" dialog

---

#### ✅ Test 2: AI Agent (1 Week - LKR 100)
1. Navigate to Premium tab
2. Select "AI Agent"
3. Select "1 Week" duration
4. Click CONTINUE
5. Fill payment form
6. Click PAY NOW
7. Use test card: `5413 3194 8802 2428`
8. Complete payment
9. **Expected Result:**
   - ✅ Payment success dialog shows
   - ✅ AI Agent tab is accessible
   - ✅ Chat tab shows "Premium Feature" dialog

---

#### ✅ Test 3: Community + AI Agent (1 Week - LKR 100)
1. Navigate to Premium tab
2. Select "Community + AI Agent"
3. Select "1 Week" duration
4. Click CONTINUE
5. Fill payment form
6. Click PAY NOW
7. Complete payment
8. **Expected Result:**
   - ✅ Payment success dialog shows
   - ✅ Both Chat and AI Agent tabs are accessible
   - ✅ No premium dialogs shown

---

### 🔍 Verification Steps

#### Check Firestore Data
1. Open Firebase Console
2. Go to Firestore Database
3. Check `users` collection for your user:
   ```
   Should contain:
   - package: "Community + AI Agent" (or selected plan)
   - paymentStatus: "paid"
   - unlockedFeatures: ["community", "ai_agent"] (or based on plan)
   - expiryDate: (7 days from payment date)
   - price: 100
   ```
4. Check `payments` collection:
   ```
   Should have new document with:
   - orderId: "ORDER_xxxxxxxxxx"
   - paymentId: (from PayHere)
   - status: "paid"
   - amount: 100
   - currency: "LKR"
   ```

---

### 🚫 Test Payment Cancellation
1. Start payment process
2. Click PAY NOW
3. Click "Cancel" or back button in PayHere
4. **Expected Result:**
   - ✅ Return to payment screen
   - ✅ No features unlocked
   - ✅ No payment record created

---

### ⏰ Test Subscription Expiry (Manual)
1. Complete a payment
2. In Firestore, manually update `expiryDate` to yesterday
3. Restart app
4. Try to access premium feature
5. **Expected Result:**
   - ✅ Feature is locked
   - ✅ Shows "Premium Feature" dialog
   - ✅ `paymentStatus` updates to "expired"

---

### 📱 Test Cards

#### Visa Cards
```
Card Number: 4916 2175 0161 1292
Expiry: Any future date (e.g., 12/25)
CVV: Any 3 digits (e.g., 123)
Name: Any name
```

#### MasterCard
```
Card Number: 5413 3194 8802 2428
Expiry: Any future date
CVV: Any 3 digits
Name: Any name
```

---

### 🐛 Common Issues & Solutions

#### Issue: "Payment Failed"
**Solution:** 
- Check internet connection
- Verify test card number is correct
- Try different test card

#### Issue: Features not unlocking
**Solution:**
- Check Firestore `users` collection
- Verify `unlockedFeatures` array exists
- Restart the app

#### Issue: PayHere not opening
**Solution:**
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild the app

#### Issue: Tab navigation not working
**Solution:**
- Check console logs for errors
- Verify user is logged in
- Check Firestore security rules

---

### 📊 Test Results Template

Use this template to record your test results:

```
Test Date: _______________
Tester: _______________

[ ] Test 1: Community Plan - PASS / FAIL
    Notes: _______________________________

[ ] Test 2: AI Agent - PASS / FAIL
    Notes: _______________________________

[ ] Test 3: Community + AI Agent - PASS / FAIL
    Notes: _______________________________

[ ] Test 4: Payment Cancellation - PASS / FAIL
    Notes: _______________________________

[ ] Test 5: Firestore Data Verification - PASS / FAIL
    Notes: _______________________________

[ ] Test 6: Feature Access Control - PASS / FAIL
    Notes: _______________________________

Overall Status: PASS / FAIL
Additional Notes:
_________________________________________
_________________________________________
```

---

### 🎯 Final Checks Before Production

- [ ] All test scenarios pass
- [ ] Firestore data is correct
- [ ] Feature access control works
- [ ] Payment cancellation works
- [ ] UI shows correct messages
- [ ] No console errors
- [ ] Update to production credentials
- [ ] Set `isSandbox = false`
- [ ] Test with small real payment
- [ ] Deploy to production

---

### 📞 Need Help?

If you encounter issues:
1. Check console logs
2. Check Firestore data
3. Review [PAYHERE_SETUP_GUIDE.md](PAYHERE_SETUP_GUIDE.md)
4. Contact PayHere support: https://www.payhere.lk/support

---

**Remember:** All sandbox payments are simulated. No real money is charged! 🎉
