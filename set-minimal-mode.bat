@echo off
REM ====================================================================
REM 保持最小资源占用状态
REM 仅运行核心服务: PostgreSQL + Redis (共约 41 MB)
REM 停止: Elasticsearch, Kafka, Kafka UI (可省约 1.7 GB)
REM ====================================================================

echo.
echo ========================================
echo   Fast SocialFi 最小资源模式
echo ========================================
echo.
echo 正在配置服务状态...
echo.

REM 检查 Docker 是否运行
docker info >nul 2>&1
if errorlevel 1 (
    echo [错误] Docker 未运行，请先启动 Docker Desktop
    pause
    exit /b 1
)

echo [1/4] 停止 Elasticsearch...
docker stop socialfi-elasticsearch >nul 2>&1
if errorlevel 1 (
    echo   - Elasticsearch 已经停止或不存在
) else (
    echo   ✓ Elasticsearch 已停止 (省约 1 GB 内存)
)

echo.
echo [2/4] 停止 Kafka...
docker stop socialfi-kafka >nul 2>&1
if errorlevel 1 (
    echo   - Kafka 已经停止或不存在
) else (
    echo   ✓ Kafka 已停止 (省约 400 MB 内存)
)

echo.
echo [3/4] 停止 Kafka UI...
docker stop socialfi-kafka-ui >nul 2>&1
if errorlevel 1 (
    echo   - Kafka UI 已经停止或不存在
) else (
    echo   ✓ Kafka UI 已停止 (省约 336 MB 内存)
)

echo.
echo [4/4] 确保核心服务运行...

REM 启动 PostgreSQL (如果未运行)
docker ps --filter "name=socialfi-postgres" --format "{{.Names}}" | findstr "socialfi-postgres" >nul
if errorlevel 1 (
    echo   启动 PostgreSQL...
    docker-compose -f docker-compose.full.yml up -d postgres
    echo   ✓ PostgreSQL 已启动
) else (
    echo   ✓ PostgreSQL 已在运行
)

echo.

REM 启动 Redis (如果未运行)
docker ps --filter "name=socialfi-redis" --format "{{.Names}}" | findstr "socialfi-redis" >nul
if errorlevel 1 (
    echo   启动 Redis...
    docker-compose -f docker-compose.full.yml up -d redis
    echo   ✓ Redis 已启动
) else (
    echo   ✓ Redis 已在运行
)

echo.
echo ========================================
echo   配置完成！
echo ========================================
echo.
echo 当前状态:
echo   ✅ PostgreSQL - 运行中 (约 37 MB)
echo   ✅ Redis      - 运行中 (约 4.57 MB)
echo   ⏸️  Elasticsearch - 已停止
echo   ⏸️  Kafka     - 已停止
echo   ⏸️  Kafka UI  - 已停止
echo.
echo 总内存占用: 约 41 MB (最小模式)
echo.
echo 提示:
echo   - 需要使用搜索功能时,运行: start-elasticsearch.bat
echo   - 需要使用消息队列时,运行: start-kafka.bat
echo   - 查看服务状态,运行: docker-status.bat
echo.

REM 显示当前运行的服务
echo 验证运行状态...
docker ps --filter "name=socialfi-" --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"

echo.
pause
