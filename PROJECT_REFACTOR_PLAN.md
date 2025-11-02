# Fast SocialFi 项目重构实施计划

## 📋 项目概述

将 Fast SocialFi 从原型项目升级为生产级去中心化社交金融平台,完成以下核心目标:

1. **架构升级**: 完整集成 PostgreSQL + Redis + Kafka + Elasticsearch
2. **功能扩展**: 添加完整的社交功能和 DeFi 功能
3. **智能合约**: 开发完整的链上合约系统
4. **全面测试**: 单元测试、集成测试、链上测试、安全审计
5. **文档完善**: 专业的技术文档和 README

---

## 🎯 阶段 1: 架构设计和功能扩展

### 1.1 新增功能列表

#### 社交功能 (Social Features)
- [x] 用户系统 (User Management)
  - 用户注册/登录 (钱包连接)
  - 用户资料管理 (Profile Management)
  - 用户认证 (KYC/Verification)
  - 用户等级系统 (User Levels)

- [ ] 内容系统 (Content System)
  - 发布帖子 (Posts/Articles)
  - 图片/视频上传 (Media Upload)
  - 话题标签 (Hashtags)
  - 内容审核 (Content Moderation)
  - 敏感词过滤 (Profanity Filter)

- [ ] 社交互动 (Social Interactions)
  - 关注/取消关注 (Follow/Unfollow)
  - 点赞/收藏 (Like/Bookmark)
  - 评论/回复 (Comment/Reply)
  - 转发/分享 (Repost/Share)
  - @提及用户 (Mentions)

- [ ] 消息系统 (Messaging)
  - 私信 (Direct Messages)
  - 群聊 (Group Chat)
  - 消息通知 (Notifications)
  - 实时推送 (Real-time Push)

#### DeFi 功能 (DeFi Features)
- [ ] 代币经济 (Token Economics)
  - Social Token 发行
  - 代币质押 (Staking)
  - 代币挖矿 (Mining/Farming)
  - 流动性提供 (Liquidity Providing)

- [ ] NFT 功能 (NFT Features)
  - NFT 铸造 (Minting)
  - NFT 交易市场 (Marketplace)
  - NFT 展示 (Gallery)
  - NFT 空投 (Airdrop)

- [ ] 收益系统 (Revenue System)
  - 内容打赏 (Tipping)
  - 付费订阅 (Subscriptions)
  - 广告收益分成 (Ad Revenue Share)
  - 创作者基金 (Creator Fund)

- [ ] DAO 治理 (DAO Governance)
  - 提案系统 (Proposals)
  - 投票机制 (Voting)
  - 财库管理 (Treasury Management)
  - 权益分配 (Revenue Distribution)

### 1.2 技术架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend (React)                      │
│  Web3.js / Ethers.js / IPFS / UI Components                 │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                    API Gateway (Express)                     │
│  Authentication / Rate Limiting / Request Validation        │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──────┐ ┌──▼────────┐ ┌▼──────────────┐
│   业务层     │ │  消息队列  │ │   搜索引擎    │
│  (Services)  │ │  (Kafka)  │ │(Elasticsearch)│
│              │ │           │ │               │
│ - UserService│ │ - Events  │ │ - Full Text   │
│ - PostService│ │ - Logs    │ │ - Analytics   │
│ - NFTService │ │ - Tasks   │ │ - Indexing    │
└───────┬──────┘ └───────────┘ └───────────────┘
        │
┌───────▼──────────────────────────────────────┐
│              数据层 (Data Layer)              │
├──────────────┬──────────────┬────────────────┤
│  PostgreSQL  │    Redis     │   IPFS/Arweave │
│  - Users     │  - Cache     │  - Images      │
│  - Posts     │  - Sessions  │  - Videos      │
│  - Comments  │  - Counters  │  - Metadata    │
│  - Follows   │  - Rankings  │                │
└──────────────┴──────────────┴────────────────┘
        │
