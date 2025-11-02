@echo off
REM =========================================
REM Fast SocialFi 数据库服务启动脚本
REM PostgreSQL + Redis
REM =========================================

echo.
echo ========================================
echo Fast SocialFi - 数据库服务启动
echo PostgreSQL + Redis
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

echo [1/5] Docker Desktop 正在运行...

REM Stop existing containers
echo [2/5] 停止现有容器...
docker-compose -f docker-compose.db.yml down 2>nul

REM Pull latest images (如果需要)
echo [3/5] 检查镜像...
docker images postgres:16-alpine >nul 2>&1
if %errorlevel% neq 0 (
    echo      拉取 PostgreSQL 镜像...
    docker pull postgres:16-alpine
)

docker images redis:7-alpine >nul 2>&1
if %errorlevel% neq 0 (
    echo      拉取 Redis 镜像...
    docker pull redis:7-alpine
)

REM Build and start containers
echo [4/5] 启动数据库服务...
docker-compose -f docker-compose.db.yml up -d

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 启动失败!
    echo 请检查上面的错误信息。
    echo.
    pause
    exit /b 1
)

REM Wait for services to be healthy
echo [5/5] 等待服务就绪...
timeout /t 10 /nobreak >nul

echo.
echo ========================================
echo 检查服务状态...
echo ========================================
docker-compose -f docker-compose.db.yml ps

echo.
echo ========================================
echo 服务连接信息:
echo ========================================
echo.
echo PostgreSQL:
echo   Host:     localhost
echo   Port:     5432
echo   Database: socialfi_db
echo   User:     socialfi
echo   Password: socialfi_pg_pass_2024
echo   连接URL:  postgresql://socialfi:socialfi_pg_pass_2024@localhost:5432/socialfi_db
echo.
echo Redis:
echo   Host:     localhost
echo   Port:     6379
echo   Password: socialfi_redis_2024
echo   连接URL:  redis://:socialfi_redis_2024@localhost:6379
echo.
echo ========================================
echo 常用命令:
echo ========================================
echo 查看日志:   docker-compose -f docker-compose.db.yml logs -f
echo 停止服务:   docker-compose -f docker-compose.db.yml down
echo 重启服务:   docker-compose -f docker-compose.db.yml restart
echo 查看状态:   docker-compose -f docker-compose.db.yml ps
echo.
echo 连接 PostgreSQL:
echo   docker exec -it socialfi-postgres psql -U socialfi -d socialfi_db
echo.
echo 连接 Redis:
echo   docker exec -it socialfi-redis redis-cli -a socialfi_redis_2024
echo.
echo ========================================
echo.

pause
