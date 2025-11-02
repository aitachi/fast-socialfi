# Fast SocialFi Backend - Node.js/TypeScript

完整的去中心化社交金融平台后端 API

## 技术栈

- **Node.js** + **TypeScript** - 运行时和语言
- **Express.js** - Web 框架
- **PostgreSQL** - 主数据库(用户/帖子/社交关系)
- **Redis** - 缓存和会话管理
- **Kafka** - 消息队列和事件驱动
- **Elasticsearch** - 全文搜索引擎
- **Ethers.js** - 区块链交互

## 项目结构

```
backend-node/
├── src/
│   ├── config/           # 数据库和服务配置
│   │   ├── database.ts   # PostgreSQL 连接
│   │   ├── redis.ts      # Redis 连接
│   │   ├── kafka.ts      # Kafka 连接
│   │   ├── elasticsearch.ts # ES 连接
│   │   └── blockchain.ts # Web3 配置
│   ├── models/           # 数据模型
│   ├── services/         # 业务逻辑层
│   │   ├── UserService.ts
│   │   ├── PostService.ts
│   │   └── SocialService.ts
│   ├── controllers/      # 控制器层
│   │   ├── UserController.ts
│   │   └── PostController.ts
│   ├── routes/           # 路由定义
│   │   ├── user.routes.ts
│   │   ├── post.routes.ts
│   │   ├── social.routes.ts
│   │   ├── search.routes.ts
│   │   └── index.ts
│   ├── middlewares/      # 中间件
│   │   ├── auth.ts       # JWT 认证
│   │   ├── rateLimit.ts  # 限流
│   │   └── validation.ts # 参数验证
│   ├── utils/            # 工具函数
│   │   ├── cache.ts      # Redis 缓存工具
│   │   ├── queue.ts      # Kafka 队列工具
│   │   └── search.ts     # ES 搜索工具
│   ├── types/            # TypeScript 类型定义
│   └── index.ts          # 主入口文件
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

## 环境要求

- Node.js >= 18.0.0
- PostgreSQL >= 14
- Redis >= 6.0
- Kafka >= 2.8 (可选,用于事件驱动)
- Elasticsearch >= 8.0 (可选,用于搜索)

## 快速开始

### 1. 安装依赖

```bash
cd backend-node
npm install
```

### 2. 配置环境变量

复制 `.env.example` 为 `.env` 并配置:

```bash
cp .env.example .env
```

编辑 `.env` 文件,设置数据库连接信息:

```env
# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=socialfi_db
DB_USER=socialfi
DB_PASSWORD=socialfi_pg_pass_2024

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Kafka (可选)
KAFKA_BROKERS=localhost:9092

# Elasticsearch (可选)
ES_NODE=http://localhost:9200

# JWT Secret (必须修改!)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

### 3. 初始化数据库

```bash
# 连接到 PostgreSQL
psql -U postgres

# 创建数据库和用户
CREATE DATABASE socialfi_db;
CREATE USER socialfi WITH PASSWORD 'socialfi_pg_pass_2024';
GRANT ALL PRIVILEGES ON DATABASE socialfi_db TO socialfi;

# 退出 psql
\q

# 执行数据库迁移
psql -U socialfi -d socialfi_db -f ../database/schema.sql

# (可选) 导入测试数据
psql -U socialfi -d socialfi_db -f ../database/seed.sql
```

### 4. 启动开发服务器

```bash
npm run dev
```

服务器将在 http://localhost:3000 启动

### 5. 测试 API

访问健康检查端点:

```bash
curl http://localhost:3000/api/health
```

查看 API 信息:

```bash
curl http://localhost:3000/api
```

## API 端点

### 用户 API

```
POST   /api/users/register     - 注册新用户(钱包签名)
POST   /api/users/login        - 登录(钱包签名)
GET    /api/users/me           - 获取当前用户信息
GET    /api/users/:id          - 获取用户信息
PUT    /api/users/:id          - 更新用户信息
GET    /api/users/:id/followers  - 获取粉丝列表
GET    /api/users/:id/following  - 获取关注列表
```

### 帖子 API

```
POST   /api/posts              - 发布帖子
GET    /api/posts/:id          - 获取帖子详情
PUT    /api/posts/:id          - 更新帖子
DELETE /api/posts/:id          - 删除帖子
GET    /api/posts/feed         - 获取时间线
GET    /api/posts/trending     - 获取热门帖子
GET    /api/posts/user/:userId - 获取用户帖子
GET    /api/posts/hashtag/:tag - 获取话题帖子
POST   /api/posts/:id/like     - 点赞
DELETE /api/posts/:id/like     - 取消点赞
POST   /api/posts/:id/bookmark - 收藏
DELETE /api/posts/:id/bookmark - 取消收藏
GET    /api/posts/:id/comments - 获取评论
POST   /api/posts/:id/comments - 发表评论
```