┌───────▼────────────────────────────────────────┐
│           区块链层 (Blockchain)                 │
│  Ethereum / Sepolia Testnet                    │
│  - SocialToken.sol (ERC20)                     │
│  - SocialNFT.sol (ERC721)                      │
│  - Governance.sol (DAO)                        │
│  - Staking.sol (质押)                          │
└────────────────────────────────────────────────┘
```

---

## 🗄️ 阶段 2: 数据库设计和 API 对接

### 2.1 PostgreSQL 数据库设计

#### 核心表结构

```sql
-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE,
    display_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    cover_url TEXT,
    email VARCHAR(255),
    twitter_handle VARCHAR(50),
    website_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    user_level INTEGER DEFAULT 1,
    reputation_score INTEGER DEFAULT 0,
    total_posts INTEGER DEFAULT 0,
    total_followers INTEGER DEFAULT 0,
    total_following INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 帖子表
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    media_urls TEXT[],
    hashtags TEXT[],
    mentioned_users UUID[],
    post_type VARCHAR(20) DEFAULT 'text', -- text, image, video, poll
    is_premium BOOLEAN DEFAULT FALSE,
    views_count INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    ipfs_hash VARCHAR(100),
    nft_token_id BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 关注关系表
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id)
);

-- 点赞表
CREATE TABLE likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, post_id)
);

-- 评论表
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID REFERENCES users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- NFT 元数据表
CREATE TABLE nfts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token_id BIGINT UNIQUE NOT NULL,
    owner_address VARCHAR(42) NOT NULL,
    creator_address VARCHAR(42) NOT NULL,
    metadata_uri TEXT NOT NULL,
    name VARCHAR(200),
    description TEXT,
    image_url TEXT,
    attributes JSONB,
    contract_address VARCHAR(42),
    transaction_hash VARCHAR(66),
    minted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 交易记录表
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tx_hash VARCHAR(66) UNIQUE NOT NULL,
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42),
    tx_type VARCHAR(50) NOT NULL, -- mint, transfer, stake, unstake, etc.
    amount NUMERIC(78, 0),
    token_address VARCHAR(42),
    block_number BIGINT,
    gas_used BIGINT,
    gas_price NUMERIC(78, 0),
    status VARCHAR(20), -- pending, confirmed, failed
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 通知表
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- like, comment, follow, mention, etc.
    title VARCHAR(200),
    content TEXT,
    related_user_id UUID REFERENCES users(id),
    related_post_id UUID REFERENCES posts(id),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 索引优化
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_hashtags ON posts USING GIN(hashtags);
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);
CREATE INDEX idx_likes_user_post ON likes(user_id, post_id);
CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_nfts_owner ON nfts(owner_address);
CREATE INDEX idx_transactions_hash ON transactions(tx_hash);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
```

### 2.2 Redis 缓存策略

```javascript
// 缓存键设计
const REDIS_KEYS = {
  // 用户缓存
  USER_PROFILE: (userId) => `user:${userId}:profile`,
  USER_FOLLOWERS: (userId) => `user:${userId}:followers`,
  USER_FOLLOWING: (userId) => `user:${userId}:following`,

  // 帖子缓存
  POST_DETAIL: (postId) => `post:${postId}`,
  POST_LIKES: (postId) => `post:${postId}:likes`,
  POST_COMMENTS: (postId) => `post:${postId}:comments`,

  // 热门排行
  TRENDING_POSTS: 'trending:posts',
  TRENDING_USERS: 'trending:users',
  TRENDING_HASHTAGS: 'trending:hashtags',

  // 计数器
  TOTAL_USERS: 'stats:total_users',
  TOTAL_POSTS: 'stats:total_posts',

  // 会话
  USER_SESSION: (sessionId) => `session:${sessionId}`,

  // 限流
  RATE_LIMIT: (userId, action) => `ratelimit:${userId}:${action}`
};

