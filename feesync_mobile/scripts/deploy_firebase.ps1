# Firebase App Distribution Deployment Script (Windows PowerShell)
# Usage: .\scripts\deploy_firebase.ps1 -Platform Android -ReleaseNotes "New features" -Groups "internal-testers"

param (
    [ValidateSet("Android", "iOS", "Both")]
    [string]$Platform = "Android",
    
    [string]$ReleaseNotes = "Beta release built on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    
    [string]$Groups = ""
)

$ErrorActionPreference = "Stop"

# 1. Load environment variables from .env.firebase
$EnvFile = "$PSScriptRoot/../.env.firebase"
if (-not (Test-Path $EnvFile)) {
    Write-Host "Error: .env.firebase file not found at: $EnvFile" -ForegroundColor Red
    Write-Host "Please copy .env.firebase.example to .env.firebase and populate it with your Firebase App IDs." -ForegroundColor Yellow
    Exit 1
}

Write-Host "Loading environment variables from $EnvFile..." -ForegroundColor Cyan
Get-Content $EnvFile | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
    $name, $value = $_ -split '=', 2
    $name = $name.Trim()
    $value = $value.Trim().Trim('"').Trim("'")
    [Environment]::SetEnvironmentVariable($name, $value, "Process")
}

$AndroidAppId = $env:FIREBASE_APP_ID_ANDROID
$IosAppId = $env:FIREBASE_APP_ID_IOS
$DefaultGroups = $env:FIREBASE_TESTERS_GROUP

# Resolve tester groups
if ([string]::IsNullOrWhiteSpace($Groups)) {
    if (-not [string]::IsNullOrWhiteSpace($DefaultGroups)) {
        $Groups = $DefaultGroups
    } else {
        $Groups = "internal-testers"
    }
}

# 2. Check Prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Cyan

# Check Flutter CLI
try {
    $null = Get-Command flutter -ErrorAction SilentlyContinue
} catch {
    Write-Host "Error: Flutter SDK is not installed or not in your system PATH." -ForegroundColor Red
    Exit 1
}

# Check Firebase CLI
try {
    $null = Get-Command firebase -ErrorAction SilentlyContinue
} catch {
    Write-Host "Error: Firebase CLI is not installed." -ForegroundColor Red
    Write-Host "Please install it using: npm install -g firebase-tools" -ForegroundColor Yellow
    Exit 1
}

# 3. Build & Deploy Android
if ($Platform -eq "Android" -or $Platform -eq "Both") {
    if ([string]::IsNullOrWhiteSpace($AndroidAppId) -or $AndroidAppId -eq "YOUR_ANDROID_APP_ID_HERE") {
        Write-Host "Error: FIREBASE_APP_ID_ANDROID is not configured in .env.firebase." -ForegroundColor Red
        Exit 1
    }

    Write-Host "`n--- [Building Android Release APK] ---" -ForegroundColor Blue
    Set-Location "$PSScriptRoot/.."
    
    # Run build
    flutter build apk --release

    $ApkPath = "build/app/outputs/flutter-apk/app-release.apk"
    if (-not (Test-Path $ApkPath)) {
        Write-Host "Error: APK build succeeded but release file was not found at $ApkPath." -ForegroundColor Red
        Exit 1
    }

    Write-Host "`n--- [Uploading Android to Firebase App Distribution] ---" -ForegroundColor Blue
    firebase appdistribution:distribute $ApkPath `
        --app $AndroidAppId `
        --release-notes "$ReleaseNotes" `
        --groups "$Groups"
        
    Write-Host "`nAndroid deployment complete!" -ForegroundColor Green
}

# 4. Build & Deploy iOS
if ($Platform -eq "iOS" -or $Platform -eq "Both") {
    if ([string]::IsNullOrWhiteSpace($IosAppId) -or $IosAppId -eq "YOUR_IOS_APP_ID_HERE") {
        Write-Host "Error: FIREBASE_APP_ID_IOS is not configured in .env.firebase." -ForegroundColor Red
        Exit 1
    }

    Write-Host "`n--- [Building iOS Release IPA] ---" -ForegroundColor Blue
    Set-Location "$PSScriptRoot/.."
    
    # Run build (requires Xcode / macOS)
    flutter build ipa --release

    $IpaPath = Get-ChildItem "build/ios/ipa/*.ipa" | Select-Object -First 1
    if (-not $IpaPath) {
        Write-Host "Error: IPA build succeeded but release file was not found under build/ios/ipa/" -ForegroundColor Red
        Exit 1
    }

    Write-Host "`n--- [Uploading iOS to Firebase App Distribution] ---" -ForegroundColor Blue
    firebase appdistribution:distribute $IpaPath.FullName `
        --app $IosAppId `
        --release-notes "$ReleaseNotes" `
        --groups "$Groups"
        
    Write-Host "`niOS deployment complete!" -ForegroundColor Green
}

Write-Host "`nFirebase App Distribution script finished successfully!" -ForegroundColor Green
