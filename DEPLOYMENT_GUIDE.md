# Fast SocialFi - 完整服务部署指南

## ✅ 已完成配置

本文档包含了 Fast SocialFi 项目所有服务的完整配置信息。

### 📦 服务清单

| 服务 | 容器名称 | 端口 | 版本 | 自动重启 |
|------|----------|------|------|----------|
| PostgreSQL | socialfi-postgres | 5432 | 16-alpine | ✅ |
| Redis | socialfi-redis | 6379 | 7-alpine | ✅ |
| Elasticsearch | socialfi-elasticsearch | 9200, 9300 | 8.11.3 | ✅ |
| Kafka (KRaft) | socialfi-kafka | 9092, 9093 | 3.7.0 | ✅ |
| Kafka UI | socialfi-kafka-ui | 8090 | latest | ✅ |

---

## 🚀 Windows 系统部署

### 前置要求

1. 安装 Docker Desktop for Windows
2. 确保 VPN 正常工作 (如果需要拉取镜像)

### 快速启动

**1. 启动所有服务**
```bash
双击运行: start-all-services.bat
```

**2. 配置开机自启动**
```bash
双击运行: setup-autostart-all.bat
```

**3. 验证服务状态**
```bash
docker ps
```

应该看到 5 个容器都在运行。

### 手动命令

```bash
# 启动所有服务
docker-compose -f docker-compose.full.yml up -d

# 查看状态
docker-compose -f docker-compose.full.yml ps

# 查看日志
docker-compose -f docker-compose.full.yml logs -f

# 停止所有服务
docker-compose -f docker-compose.full.yml down
```

---

## 🐧 Ubuntu 系统部署

### 前置要求

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo apt install docker-compose-plugin

# 添加当前用户到 docker 组
sudo usermod -aG docker $USER
newgrp docker
```

### 部署服务

**1. 克隆或上传项目文件到 Ubuntu**
```bash
cd /home/your_username/
mkdir fast-socialfi
cd fast-socialfi
# 上传 docker-compose.full.yml, services.conf, redis.conf 等文件
```

**2. 启动服务**
```bash
docker-compose -f docker-compose.full.yml up -d
```

**3. 查看状态**
```bash
docker-compose -f docker-compose.full.yml ps
```

### 配置开机自启动 (Ubuntu)

**方法1: 使用 systemd**

1. 编辑 `docker-socialfi.service` 文件，修改路径：
```bash
# 修改 WorkingDirectory
WorkingDirectory=/home/YOUR_USERNAME/fast-socialfi
```

2. 安装 systemd 服务：
```bash
# 复制服务文件
sudo cp docker-socialfi.service /etc/systemd/system/

# 重新加载 systemd
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable docker-socialfi.service

# 启动服务
sudo systemctl start docker-socialfi.service

# 查看状态
sudo systemctl status docker-socialfi.service
```

**方法2: 使用 crontab**

```bash
# 编辑 crontab
crontab -e

# 添加以下行
@reboot sleep 30 && cd /home/YOUR_USERNAME/fast-socialfi && docker-compose -f docker-compose.full.yml up -d
```

---

## 📋 详细配置信息

### 1. PostgreSQL

**连接信息:**
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

**命令行连接:**
```bash
# 进入容器
docker exec -it socialfi-postgres psql -U socialfi -d socialfi_db

# 从宿主机连接 (需安装 psql)
psql -h localhost -p 5432 -U socialfi -d socialfi_db
```

**Node.js 连接示例:**
```javascript
const { Pool } = require('pg');
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'socialfi_db',
  user: 'socialfi',
  password: 'socialfi_pg_pass_2024',
  max: 20,
});
```

### 2. Redis

**连接信息:**
```
Host:     localhost
Port:     6379
Password: socialfi_redis_2024
```

**连接 URL:**
```
redis://:socialfi_redis_2024@localhost:6379
```

**命令行连接:**
```bash
# 进入 Redis CLI
docker exec -it socialfi-redis redis-cli -a socialfi_redis_2024

