# Fast SocialFi Docker 配置完成

## 已创建的文件

### Docker 配置文件
1. **[docker-compose.yml](docker-compose.yml)** - Docker Compose 配置文件
   - 定义了 MySQL、Redis 和 Backend 三个服务
   - 配置了自动重启策略 `restart: always`
   - 包含健康检查和依赖管理

2. **[Dockerfile](Dockerfile)** - Backend 应用容器镜像
   - 多阶段构建优化镜像大小
   - 使用非 root 用户运行
   - 包含健康检查

3. **[.dockerignore](.dockerignore)** - Docker 构建忽略文件
   - 优化构建速度和镜像大小

4. **[.env.docker](.env.docker)** - Docker 环境配置
   - 包含生产环境配置
   - 数据库和 Redis 连接信息

### 管理脚本

#### 日常使用脚本
1. **[docker-start.bat](docker-start.bat)** - 启动所有服务
   - 检查 Docker 状态
   - 构建并启动容器
   - 显示服务状态

2. **[docker-stop.bat](docker-stop.bat)** - 停止所有服务
   - 优雅地停止所有容器

3. **[docker-logs.bat](docker-logs.bat)** - 查看实时日志
   - 显示所有服务的实时日志

4. **[docker-status.bat](docker-status.bat)** - 检查服务状态
   - 查看容器运行状态
   - 检查服务健康状态
   - 显示资源使用情况

#### 自启动配置脚本
5. **[docker-setup-autostart.bat](docker-setup-autostart.bat)** - 配置开机自启动
   - 创建 Windows 启动脚本
   - 配置容器自动启动

6. **[docker-remove-autostart.bat](docker-remove-autostart.bat)** - 移除自启动配置
   - 删除自启动脚本

### 文档
7. **[DOCKER_README.md](DOCKER_README.md)** - 详细使用文档
   - 完整的使用指南
   - 常见问题解决
   - 命令参考

## 快速开始指南

### 1️⃣ 首次启动（必做）

```bash
# 双击运行
docker-start.bat
```

这将会：
- ✅ 自动拉取 MySQL 和 Redis 镜像
- ✅ 构建 Backend 应用镜像
- ✅ 启动所有服务
- ✅ 显示服务状态

### 2️⃣ 配置自启动（推荐）

```bash
# 双击运行
docker-setup-autostart.bat
```

按照提示完成配置后：
- ✅ 容器会在系统重启后自动启动
- ✅ 容器崩溃后会自动重启
- ✅ Docker Desktop 重启后容器自动恢复

### 3️⃣ 日常使用

**查看状态：**
```bash
docker-status.bat
```

**查看日志：**
```bash
docker-logs.bat
```

**停止服务：**
```bash
docker-stop.bat
```

**重新启动：**
```bash
docker-start.bat
```

## 服务访问信息

### 🌐 Web 服务
- **Backend API**: http://localhost:8080
- **API 文档**: http://localhost:8080/api-docs (如果已配置)

### 🗄️ 数据库
- **MySQL**
  - Host: `localhost`
  - Port: `3306`
  - Database: `socialfi_db`
  - User: `socialfi`
  - Password: `socialfi_pass_2024`
  - Root Password: `socialfi_root_2024`

- **Redis**
  - Host: `localhost`
  - Port: `6379`
  - Password: `socialfi_redis_2024`

## 自动重启功能

### 已配置的自动重启
所有服务都配置了 `restart: always` 策略：

1. **容器崩溃自动重启**
   - 任何服务异常退出会立即重启
   - 无需手动干预

2. **Docker 重启后自动恢复**
   - Docker Desktop 重启后自动启动容器
   - 保持服务持续运行

3. **系统重启后自动启动**（需配置）
   - 运行 `docker-setup-autostart.bat` 配置
   - 系统启动后等待 30 秒自动启动容器

### 验证自动重启

**测试容器崩溃重启：**
```bash
# 强制停止一个容器
docker stop socialfi-backend

# 查看状态，几秒后会看到容器自动重启
docker-status.bat
```

## 常用命令参考

### 查看和管理

```bash
# 查看所有容器状态
docker-compose ps

# 查看资源使用
docker stats

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f mysql
docker-compose logs -f redis

# 重启特定服务
docker-compose restart backend
```

### 进入容器

```bash
# 进入 Backend 容器
docker-compose exec backend sh

# 进入 MySQL 容器
docker-compose exec mysql bash

# 连接 MySQL 数据库
docker-compose exec mysql mysql -u socialfi -p socialfi_db

# 进入 Redis CLI
docker-compose exec redis redis-cli -a socialfi_redis_2024
```

