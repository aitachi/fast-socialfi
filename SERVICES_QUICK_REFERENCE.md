# 🚀 Fast SocialFi 服务快速参考

> 开发人员必备 - 所有服务的连接信息和配置

---

## 📋 服务总览

| 服务 | 状态 | 端口 | 用途 | 性能 |
|------|------|------|------|------|
| PostgreSQL | ✅ | 5432 | 主数据库 | 105 写/s, 368 读/s |
| Redis | ✅ | 6379 | 缓存 | 18.8K 写/s, 7.1K 读/s |
| Elasticsearch | ✅ | 9200 | 搜索引擎 | 249 索引/s, 38 查询/s |
| Kafka | ✅ | 9092 | 消息队列 | 7.4K 生产/s, 2.3K 消费/s |
| Kafka UI | ✅ | 8090 | 管理界面 | - |
| MySQL | ✅ | 3306 | 兼容数据库 | 88 写/s, 909 读/s |

---

## 1️⃣ PostgreSQL (主数据库)

### 连接信息
```javascript
// Node.js (pg)
const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  user: 'socialfi',
  password: 'socialfi_pg_pass_2024',
  database: 'socialfi_db'
});

await client.connect();
```

### 配置详情
| 参数 | 值 |
|------|------|
| **主机** | `localhost` |
| **端口** | `5432` |
| **数据库** | `socialfi_db` |
| **用户名** | `socialfi` |
| **密码** | `socialfi_pg_pass_2024` |
| **Schema** | `socialfi` (默认还有 `public`) |
| **容器名** | `socialfi-postgres` |
| **版本** | PostgreSQL 16.10 (Alpine) |

### 连接字符串
```bash
# psql 命令行
psql -h localhost -p 5432 -U socialfi -d socialfi_db

# 连接 URL
postgresql://socialfi:socialfi_pg_pass_2024@localhost:5432/socialfi_db
```

### 常用命令
```sql
-- 设置搜索路径(推荐在每次连接后执行)
SET search_path TO socialfi, public;

-- 查看所有表
\dt socialfi.*

-- 查看用户表
SELECT * FROM socialfi.users LIMIT 10;
```

### 使用场景
- ✅ 用户数据 (users)
- ✅ 帖子内容 (posts)
- ✅ 关系数据 (follows, likes)
- ✅ 需要事务的操作
- ✅ 复杂查询和 JOIN

---

## 2️⃣ Redis (缓存层)

### 连接信息
```javascript
// Node.js (redis)
const redis = require('redis');

const client = redis.createClient({
  socket: {
    host: 'localhost',
    port: 6379
  }
  // 注意: 当前无密码,生产环境应启用密码
});

await client.connect();
```

### 配置详情
| 参数 | 值 |
|------|------|
| **主机** | `localhost` |
| **端口** | `6379` |
| **密码** | 无 (开发环境) |
| **容器名** | `socialfi-redis` |
| **版本** | Redis 6.0.16 (7-alpine) |
| **持久化** | AOF 已启用 |

### CLI 连接
```bash
# 连接 Redis
docker exec -it socialfi-redis redis-cli

# 或本地连接
redis-cli -h localhost -p 6379
```

### 常用操作
```javascript
// 字符串
await client.set('user:1001:name', 'Alice');
const name = await client.get('user:1001:name');

// Hash (用户对象)
await client.hSet('user:1001', {
  username: 'alice',
  email: 'alice@example.com',
  followers: 150
});

// 排行榜 (Sorted Set)
await client.zAdd('trending:posts', [
  { score: 1500, value: 'post:123' },
  { score: 1200, value: 'post:456' }
]);

// 缓存 (带过期时间)
await client.setEx('session:abc123', 3600, 'user_data');

// 计数器
await client.incr('post:123:views');
```

### 使用场景
- ✅ 用户会话 (Session)
- ✅ 热点数据缓存
- ✅ 排行榜 (热门帖子、用户榜)
- ✅ 计数器 (点赞数、浏览数)
- ✅ 分布式锁
- ✅ 实时通知队列

---

## 3️⃣ Elasticsearch (搜索引擎)

