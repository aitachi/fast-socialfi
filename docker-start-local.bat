@echo off
REM =========================================
REM Fast SocialFi Docker 启动 (使用本地数据库)
REM =========================================

echo.
echo ========================================
echo Fast SocialFi - 启动 (本地数据库模式)
echo ========================================
echo.

echo [信息] 此脚本将使用本地 MySQL 和 Redis 服务
echo [信息] 只启动 Backend 应用的 Docker 容器
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

REM Check if local MySQL is running
echo [2/5] Checking local MySQL...
netstat -ano | findstr ":3306" | findstr "LISTENING" >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Local MySQL (port 3306) is not running!
    echo Please start MySQL service first.
    echo.
    echo To start MySQL:
    echo - Open Services (services.msc)
    echo - Find MySQL service
    echo - Click "Start"
    echo.
    pause
    exit /b 1
)
echo [OK] Local MySQL is running

REM Check if local Redis is running
echo [3/5] Checking local Redis...
netstat -ano | findstr ":6379" | findstr "LISTENING" >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Local Redis (port 6379) is not running!
    echo Please start Redis service first.
    pause
    exit /b 1
)
echo [OK] Local Redis is running

REM Stop existing containers
echo [4/5] Stopping existing containers...
docker-compose -f docker-compose.local.yml down 2>nul

REM Build and start backend container
echo [5/5] Building and starting Backend container...
docker-compose -f docker-compose.local.yml up -d --build

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to start container!
    echo Please check the error message above.
    pause
    exit /b 1
)

REM Wait for service to be ready
echo.
echo Waiting for backend to be ready...
timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo Checking service status...
echo ========================================
docker-compose -f docker-compose.local.yml ps

echo.
echo ========================================
echo Service Information:
echo ========================================
echo Backend API:  http://localhost:8080
echo MySQL:        localhost:3306 (本地服务)
echo Redis:        localhost:6379 (本地服务)
echo.
echo Container logs: docker-compose -f docker-compose.local.yml logs -f
echo Stop service:   docker-compose -f docker-compose.local.yml down
echo ========================================
echo.

pause
