@echo off
REM =========================================
REM Fast SocialFi Docker Startup Script
REM =========================================

echo.
echo ========================================
echo Fast SocialFi - Docker Startup
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

echo [1/5] Docker is running...

REM Stop existing containers
echo [2/5] Stopping existing containers...
docker-compose down

REM Remove orphan containers
echo [3/5] Cleaning up orphan containers...
docker-compose down --remove-orphans

REM Build and start containers
echo [4/5] Building and starting containers...
docker-compose up -d --build

REM Wait for services to be healthy
echo [5/5] Waiting for services to be healthy...
timeout /t 10 /nobreak >nul

echo.
echo ========================================
echo Checking service status...
echo ========================================
docker-compose ps

echo.
echo ========================================
echo Service URLs:
echo ========================================
echo Backend API:  http://localhost:8080
echo MySQL:        localhost:3306
echo Redis:        localhost:6379
echo.
echo To view logs: docker-compose logs -f
echo To stop:      docker-compose down
echo ========================================
echo.

pause
