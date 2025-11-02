# Fast SocialFi - Docker 数据库服务完整指南

## ✅ 配置完成总结

### 已创建的服务

#### PostgreSQL 16 Alpine
- **容器名称**: `socialfi-postgres`
- **镜像**: `postgres:16-alpine`
- **端口**: `5432`
- **数据库**: `socialfi_db`
- **用户**: `socialfi`
- **密码**: `socialfi_pg_pass_2024`
- **自动重启**: ✅ 已启用
- **健康检查**: ✅ 已配置
- **数据持久化**: ✅ Docker Volume

#### Redis 7 Alpine
- **容器名称**: `socialfi-redis`
- **镜像**: `redis:7-alpine`
- **端口**: `6379`
- **密码**: `socialfi_redis_2024`
- **自动重启**: ✅ 已启用
- **健康检查**: ✅ 已配置
- **数据持久化**: ✅ AOF + RDB
- **内存限制**: 256MB (可调整)

---

## 🚀 快速开始

### 1. 启动数据库服务

**方法1: 双击脚本（推荐）**
```
双击运行: start-databases.bat
```

**方法2: 命令行**
```bash
docker-compose -f docker-compose.db.yml up -d
```

### 2. 检查服务状态

```bash
docker-compose -f docker-compose.db.yml ps
```

应该看到：
```
NAME                STATUS
socialfi-postgres   Up (healthy)
socialfi-redis      Up (healthy)
```

### 3. 测试连接

**PostgreSQL:**
```bash
docker exec -it socialfi-postgres psql -U socialfi -d socialfi_db
```

**Redis:**
```bash
docker exec -it socialfi-redis redis-cli -a socialfi_redis_2024
```

---

## 🔐 连接信息

### PostgreSQL 连接

**标准连接信息:**
```
Host:     localhost
Port:     5432
Database: socialfi_db
User:     socialfi
Password: socialfi_pg_pass_2024
```

**连接 URL:**
```
postgresql://socialfi:socialfi_pg_pass_2024@localhost:5432/socialfi_db
```

**从宿主机连接 (使用 psql):**
```bash
psql -h localhost -p 5432 -U socialfi -d socialfi_db
# 输入密码: socialfi_pg_pass_2024
```

**从 Node.js 应用连接:**
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'socialfi_db',
  user: 'socialfi',
  password: 'socialfi_pg_pass_2024',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

**从 Python 应用连接:**
```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="socialfi_db",
    user="socialfi",
    password="socialfi_pg_pass_2024"
)
```

### Redis 连接

**标准连接信息:**
```
Host:     localhost
Port:     6379
Password: socialfi_redis_2024
```

**连接 URL:**
```
redis://:socialfi_redis_2024@localhost:6379
```

**从 Node.js 应用连接:**
```javascript
const redis = require('redis');

const client = redis.createClient({
  url: 'redis://:socialfi_redis_2024@localhost:6379'
});

// 或者
const client = redis.createClient({
  host: 'localhost',
  port: 6379,
  password: 'socialfi_redis_2024'
});
```

**从 Python 应用连接:**
```python
import redis

r = redis.Redis(
    host='localhost',
    port=6379,
    password='socialfi_redis_2024',
    decode_responses=True
)
```

---

## 🔄 自动重启配置

### 当前状态
✅ 所有容器已配置 `restart: always`

这意味着：
- **容器崩溃后自动重启**
- **Docker Desktop 重启后自动恢复**
- **无需手动干预**

### 配置开机自启动

运行以下脚本：
```bash
双击运行: setup-db-autostart.bat
```

这将配置：
1. Windows 启动时自动运行启动脚本
2. 等待 Docker Desktop 完全启动（45秒）
3. 自动启动 PostgreSQL 和 Redis 容器

**重要步骤:**
1. 确保 Docker Desktop 设置为开机启动
   - 打开 Docker Desktop
   - Settings → General
   - 勾选 "Start Docker Desktop when you log in"

2. 测试配置
   - 重启计算机
   - 等待约1分钟
   - 运行 `docker ps`
   - 应该能看到两个容器正在运行

---

## 📊 管理命令

### 服务控制

