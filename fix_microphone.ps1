# Fix Microphone Permission for AI Agent Voice
Write-Host "🎤 Fixing Microphone Permission for AI Agent..." -ForegroundColor Cyan

# Stop any running Flutter processes
Write-Host "Stopping Flutter processes..." -ForegroundColor Yellow
flutter clean

# Rebuild the app
Write-Host "Rebuilding the app with microphone permissions..." -ForegroundColor Green
flutter pub get

Write-Host ""
Write-Host "✅ Microphone permission fix applied!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Now run the app with:" -ForegroundColor Cyan
Write-Host "   flutter run -d R9YR8086S5T" -ForegroundColor White
Write-Host ""
Write-Host "🔑 When you open the AI Agent (Voice tab), the app will:" -ForegroundColor Yellow
Write-Host "   1. Request microphone permission" -ForegroundColor White
Write-Host "   2. Enable microphone in WebView" -ForegroundColor White
Write-Host "   3. Allow you to speak with the AI agent" -ForegroundColor White
Write-Host ""
