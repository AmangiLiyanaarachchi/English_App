# Random Call Limit - Deployment Script
# Run this script to deploy Firestore rules and test the feature

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Random Call Limit System - Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if Firebase CLI is installed
Write-Host "Step 1: Checking Firebase CLI..." -ForegroundColor Yellow
$firebaseVersion = firebase --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Firebase CLI not found!" -ForegroundColor Red
    Write-Host "Install it with: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}
else {
    Write-Host "✅ Firebase CLI installed: $firebaseVersion" -ForegroundColor Green
}
Write-Host ""

# Step 2: Login check
Write-Host "Step 2: Checking Firebase login..." -ForegroundColor Yellow
firebase projects:list 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not logged in to Firebase" -ForegroundColor Red
    Write-Host "Running: firebase login" -ForegroundColor Yellow
    firebase login
}
else {
    Write-Host "✅ Already logged in to Firebase" -ForegroundColor Green
}
Write-Host ""

# Step 3: Deploy Firestore Rules
Write-Host "Step 3: Deploying Firestore Rules..." -ForegroundColor Yellow
Write-Host "This will update your Firestore security rules to support random call tracking" -ForegroundColor White
$confirm = Read-Host "Do you want to deploy Firestore rules? (y/n)"
if ($confirm -eq 'y' -or $confirm -eq 'Y') {
    firebase deploy --only firestore:rules
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Firestore rules deployed successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Failed to deploy Firestore rules" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "⏭️  Skipped Firestore rules deployment" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 What's Implemented:" -ForegroundColor Green
Write-Host "  ✅ 3-minute timer per random call" -ForegroundColor White
Write-Host "  ✅ 3 random calls maximum per user" -ForegroundColor White
Write-Host "  ✅ Auto-disable after limit reached" -ForegroundColor White
Write-Host "  ✅ Call count tracking in Firestore" -ForegroundColor White
Write-Host ""
Write-Host "📁 Files Created/Updated:" -ForegroundColor Green
Write-Host "  • lib/services/random_call_service.dart (NEW)" -ForegroundColor White
Write-Host "  • lib/screens/voice_call_screen.dart (UPDATED)" -ForegroundColor White
Write-Host "  • lib/screens/home_screen.dart (UPDATED)" -ForegroundColor White
Write-Host "  • firestore.rules (UPDATED)" -ForegroundColor White
Write-Host "  • RANDOM_CALL_LIMIT_SETUP.md (NEW)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Run your Flutter app: flutter run" -ForegroundColor White
Write-Host "  2. Test random calls (each call limited to 3 minutes)" -ForegroundColor White
Write-Host "  3. Make 3 random calls to test the limit" -ForegroundColor White
Write-Host "  4. After 3 calls, button should be disabled" -ForegroundColor White
Write-Host ""
Write-Host "📖 For detailed documentation, see: RANDOM_CALL_LIMIT_SETUP.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "🐛 Testing Tips:" -ForegroundColor Yellow
Write-Host "  • Each call auto-ends at 3 minutes" -ForegroundColor White
Write-Host "  • Only connected calls count toward limit" -ForegroundColor White
Write-Host "  • Check Firebase Console to see randomCallCount field" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
