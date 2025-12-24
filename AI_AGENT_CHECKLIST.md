# ✅ AI Agent Premium Plan - Implementation Checklist

## 📋 Pre-Deployment Checklist

### 1. Code Configuration
- [ ] **Update JotForm URL** in `lib/screens/ai_agent_screen.dart` (line 11)
  ```dart
  final String jotFormUrl = "https://form.jotform.com/YOUR_FORM_ID";
  ```
  Replace with your actual JotForm AI Agent URL

- [ ] **Verify PayHere Credentials** in `lib/services/payhere_service.dart`
  - [ ] Merchant ID is correct
  - [ ] Merchant Secret is correct
  - [ ] Set `isSandbox = false` for production

### 2. Firebase Configuration
- [ ] **Deploy Firestore Rules**
  ```powershell
  firebase deploy --only firestore:rules
  ```
  
- [ ] **Verify Rules Deployed**
  - Open Firebase Console
  - Go to Firestore → Rules
  - Check that AI agent fields are allowed

- [ ] **Test Firestore Connection**
  - Run app
  - Check if user data loads correctly

### 3. Testing (Sandbox/Development)

#### Test 1: Premium Screen Display
- [ ] Open app
- [ ] Navigate to "AIagent" tab
- [ ] Should show Premium Plans screen
- [ ] AI Agent plan shows "1000 Credits" with "20 minutes" subtitle
- [ ] AI Agent plan shows "2500 Credits" with "45 minutes" subtitle

#### Test 2: Purchase Flow (1000 Credits)
- [ ] Select "AI Agent" plan
- [ ] Click "1000 Credits"
- [ ] Click "Continue"
- [ ] Fill payment form
- [ ] Complete payment (use test card)
- [ ] Payment success dialog shows
- [ ] Check Firestore → `users/{userId}`:
  - [ ] `planType` = "AI_1000"
  - [ ] `aiTotalSeconds` = 1200
  - [ ] `aiUsedSeconds` = 0
  - [ ] `aiEnabled` = true
  - [ ] `package` = "AI Agent"

#### Test 3: Purchase Flow (2500 Credits)
- [ ] Repeat above with "2500 Credits"
- [ ] Check Firestore:
  - [ ] `planType` = "AI_2500"
  - [ ] `aiTotalSeconds` = 2700

#### Test 4: AI Agent Access
- [ ] After successful purchase
- [ ] Navigate to "AIagent" tab
- [ ] Should now show AI Agent screen (not Premium)
- [ ] Timer appears in top-right
- [ ] Progress bar shows
- [ ] JotForm loads in iframe

#### Test 5: Time Tracking
- [ ] Open AI Agent screen
- [ ] Note start time
- [ ] Use for 30 seconds
- [ ] Press back button
- [ ] Check Firestore → `aiUsedSeconds`
- [ ] Should be approximately 30 seconds

#### Test 6: Timer Display
- [ ] Timer shows correct format (MM:SS)
- [ ] Timer counts down every second
- [ ] Progress bar updates
- [ ] When < 5 minutes: Timer turns red

#### Test 7: Background Handling
- [ ] Open AI Agent
- [ ] Press home button (app goes background)
- [ ] Wait 10 seconds
- [ ] Return to app
- [ ] Check Firestore → `aiUsedSeconds` updated

#### Test 8: Time Limit
**Option A: Wait for actual time**
- [ ] Use AI Agent until time runs out
- [ ] "Time Finished" dialog appears
- [ ] Check Firestore:
  - [ ] `aiUsedSeconds` = `aiTotalSeconds`
  - [ ] `aiEnabled` = false

**Option B: Quick test (modify code)**
- [ ] Temporarily set `remainingSeconds = 30` in code
- [ ] Wait 30 seconds
- [ ] Dialog appears
- [ ] Access disabled
- [ ] **Revert code change!**

#### Test 9: Access After Time Finished
- [ ] After time runs out
- [ ] Close app
- [ ] Reopen app
- [ ] Try to open AI Agent
- [ ] Should show "Your AI minutes are finished" error
- [ ] Navigate returns to previous screen

#### Test 10: Multiple Sessions
- [ ] Use AI Agent for 1 minute
- [ ] Exit and close
- [ ] Reopen AI Agent
- [ ] Timer should show reduced time
- [ ] Usage accumulates correctly

### 4. Edge Cases Testing
- [ ] **No Internet During Use**
  - Disconnect WiFi
  - Use AI Agent
  - Reconnect
  - Time should save when connection restored