```bash
# 启动所有服务
docker-compose -f docker-compose.db.yml up -d

# 停止所有服务
docker-compose -f docker-compose.db.yml down

# 重启所有服务
docker-compose -f docker-compose.db.yml restart

# 重启单个服务
docker-compose -f docker-compose.db.yml restart postgres
docker-compose -f docker-compose.db.yml restart redis
```

### 查看日志

```bash
# 所有服务的日志
docker-compose -f docker-compose.db.yml logs -f

# PostgreSQL 日志
docker-compose -f docker-compose.db.yml logs -f postgres

# Redis 日志
docker-compose -f docker-compose.db.yml logs -f redis

# 最近 100 行日志
docker-compose -f docker-compose.db.yml logs --tail=100
```

### 容器管理

```bash
# 进入 PostgreSQL 容器
docker exec -it socialfi-postgres sh

# 进入 Redis 容器
docker exec -it socialfi-redis sh

# 查看容器详细信息
docker inspect socialfi-postgres
docker inspect socialfi-redis

# 查看容器资源使用
docker stats socialfi-postgres socialfi-redis
```

### 数据库操作

**PostgreSQL:**
```bash
# 连接到数据库
docker exec -it socialfi-postgres psql -U socialfi -d socialfi_db

# 列出所有数据库
docker exec -it socialfi-postgres psql -U socialfi -c "\l"

# 列出所有表
docker exec -it socialfi-postgres psql -U socialfi -d socialfi_db -c "\dt"

# 执行 SQL 文件
docker exec -i socialfi-postgres psql -U socialfi -d socialfi_db < script.sql

# 备份数据库
docker exec socialfi-postgres pg_dump -U socialfi socialfi_db > backup.sql

# 恢复数据库
docker exec -i socialfi-postgres psql -U socialfi -d socialfi_db < backup.sql
```

**Redis:**
```bash
# 连接到 Redis CLI
docker exec -it socialfi-redis redis-cli -a socialfi_redis_2024

# 查看所有键
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 KEYS "*"

# 获取键的值
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 GET key_name

# 查看 Redis 信息
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 INFO

# 保存 RDB 快照
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 SAVE

# 清空所有数据（⚠️ 危险）
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 FLUSHALL
```

---

## 💾 数据管理

### 数据持久化位置

数据存储在 Docker volumes 中：
- **PostgreSQL**: `fast-socialfi_postgres_data`
- **Redis**: `fast-socialfi_redis_data`

### 查看 Volumes

```bash
# 列出所有 volumes
docker volume ls | grep socialfi

# 查看 volume 详情
docker volume inspect fast-socialfi_postgres_data
docker volume inspect fast-socialfi_redis_data
```

### 备份数据

**备份 PostgreSQL:**
```bash
# 创建备份目录
mkdir -p backups

# 备份数据库
docker exec socialfi-postgres pg_dump -U socialfi socialfi_db > backups/socialfi_$(date +%Y%m%d_%H%M%S).sql

# 备份所有数据库
docker exec socialfi-postgres pg_dumpall -U socialfi > backups/all_databases_$(date +%Y%m%d_%H%M%S).sql
```

**备份 Redis:**
```bash
# 触发 RDB 保存
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 SAVE

# 复制 dump 文件
docker cp socialfi-redis:/data/dump.rdb backups/redis_dump_$(date +%Y%m%d_%H%M%S).rdb
```

### 恢复数据

**恢复 PostgreSQL:**
```bash
# 从 SQL 文件恢复
docker exec -i socialfi-postgres psql -U socialfi -d socialfi_db < backups/backup.sql
```

**恢复 Redis:**
```bash
# 停止 Redis
docker-compose -f docker-compose.db.yml stop redis

# 复制备份文件
docker cp backups/redis_dump.rdb socialfi-redis:/data/dump.rdb

# 启动 Redis
docker-compose -f docker-compose.db.yml start redis
```

---

## 🔧 配置调优

### PostgreSQL 性能配置

当前配置针对中等工作负载优化，如需调整，编辑 [docker-compose.db.yml](docker-compose.db.yml):

```yaml
command:
  - "postgres"
  - "-c"
  - "max_connections=200"           # 最大连接数
  - "-c"
  - "shared_buffers=256MB"          # 共享缓冲区
  - "-c"
  - "effective_cache_size=1GB"      # 有效缓存大小
  - "-c"
  - "work_mem=1310kB"               # 工作内存
```

