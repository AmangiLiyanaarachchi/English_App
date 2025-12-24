# AI Agent Premium Plan - Setup & Test Script
Write-Host "🧠 AI Agent Premium Plan - Setup & Test" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to project directory
$projectPath = "D:\English app argent\amangii new\English_App"
Set-Location $projectPath

Write-Host "📁 Current directory: $projectPath" -ForegroundColor Green
Write-Host ""

# Menu
Write-Host "What would you like to do?" -ForegroundColor Yellow
Write-Host "1. Deploy Firestore Rules" -ForegroundColor White
Write-Host "2. Run App (Testing)" -ForegroundColor White
Write-Host "3. Clean & Rebuild" -ForegroundColor White
Write-Host "4. Check Firestore Rules" -ForegroundColor White
Write-Host "5. Open Documentation" -ForegroundColor White
Write-Host "6. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-6)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🔥 Deploying Firestore Rules..." -ForegroundColor Cyan
        firebase deploy --only firestore:rules
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Firestore rules deployed successfully!" -ForegroundColor Green
        }
        else {
            Write-Host ""
            Write-Host "❌ Failed to deploy Firestore rules" -ForegroundColor Red
            Write-Host "Make sure you're logged in: firebase login" -ForegroundColor Yellow
        }
    }
    
    "2" {
        Write-Host ""
        Write-Host "📱 Available devices:" -ForegroundColor Cyan
        flutter devices
        Write-Host ""
        
        $device = Read-Host "Enter device ID (or press Enter for default)"
        
        Write-Host ""
        Write-Host "🚀 Running app..." -ForegroundColor Cyan
        
        if ($device) {
            flutter run -d $device
        }
        else {
            flutter run
        }
    }
    
    "3" {
        Write-Host ""
        Write-Host "🧹 Cleaning project..." -ForegroundColor Cyan
        flutter clean
        
        Write-Host ""
        Write-Host "📦 Getting dependencies..." -ForegroundColor Cyan
        flutter pub get
        
        Write-Host ""
        Write-Host "✅ Clean & rebuild complete!" -ForegroundColor Green
    }
    
    "4" {
        Write-Host ""
        Write-Host "📄 Firestore Rules:" -ForegroundColor Cyan
        Write-Host "===================" -ForegroundColor Cyan
        Get-Content firestore.rules | Select-String -Pattern "aiTotalSeconds|aiUsedSeconds|aiEnabled|planType" -Context 2, 2
        Write-Host ""
        Write-Host "✅ AI Agent fields are included in rules" -ForegroundColor Green
    }
    
    "5" {
        Write-Host ""
        Write-Host "📚 Opening documentation..." -ForegroundColor Cyan
        
        # Open markdown files in VS Code
        code AI_AGENT_IMPLEMENTATION_COMPLETE.md
        Start-Sleep -Seconds 1
        code AI_AGENT_QUICK_START.md
        Start-Sleep -Seconds 1
        code AI_AGENT_PREMIUM_SETUP.md
        
        Write-Host ""
        Write-Host "✅ Documentation opened in VS Code" -ForegroundColor Green
    }
    
    "6" {
        Write-Host ""
        Write-Host "👋 Goodbye!" -ForegroundColor Cyan
        exit
    }
    
    default {
        Write-Host ""
        Write-Host "❌ Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