- [ ] **Force Close App**
  - Open AI Agent
  - Force close app (swipe away)
  - Reopen app
  - Some time should be saved

- [ ] **Multiple Devices**
  - Login on Device A
  - Use AI Agent
  - Login on Device B
  - Time should sync

- [ ] **Expired Subscription**
  - Manually set expiry date to past
  - Check if access is blocked

### 5. UI/UX Testing
- [ ] **Timer Visibility**
  - Timer is clearly visible
  - Easy to read
  - Updates smoothly

- [ ] **Progress Bar**
  - Shows correct percentage
  - Smooth animation
  - Color changes at < 5 min

- [ ] **Error Messages**
  - Clear and helpful
  - Proper formatting
  - Action buttons work

- [ ] **Navigation**
  - Back button works
  - Bottom nav works
  - No navigation bugs

### 6. Performance Testing
- [ ] **App Performance**
  - No lag during timer countdown
  - Smooth iframe scrolling
  - No memory leaks

- [ ] **Firestore Writes**
  - Usage saves efficiently
  - No excessive writes
  - Batch updates work

### 7. Security Testing
- [ ] **Firestore Rules**
  - Can only update own user
  - Can't bypass time limit
  - Can't modify others' data

- [ ] **Payment Security**
  - Payment records created correctly
  - No duplicate charges
  - Transaction IDs unique

### 8. Documentation Review
- [ ] Read `AI_AGENT_IMPLEMENTATION_COMPLETE.md`
- [ ] Read `AI_AGENT_QUICK_START.md`
- [ ] Read `AI_AGENT_PREMIUM_SETUP.md`
- [ ] Read `AI_AGENT_VISUAL_GUIDE.md`
- [ ] Understand complete flow

### 9. Production Preparation
- [ ] **JotForm URL**
  - [ ] Production JotForm URL configured
  - [ ] JotForm tested and working

- [ ] **PayHere**
  - [ ] Switch to production mode (`isSandbox = false`)
  - [ ] Test with real payment (small amount)
  - [ ] Verify payment webhook

- [ ] **Firebase**
  - [ ] Firestore rules deployed to production
  - [ ] Indexes created if needed
  - [ ] Backup strategy in place

- [ ] **App Build**
  - [ ] Build for Android/iOS
  - [ ] Test on real devices
  - [ ] Version number updated

### 10. Post-Deployment Monitoring
- [ ] **Monitor Usage**
  - Check Firestore for AI purchases
  - Monitor `aiUsedSeconds` values
  - Check for errors

- [ ] **User Feedback**
  - Collect user feedback
  - Monitor support tickets
  - Fix issues quickly

- [ ] **Analytics**
  - Track AI Agent usage
  - Monitor time limits
  - Analyze purchase patterns

---

## 🚀 Launch Readiness

### Required Before Launch:
✅ All tests passed  
✅ JotForm URL updated  
✅ PayHere in production mode  
✅ Firestore rules deployed  
✅ Documentation reviewed  
✅ Team trained  

### Optional But Recommended:
✅ Analytics integrated  
✅ Error tracking (Sentry/Crashlytics)  
✅ User feedback system  
✅ Support documentation  

---

## 📊 Success Metrics

### Week 1 Goals:
- [ ] X AI Agent plans sold
- [ ] Average usage: Y minutes
- [ ] Zero critical bugs
- [ ] 95%+ uptime

### Month 1 Goals:
- [ ] Revenue from AI plans: LKR XXXXX
- [ ] User retention: 80%+
- [ ] Time tracking accuracy: 99%+
- [ ] Support tickets: < 5%

---

## 🎯 Final Check

Before going live, confirm:
- [ ] ✅ All code reviewed
- [ ] ✅ All tests passed
- [ ] ✅ All configurations correct
- [ ] ✅ All documentation complete
- [ ] ✅ Team ready to support
- [ ] ✅ Monitoring in place

**If all checked ✅ → You're ready to launch! 🚀**

---

## 📞 Emergency Contacts

### If Issues Occur:
1. Check Firestore logs
2. Check app console logs
3. Review error messages
4. Rollback if critical

### Common Quick Fixes:
- **Timer not showing**: Check Firestore fields
- **Access denied**: Check `aiEnabled` flag
- **Payment not working**: Check PayHere credentials
- **JotForm not loading**: Check URL and internet

---

**Good luck with your launch! 🎉**
