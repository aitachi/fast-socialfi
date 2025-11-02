@echo off
REM =========================================
REM 配置所有服务开机自启动 (Windows)
REM =========================================

echo.
echo ========================================
echo Fast SocialFi - 配置开机自启动
echo ========================================
echo.

REM Get the current directory
set CURRENT_DIR=%~dp0

REM Create startup script in Windows Startup folder
set STARTUP_SCRIPT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\fast-socialfi-all-services.bat

echo 正在创建启动脚本...
echo.

echo @echo off > "%STARTUP_SCRIPT%"
echo REM Fast SocialFi 所有服务自启动 >> "%STARTUP_SCRIPT%"
echo. >> "%STARTUP_SCRIPT%"
echo REM 等待 Docker Desktop 启动 >> "%STARTUP_SCRIPT%"
echo timeout /t 45 /nobreak ^>nul >> "%STARTUP_SCRIPT%"
echo. >> "%STARTUP_SCRIPT%"
echo REM 切换到项目目录 >> "%STARTUP_SCRIPT%"
echo cd /d "%CURRENT_DIR%" >> "%STARTUP_SCRIPT%"
echo. >> "%STARTUP_SCRIPT%"
echo REM 启动所有服务 >> "%STARTUP_SCRIPT%"
echo docker-compose -f docker-compose.full.yml up -d >> "%STARTUP_SCRIPT%"
echo. >> "%STARTUP_SCRIPT%"
echo REM 记录启动时间 >> "%STARTUP_SCRIPT%"
echo echo [%%date%% %%time%%] All services started ^>^> startup.log >> "%STARTUP_SCRIPT%"

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
echo 2. 服务列表:
echo    ✓ PostgreSQL (端口 5432)
echo    ✓ Redis (端口 6379)
echo    ✓ Elasticsearch (端口 9200, 9300)
echo    ✓ Kafka (端口 9092, 9093)
echo    ✓ Kafka UI (端口 8090)
echo.
echo 3. 测试自启动:
echo    - 重启计算机
echo    - 等待约 1-2 分钟
echo    - 运行: docker ps
echo    - 应该能看到所有 5 个容器
echo.

echo ========================================
echo 配置完成!
echo ========================================
echo.
echo 自启动功能:
echo  ✓ 系统启动后自动运行所有服务
echo  ✓ 容器崩溃后自动重启 (restart: always)
echo  ✓ Docker 重启后自动恢复
echo.
echo 提示: 启动脚本等待 45 秒以确保 Docker 完全启动
echo.

pause
