@echo off
REM =========================================
REM 配置数据库服务开机自启动
REM =========================================

echo.
echo ========================================
echo 数据库服务 - 开机自启动配置
echo ========================================
echo.

echo 此脚本将配置 PostgreSQL 和 Redis 容器开机自动启动
echo.

REM Get the current directory
set CURRENT_DIR=%~dp0

REM Create startup script
set STARTUP_SCRIPT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\socialfi-databases.bat

echo 正在创建启动脚本...
echo.

echo @echo off > "%STARTUP_SCRIPT%"
echo REM Fast SocialFi 数据库服务自启动 >> "%STARTUP_SCRIPT%"
echo. >> "%STARTUP_SCRIPT%"
echo REM 等待 Docker Desktop 启动 >> "%STARTUP_SCRIPT%"
echo timeout /t 45 /nobreak ^>nul >> "%STARTUP_SCRIPT%"
echo. >> "%STARTUP_SCRIPT%"
echo REM 切换到项目目录 >> "%STARTUP_SCRIPT%"
echo cd /d "%CURRENT_DIR%" >> "%STARTUP_SCRIPT%"
echo. >> "%STARTUP_SCRIPT%"
echo REM 启动数据库服务 >> "%STARTUP_SCRIPT%"
echo docker-compose -f docker-compose.db.yml up -d >> "%STARTUP_SCRIPT%"

echo [完成] 自启动脚本已创建
echo.
echo 位置: %STARTUP_SCRIPT%
echo.

echo ========================================
echo 重要配置步骤:
echo ========================================
echo.
echo 1. 确保 Docker Desktop 开机自启动:
echo    - 打开 Docker Desktop
echo    - Settings -^> General
echo    - 勾选 "Start Docker Desktop when you log in"
echo    - 点击 "Apply & Restart"
echo.
echo 2. 测试自启动:
echo    - 重启计算机
echo    - 等待约 1 分钟
echo    - 运行: docker ps
echo    - 应该能看到 socialfi-postgres 和 socialfi-redis
echo.

echo ========================================
echo 配置完成!
echo ========================================
echo.
echo 现在你的数据库服务将在以下情况自动启动:
echo  ✓ 系统启动后自动运行
echo  ✓ 容器崩溃后自动重启
echo  ✓ Docker 重启后自动恢复
echo.
echo 提示: 启动脚本等待 45 秒以确保 Docker 完全启动
echo.

pause