### 连接信息
```javascript
// Node.js (@elastic/elasticsearch)
const { Client } = require('@elastic/elasticsearch');

const client = new Client({
  node: 'http://localhost:9200'
  // 注意: 安全认证已禁用(开发环境)
});
```

### 配置详情
| 参数 | 值 |
|------|------|
| **主机** | `localhost` |
| **HTTP 端口** | `9200` |
| **Transport 端口** | `9300` |
| **认证** | 禁用 (开发环境) |
| **容器名** | `socialfi-elasticsearch` |
| **版本** | Elasticsearch 8.19.2 |
| **客户端版本** | @elastic/elasticsearch@8.11.1 |
| **集群状态** | Yellow (单节点) |

### API 访问
```bash
# 健康检查
curl http://localhost:9200/_cluster/health

# 查看所有索引
curl http://localhost:9200/_cat/indices?v

# 搜索示例
curl http://localhost:9200/posts/_search?q=blockchain
```

### 常用操作
```javascript
// 创建索引
await client.indices.create({
  index: 'posts',
  body: {
    mappings: {
      properties: {
        title: { type: 'text' },
        content: { type: 'text' },
        author: { type: 'keyword' },
        created_at: { type: 'date' }
      }
    }
  }
});

// 索引文档
await client.index({
  index: 'posts',
  id: '123',
  body: {
    title: 'Hello Blockchain',
    content: 'This is a post about blockchain...',
    author: 'alice',
    created_at: new Date()
  }
});

// 搜索
const result = await client.search({
  index: 'posts',
  body: {
    query: {
      multi_match: {
        query: 'blockchain',
        fields: ['title^2', 'content']
      }
    }
  }
});
```

### 使用场景
- ✅ 全文搜索 (帖子、用户)
- ✅ 自动补全 (搜索建议)
- ✅ 日志分析
- ✅ 实时数据聚合
- ✅ 复杂过滤和排序

---

## 4️⃣ Kafka (消息队列)

### 连接信息
```javascript
// Node.js (kafkajs)
const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'socialfi-app',
  brokers: ['localhost:9092']
});

// 创建生产者
const producer = kafka.producer();
await producer.connect();

// 创建消费者
const consumer = kafka.consumer({ groupId: 'my-group' });
await consumer.connect();
```

### 配置详情
| 参数 | 值 |
|------|------|
| **主机** | `localhost` |
| **Broker 端口** | `9092` |
| **Internal 端口** | `9093` |
| **UI 端口** | `8090` |
| **容器名** | `socialfi-kafka` |
| **版本** | Apache Kafka 3.7.0 |
| **模式** | KRaft (无 ZooKeeper) |

### Kafka UI
```
访问: http://localhost:8090
可视化管理主题、消费者组、消息等
```

### 常用操作
```javascript
// 生产消息
await producer.send({
  topic: 'user-events',
  messages: [
    {
      key: 'user-123',
      value: JSON.stringify({
        type: 'USER_CREATED',
        userId: '123',
        username: 'alice',
        timestamp: Date.now()
      })
    }
  ]
});

// 消费消息
await consumer.subscribe({ topic: 'user-events', fromBeginning: false });

await consumer.run({
  eachMessage: async ({ topic, partition, message }) => {
    const event = JSON.parse(message.value.toString());
    console.log('收到事件:', event);

    // 处理事件...
  }
});
```

### 主题建议
```javascript
// 推荐的主题命名
'user-events'           // 用户相关事件
'post-events'           // 帖子相关事件
'notification-events'   // 通知事件
'analytics-events'      // 分析统计事件
'transaction-events'    // 交易事件
```

### 使用场景
- ✅ 事件溯源 (Event Sourcing)
- ✅ 异步任务处理
- ✅ 微服务间通信
- ✅ 日志聚合
- ✅ 实时流处理
- ✅ 数据同步 (DB → Elasticsearch)

---

## 5️⃣ MySQL (兼容数据库)

### 连接信息
```javascript
// Node.js (mysql2)
const mysql = require('mysql2/promise');

const connection = await mysql.createConnection({
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: '',  // 无密码
  database: 'your_database'
});
```

### 配置详情
| 参数 | 值 |
|------|------|
| **主机** | `localhost` |
| **端口** | `3306` |
| **用户名** | `root` |
| **密码** | 空 (无密码) |
| **版本** | MySQL 8.4.6 |
| **部署** | 本机 (非容器) |