// 缓存过期时间
const CACHE_TTL = {
  USER_PROFILE: 3600,      // 1小时
  POST_DETAIL: 1800,       // 30分钟
  TRENDING: 300,           // 5分钟
  SESSION: 86400,          // 24小时
  RATE_LIMIT: 60          // 1分钟
};
```

### 2.3 Kafka 消息队列设计

```javascript
// 主题设计
const KAFKA_TOPICS = {
  // 用户事件
  USER_CREATED: 'user.created',
  USER_UPDATED: 'user.updated',
  USER_VERIFIED: 'user.verified',

  // 内容事件
  POST_CREATED: 'post.created',
  POST_UPDATED: 'post.updated',
  POST_DELETED: 'post.deleted',

  // 社交事件
  USER_FOLLOWED: 'social.followed',
  POST_LIKED: 'social.liked',
  COMMENT_CREATED: 'social.commented',

  // 区块链事件
  NFT_MINTED: 'blockchain.nft.minted',
  TOKEN_TRANSFERRED: 'blockchain.token.transferred',
  STAKING_DEPOSITED: 'blockchain.staking.deposited',

  // 系统事件
  NOTIFICATION_CREATED: 'system.notification',
  EMAIL_SEND: 'system.email',
  ANALYTICS_EVENT: 'system.analytics'
};
```

### 2.4 Elasticsearch 索引设计

```json
{
  "mappings": {
    "properties": {
      "id": { "type": "keyword" },
      "author": {
        "properties": {
          "id": { "type": "keyword" },
          "username": { "type": "keyword" },
          "displayName": { "type": "text" }
        }
      },
      "content": {
        "type": "text",
        "analyzer": "standard",
        "fields": {
          "raw": { "type": "keyword" }
        }
      },
      "hashtags": { "type": "keyword" },
      "mediaUrls": { "type": "keyword" },
      "postType": { "type": "keyword" },
      "likesCount": { "type": "integer" },
      "commentsCount": { "type": "integer" },
      "createdAt": { "type": "date" },
      "suggest": {
        "type": "completion",
        "analyzer": "simple"
      }
    }
  }
}
```

---

## 💻 阶段 3: 后端代码实现

### 3.1 技术栈
- Node.js + Express
- TypeScript
- PostgreSQL (pg)
- Redis (ioredis)
- Kafka (kafkajs)
- Elasticsearch (@elastic/elasticsearch)
- Ethers.js (区块链交互)
- IPFS (ipfs-http-client)

### 3.2 项目结构
```
backend/
├── src/
│   ├── config/           # 配置文件
│   │   ├── database.ts
│   │   ├── redis.ts
│   │   ├── kafka.ts
│   │   └── blockchain.ts
│   ├── models/           # 数据模型
│   ├── services/         # 业务逻辑
│   ├── controllers/      # 控制器
│   ├── routes/           # 路由
│   ├── middlewares/      # 中间件
│   ├── utils/            # 工具函数
│   ├── events/           # 事件处理
│   └── index.ts          # 入口文件
├── tests/                # 测试文件
└── package.json
```

---

## ⛓️ 阶段 4: 智能合约开发

### 4.1 合约列表

#### SocialToken.sol (ERC20)
- 平台治理代币
- 质押挖矿
- 投票权重

#### SocialNFT.sol (ERC721)
- 内容 NFT 化
- 创作者认证徽章
- 特殊权益 NFT

#### ContentRegistry.sol
- 内容版权登记
- 内容打赏
- 版税分配

#### Governance.sol
- DAO 提案
- 投票机制
- 财库管理

#### Staking.sol
- 代币质押
- 收益分配
- 锁定期管理

---

## 🧪 阶段 5: 全面测试

### 5.1 测试类型

#### 后端测试
- 单元测试 (Jest)
- 集成测试 (Supertest)
- API 测试
- 性能测试 (Artillery)
- 负载测试

#### 智能合约测试
- 单元测试 (Hardhat)
- 集成测试
- Gas 优化测试
- 边界测试

#### 端到端测试
- 前后端联调
- 区块链交互测试
- 用户流程测试

---

## 🌐 阶段 6: Sepolia 链上测试

### 6.1 测试计划
1. 合约部署
2. 功能验证
3. 交互测试
4. 性能测试
5. 记录所有交易哈希

---

## 🔒 阶段 7: 安全审计

### 7.1 审计内容
- 智能合约安全审计
- API 安全测试
- 数据库安全检查
- 前端安全扫描

---

## 📚 阶段 8: 文档整理

### 8.1 文档列表
1. README.md (主文档)
2. API_DOCUMENTATION.md
3. SMART_CONTRACT_DOCUMENTATION.md
4. TESTING_REPORT.md
5. SECURITY_AUDIT_REPORT.md
6. DEPLOYMENT_GUIDE.md

---

## ⏱️ 时间估算

| 阶段 | 预计时间 | 状态 |
|------|---------|------|
| 阶段 1-2 | 2-3 小时 | 进行中 |
| 阶段 3 | 3-4 小时 | 待开始 |
| 阶段 4 | 2-3 小时 | 待开始 |
| 阶段 5 | 2-3 小时 | 待开始 |
| 阶段 6 | 1-2 小时 | 待开始 |
| 阶段 7 | 1-2 小时 | 待开始 |
| 阶段 8 | 1-2 小时 | 待开始 |

**总计**: 约 12-19 小时

---

这是一个大型项目,我将分阶段实施。现在开始阶段 1 和阶段 2 的详细设计。是否继续?
