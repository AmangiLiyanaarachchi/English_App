# Chat Feature Setup Script
# Run this in PowerShell to set up the chat system

Write-Host "🚀 Setting up WhatsApp-Style Chat System..." -ForegroundColor Green
Write-Host ""

# Navigate to project directory
Set-Location "d:\English app argent\English_App"

Write-Host "📦 Step 1: Installing dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host ""
Write-Host "🔨 Step 2: Generating Hive adapters..." -ForegroundColor Cyan
flutter pub run build_runner build --delete-conflicting-outputs

Write-Host ""
Write-Host "🧹 Step 3: Cleaning build..." -ForegroundColor Cyan
flutter clean

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Make sure Firebase is configured (google-services.json)"
Write-Host "  2. Update Firestore security rules (see CHAT_IMPLEMENTATION_GUIDE.md)"
Write-Host "  3. Run the app: flutter run"
Write-Host ""
Write-Host "📚 For full documentation, see: CHAT_IMPLEMENTATION_GUIDE.md" -ForegroundColor Cyan
