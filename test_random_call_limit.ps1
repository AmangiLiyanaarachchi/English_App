# Test Random Call Limit Feature
# This script helps you test the random call limit system

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Random Call Limit - Test Guide" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🧪 Test Scenarios:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1️⃣  Test 3-Minute Auto-End Timer" -ForegroundColor Green
Write-Host "   ----------------------------------------" -ForegroundColor DarkGray
Write-Host "   Steps:" -ForegroundColor White
Write-Host "   • Start a random call" -ForegroundColor White
Write-Host "   • Wait for 3 minutes (180 seconds)" -ForegroundColor White
Write-Host "   • Call should automatically end" -ForegroundColor White
Write-Host "   • You should see: 'Call ended - 3 minute limit reached'" -ForegroundColor White
Write-Host ""
Write-Host "   ✅ Expected: Call ends exactly at 3:00" -ForegroundColor Green
Write-Host "   ❌ If not working: Check VoiceCallScreen logs" -ForegroundColor Red
Write-Host ""

Write-Host "2️⃣  Test Call Count Tracking" -ForegroundColor Green
Write-Host "   ----------------------------------------" -ForegroundColor DarkGray
Write-Host "   Steps:" -ForegroundColor White
Write-Host "   • Make 1st random call → Should see 'Random calls remaining: 2'" -ForegroundColor White
Write-Host "   • Make 2nd random call → Should see 'Random calls remaining: 1'" -ForegroundColor White
Write-Host "   • Make 3rd random call → Should see 'Random calls remaining: 0'" -ForegroundColor White
Write-Host ""
Write-Host "   ✅ Expected: Counter decrements after each call" -ForegroundColor Green
Write-Host "   ❌ If not working: Check Firestore randomCallCount field" -ForegroundColor Red
Write-Host ""

Write-Host "3️⃣  Test Auto-Disable After 3 Calls" -ForegroundColor Green
Write-Host "   ----------------------------------------" -ForegroundColor DarkGray
Write-Host "   Steps:" -ForegroundColor White
Write-Host "   • Make 3 random calls (complete them)" -ForegroundColor White
Write-Host "   • Try to make 4th call" -ForegroundColor White
Write-Host "   • Should see dialog: 'Random Call Limit Reached'" -ForegroundColor White
Write-Host "   • Button should show error message" -ForegroundColor White
Write-Host ""
Write-Host "   ✅ Expected: Cannot make 4th call" -ForegroundColor Green
Write-Host "   ❌ If not working: Check randomCallEnabled field in Firestore" -ForegroundColor Red
Write-Host ""

Write-Host "4️⃣  Test Cancelled Calls Don't Count" -ForegroundColor Green
Write-Host "   ----------------------------------------" -ForegroundColor DarkGray
Write-Host "   Steps:" -ForegroundColor White
Write-Host "   • Start a random call" -ForegroundColor White
Write-Host "   • End call immediately (before connecting)" -ForegroundColor White
Write-Host "   • Counter should NOT increase" -ForegroundColor White
Write-Host ""
Write-Host "   ✅ Expected: Only connected calls count" -ForegroundColor Green
Write-Host "   ❌ If not working: Check _callDuration > 0 logic" -ForegroundColor Red
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 How to Check Firestore Data:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open Firebase Console: https://console.firebase.google.com" -ForegroundColor White
Write-Host "2. Go to Firestore Database" -ForegroundColor White
Write-Host "3. Navigate to: users → [your_user_id]" -ForegroundColor White
Write-Host "4. Check these fields:" -ForegroundColor White
Write-Host "   • randomCallCount: should be 0-3" -ForegroundColor Cyan
Write-Host "   • randomCallEnabled: should be true/false" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔄 How to Reset Call Count (for testing):" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Firestore Console" -ForegroundColor Green
Write-Host "  • Go to users → [your_user_id]" -ForegroundColor White
Write-Host "  • Set randomCallCount = 0" -ForegroundColor White
Write-Host "  • Set randomCallEnabled = true" -ForegroundColor White
Write-Host ""
Write-Host "Option 2: Add Debug Button (Developer Only)" -ForegroundColor Green
Write-Host "  • Add this code to your app:" -ForegroundColor White
Write-Host ""
Write-Host "    ElevatedButton(" -ForegroundColor Cyan
Write-Host "      onPressed: () async {" -ForegroundColor Cyan
Write-Host "        final userId = FirebaseAuth.instance.currentUser?.uid;" -ForegroundColor Cyan
Write-Host "        if (userId != null) {" -ForegroundColor Cyan
Write-Host "          await RandomCallService().resetRandomCallCount(userId);" -ForegroundColor Cyan
Write-Host "          print('✅ Call count reset!');" -ForegroundColor Cyan
Write-Host "        }" -ForegroundColor Cyan
Write-Host "      }," -ForegroundColor Cyan
Write-Host "      child: Text('Reset Random Calls (DEBUG)')," -ForegroundColor Cyan
Write-Host "    )" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📊 Expected Behavior Summary:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Call #  | Duration Limit | Remaining | Can Call?" -ForegroundColor White
Write-Host "--------|----------------|-----------|------------" -ForegroundColor DarkGray
Write-Host "   1    |   3 minutes    |     2     |     ✅     " -ForegroundColor White
Write-Host "   2    |   3 minutes    |     1     |     ✅     " -ForegroundColor White
Write-Host "   3    |   3 minutes    |     0     |     ✅     " -ForegroundColor White
Write-Host "   4    |      N/A       |     0     |     ❌     " -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🐛 Troubleshooting:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Problem: Timer not working" -ForegroundColor Red
Write-Host "  → Check: isRandomCall=true passed to VoiceCallScreen" -ForegroundColor White
Write-Host "  → Check: Console logs for '⏱️ 3-minute timer started'" -ForegroundColor White
Write-Host ""
Write-Host "Problem: Call count not incrementing" -ForegroundColor Red
Write-Host "  → Check: Firestore rules deployed correctly" -ForegroundColor White
Write-Host "  → Check: User authenticated" -ForegroundColor White
Write-Host "  → Check: Call duration > 0 (call was connected)" -ForegroundColor White
Write-Host ""
Write-Host "Problem: Still can call after 3 calls" -ForegroundColor Red
Write-Host "  → Check: randomCallEnabled=false in Firestore" -ForegroundColor White
Write-Host "  → Check: randomCallCount=3 in Firestore" -ForegroundColor White
Write-Host "  → Try: Restart the app" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Ready to Test!" -ForegroundColor Green
Write-Host ""
Write-Host "Run your app with: flutter run" -ForegroundColor Cyan
Write-Host ""
Write-Host "Happy Testing! 🎉" -ForegroundColor Yellow
Write-Host ""
