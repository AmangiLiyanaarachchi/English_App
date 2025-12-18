# PayHere Payment Gateway - Quick Test Script
# Run this after app is running

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   PayHere Payment Gateway Test Helper" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ PayHere Integration Status: READY" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Sandbox Credentials:" -ForegroundColor Yellow
Write-Host "   Merchant ID: 1233181" -ForegroundColor White
Write-Host "   Mode: SANDBOX (Test Mode)" -ForegroundColor White
Write-Host ""

Write-Host "💳 Test Cards:" -ForegroundColor Yellow
Write-Host "   Visa:       4916 2175 0161 1292" -ForegroundColor White
Write-Host "   MasterCard: 5413 3194 8802 2428" -ForegroundColor White
Write-Host "   Expiry:     12/25 (any future date)" -ForegroundColor White
Write-Host "   CVV:        123 (any 3 digits)" -ForegroundColor White
Write-Host ""

Write-Host "🎯 Testing Steps:" -ForegroundColor Yellow
Write-Host "   1. Open app → Navigate to Premium tab" -ForegroundColor White
Write-Host "   2. Select a plan (Community / AI Agent / Both)" -ForegroundColor White
Write-Host "   3. Choose duration (1 Week or 6 Months)" -ForegroundColor White
Write-Host "   4. Click CONTINUE button" -ForegroundColor White
Write-Host "   5. Fill payment form:" -ForegroundColor White
Write-Host "      - First Name: Test" -ForegroundColor Gray
Write-Host "      - Last Name: User" -ForegroundColor Gray
Write-Host "      - Email: test@example.com" -ForegroundColor Gray
Write-Host "      - Phone: 771234567" -ForegroundColor Gray
Write-Host "   6. Click PAY NOW" -ForegroundColor White
Write-Host "   7. Use test card above" -ForegroundColor White
Write-Host "   8. Complete payment" -ForegroundColor White
Write-Host "   9. Verify features unlock!" -ForegroundColor White
Write-Host ""

Write-Host "📱 Feature Access:" -ForegroundColor Yellow
Write-Host "   Community Plan      → Unlocks Chat tab" -ForegroundColor White
Write-Host "   AI Agent            → Unlocks AI Agent tab" -ForegroundColor White
Write-Host "   Community + AI      → Unlocks BOTH tabs" -ForegroundColor White
Write-Host ""

Write-Host "🔍 Verification:" -ForegroundColor Yellow
Write-Host "   After payment, check:" -ForegroundColor White
Write-Host "   ✓ Success dialog appears" -ForegroundColor Green
Write-Host "   ✓ Can access unlocked tabs" -ForegroundColor Green
Write-Host "   ✓ Firestore users collection updated" -ForegroundColor Green
Write-Host "   ✓ Firestore payments collection has record" -ForegroundColor Green
Write-Host ""

Write-Host "⚠️  Important:" -ForegroundColor Red
Write-Host "   - All payments in SANDBOX mode" -ForegroundColor Yellow
Write-Host "   - NO REAL MONEY charged" -ForegroundColor Yellow
Write-Host "   - Test cards always succeed" -ForegroundColor Yellow
Write-Host "   - Unlimited testing!" -ForegroundColor Yellow
Write-Host ""

Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "   - Setup Guide: PAYHERE_SETUP_GUIDE.md" -ForegroundColor White
Write-Host "   - Testing Checklist: PAYHERE_TESTING_CHECKLIST.md" -ForegroundColor White
Write-Host "   - Quick Summary: PAYHERE_QUICK_SUMMARY.md" -ForegroundColor White
Write-Host ""

Write-Host "🚀 Ready to test? Run the app:" -ForegroundColor Cyan
Write-Host "   flutter run" -ForegroundColor White
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Happy Testing! 🎉" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Ask if user wants to run the app
$run = Read-Host "Start the app now? (y/n)"
if ($run -eq "y" -or $run -eq "Y") {
    Write-Host ""
    Write-Host "Starting Flutter app..." -ForegroundColor Green
    flutter run
}
else {
    Write-Host ""
    Write-Host "To start later, run: flutter run" -ForegroundColor Yellow
    Write-Host ""
}