### CLI 连接
```bash
# 连接 MySQL
mysql -h localhost -u root

# 或指定数据库
mysql -h localhost -u root -D your_database
```

### ⚠️ 注意事项
- 建议迁移到容器化部署
- 写入性能较低,建议使用批量插入
- 生产环境应设置密码
- 考虑使用 PostgreSQL 替代

---

## 🔧 Docker 管理命令

### 启动所有服务
```bash
# 启动完整服务栈
docker-compose -f docker-compose.full.yml up -d

# 仅启动数据库服务
docker-compose -f docker-compose.db.yml up -d
```

### 查看服务状态
```bash
# 查看所有容器
docker ps --filter "name=socialfi-"

# 查看特定服务日志
docker logs socialfi-postgres
docker logs socialfi-redis
docker logs socialfi-elasticsearch
docker logs socialfi-kafka
```

### 停止服务
```bash
# 停止所有服务
docker-compose -f docker-compose.full.yml down

# 停止并删除数据卷 (⚠️ 会删除所有数据)
docker-compose -f docker-compose.full.yml down -v
```

### 进入容器
```bash
# PostgreSQL
docker exec -it socialfi-postgres psql -U socialfi -d socialfi_db

# Redis
docker exec -it socialfi-redis redis-cli

# Kafka
docker exec -it socialfi-kafka kafka-topics.sh --list --bootstrap-server localhost:9092
```

---

## 📦 NPM 依赖包

### 安装所需的客户端库
```bash
npm install --save pg redis @elastic/elasticsearch kafkajs mysql2
```

### 版本要求
```json
{
  "dependencies": {
    "pg": "^8.x",
    "redis": "^4.x",
    "@elastic/elasticsearch": "8.11.1",
    "kafkajs": "^2.x",
    "mysql2": "^3.x"
  }
}
```

---

## 🌐 环境变量配置

### 创建 `.env` 文件
```bash
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=socialfi_db
POSTGRES_USER=socialfi
POSTGRES_PASSWORD=socialfi_pg_pass_2024

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Elasticsearch
ELASTICSEARCH_NODE=http://localhost:9200

# Kafka
KAFKA_BROKERS=localhost:9092

# MySQL
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=
```

### 在代码中使用
```javascript
require('dotenv').config();

const pgConfig = {
  host: process.env.POSTGRES_HOST,
  port: process.env.POSTGRES_PORT,
  database: process.env.POSTGRES_DB,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD
};
```

---

## 🎯 常见使用场景示例

### 场景 1: 用户注册
```javascript
// 1. 保存用户到 PostgreSQL
const user = await pgClient.query(
  'INSERT INTO socialfi.users (address, username, email) VALUES ($1, $2, $3) RETURNING *',
  [walletAddress, username, email]
);

// 2. 缓存用户信息到 Redis
await redisClient.hSet(`user:${user.id}`, {
  username: user.username,
  email: user.email
});

// 3. 索引用户到 Elasticsearch (用于搜索)
await esClient.index({
  index: 'users',
  id: user.id,
  body: {
    username: user.username,
    bio: user.bio
  }
});

// 4. 发送用户创建事件到 Kafka
await producer.send({
  topic: 'user-events',
  messages: [{
    value: JSON.stringify({
      type: 'USER_CREATED',
      userId: user.id,
      timestamp: Date.now()
    })
  }]
});
```

### 场景 2: 发布帖子
```javascript
// 1. 保存帖子到 PostgreSQL
const post = await pgClient.query(
  'INSERT INTO socialfi.posts (user_id, title, content) VALUES ($1, $2, $3) RETURNING *',
  [userId, title, content]
);

// 2. 索引到 Elasticsearch (用于全文搜索)
await esClient.index({
  index: 'posts',
  id: post.id,
  body: {
    title: post.title,
    content: post.content,
    author: userId,
    created_at: new Date()
  }
});

// 3. 缓存热门帖子到 Redis
await redisClient.zAdd('trending:posts', {
  score: Date.now(),
  value: post.id
});

// 4. 发送事件到 Kafka (用于通知粉丝)
await producer.send({
  topic: 'post-events',
  messages: [{
    value: JSON.stringify({
      type: 'POST_CREATED',
      postId: post.id,
      userId: userId
    })
  }]
});
```

