@echo off
REM =========================================
REM Remove Docker Auto-Start Configuration
REM =========================================

echo.
echo ========================================
echo Remove Docker Auto-Start
echo ========================================
echo.

set STARTUP_SCRIPT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\fast-socialfi-docker.bat

if exist "%STARTUP_SCRIPT%" (
    del "%STARTUP_SCRIPT%"
    echo [OK] Auto-start script removed successfully.
) else (
    echo [INFO] No auto-start script found.
)

echo.
echo ========================================
echo Done!
echo ========================================
echo.
echo The containers will no longer start automatically
echo when Windows boots.
echo.
echo Note: This does not affect Docker Desktop's
echo auto-start setting. To change that:
echo 1. Open Docker Desktop Settings
echo 2. Uncheck "Start Docker Desktop when you log in"
echo ========================================
echo.

pause
