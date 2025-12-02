#!/usr/bin/env pwsh
# EnglishCircle - Firebase Setup Script for Google Sign-In

Write-Host "🚀 EnglishCircle - Google Sign-In Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get SHA-1 Fingerprint
Write-Host "📱 Step 1: Getting SHA-1 Fingerprint..." -ForegroundColor Yellow
Write-Host "Running gradlew signingReport..." -ForegroundColor Gray
Set-Location "android"
$signingReport = .\gradlew.bat signingReport 2>&1

# Extract SHA-1
$sha1 = $signingReport | Select-String -Pattern "SHA1: (.+)" | ForEach-Object { $_.Matches.Groups[1].Value }

if ($sha1) {
    Write-Host "✅ SHA-1 Fingerprint Found!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your SHA-1:" -ForegroundColor Cyan
    Write-Host $sha1 -ForegroundColor White
    Write-Host ""
    
    # Copy to clipboard
    Set-Clipboard -Value $sha1
    Write-Host "📋 Copied to clipboard!" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "❌ Could not find SHA-1. Please run manually:" -ForegroundColor Red
    Write-Host "   cd android" -ForegroundColor Gray
    Write-Host "   .\gradlew.bat signingReport" -ForegroundColor Gray
    Write-Host ""
}

Set-Location ".."

# Step 2: Firebase Instructions
Write-Host "🔥 Step 2: Configure Firebase Console" -ForegroundColor Yellow
Write-Host ""
Write-Host "Please complete these steps:" -ForegroundColor Cyan
Write-Host "  1. Open https://console.firebase.google.com/" -ForegroundColor White
Write-Host "  2. Select your project" -ForegroundColor White
Write-Host "  3. Go to Project Settings (gear icon)" -ForegroundColor White
Write-Host "  4. Scroll to 'Your apps' → Click Android app" -ForegroundColor White
Write-Host "  5. Paste SHA-1 fingerprint (already in clipboard!)" -ForegroundColor White
Write-Host "  6. Download new google-services.json" -ForegroundColor White
Write-Host "  7. Replace: android\app\google-services.json" -ForegroundColor White
Write-Host ""
Write-Host "  8. Go to Authentication → Sign-in method" -ForegroundColor White
Write-Host "  9. Enable 'Google' provider" -ForegroundColor White
Write-Host "  10. Click Save" -ForegroundColor White
Write-Host ""

# Wait for user confirmation
Read-Host "Press Enter when you've completed the Firebase steps..."

# Step 3: Install Dependencies
Write-Host ""
Write-Host "📦 Step 3: Installing Dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencies installed!" -ForegroundColor Green
}
else {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Step 4: Check devices
Write-Host ""
Write-Host "📱 Step 4: Checking Connected Devices..." -ForegroundColor Yellow
$devices = flutter devices

Write-Host $devices
Write-Host ""

# Step 5: Ready to run
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "To run the app:" -ForegroundColor Cyan
Write-Host "  flutter run -d <DEVICE_ID>" -ForegroundColor White
Write-Host ""
Write-Host "Example:" -ForegroundColor Cyan
Write-Host "  flutter run -d R9YR8086S5T" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Important:" -ForegroundColor Yellow
Write-Host "  • Google Sign-In requires a REAL Android device" -ForegroundColor White
Write-Host "  • Device must have Google account signed in" -ForegroundColor White
Write-Host "  • Emulators won't work properly" -ForegroundColor White
Write-Host ""
Write-Host "📚 For more info, see:" -ForegroundColor Cyan
Write-Host "  • IMPLEMENTATION_SUMMARY.md" -ForegroundColor White
Write-Host "  • GOOGLE_SIGNIN_SETUP.md" -ForegroundColor White
Write-Host ""
