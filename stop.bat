@echo off
REM Fast SocialFi - Stop Services

echo.
echo ========================================
echo Fast SocialFi - Stopping Services
echo ========================================
echo.

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running!
    pause
    exit /b 1
)

echo Stopping all containers...
docker-compose down

echo.
echo [OK] All services stopped
echo.

pause
