# Voice Call Audio Test Script
# Run this to clean build and test the voice call fixes

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Voice Call Audio Fix - Test Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to project directory
Set-Location "d:\English app argent\English_App"

Write-Host "Step 1: Cleaning project..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "Step 3: Building and running app..." -ForegroundColor Yellow
Write-Host "Please wait, this may take a few minutes..." -ForegroundColor Gray
Write-Host ""

flutter run

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Checklist:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[TEST 1] Make an outgoing call" -ForegroundColor White
Write-Host "  ✓ Should default to SPEAKER ON" -ForegroundColor Green
Write-Host "  ✓ Both users should hear each other" -ForegroundColor Green
Write-Host ""
Write-Host "[TEST 2] Receive an incoming call" -ForegroundColor White
Write-Host "  ✓ Should default to SPEAKER ON" -ForegroundColor Green
Write-Host "  ✓ Both users should hear each other" -ForegroundColor Green
Write-Host ""
Write-Host "[TEST 3] Toggle speaker button" -ForegroundColor White
Write-Host "  ✓ Should switch to earpiece (phone speaker)" -ForegroundColor Green
Write-Host "  ✓ Audio should still be clear" -ForegroundColor Green
Write-Host "  ✓ Toggle back to speaker should work" -ForegroundColor Green
Write-Host ""
Write-Host "[TEST 4] Mute/Unmute" -ForegroundColor White
Write-Host "  ✓ Mute should stop your audio" -ForegroundColor Green
Write-Host "  ✓ Other person should not hear you" -ForegroundColor Green
Write-Host "  ✓ Unmute should restore audio" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Expected Log Messages:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ 'Speaker enabled after 300ms delay'" -ForegroundColor Green
Write-Host "✓ 'Speaker enabled - attempt 1, result: 0'" -ForegroundColor Green
Write-Host "✓ 'Audio route set to speaker'" -ForegroundColor Green
Write-Host ""
Write-Host "If you see these messages, audio routing is working correctly!" -ForegroundColor Cyan
Write-Host ""
