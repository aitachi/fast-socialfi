@echo off
REM ====================================================================
REM 查看所有 SocialFi 服务状态
REM ====================================================================

echo.
echo ========================================
echo   Fast SocialFi 服务状态
echo ========================================
echo.

REM 检查 Docker 是否运行
docker info >nul 2>&1
if errorlevel 1 (
    echo [错误] Docker 未运行
    echo.
    pause
    exit /b 1
)

echo 正在检查服务状态...
echo.

REM 显示服务列表
docker ps -a --filter "name=socialfi-" --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"

echo.
echo ----------------------------------------
echo   资源占用
echo ----------------------------------------
echo.

REM 仅显示运行中的服务资源占用
docker stats --no-stream --filter "name=socialfi-" --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo.
echo ----------------------------------------
echo   快速操作
echo ----------------------------------------
echo.
echo   1. 切换最小模式 (仅 PostgreSQL + Redis, 41 MB)
echo      运行: set-minimal-mode.bat
echo.
echo   2. 启动 Elasticsearch (增加 1 GB 内存)
echo      运行: start-elasticsearch.bat
echo.
echo   3. 启动 Kafka (增加 700 MB 内存)
echo      运行: start-kafka.bat
echo.
echo   4. 智能启动 (自动检测需要的服务)
echo      运行: smart-start.bat
echo.
echo   5. 启动所有服务
echo      运行: docker-compose -f docker-compose.full.yml up -d
echo.
echo   6. 停止所有服务
echo      运行: docker-compose -f docker-compose.full.yml down
echo.

pause
