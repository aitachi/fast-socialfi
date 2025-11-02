@echo off
REM ====================================================================
REM 按需启动 Elasticsearch
REM 自动检测是否需要启动,如果已运行则跳过
REM ====================================================================

echo.
echo ========================================
echo   启动 Elasticsearch 服务
echo ========================================
echo.

REM 检查 Docker 是否运行
docker info >nul 2>&1
if errorlevel 1 (
    echo [错误] Docker 未运行，请先启动 Docker Desktop
    pause
    exit /b 1
)

REM 检查 Elasticsearch 是否已经在运行
docker ps --filter "name=socialfi-elasticsearch" --format "{{.Names}}" | findstr "socialfi-elasticsearch" >nul
if not errorlevel 1 (
    echo ✓ Elasticsearch 已经在运行中
    echo.
    docker ps --filter "name=socialfi-elasticsearch" --format "table {{.Names}}\t{{.Status}}"
    echo.
    echo 提示: 访问 http://localhost:9200 检查服务状态
    echo.
    goto :end
)

echo 正在启动 Elasticsearch...
echo.

REM 启动 Elasticsearch
docker-compose -f docker-compose.full.yml up -d elasticsearch

echo.
echo 等待 Elasticsearch 启动完成 (约需 60 秒)...
echo.

REM 等待健康检查
set /a count=0
:wait_loop
docker ps --filter "name=socialfi-elasticsearch" --filter "health=healthy" --format "{{.Names}}" | findstr "socialfi-elasticsearch" >nul
if not errorlevel 1 (
    goto :healthy
)

set /a count+=1
if %count% gtr 60 (
    echo.
    echo [警告] Elasticsearch 启动超时
    echo 请运行以下命令检查日志:
    echo   docker logs socialfi-elasticsearch
    goto :end
)

echo [%count%/60] 等待中...
timeout /t 1 /nobreak >nul
goto :wait_loop

:healthy
echo.
echo ========================================
echo   ✅ Elasticsearch 启动成功！
echo ========================================
echo.
echo 服务信息:
echo   地址: http://localhost:9200
echo   内存: 约 1 GB
echo.

REM 测试连接
echo 测试连接...
curl -s http://localhost:9200/_cluster/health?pretty
echo.

echo 提示:
echo   - 停止服务: docker stop socialfi-elasticsearch
echo   - 查看日志: docker logs -f socialfi-elasticsearch
echo   - 切换回最小模式: set-minimal-mode.bat
echo.

:end
if not "%1"=="auto" pause
