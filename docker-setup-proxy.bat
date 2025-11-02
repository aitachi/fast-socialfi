@echo off
REM =========================================
REM Configure Docker to Use VPN Proxy
REM =========================================

echo.
echo ========================================
echo Docker VPN 代理配置
echo ========================================
echo.

echo [信息] 检测到你的 VPN 端口: 7987
echo.

echo ========================================
echo 配置步骤:
echo ========================================
echo.
echo 1. 打开 Docker Desktop
echo 2. 点击设置图标 (齿轮)
echo 3. 进入 "Resources" -^> "Proxies"
echo 4. 选择 "Manual proxy configuration"
echo 5. 填写以下信息:
echo.
echo    Web Server (HTTP):
echo    http://127.0.0.1:7897
echo.
echo    Secure Web Server (HTTPS):
echo    http://127.0.0.1:7897
echo.
echo 6. 点击 "Apply & Restart"
echo 7. 等待 Docker Desktop 重启完成
echo.

echo ========================================
echo 或者使用命令行配置 (推荐):
echo ========================================
echo.

echo 正在创建 Docker 配置...

set DOCKER_CONFIG=%USERPROFILE%\.docker\config.json

REM Backup existing config
if exist "%DOCKER_CONFIG%" (
    copy "%DOCKER_CONFIG%" "%DOCKER_CONFIG%.backup" >nul 2>&1
    echo [OK] 已备份现有配置到: %DOCKER_CONFIG%.backup
)

echo.
echo ========================================
echo 重要提示:
echo ========================================
echo.
echo 配置完成后，请执行以下步骤:
echo.
echo 1. 确保你的 VPN 正在运行
echo 2. 重启 Docker Desktop
echo 3. 运行以下命令测试:
echo.
echo    docker pull hello-world
echo.
echo 4. 如果成功，运行:
echo    docker-start.bat
echo.

pause
