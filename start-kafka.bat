@echo off
REM ====================================================================
REM 按需启动 Kafka + Kafka UI
REM 自动检测是否需要启动,如果已运行则跳过
REM ====================================================================

echo.
echo ========================================
echo   启动 Kafka 消息队列服务
echo ========================================
echo.

REM 检查 Docker 是否运行
docker info >nul 2>&1
if errorlevel 1 (
    echo [错误] Docker 未运行，请先启动 Docker Desktop
    pause
    exit /b 1
)

REM 检查 Kafka 是否已经在运行
docker ps --filter "name=socialfi-kafka" --format "{{.Names}}" | findstr "socialfi-kafka" | findstr /v "kafka-ui" >nul
if not errorlevel 1 (
    echo ✓ Kafka 已经在运行中
    set KAFKA_RUNNING=1
) else (
    set KAFKA_RUNNING=0
)

REM 检查 Kafka UI 是否已经在运行
docker ps --filter "name=socialfi-kafka-ui" --format "{{.Names}}" | findstr "socialfi-kafka-ui" >nul
if not errorlevel 1 (
    echo ✓ Kafka UI 已经在运行中
    set KAFKA_UI_RUNNING=1
) else (
    set KAFKA_UI_RUNNING=0
)

if "%KAFKA_RUNNING%"=="1" if "%KAFKA_UI_RUNNING%"=="1" (
    echo.
    echo 所有 Kafka 服务已在运行中:
    docker ps --filter "name=socialfi-kafka" --format "table {{.Names}}\t{{.Status}}"
    echo.
    echo 访问地址:
    echo   Kafka Broker: localhost:9092
    echo   Kafka UI: http://localhost:8090
    echo.
    goto :end
)

echo 正在启动 Kafka 服务...
echo.

REM 启动 Kafka
if "%KAFKA_RUNNING%"=="0" (
    echo [1/2] 启动 Kafka Broker...
    docker-compose -f docker-compose.full.yml up -d kafka
    echo ✓ Kafka Broker 已启动
) else (
    echo [1/2] Kafka Broker 已在运行，跳过
)

echo.

REM 启动 Kafka UI
if "%KAFKA_UI_RUNNING%"=="0" (
    echo [2/2] 启动 Kafka UI...
    docker-compose -f docker-compose.full.yml up -d kafka-ui
    echo ✓ Kafka UI 已启动
) else (
    echo [2/2] Kafka UI 已在运行，跳过
)

echo.
echo 等待 Kafka 完全启动 (约需 10 秒)...
timeout /t 10 /nobreak >nul

echo.
echo ========================================
echo   ✅ Kafka 服务启动成功！
echo ========================================
echo.
echo 服务信息:
echo   Kafka Broker: localhost:9092
echo   Kafka UI:     http://localhost:8090
echo   内存占用:     约 700 MB (Kafka 400MB + UI 336MB)
echo.
echo 提示:
echo   - 在浏览器打开 Kafka UI: http://localhost:8090
echo   - 停止服务: docker stop socialfi-kafka socialfi-kafka-ui
echo   - 查看 Kafka 日志: docker logs -f socialfi-kafka
echo   - 切换回最小模式: set-minimal-mode.bat
echo.

REM 自动打开 Kafka UI (可选)
if "%1"=="ui" (
    echo 正在打开 Kafka UI...
    start http://localhost:8090
)

:end
if not "%1"=="auto" if not "%1"=="ui" pause
