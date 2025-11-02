@echo off
REM Fast SocialFi - Quick Start

echo.
echo ========================================
echo Fast SocialFi Platform
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running!
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

echo [1/3] Docker is running...

REM Stop existing containers
echo [2/3] Cleaning up...
docker-compose down 2>nul

REM Start services
echo [3/3] Starting services...
docker-compose up -d

echo.
echo ========================================
echo Service Status:
echo ========================================
docker-compose ps

echo.
echo ========================================
echo Quick Links:
echo ========================================
echo Backend API:  http://localhost:8080
echo PostgreSQL:   localhost:5432
echo Redis:        localhost:6379
echo.
echo Useful commands:
echo   View logs:  docker-compose logs -f
echo   Stop:       stop.bat
echo   Status:     check-services.bat
echo ========================================
echo.

pause