### 社交 API

```
POST   /api/social/follow/:userId   - 关注用户
DELETE /api/social/follow/:userId   - 取消关注
GET    /api/social/following/:userId - 检查关注状态
GET    /api/social/bookmarks        - 获取收藏列表
```

### 搜索 API

```
GET    /api/search/users       - 搜索用户
GET    /api/search/posts       - 搜索帖子
GET    /api/search/hashtags    - 搜索话题
GET    /api/search/suggest/users - 用户自动补全
```

## 认证

API 使用 JWT Bearer Token 认证:

```bash
# 登录获取 token
curl -X POST http://localhost:3000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "wallet_address": "0x1234...",
    "signature": "0xabc...",
    "message": "Sign in to Fast SocialFi"
  }'

# 使用 token 访问受保护的端点
curl http://localhost:3000/api/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 开发脚本

```bash
# 开发模式(热重载)
npm run dev

# 构建生产版本
npm run build

# 启动生产服务器
npm start

# 运行测试
npm test

# 代码格式化
npm run format

# 代码检查
npm run lint
```

## 数据库连接测试

创建测试脚本 `test-connections.ts`:

```typescript
import db from './src/config/database';
import redisClient from './src/config/redis';
import esClient from './src/config/elasticsearch';
import kafkaClient from './src/config/kafka';

async function testConnections() {
  console.log('Testing database connections...\n');

  // PostgreSQL
  const dbOk = await db.testConnection();
  console.log('PostgreSQL:', dbOk ? '✓ OK' : '✗ FAIL');

  // Redis
  const redisOk = await redisClient.testConnection();
  console.log('Redis:', redisOk ? '✓ OK' : '✗ FAIL');

  // Elasticsearch
  const esOk = await esClient.testConnection();
  console.log('Elasticsearch:', esOk ? '✓ OK' : '✗ FAIL');

  // Kafka
  const kafkaOk = await kafkaClient.testConnection();
  console.log('Kafka:', kafkaOk ? '✓ OK' : '✗ FAIL');

  process.exit(0);
}

testConnections();
```

运行测试:

```bash
npx ts-node test-connections.ts
```

## 性能优化

### 缓存策略

- 用户信息: TTL 1小时
- 帖子内容: TTL 30分钟
- Feed 时间线: TTL 5分钟
- 搜索结果: TTL 10分钟

### 数据库索引

所有关键查询字段都已建立索引,参见 `database/schema.sql`

### 限流配置

- 通用 API: 100请求/15分钟
- 认证端点: 5请求/15分钟
- 发帖: 5帖子/分钟
- 评论: 10评论/分钟
- 搜索: 30请求/分钟

## 部署

### Docker 部署

```bash
# 构建镜像
docker build -t fast-socialfi-backend .

# 运行容器
docker run -p 3000:3000 \
  -e DB_HOST=postgres \
  -e REDIS_HOST=redis \
  fast-socialfi-backend
```

### PM2 部署

```bash
# 安装 PM2
npm install -g pm2

# 构建项目
npm run build

# 启动应用
pm2 start dist/index.js --name fast-socialfi-backend

# 查看日志
pm2 logs fast-socialfi-backend

# 重启应用
pm2 restart fast-socialfi-backend
```

## 安全建议

1. **修改默认密钥**: 在生产环境中必须修改 `JWT_SECRET` 和 `JWT_REFRESH_SECRET`
2. **使用 HTTPS**: 生产环境必须使用 HTTPS
3. **数据库安全**: 使用强密码,限制访问IP
4. **环境变量**: 不要将 `.env` 文件提交到版本控制
5. **限流**: 根据实际情况调整限流参数

## 故障排除

### PostgreSQL 连接失败

```bash
# 检查 PostgreSQL 是否运行
sudo systemctl status postgresql

# 检查连接
psql -U socialfi -d socialfi_db
```

### Redis 连接失败

```bash
# 检查 Redis 是否运行
redis-cli ping

# 启动 Redis
sudo systemctl start redis
```

### Kafka 连接失败

```bash
# 检查 Kafka 是否运行
kafka-topics.sh --bootstrap-server localhost:9092 --list
```

## 监控和日志

应用使用 Morgan 记录 HTTP 请求日志,使用 Winston 记录应用日志。

日志级别可通过 `LOG_LEVEL` 环境变量配置:

```env
LOG_LEVEL=debug   # development
LOG_LEVEL=info    # production
```

## 贡献

欢迎提交 Issue 和 Pull Request!

## 许可证

MIT License

## 联系方式

- GitHub: https://github.com/fast-socialfi
- Email: support@fast-socialfi.com
