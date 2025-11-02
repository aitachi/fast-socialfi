@echo off
REM =========================================
REM Configure Docker Auto-Start on Windows Boot
REM =========================================

echo.
echo ========================================
echo Docker Auto-Start Configuration
echo ========================================
echo.

echo This script will help you configure Docker to:
echo 1. Start automatically when Windows boots
echo 2. Auto-start your SocialFi containers
echo.

echo [Step 1] Checking Docker Desktop...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running!
    echo Please start Docker Desktop first.
    pause
    exit /b 1
)

echo [OK] Docker is running
echo.

echo [Step 2] Instructions for Docker Desktop Auto-Start:
echo.
echo Please follow these steps:
echo 1. Open Docker Desktop
echo 2. Click on Settings (gear icon)
echo 3. Go to "General" tab
echo 4. Check "Start Docker Desktop when you log in"
echo 5. Check "Open Docker Dashboard at startup" (optional)
echo 6. Click "Apply & Restart"
echo.
echo Press any key after you have completed the above steps...
pause >nul

echo.
echo [Step 3] Creating Windows Startup Task...
echo.

REM Get the current directory
set CURRENT_DIR=%~dp0

REM Create a batch file in startup folder
set STARTUP_SCRIPT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\fast-socialfi-docker.bat

echo @echo off > "%STARTUP_SCRIPT%"
echo REM Fast SocialFi Docker Auto-Start >> "%STARTUP_SCRIPT%"
echo timeout /t 30 /nobreak ^>nul >> "%STARTUP_SCRIPT%"
echo cd /d "%CURRENT_DIR%" >> "%STARTUP_SCRIPT%"
echo docker-compose up -d >> "%STARTUP_SCRIPT%"

echo [OK] Startup script created at:
echo %STARTUP_SCRIPT%
echo.

echo ========================================
echo Configuration Complete!
echo ========================================
echo.
echo Your Fast SocialFi containers will now:
echo - Start automatically after Windows boots
echo - Restart automatically if they crash
echo - Persist across system reboots
echo.
echo The startup script waits 30 seconds after boot
echo to ensure Docker Desktop is fully started.
echo.
echo To test: Restart your computer
echo ========================================
echo.

pause
