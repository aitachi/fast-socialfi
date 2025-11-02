@echo off
REM =========================================
REM Fast SocialFi 数据库服务停止脚本
REM =========================================

echo.
echo ========================================
echo Fast SocialFi - 停止数据库服务
echo ========================================
echo.

echo 正在停止 PostgreSQL 和 Redis...
docker-compose -f docker-compose.db.yml down

echo.
echo [完成] 所有数据库服务已停止
echo.
echo 注意: 数据已保存在 Docker volumes 中
echo 下次启动时数据不会丢失
echo.

pause
