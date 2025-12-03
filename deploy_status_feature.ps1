# ========================================
# Status Feature - Quick Deployment Script
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Status Feature Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Deploy Firestore Rules
Write-Host "Step 1: Deploying Firestore Rules..." -ForegroundColor Yellow
firebase deploy --only firestore:rules

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Firestore rules deployed successfully!" -ForegroundColor Green
}
else {
    Write-Host "❌ Failed to deploy Firestore rules" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Test Flutter App
Write-Host "Step 2: Would you like to test the app now? (Y/N)" -ForegroundColor Yellow
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "Running Flutter app..." -ForegroundColor Cyan
    flutter run
}
else {
    Write-Host "Skipping app test" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test posting text status" -ForegroundColor White
Write-Host "2. Test posting image status" -ForegroundColor White
Write-Host "3. Test commenting on status" -ForegroundColor White
Write-Host "4. Verify auto-delete after 24 hours" -ForegroundColor White
Write-Host ""
Write-Host "Optional: Setup Cloud Function for auto-delete" -ForegroundColor Yellow
Write-Host "See: STATUS_CLOUD_FUNCTION_SETUP.md" -ForegroundColor White
Write-Host ""
