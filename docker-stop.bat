@echo off
REM =========================================
REM Fast SocialFi Docker Stop Script
REM =========================================

echo.
echo ========================================
echo Fast SocialFi - Docker Stop
echo ========================================
echo.

echo Stopping all containers...
docker-compose down

echo.
echo All containers stopped.
echo.

pause
