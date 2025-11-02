@echo off
REM Fast SocialFi Services Status Checker

echo.
echo ========================================
echo   Fast SocialFi Service Status
echo ========================================
echo.

docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running
    echo.
    pause
    exit /b 1
)

echo Checking service status...
echo.

REM Display service list
docker ps -a --filter "name=socialfi-" --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"

echo.
echo ----------------------------------------
echo   Resource Usage
echo ----------------------------------------
echo.

REM Display resource usage for running services
docker stats --no-stream --filter "name=socialfi-" --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo.
echo ----------------------------------------
echo   Quick Actions
echo ----------------------------------------
echo.
echo   Start all:  start.bat
echo   Stop all:   stop.bat
echo   View logs:  docker-compose logs -f
echo.

pause