### Redis 性能配置

编辑 [redis.conf](redis.conf):

```conf
maxmemory 256mb              # 最大内存（可调整）
maxmemory-policy allkeys-lru # 内存淘汰策略
appendonly yes               # AOF 持久化
appendfsync everysec         # 每秒同步
```

### 监控和调整

```bash
# PostgreSQL 连接数
docker exec socialfi-postgres psql -U socialfi -d socialfi_db -c "SELECT count(*) FROM pg_stat_activity;"

# Redis 内存使用
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 INFO memory

# 容器资源使用
docker stats --no-stream socialfi-postgres socialfi-redis
```

---

## 🚨 故障排除

### 容器无法启动

**检查日志:**
```bash
docker-compose -f docker-compose.db.yml logs
```

**常见问题:**

1. **端口被占用**
   ```bash
   # 检查端口
   netstat -ano | findstr ":5432"
   netstat -ano | findstr ":6379"
   ```

2. **权限问题**
   - 确保有管理员权限
   - 检查 Docker Desktop 是否正常运行

3. **磁盘空间不足**
   ```bash
   docker system df
   ```

### PostgreSQL 连接失败

```bash
# 检查 PostgreSQL 是否就绪
docker exec socialfi-postgres pg_isready -U socialfi

# 查看 PostgreSQL 日志
docker logs socialfi-postgres

# 测试连接
docker exec socialfi-postgres psql -U socialfi -d socialfi_db -c "SELECT 1;"
```

### Redis 连接失败

```bash
# 测试 Redis
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 ping

# 查看 Redis 日志
docker logs socialfi-redis

# 检查 Redis 配置
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 CONFIG GET "*"
```

### 重置所有配置

```bash
# 停止并删除所有容器
docker-compose -f docker-compose.db.yml down

# 删除所有数据（⚠️ 会丢失数据）
docker-compose -f docker-compose.db.yml down -v

# 重新启动
start-databases.bat
```

---

## 📝 最佳实践

### 开发环境

1. **定期备份数据**
   - 使用上述备份命令
   - 建议每天或每周备份

2. **监控资源使用**
   ```bash
   docker stats
   ```

3. **定期清理日志**
   ```bash
   docker-compose -f docker-compose.db.yml logs --tail=0 -f
   ```

### 生产环境建议

1. **修改默认密码**
   - 编辑 [docker-compose.db.yml](docker-compose.db.yml)
   - 使用强密码

2. **限制容器资源**
   ```yaml
   services:
     postgres:
       deploy:
         resources:
           limits:
             cpus: '2'
             memory: 2G
   ```

3. **配置备份策略**
   - 自动化备份脚本
   - 异地备份

4. **监控和告警**
   - 使用 Prometheus + Grafana
   - 配置健康检查告警

---

## 📚 相关文件

- [docker-compose.db.yml](docker-compose.db.yml) - Docker Compose 配置
- [redis.conf](redis.conf) - Redis 配置文件
- [database/init-postgres.sql](database/init-postgres.sql) - PostgreSQL 初始化脚本
- [start-databases.bat](start-databases.bat) - 启动脚本
- [stop-databases.bat](stop-databases.bat) - 停止脚本
- [setup-db-autostart.bat](setup-db-autostart.bat) - 自启动配置脚本

---

## ✅ 验证清单

- [x] PostgreSQL 容器正常启动
- [x] Redis 容器正常启动
- [x] 健康检查通过
- [x] 可以连接到 PostgreSQL
- [x] 可以连接到 Redis
- [x] 数据持久化配置正确
- [x] 自动重启功能正常
- [x] 启动脚本可用

---

## 🎉 全部完成！

你的 Docker 数据库服务已经完全配置好了！

**当前状态:**
- ✅ PostgreSQL 16 正在运行
- ✅ Redis 7 正在运行
- ✅ 健康检查已配置
- ✅ 自动重启已启用
- ✅ 数据持久化已配置

**下一步:**
1. 双击运行 `setup-db-autostart.bat` 配置开机自启动
2. 在你的应用中使用上述连接信息连接数据库
3. 定期备份数据

**需要帮助?**
- 查看本文档的故障排除部分
- 运行 `docker-compose -f docker-compose.db.yml logs -f` 查看日志
- 使用 `docker ps` 检查容器状态
