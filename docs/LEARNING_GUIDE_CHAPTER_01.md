# Fast SocialFi 技术学习文档 - 第1章：项目架构与技术栈

**作者**: Aitachi
**邮箱**: 44158892@qq.com
**日期**: 2025-11-02
**版本**: 1.0

---

## 目录

1. [项目概述](#项目概述)
2. [核心价值与创新点](#核心价值与创新点)
3. [技术架构总览](#技术架构总览)
4. [技术栈详解](#技术栈详解)
5. [项目目录结构](#项目目录结构)
6. [系统架构设计](#系统架构设计)
7. [数据流转分析](#数据流转分析)

---

## 1. 项目概述

### 1.1 什么是 Fast SocialFi?

Fast SocialFi 是一个**去中心化社交金融（SocialFi）平台**，它深度融合了社交网络与 DeFi（去中心化金融）机制。项目的核心理念是：

> **让社交互动产生真实的经济价值，让内容创作者通过社区获得可持续的收益。**

### 1.2 核心功能

| 功能模块 | 说明 | 技术实现 |
|---------|------|---------|
| **Circle（社交圈）** | 创建者建立独立社群，发行专属 Token | 智能合约 + Bonding Curve |
| **Token 交易** | 基于联合曲线的动态定价机制 | Solidity + Web3.js |
| **内容激励** | 内容获得打赏、点赞即可获得收益 | PostgreSQL + Redis |
| **治理投票** | 社区成员通过 Token 参与决策 | DAO 智能合约 |
| **DeFi 集成** | Staking、借贷、收益分配 | Solidity 合约群 |
| **实时搜索** | 全文搜索、话题推荐 | Elasticsearch |
| **消息队列** | 异步处理、事件溯源 | Kafka |

### 1.3 项目特点

1. **完整的全栈实现**：从智能合约到前端，涵盖完整的 Web3 开发流程
2. **双后端架构**：Go 负责高性能交易，Node.js 负责社交功能
3. **企业级基础设施**：PostgreSQL + Redis + Elasticsearch + Kafka
4. **生产级代码质量**：安全审计、Gas 优化、完整测试

---

## 2. 核心价值与创新点

### 2.1 Bonding Curve（联合曲线）创新

**传统 Token 经济问题**：
- 早期投资者 Dump（抛售）导致价格崩盘
- 流动性不足，无法自由交易
- 价格操纵严重

**Bonding Curve 解决方案**：
```
价格随供应量自动调整
价格 = f(当前总供应量)

支持的曲线类型：
1. LINEAR（线性）: price = basePrice + slope × supply
2. EXPONENTIAL（指数）: price = basePrice × (1 + r)^supply
3. SIGMOID（S型）: price = basePrice + (maxPrice - basePrice) × supply / (inflectionPoint + supply)
```

**优势**：
- ✅ 自动做市（AMM），无需交易对手
- ✅ 价格透明可预测
- ✅ 早期支持者获得更好的价格
- ✅ 流动性始终存在

### 2.2 多层安全设计

| 安全层级 | 技术手段 | 代码位置 |
|---------|---------|---------|
| **合约安全** | ReentrancyGuard、Pausable | `contracts/core/*.sol` |
| **访问控制** | Ownable、onlyFactory 修饰符 | `CircleFactory.sol:64` |
| **参数验证** | require 检查、边界验证 | `BondingCurve.sol:103` |
| **费用限制** | 最高 5% 手续费上限 | `CircleToken.sol:134` |
| **紧急暂停** | pause/unpause 功能 | `CircleToken.sol:217` |

### 2.3 Gas 优化技术

**1. 存储优化**：
```solidity
// ❌ 低效写法 (3个 SSTORE 操作)
circles[id].owner = newOwner;
circles[id].active = true;
circles[id].tokenAddress = token;

// ✅ 优化写法 (1个 SSTORE 操作)
Circle memory circle = Circle({
    owner: newOwner,
    active: true,
    tokenAddress: token
});
circles[id] = circle;
```

**2. 二分查找算法**（`BondingCurve.sol:199-218`）：
```solidity
// 用于反向计算：给定 ETH，计算能买多少 Token
function calculateTokensForEth(...) {
    uint256 low = 0;
    uint256 high = ethAmount * 1000;

    while (low <= high) {
        uint256 mid = (low + high) / 2;
        uint256 cost = calculateBuyCost(..., mid, ...);

        if (cost == ethAmount) return mid;
        else if (cost < ethAmount) {
            tokensToMint = mid;
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
}
```

---

## 3. 技术架构总览

### 3.1 三层架构

```
┌─────────────────────────────────────────────────────────┐
│                      前端层（未包含）                     │
│                  React + Vite + Web3.js                 │
└─────────────────────────────────────────────────────────┘
                            ↓ HTTP/WebSocket
┌─────────────────────────────────────────────────────────┐
│                       后端服务层                         │
├──────────────────────┬──────────────────────────────────┤
│   Go Backend API     │   Node.js Backend API            │
│   (8080端口)          │   (3000端口)                     │
│                      │                                  │
│ • 高性能交易处理      │ • 社交功能                        │
│ • Web3 集成          │ • 内容管理                        │
│ • Circle 管理        │ • 搜索引擎                        │
│ • 实时行情           │ • 消息队列                        │
└──────────────────────┴──────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                     数据持久化层                         │
├──────────────┬──────────────┬──────────────┬────────────┤
│ PostgreSQL   │    Redis     │ Elasticsearch│   Kafka    │
│ (5432)       │   (6379)     │   (9200)     │  (9092)    │
│              │              │              │            │
│ 关系型数据    │ 缓存+会话    │ 全文搜索      │ 消息队列   │
└──────────────┴──────────────┴──────────────┴────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                     区块链层                             │
│           Ethereum (Sepolia Testnet)                    │
│                                                         │
│  • CircleFactory    • BondingCurve   • CircleToken     │
│  • Governance       • Staking        • NFT             │
└─────────────────────────────────────────────────────────┘
```

### 3.2 微服务设计理念

虽然项目未采用完全的微服务架构，但体现了**职责分离**原则：

| 服务 | 职责 | 技术选型理由 |
|------|------|-------------|
| **Go API** | 交易处理、区块链交互 | 高并发、低延迟、强类型 |
| **Node.js API** | 社交功能、内容管理 | 生态丰富、异步IO、快速开发 |
| **PostgreSQL** | 核心业务数据 | ACID 事务、关系完整性 |
| **Redis** | 缓存、会话、实时排行 | 内存速度、丰富数据结构 |
| **Elasticsearch** | 全文搜索、日志分析 | 倒排索引、分布式搜索 |
| **Kafka** | 事件溯源、异步处理 | 高吞吐、持久化、顺序保证 |

---

## 4. 技术栈详解

### 4.1 区块链层

#### 4.1.1 Solidity ^0.8.20

**选择理由**：
- ✅ 内置溢出检查（Checked Arithmetic）
- ✅ Custom Errors 节省 Gas
- ✅ 更好的错误处理机制

**核心依赖**：
```json
{
  "@openzeppelin/contracts": "^5.0.0",  // 安全的合约基类
  "hardhat": "^2.19.0",                 // 开发框架
  "ethers": "^6.9.0"                    // Web3 库
}
```

#### 4.1.2 Hardhat 开发环境

**配置亮点**（`hardhat.config.ts`）：
```typescript
{
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200  // 优化部署成本
      }
    }
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 'auto'  // 自动调整 Gas 价格
    }
  }
}
```

### 4.2 Go 后端 (v1.21+)

#### 4.2.1 核心库

| 库名 | 版本 | 用途 | 代码示例 |
|-----|------|------|---------|
| **Gin** | v1.9+ | HTTP 框架 | `backend/cmd/api/main.go:76` |
| **GORM** | v1.25+ | ORM | `backend/internal/database/database.go` |
| **go-ethereum** | v1.13+ | Web3 集成 | `backend/internal/web3/web3_service.go` |
| **godotenv** | v1.5+ | 环境变量 | `backend/cmd/api/main.go:29` |

#### 4.2.2 架构特点

**分层架构**：
```
main.go (入口)
  ↓
handlers/ (HTTP 处理)
  ↓
services/ (业务逻辑)
  ↓
repository/ (数据访问)
  ↓
models/ (数据模型)
```

**依赖注入示例**（`main.go:62-69`）：
```go
userService := services.NewUserService(db)
circleService := services.NewCircleService(db)
tradeService := services.NewTradeService(db)
web3Service, _ := services.NewWeb3Service(cfg.Blockchain)

// 通过构造函数注入依赖
userHandler := handlers.NewUserHandler(userService, web3Service)
```

### 4.3 Node.js 后端 (v18+)

#### 4.3.1 核心技术

```json
{
  "express": "^4.18.0",           // Web 框架
  "typeorm": "^0.3.0",            // ORM
  "pg": "^8.11.0",                // PostgreSQL 驱动
  "ioredis": "^5.3.0",            // Redis 客户端
  "@elastic/elasticsearch": "^8.0",
  "kafkajs": "^2.2.0",
  "helmet": "^7.0.0",             // 安全中间件
  "compression": "^1.7.4"         // Gzip 压缩
}
```

#### 4.3.2 类型安全

使用 **TypeScript** 实现强类型约束：

```typescript
// backend-node/src/types/index.ts
export interface User {
  id: number;
  wallet_address: string;
  username?: string;
  created_at: Date;
}

export interface Post {
  id: number;
  author_id: number;
  content: string;
  media_urls: string[];
  like_count: number;
}
```

### 4.4 数据库设计

#### 4.4.1 PostgreSQL 表结构

**核心表**（`database/schema.sql`）：

| 表名 | 主要字段 | 索引 | 用途 |
|-----|---------|------|------|
| `users` | wallet_address, username | ✅ wallet_address | 用户信息 |
| `posts` | author_id, content, hashtags | ✅ author_id<br>✅ created_at | 帖子内容 |
| `follows` | follower_id, following_id | ✅ (follower_id, following_id) | 关注关系 |
| `circles` | token_address, curve_type | ✅ token_address | Circle 信息 |
| `transactions` | tx_hash, tx_type | ✅ tx_hash<br>✅ (user_id, created_at) | 交易记录 |

**设计亮点**：

1. **JSONB 类型**：
```sql
CREATE TABLE posts (
    ...
    media_urls JSONB DEFAULT '[]'::jsonb,  -- 灵活的媒体列表
    metadata JSONB DEFAULT '{}'::jsonb     -- 扩展字段
);
```

2. **数组类型**：
```sql
hashtags TEXT[],      -- 话题标签
mentions BIGINT[]     -- @提及的用户
```

3. **CHECK 约束**：
```sql
CHECK (follower_id != following_id)  -- 禁止自己关注自己
```

#### 4.4.2 Redis 数据结构

| 数据类型 | Key 模式 | 用途 | TTL |
|---------|---------|------|-----|
| STRING | `session:{token}` | 用户会话 | 7天 |
| HASH | `user:{id}` | 用户缓存 | 1小时 |
| ZSET | `trending:circles` | 热门 Circle 排行 | 实时 |
| LIST | `feed:{userId}` | 用户信息流 | 24小时 |
| SET | `online:users` | 在线用户集合 | 实时 |

---

## 5. 项目目录结构

```
fast-socialfi/
├── contracts/                    # 智能合约
│   ├── core/                     # 核心合约
│   │   ├── CircleFactory.sol    # Circle 工厂（创建 Circle）
│   │   ├── CircleToken.sol      # Circle Token（ERC20）
│   │   └── BondingCurve.sol     # 联合曲线（定价算法）
│   ├── finance/                  # DeFi 模块
│   │   ├── StakingPool.sol      # Staking 质押
│   │   ├── RevenueDistribution.sol  # 收益分配
│   │   └── SocialLending.sol    # 社交借贷
│   ├── governance/               # 治理模块
│   │   └── CircleGovernor.sol   # DAO 治理
│   ├── libraries/                # 合约库
│   │   └── BondingCurveMath.sol # 数学计算库
│   └── socialfi/                 # SocialFi 特定合约
│       └── core/
│           ├── ContentRegistry.sol  # 内容注册
│           ├── SocialNFT.sol       # 社交 NFT
│           └── Governance.sol      # 社区治理
│
├── backend/                      # Go 后端
│   ├── cmd/api/                  # 应用入口
│   │   └── main.go              # 主程序
│   ├── internal/                 # 内部包
│   │   ├── config/              # 配置管理
│   │   ├── database/            # 数据库连接
│   │   ├── handler/             # HTTP 处理器
│   │   ├── middleware/          # 中间件
│   │   ├── models/              # 数据模型
│   │   ├── repository/          # 数据仓库
│   │   ├── service/             # 业务逻辑
│   │   └── web3/                # Web3 集成
│   └── tests/                   # 测试代码
│
├── backend-node/                 # Node.js 后端
│   ├── src/
│   │   ├── config/              # 配置（DB、Redis、ES、Kafka）
│   │   ├── controllers/         # 控制器
│   │   ├── middlewares/         # 中间件
│   │   ├── routes/              # 路由定义
│   │   ├── services/            # 业务服务
│   │   ├── types/               # TypeScript 类型
│   │   ├── utils/               # 工具函数
│   │   └── index.ts             # 应用入口
│   └── package.json
│
├── database/                     # 数据库
│   ├── schema.sql               # 表结构定义
│   ├── seed.sql                 # 测试数据
│   └── migrations/              # 数据迁移
│
├── scripts/                      # 脚本
│   └── socialfi/
│       ├── deploy.ts            # 合约部署
│       ├── verify.ts            # 合约验证
│       └── interact.ts          # 合约交互
│
├── tests/                        # 测试套件
│   ├── e2e/                     # 端到端测试
│   ├── performance/             # 性能测试
│   └── security/                # 安全测试
│
├── docker-compose.yml           # Docker 编排
├── hardhat.config.ts            # Hardhat 配置
├── start.bat / start.sh         # 启动脚本
└── README.md                    # 项目文档
```

---

## 6. 系统架构设计

### 6.1 请求处理流程

**示例：用户购买 Circle Token**

```
1. 前端发起请求
   ↓
2. Go Backend (/api/v1/trades/buy)
   ├─ 验证用户身份 (JWT)
   ├─ 检查 Circle 状态 (PostgreSQL)
   ├─ 调用智能合约 (Web3)
   └─ 记录交易 (PostgreSQL)
   ↓
3. 区块链执行
   ├─ BondingCurve.buyTokens()
   ├─ 计算 Token 数量
   ├─ Mint Token
   └─ 转账 ETH
   ↓
4. 异步处理
   ├─ Kafka 发送事件 (trade.completed)
   ├─ Node.js 消费事件
   └─ 更新 Elasticsearch 索引
   ↓
5. 返回结果给前端
```

### 6.2 缓存策略

**多级缓存设计**：

```
请求
  ↓
应用层缓存 (Node.js Memory Cache)
  ↓ Miss
Redis 缓存 (1小时TTL)
  ↓ Miss
PostgreSQL 数据库
  ↓
写回 Redis
  ↓
返回数据
```

**缓存键设计**：
```typescript
// 用户信息
`user:${walletAddress}`

// Circle 详情
`circle:${circleId}`

// Token 价格（短TTL：1分钟）
`price:${tokenAddress}:${timestamp / 60000 | 0}`

// 热门排行（实时更新）
`trending:circles:${date}`
```

### 6.3 数据一致性

**最终一致性模型**：

| 场景 | 策略 | 实现方式 |
|------|------|---------|
| **链上→链下** | 事件监听 + 重试 | Web3 Event Listener |
| **缓存失效** | TTL + 主动刷新 | Redis Expire + LRU |
| **搜索同步** | 异步索引 | Kafka → Elasticsearch |
| **统计数据** | 定时聚合 | Cron Job |

---

## 7. 数据流转分析

### 7.1 创建 Circle 流程

```
1. 用户调用 CircleFactory.createCircle()
   ├─ 支付创建费用 (0.01 ETH)
   ├─ 部署 CircleToken 合约
   ├─ 初始化 BondingCurve
   └─ 触发 CircleCreated 事件

2. Go Backend 监听事件
   ├─ 解析事件参数
   ├─ 写入 PostgreSQL (circles 表)
   └─ 发送 Kafka 消息

3. Node.js 后端消费消息
   ├─ 更新 Elasticsearch 索引
   ├─ 创建 Redis 缓存
   └─ 推送通知给关注者
```

### 7.2 交易数据流

```
链上交易 (Transaction)
  ↓
Go Backend 同步 (tx_hash)
  ↓
PostgreSQL 写入 (transactions 表)
  ↓
Redis 更新缓存 (用户余额)
  ↓
Kafka 发送事件 (trade.completed)
  ↓
Node.js 消费
  ├─ Elasticsearch 索引 (交易记录)
  ├─ 更新统计数据 (24h 交易量)
  └─ WebSocket 推送 (实时行情)
```

---

## 总结

本章介绍了 Fast SocialFi 项目的整体架构和技术选型。核心要点：

1. **三层架构**：前端 → 后端 (Go + Node.js) → 区块链
2. **双后端设计**：Go 负责高性能交易，Node.js 负责社交功能
3. **企业级基础设施**：PostgreSQL + Redis + Elasticsearch + Kafka
4. **Bonding Curve 创新**：自动做市、价格透明、流动性保证
5. **多层安全机制**：合约安全、访问控制、参数验证
6. **Gas 优化技术**：存储优化、二分查找、批量操作

**下一章预告**：第2章将深入分析智能合约代码，详解 Bonding Curve 数学原理、安全机制、Gas 优化技巧等核心技术。

---

**文档导航**：
- [第2章：智能合约深度解析 →](./LEARNING_GUIDE_CHAPTER_02.md)
