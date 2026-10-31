$ErrorActionPreference = "Stop"

# مسیرها
$backendPath = "F:\project\student-transport"
$flutterPath = "F:\project\student_transport_mobile"

$python = Join-Path $backendPath ".venv313\Scripts\python.exe"
$adb = "G:\android\sdk\android-sdk-essential\platform-tools\adb.exe"
$flutter = "F:\dev\sdk\flutter\bin\flutter.bat"

$deviceId = "2303CRA44A"
$backendPort = 8000

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "        اجرای پروژه هم‌مسیر" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# بررسی Python Backend
if (-not (Test-Path $python)) {
    throw "Python محیط مجازی Backend پیدا نشد: $python"
}

# بررسی ADB
if (-not (Test-Path $adb)) {
    throw "ADB پیدا نشد: $adb"
}

# بررسی Flutter
if (-not (Test-Path $flutter)) {
    throw "Flutter پیدا نشد: $flutter"
}

# بررسی Backend
$backendConnection = Get-NetTCPConnection `
    -LocalPort $backendPort `
    -State Listen `
    -ErrorAction SilentlyContinue

if ($backendConnection) {
    Write-Host "Backend در حال اجراست." -ForegroundColor Green
}
else {
    Write-Host "Backend در حال اجرا نیست؛ در حال راه‌اندازی..." -ForegroundColor Yellow

    Start-Process powershell.exe -ArgumentList @(
        "-NoExit",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        "Set-Location '$backendPath'; & '$python' -m uvicorn app.main:app --reload"
    )

    Write-Host "در انتظار آماده‌شدن Backend..." -ForegroundColor Yellow

    $backendReady = $false

    for ($i = 1; $i -le 30; $i++) {
        Start-Sleep -Seconds 1

        $connection = Get-NetTCPConnection `
            -LocalPort $backendPort `
            -State Listen `
            -ErrorAction SilentlyContinue

        if ($connection) {
            $backendReady = $true
            break
        }

        Write-Host "." -NoNewline
    }

    Write-Host ""

    if (-not $backendReady) {
        throw "Backend در مدت 30 ثانیه روی پورت 8000 آماده نشد."
    }

    Write-Host "Backend با موفقیت آماده شد." -ForegroundColor Green
}

# راه‌اندازی ADB
Write-Host ""
Write-Host "راه‌اندازی ADB..." -ForegroundColor Yellow

& $adb start-server | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "ADB نتوانست اجرا شود."
}

# بررسی اتصال گوشی
Write-Host "بررسی اتصال گوشی..." -ForegroundColor Yellow

$devices = & $adb devices

if (-not ($devices -match $deviceId)) {
    throw "گوشی با شناسه $deviceId به ADB متصل نیست."
}

Write-Host "گوشی شناسایی شد." -ForegroundColor Green

# ADB Reverse
Write-Host ""
Write-Host "تنظیم ارتباط گوشی با Backend..." -ForegroundColor Yellow

& $adb reverse tcp:8000 tcp:8000

if ($LASTEXITCODE -ne 0) {
    throw "ADB Reverse با خطا مواجه شد."
}

Write-Host "ADB Reverse با موفقیت فعال شد." -ForegroundColor Green

# اجرای Flutter
Write-Host ""
Write-Host "اجرای Flutter..." -ForegroundColor Cyan
Write-Host ""

Set-Location $flutterPath

& $flutter run -d $deviceId