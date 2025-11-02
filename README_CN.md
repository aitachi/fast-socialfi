# Fast SocialFi - 去中心化社交金融平台

**作者/Author**: Aitachi  
**邮箱/Email**: 44158892@qq.com  
**日期/Date**: 11-02-2025 17

---

[![Ethereum](https://img.shields.io/badge/Ethereum-Sepolia-blue)](https://sepolia.etherscan.io/)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-orange)](https://soliditylang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green)](https://nodejs.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

Fast SocialFi 是一个基于以太坊构建的去中心化社交金融(SocialFi)平台，深度整合社交网络与DeFi机制。

**开发者**: Aitachi <44158892@qq.com>  
**版本**: v1.0.0  
**状态**: 生产就绪

---

## 核心功能

### 社交功能
- 用户注册/登录 (钱包签名)
- 内容创作与分享 (文本/图片/视频)
- 点赞/评论/转发
- 关注/粉丝系统
- 实时通知

### DeFi功能
- ERC20治理代币 (SOCIAL)
- ERC721内容NFT
- 内容版权登记
- 质押挖矿 (7/30/90天锁定期)
- DAO治理系统

---

## 技术架构

### 技术栈
- **区块链**: Solidity 0.8.20, Hardhat, OpenZeppelin
- **后端**: Node.js 18+, TypeScript, Express
- **数据库**: PostgreSQL 16+, Redis 7+
- **消息队列**: Apache Kafka 3.7+
- **搜索引擎**: Elasticsearch 8.11+

### 系统架构
```
前端 (React/Next.js)
      ↓
TypeScript后端API
      ↓
PostgreSQL + Redis + Kafka + Elasticsearch
      ↓
以太坊区块链 (智能合约)
```

---

## 快速开始

### 1. 环境准备
```bash
# 启动数据库服务
docker-compose -f docker-compose.full.yml up -d

# 或最小模式 (仅PostgreSQL + Redis, 41MB)
./set-minimal-mode.bat
```

### 2. 安装依赖
```bash
npm install
cd backend-node && npm install
```

### 3. 初始化数据库
```bash
psql -U socialfi -d socialfi_db -f database/schema.sql
psql -U socialfi -d socialfi_db -f database/seed.sql
```

### 4. 启动后端
```bash
cd backend-node
npm run dev
```

### 5. 测试
```bash
# 后端测试
cd backend-node && npm test

# 合约测试
npx hardhat test

# 性能测试
cd tests/performance && artillery run load-test.yml
```

---

## Sepolia测试网合约

| 合约 | 地址 | Etherscan |
|------|------|-----------|
| SocialToken | `0x8110ff880fa5a49Ba6C64B01258fD39bC76654c6` | [查看](https://sepolia.etherscan.io/address/0x8110ff880fa5a49Ba6C64B01258fD39bC76654c6) |
| SocialNFT | `0x7D13829EF503AC0A9d935a708c1948e9cAEe1b3c` | [查看](https://sepolia.etherscan.io/address/0x7D13829EF503AC0A9d935a708c1948e9cAEe1b3c) |
| ContentRegistry | `0xA9b895C81ba07de36BA567E06351D4F23aE196af` | [查看](https://sepolia.etherscan.io/address/0xA9b895C81ba07de36BA567E06351D4F23aE196af) |
| Staking | `0x7c9C7ED2363A76D0209c4c815E80f9784c29a0B5` | [查看](https://sepolia.etherscan.io/address/0x7c9C7ED2363A76D0209c4c815E80f9784c29a0B5) |
| Governance | `0x4a5e2bD11D59a97f74635972c83Eef08E115d8FD` | [查看](https://sepolia.etherscan.io/address/0x4a5e2bD11D59a97f74635972c83Eef08E115d8FD) |

---

## 测试结果

**测试通过率**: 100% (112/112)  
**代码覆盖率**: 后端 87.6%, 合约 35.2%  
**性能**: 响应时间 P95 < 178ms, 吞吐量 68 req/s  
**安全评分**: 89/100

详见: [TESTING_REPORT.md](TESTING_REPORT.md)

---

## 项目结构

```
fast-socialfi/
├── backend-node/         # TypeScript后端 (23个文件, 32个API)
├── contracts/socialfi/   # 智能合约 (5个Solidity文件)
├── database/             # 数据库schema (18个表)
├── scripts/              # 部署和管理脚本
├── tests/                # 测试套件
└── docs/                 # API文档
```

详见: [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)

---

## 文档

- [项目概述](PROJECT_OVERVIEW.md)
- [测试报告](TESTING_REPORT.md)
- [API文档](docs/API_DOCUMENTATION.md)
- [English README](README.md)

---

## 联系方式

**开发者**: Aitachi  
**邮箱**: 44158892@qq.com  
**GitHub**: https://github.com/aitachi/fast-socialfi

---

## License

MIT License - 详见 [LICENSE](LICENSE)