### 维护和清理

```bash
# 重建容器
docker-compose up -d --build

# 停止并删除容器（保留数据）
docker-compose down

# 停止并删除容器和数据（⚠️ 危险）
docker-compose down -v

# 清理未使用的镜像
docker image prune -a
```

## 健康检查

所有服务都配置了健康检查：

| 服务 | 检查间隔 | 超时时间 | 重试次数 |
|------|---------|---------|---------|
| MySQL | 10秒 | 5秒 | 5次 |
| Redis | 10秒 | 5秒 | 5次 |
| Backend | 30秒 | 10秒 | 3次 |

查看健康状态：
```bash
docker-compose ps
# 或者
docker-status.bat
```

## 数据持久化

数据通过 Docker volumes 持久化，即使删除容器也不会丢失：

- `mysql_data` - MySQL 数据库文件
- `redis_data` - Redis 持久化数据
- `node_modules` - Node.js 依赖包

查看 volumes：
```bash
docker volume ls
```

## 故障排除

### 端口被占用

如果启动失败，可能是端口被占用：

```bash
# 检查端口占用
netstat -ano | findstr :3306
netstat -ano | findstr :6379
netstat -ano | findstr :8080
```

### 容器无法启动

1. 查看详细日志：
   ```bash
   docker-compose logs backend
   ```

2. 检查 Docker Desktop 是否运行

3. 重新构建：
   ```bash
   docker-compose down
   docker-compose up -d --build
   ```

### 数据库连接失败

确保 backend 等待数据库健康后再启动（已配置）：
```yaml
depends_on:
  mysql:
    condition: service_healthy
```

### 完全重置

如果遇到无法解决的问题：

```bash
# 停止所有服务
docker-compose down -v

# 删除所有镜像
docker-compose down --rmi all

# 清理系统
docker system prune -a

# 重新构建
docker-start.bat
```

## 安全建议

### ⚠️ 生产环境注意事项

1. **修改默认密码**
   - 编辑 [docker-compose.yml](docker-compose.yml)
   - 修改所有 `_2024` 后缀的密码
   - 同步更新 [.env.docker](.env.docker)

2. **限制网络访问**
   - 考虑只暴露必要的端口
   - 使用防火墙规则限制访问

3. **定期更新**
   - 定期更新基础镜像
   - 关注安全补丁

4. **备份数据**
   - 定期备份 `mysql_data` volume
   - 考虑使用自动备份脚本

## 监控和日志

### 实时监控
```bash
# 查看资源使用
docker stats

# 查看所有日志
docker-logs.bat

# 查看特定服务
docker-compose logs -f backend
```

### 日志管理

日志默认存储在容器内，可以配置日志轮转：

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## 更新部署

当代码更新后：

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-start.bat
```

## 性能优化建议

1. **为 Docker 分配足够资源**
   - Docker Desktop → Settings → Resources
   - 建议至少 4GB RAM

2. **使用 BuildKit**
   - 已在 Docker Desktop 中默认启用
   - 加速构建过程

3. **清理未使用资源**
   ```bash
   docker system prune -a --volumes
   ```

## 技术栈

- **容器编排**: Docker Compose
- **数据库**: MySQL 8.0
- **缓存**: Redis 7 Alpine
- **运行时**: Node.js 18 Alpine
- **网络**: Bridge 网络模式

## 支持和帮助

### 查看文档
- 详细文档：[DOCKER_README.md](DOCKER_README.md)
- 项目文档：[README.md](README.md)

### 检查日志
```bash
docker-compose logs -f
```

### 验证配置
```bash
docker-compose config
```

## 总结

✅ **已完成配置：**
- Docker Compose 配置文件
- 自动重启策略（restart: always）
- 健康检查机制
- 数据持久化
- 完整的管理脚本
- 开机自启动支持
- 详细的使用文档

✅ **自动重启功能：**
- 容器崩溃自动重启 ✓
- Docker 重启后自动恢复 ✓
- 系统重启后自动启动 ✓（需运行 docker-setup-autostart.bat）

✅ **立即可用：**
双击 `docker-start.bat` 即可启动所有服务！

---

**下一步操作：**
1. 运行 `docker-start.bat` 启动服务
2. 运行 `docker-setup-autostart.bat` 配置自启动
3. 运行 `docker-status.bat` 检查状态

祝使用愉快！🚀