# 测试连接
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 ping
```

**Node.js 连接示例:**
```javascript
const redis = require('redis');
const client = redis.createClient({
  url: 'redis://:socialfi_redis_2024@localhost:6379'
});
await client.connect();
```

### 3. Elasticsearch

**连接信息:**
```
HTTP API:      http://localhost:9200
Transport:     localhost:9300
Cluster Name:  socialfi-cluster
Node Name:     socialfi-es-node
```

**测试连接:**
```bash
# 检查集群健康
curl http://localhost:9200/_cluster/health?pretty

# 查看节点信息
curl http://localhost:9200

# 列出所有索引
curl http://localhost:9200/_cat/indices?v
```

**Node.js 连接示例:**
```javascript
const { Client } = require('@elastic/elasticsearch');
const client = new Client({
  node: 'http://localhost:9200'
});

// 测试连接
const info = await client.info();
console.log(info);
```

**创建索引示例:**
```bash
curl -X PUT "localhost:9200/users?pretty" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  }
}
'
```

### 4. Kafka (KRaft Mode - 无 ZooKeeper)

**连接信息:**
```
Bootstrap Servers: localhost:9092
Controller Port:   9093
Cluster ID:        MkU3OEVBNTcwNTJENDM2Qk
Mode:              KRaft (No ZooKeeper Required)
```

**常用命令:**

**创建 Topic:**
```bash
docker exec socialfi-kafka kafka-topics.sh \
  --create \
  --topic test-topic \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1
```

**列出所有 Topics:**
```bash
docker exec socialfi-kafka kafka-topics.sh \
  --list \
  --bootstrap-server localhost:9092
```

**查看 Topic 详情:**
```bash
docker exec socialfi-kafka kafka-topics.sh \
  --describe \
  --topic test-topic \
  --bootstrap-server localhost:9092
```

**生产消息:**
```bash
docker exec -it socialfi-kafka kafka-console-producer.sh \
  --topic test-topic \
  --bootstrap-server localhost:9092
```

**消费消息:**
```bash
docker exec -it socialfi-kafka kafka-console-consumer.sh \
  --topic test-topic \
  --from-beginning \
  --bootstrap-server localhost:9092
```

**Node.js 连接示例 (KafkaJS):**
```javascript
const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'socialfi-app',
  brokers: ['localhost:9092']
});

// Producer
const producer = kafka.producer();
await producer.connect();
await producer.send({
  topic: 'test-topic',
  messages: [
    { value: 'Hello Kafka!' }
  ]
});

// Consumer
const consumer = kafka.consumer({ groupId: 'test-group' });
await consumer.connect();
await consumer.subscribe({ topic: 'test-topic', fromBeginning: true });
await consumer.run({
  eachMessage: async ({ topic, partition, message }) => {
    console.log({
      value: message.value.toString(),
    });
  },
});
```

### 5. Kafka UI

**访问地址:**
```
http://localhost:8090
```

在浏览器中打开即可看到可视化的 Kafka 管理界面，可以：
- 查看 Topics
- 查看 Messages
- 查看 Consumer Groups
- 管理配置
- 监控性能

---

## 🔧 管理命令

### 查看所有服务状态
```bash
docker-compose -f docker-compose.full.yml ps
```

### 查看资源使用
```bash
docker stats
```

### 查看日志
```bash
# 所有服务
docker-compose -f docker-compose.full.yml logs -f

# 特定服务
docker-compose -f docker-compose.full.yml logs -f postgres
docker-compose -f docker-compose.full.yml logs -f redis
docker-compose -f docker-compose.full.yml logs -f elasticsearch
docker-compose -f docker-compose.full.yml logs -f kafka
docker-compose -f docker-compose.full.yml logs -f kafka-ui
```

### 重启服务
```bash
# 重启所有
docker-compose -f docker-compose.full.yml restart

# 重启单个
docker-compose -f docker-compose.full.yml restart kafka
```

### 停止服务
```bash
docker-compose -f docker-compose.full.yml down
```

### 完全重置 (⚠️ 会删除所有数据)
```bash
docker-compose -f docker-compose.full.yml down -v
docker-compose -f docker-compose.full.yml up -d
```

---

## 💾 数据备份

### PostgreSQL 备份
```bash
# 备份单个数据库
docker exec socialfi-postgres pg_dump -U socialfi socialfi_db > backup_pg_$(date +%Y%m%d).sql

# 备份所有数据库
docker exec socialfi-postgres pg_dumpall -U socialfi > backup_pg_all_$(date +%Y%m%d).sql

