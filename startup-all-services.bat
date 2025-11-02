@echo off
REM =========================================
REM Fast SocialFi - 所有服务自启动脚本
REM Windows 开机自动运行
REM =========================================

REM 等待 Docker Desktop 完全启动
echo Waiting for Docker Desktop to start...
timeout /t 45 /nobreak >nul

REM 切换到项目目录
cd /d "C:\Users\Administrator\Desktop\AGITHUB\fast-socialfi"

REM 启动所有服务
docker-compose -f docker-compose.full.yml up -d

REM 记录启动时间
echo [%date% %time%] All services started >> startup.log

exit
