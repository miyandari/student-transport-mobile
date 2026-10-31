@echo off
setlocal

title Hammasir - Development

echo.
echo =========================================
echo          HAMMASIR DEVELOPMENT
echo =========================================
echo.

set "BACKEND=F:\project\student-transport"
set "PYTHON=F:\project\student-transport\.venv313\Scripts\python.exe"
set "ADB=G:\android\sdk\android-sdk-essential\platform-tools\adb.exe"
set "FLUTTER=F:\dev\sdk\flutter\bin\flutter.bat"
set "DEVICE=2303CRA44A"

echo [1/4] Checking Backend...

netstat -ano | findstr ":8000" | findstr "LISTENING" >nul

if not errorlevel 1 (
    echo Backend is already running.
) else (
    echo Starting Backend...

    start "Hammasir Backend" powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -Command "Set-Location '%BACKEND%'; & '%PYTHON%' -m uvicorn app.main:app --reload"

    echo Waiting for Backend...

    :WAIT_BACKEND
    timeout /t 1 /nobreak >nul

    netstat -ano | findstr ":8000" | findstr "LISTENING" >nul

    if errorlevel 1 goto WAIT_BACKEND

    echo Backend is ready.
)

echo.
echo [2/4] Starting ADB...

"%ADB%" start-server >nul

echo.
echo [3/4] Connecting phone...

"%ADB%" devices

echo.
echo Setting ADB reverse...

"%ADB%" reverse tcp:8000 tcp:8000

if errorlevel 1 (
    echo.
    echo ERROR: ADB reverse failed.
    echo Make sure the phone is connected and USB debugging is enabled.
    pause
    exit /b 1
)

echo ADB reverse is ready.

echo.
echo [4/4] Starting Flutter...
echo.

cd /d "F:\project\student_transport_mobile"

"%FLUTTER%" run -d %DEVICE%

pause