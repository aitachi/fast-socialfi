@echo off
REM Fast SocialFi - Setup Auto-start on Windows

echo.
echo ========================================
echo Fast SocialFi - Auto-start Setup
echo ========================================
echo.

set SCRIPT_NAME=fast-socialfi-autostart.bat
set STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
set PROJECT_DIR=%~dp0

echo Creating startup script...

REM Create the autostart script
(
echo @echo off
echo REM Fast SocialFi Auto-start Script
echo REM Wait for Docker Desktop to start
echo timeout /t 45 /nobreak ^>nul
echo.
echo REM Navigate to project directory
echo cd /d "%PROJECT_DIR%"
echo.
echo REM Start all services
echo docker-compose up -d
echo.
echo REM Log startup time
echo echo [%%date%% %%time%%] Services started ^>^> startup.log
echo.
echo exit
) > "%STARTUP_FOLDER%\%SCRIPT_NAME%"

if %errorlevel% equ 0 (
    echo.
    echo [OK] Auto-start configured successfully!
    echo.
    echo Script location: %STARTUP_FOLDER%\%SCRIPT_NAME%
    echo.
    echo NOTE: Make sure Docker Desktop is set to start on login:
    echo   Docker Desktop ^> Settings ^> General ^> Start Docker Desktop when you log in
    echo.
) else (
    echo.
    echo [ERROR] Failed to create startup script
    echo Please run this script as Administrator
    echo.
)

pause