# 恢复
docker exec -i socialfi-postgres psql -U socialfi -d socialfi_db < backup_pg_20251102.sql
```

### Redis 备份
```bash
# 触发保存
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 SAVE

# 复制备份文件
docker cp socialfi-redis:/data/dump.rdb backup_redis_$(date +%Y%m%d).rdb

# 恢复
docker-compose -f docker-compose.full.yml stop redis
docker cp backup_redis_20251102.rdb socialfi-redis:/data/dump.rdb
docker-compose -f docker-compose.full.yml start redis
```

### Elasticsearch 备份
```bash
# 创建快照仓库 (首次)
curl -X PUT "localhost:9200/_snapshot/my_backup" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/usr/share/elasticsearch/backup"
  }
}
'

# 创建快照
curl -X PUT "localhost:9200/_snapshot/my_backup/snapshot_$(date +%Y%m%d)?wait_for_completion=true"

# 恢复快照
curl -X POST "localhost:9200/_snapshot/my_backup/snapshot_20251102/_restore"
```

---

## 🔍 健康检查

### 快速检查所有服务
```bash
# PostgreSQL
docker exec socialfi-postgres pg_isready -U socialfi

# Redis
docker exec socialfi-redis redis-cli -a socialfi_redis_2024 ping

# Elasticsearch
curl http://localhost:9200/_cluster/health

# Kafka
docker exec socialfi-kafka kafka-broker-api-versions.sh --bootstrap-server localhost:9092

# 查看所有容器健康状态
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## 🚨 故障排除

### 端口冲突

如果端口已被占用：

**Windows:**
```bash
netstat -ano | findstr ":5432"
netstat -ano | findstr ":6379"
netstat -ano | findstr ":9200"
netstat -ano | findstr ":9092"
```

**Ubuntu:**
```bash
sudo lsof -i :5432
sudo lsof -i :6379
sudo lsof -i :9200
sudo lsof -i :9092
```

### Elasticsearch 内存不足

如果 Elasticsearch 无法启动，可能需要增加 vm.max_map_count：

**Ubuntu:**
```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

**Windows (WSL2):**
```bash
# 在 PowerShell 中运行
wsl -d docker-desktop
sysctl -w vm.max_map_count=262144
```

### Kafka 无法启动

检查日志：
```bash
docker logs socialfi-kafka
```

常见问题：
1. CLUSTER_ID 不正确
2. 端口冲突
3. 内存不足

### 容器无法访问外网

如果拉取镜像失败，确保：
1. VPN 正在运行
2. Docker 代理配置正确
3. 参考 `VPN_PROXY_CONFIG.md`

---

## 📊 监控建议

### Prometheus + Grafana (可选)

可以添加 Prometheus 和 Grafana 进行监控：

```yaml
# 在 docker-compose.full.yml 中添加
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
```

---

## 📝 配置文件位置

- **Docker Compose**: `docker-compose.full.yml`
- **服务配置**: `services.conf`
- **Redis 配置**: `redis.conf`
- **PostgreSQL 初始化**: `database/init-postgres.sql`
- **Windows 启动脚本**: `start-all-services.bat`
- **Ubuntu Systemd 服务**: `docker-socialfi.service`

---

## ✅ 验证清单

部署完成后，验证以下内容：

- [ ] 所有 5 个容器都在运行
- [ ] 可以连接到 PostgreSQL
- [ ] 可以连接到 Redis
- [ ] Elasticsearch HTTP API 可访问
- [ ] Kafka 可以创建 Topic
- [ ] Kafka UI 可以在浏览器中打开
- [ ] 所有容器都是 healthy 状态
- [ ] 开机自启动已配置

---

## 🎉 完成！

所有服务现在已经部署完成并配置了自动重启。

**下一步：**
1. 在应用中使用上述连接信息
2. 创建必要的数据库表和索引
3. 配置应用程序连接到这些服务
4. 设置监控和日志收集
5. 定期备份数据

**需要帮助？**
- 查看 `services.conf` 获取详细配置
- 查看 `DATABASE_SETUP_GUIDE.md` 了解数据库详情
- 运行 `docker-compose -f docker-compose.full.yml logs -f` 查看日志