### 场景 3: 搜索用户
```javascript
// Elasticsearch 全文搜索
const result = await esClient.search({
  index: 'users',
  body: {
    query: {
      multi_match: {
        query: searchTerm,
        fields: ['username^2', 'bio'],
        fuzziness: 'AUTO'
      }
    },
    size: 20
  }
});

const users = result.hits.hits.map(hit => ({
  id: hit._id,
  ...hit._source,
  score: hit._score
}));
```

---

## 📊 性能优化建议

### PostgreSQL
```javascript
// ❌ 避免: 单条插入
for (let i = 0; i < 1000; i++) {
  await client.query('INSERT INTO posts VALUES ($1)', [data]);
}

// ✅ 推荐: 批量插入
const values = data.map((item, i) =>
  `($${i*2+1}, $${i*2+2})`
).join(',');
await client.query(
  `INSERT INTO posts (title, content) VALUES ${values}`,
  data.flatMap(d => [d.title, d.content])
);

// ✅ 推荐: 使用事务
await client.query('BEGIN');
try {
  // 多个操作...
  await client.query('COMMIT');
} catch (e) {
  await client.query('ROLLBACK');
}
```

### Redis
```javascript
// ✅ 使用 Pipeline 批量操作
const pipeline = redisClient.pipeline();
for (let i = 0; i < 1000; i++) {
  pipeline.set(`key:${i}`, `value${i}`);
}
await pipeline.exec();

// ✅ 使用合适的数据类型
// Hash 比多个 String 键更节省内存
await redisClient.hSet('user:1001', { name: 'Alice', age: 25 });
```

---

## 🔍 健康检查端点

### 创建健康检查 API
```javascript
app.get('/health', async (req, res) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    services: {}
  };

  // PostgreSQL
  try {
    await pgClient.query('SELECT 1');
    health.services.postgres = 'healthy';
  } catch (e) {
    health.services.postgres = 'unhealthy';
    health.status = 'degraded';
  }

  // Redis
  try {
    await redisClient.ping();
    health.services.redis = 'healthy';
  } catch (e) {
    health.services.redis = 'unhealthy';
    health.status = 'degraded';
  }

  // Elasticsearch
  try {
    await esClient.ping();
    health.services.elasticsearch = 'healthy';
  } catch (e) {
    health.services.elasticsearch = 'unhealthy';
    health.status = 'degraded';
  }

  res.json(health);
});
```

---

## 📚 相关文档

- [Docker Compose 配置](./docker-compose.full.yml)
- [PostgreSQL 初始化脚本](./database/init-postgres.sql)
- [服务测试脚本](./test-services.js)
- [完整测试报告](./SERVICE_FIX_REPORT.md)

---

## 🆘 故障排查

### PostgreSQL 连接失败
```bash
# 检查容器状态
docker ps | grep postgres

# 查看日志
docker logs socialfi-postgres

# 重启容器
docker restart socialfi-postgres
```

### Redis 连接超时
```bash
# 检查 Redis 是否运行
docker exec -it socialfi-redis redis-cli ping

# 应返回: PONG
```

### Elasticsearch 启动慢
```bash
# Elasticsearch 需要 60 秒启动时间
# 查看启动进度
docker logs -f socialfi-elasticsearch
```

### Kafka 消息丢失
```bash
# 检查主题配置
docker exec -it socialfi-kafka kafka-topics.sh \
  --describe --topic your-topic \
  --bootstrap-server localhost:9092
```

---

**最后更新**: 2025-11-02
**维护者**: DevOps Team
**测试状态**: ✅ 所有服务已验证

---

## 🎉 快速开始

```bash
# 1. 克隆项目
git clone <repository>
cd fast-socialfi

# 2. 启动所有服务
docker-compose -f docker-compose.full.yml up -d

# 3. 安装依赖
npm install

# 4. 配置环境变量
cp .env.example .env

# 5. 运行测试
node test-services.js

# 6. 开始开发
npm run dev
```

**祝开发顺利! 🚀**
