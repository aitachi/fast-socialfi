@echo off
REM =========================================
REM Fast SocialFi Docker Logs Viewer
REM =========================================

echo.
echo ========================================
echo Fast SocialFi - Docker Logs
echo ========================================
echo.
echo Press Ctrl+C to exit log viewing
echo.

docker-compose logs -f
