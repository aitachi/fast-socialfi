@echo off
REM =========================================
REM Fast SocialFi Docker Status Checker
REM =========================================

echo.
echo ========================================
echo Fast SocialFi - Container Status
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running!
    echo Please start Docker Desktop.
    echo.
    pause
    exit /b 1
)

echo [Docker Status]
echo Docker is running
echo.

echo [Container Status]
docker-compose ps
echo.

echo [Service Health]
echo Checking MySQL...
docker exec socialfi-mysql mysqladmin ping -h localhost --silent 2>nul && echo [OK] MySQL is healthy || echo [ERROR] MySQL is not responding

echo Checking Redis...
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 ping 2>nul | findstr "PONG" >nul && echo [OK] Redis is healthy || echo [ERROR] Redis is not responding

echo Checking Backend...
curl -f http://localhost:8080/health >nul 2>&1 && echo [OK] Backend is healthy || echo [WARNING] Backend may not be responding
echo.

echo [Resource Usage]
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo.

echo [Network Info]
echo Backend API:  http://localhost:8080
echo MySQL:        localhost:3306
echo Redis:        localhost:6379
echo.

echo ========================================
echo Press any key to exit...
pause >nul
