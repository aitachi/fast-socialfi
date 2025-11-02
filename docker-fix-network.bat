@echo off
REM =========================================
REM Docker 镜像加速器配置指南
REM =========================================

echo.
echo ========================================
echo Docker 镜像加速器配置
echo ========================================
echo.

echo [问题] Docker 无法从 Docker Hub 拉取镜像
echo.
echo [解决方案] 配置国内镜像加速器
echo.

echo ========================================
echo 手动配置步骤:
echo ========================================
echo.
echo 1. 打开 Docker Desktop
echo 2. 点击右上角的设置图标 (齿轮)
echo 3. 进入 "Docker Engine" 选项
echo 4. 在 JSON 配置中添加以下内容:
echo.
echo {
echo   "registry-mirrors": [
echo     "https://docker.mirrors.ustc.edu.cn",
echo     "https://hub-mirror.c.163.com",
echo     "https://mirror.ccs.tencentyun.com"
echo   ]
echo }
echo.
echo 5. 点击 "Apply & Restart" 按钮
echo 6. 等待 Docker Desktop 重启完成
echo.

echo ========================================
echo 或者使用阿里云镜像加速器:
echo ========================================
echo.
echo 1. 访问: https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors
echo 2. 登录你的阿里云账号
echo 3. 获取你的专属加速器地址
echo 4. 在 Docker Desktop 中配置该地址
echo.

echo ========================================
echo 配置完成后:
echo ========================================
echo.
echo 运行以下命令验证:
echo docker info ^| findstr "Registry Mirrors"
echo.
echo 然后重新运行: docker-start.bat
echo.

echo ========================================
echo 替代方案: 使用本地 MySQL 和 Redis
echo ========================================
echo.
echo 如果无法配置镜像加速，你可以:
echo 1. 使用本地已安装的 MySQL (端口 3306)
echo 2. 使用本地已安装的 Redis (端口 6379)
echo 3. 只启动 Backend 应用的 Docker 容器
echo.
echo 需要帮助请按任意键继续...

pause
