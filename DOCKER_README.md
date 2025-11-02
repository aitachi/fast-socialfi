# Fast SocialFi Docker 部署指南

## 快速开始

### 前置要求

1. 安装 Docker Desktop for Windows
2. 确保 Docker Desktop 正在运行

### 启动服务

**方法 1: 使用启动脚本（推荐）**
```bash
# 双击运行
docker-start.bat
```

**方法 2: 手动命令**
```bash
# 构建并启动所有服务
docker-compose up -d --build

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 停止服务

**方法 1: 使用停止脚本**
```bash
# 双击运行
docker-stop.bat
```

**方法 2: 手动命令**
```bash
docker-compose down
```

### 查看日志

**方法 1: 使用日志脚本**
```bash
# 双击运行
docker-logs.bat
```

**方法 2: 手动命令**
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f mysql
docker-compose logs -f redis
```

## 服务信息

### 端口映射

- **Backend API**: http://localhost:8080
- **MySQL**: localhost:3306
- **Redis**: localhost:6379

### 数据库凭据

**MySQL:**
- Host: localhost (外部) / mysql (容器内)
- Port: 3306
- Database: socialfi_db
- User: socialfi
- Password: socialfi_pass_2024
- Root Password: socialfi_root_2024

**Redis:**
- Host: localhost (外部) / redis (容器内)
- Port: 6379
- Password: socialfi_redis_2024

## 自动重启配置

所有服务已配置 `restart: always`，这意味着：

1. ✅ 容器异常退出时自动重启
2. ✅ Docker Desktop 重启后自动启动
3. ✅ 系统重启后自动启动（如果 Docker Desktop 设置为开机启动）

### 确保开机自启动

1. 打开 Docker Desktop
2. 进入 Settings (设置)
3. 勾选 "Start Docker Desktop when you log in"
4. 点击 "Apply & Restart"

## 常用命令

### 重启服务
```bash
docker-compose restart

# 重启特定服务
docker-compose restart backend
```

### 查看容器状态
```bash
docker-compose ps
```

### 进入容器
```bash
# 进入 backend 容器
docker-compose exec backend sh

# 进入 MySQL 容器
docker-compose exec mysql bash

# 进入 Redis 容器
docker-compose exec redis sh
```

### 执行 MySQL 命令
```bash
# 连接到 MySQL
docker-compose exec mysql mysql -u socialfi -p socialfi_db
# 密码: socialfi_pass_2024
```

### 执行 Redis 命令
```bash
# 连接到 Redis
docker-compose exec redis redis-cli -a socialfi_redis_2024
```

### 清理和重建
```bash
# 停止并删除所有容器、网络
docker-compose down

# 停止并删除所有容器、网络、卷（⚠️ 会删除数据）
docker-compose down -v

# 重新构建并启动
docker-compose up -d --build
```

### 查看资源使用情况
```bash
docker stats
```

## 健康检查

所有服务都配置了健康检查：

- **MySQL**: 每10秒检查一次
- **Redis**: 每10秒检查一次
- **Backend**: 每30秒检查一次，通过 `/health` 端点

查看健康状态：
```bash
docker-compose ps
```

## 数据持久化

数据通过 Docker volumes 持久化存储：

- `mysql_data`: MySQL 数据库文件
- `redis_data`: Redis 持久化文件
- `node_modules`: Node.js 依赖

## 故障排除

### 容器无法启动

1. 检查 Docker Desktop 是否正在运行
2. 检查端口是否被占用：
   ```bash
   netstat -ano | findstr :3306
   netstat -ano | findstr :6379
   netstat -ano | findstr :8080
   ```

### 查看详细错误信息
```bash
docker-compose logs backend
docker-compose logs mysql
docker-compose logs redis
```

### 完全重置
```bash
# 停止所有容器
docker-compose down -v

# 删除所有相关镜像
docker-compose down --rmi all

# 重新构建
docker-compose up -d --build
```

### Backend 无法连接数据库

确保 backend 服务在数据库服务健康后才启动：
```yaml
depends_on:
  mysql:
    condition: service_healthy
```

## 环境配置

使用 `.env.docker` 文件进行 Docker 环境配置。

关键配置：
- 数据库主机使用服务名: `DB_HOST=mysql`
- Redis 主机使用服务名: `REDIS_HOST=redis`
- 生产环境: `NODE_ENV=production`

## 网络架构

所有服务在 `socialfi-network` 桥接网络中通信，容器间可以通过服务名相互访问。

## 更新部署

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose up -d --build
```

## 监控和维护

### 定期清理未使用的资源
```bash
# 清理未使用的镜像
docker image prune -a

# 清理未使用的卷
docker volume prune

# 清理未使用的网络
docker network prune

# 一键清理所有未使用资源
docker system prune -a
```

## 安全建议

1. ✅ 已使用非 root 用户运行容器
2. ✅ 生产环境请修改默认密码
3. ✅ 限制容器资源使用（可选）
4. ✅ 定期更新基础镜像

## 支持

如有问题，请查看：
1. Docker 日志: `docker-compose logs -f`
2. 容器状态: `docker-compose ps`
3. 健康检查: `docker inspect <container-name>`
