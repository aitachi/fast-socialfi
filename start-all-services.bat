@echo off
REM =========================================
REM Fast SocialFi - 启动所有服务
REM PostgreSQL + Redis + Elasticsearch + Kafka
REM =========================================

echo.
echo ========================================
echo Fast SocialFi - 启动所有服务
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Desktop 未运行!
    echo 请先启动 Docker Desktop，然后重试。
    echo.
    pause
    exit /b 1
)

echo [1/4] Docker Desktop 正在运行...

REM Stop existing containers
echo [2/4] 停止现有容器...
docker-compose -f docker-compose.full.yml down 2>nul

REM Build and start containers
echo [3/4] 启动所有服务（可能需要几分钟）...
docker-compose -f docker-compose.full.yml up -d

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 启动失败!
    echo 请检查上面的错误信息。
    echo.
    pause
    exit /b 1
)

REM Wait for services to be ready
echo [4/4] 等待服务就绪...
echo.
echo 正在等待 PostgreSQL...
timeout /t 5 /nobreak >nul
echo 正在等待 Redis...
timeout /t 2 /nobreak >nul
echo 正在等待 Elasticsearch (可能需要较长时间)...
timeout /t 15 /nobreak >nul
echo 正在等待 Kafka...
timeout /t 10 /nobreak >nul

echo.
echo ========================================
echo 检查服务状态...
echo ========================================
docker-compose -f docker-compose.full.yml ps

echo.
echo ========================================
echo 服务访问信息:
echo ========================================
echo.
echo PostgreSQL:
echo   URL: http://localhost:5432
echo   连接: docker exec -it socialfi-postgres psql -U socialfi -d socialfi_db
echo.
echo Redis:
echo   URL: http://localhost:6379
echo   连接: docker exec -it socialfi-redis redis-cli -a socialfi_redis_2024
echo.
echo Elasticsearch:
echo   HTTP: http://localhost:9200
echo   测试: curl http://localhost:9200
echo.
echo Kafka:
echo   Bootstrap: localhost:9092
echo   测试: docker exec socialfi-kafka kafka-topics.sh --list --bootstrap-server localhost:9092
echo.
echo Kafka UI:
echo   Web: http://localhost:8090
echo   浏览器打开即可查看 Kafka 管理界面
echo.
echo ========================================
echo 常用命令:
echo ========================================
echo 查看日志:   docker-compose -f docker-compose.full.yml logs -f
echo 停止服务:   docker-compose -f docker-compose.full.yml down
echo 重启服务:   docker-compose -f docker-compose.full.yml restart
echo 查看状态:   docker-compose -f docker-compose.full.yml ps
echo.
echo ========================================
echo.

pause
