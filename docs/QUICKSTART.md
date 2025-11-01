# 🚀 SocialFi 快速启动指南

本指南将帮助你在 5 分钟内启动并运行 SocialFi 后端平台。

## 📋 前置要求

### 必需软件
```bash
# 1. Foundry (智能合约开发)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 2. Go 1.21+ (后端服务)
# Windows: 从 https://golang.org/dl/ 下载安装

# 3. MySQL 8.0+ (数据库)
# Windows: 从 https://dev.mysql.com/downloads/mysql/ 下载安装

# 4. Git
# Windows: 从 https://git-scm.com/download/win 下载安装
```

### 可选软件
```bash
# Redis (缓存层 - 可选)
# Windows: 从 https://github.com/microsoftarchive/redis/releases 下载

# Node.js (如果需要运行前端)
# Windows: 从 https://nodejs.org/ 下载安装
```

## ⚡ 快速启动步骤

### 1. 克隆并设置项目

```bash
# 进入项目目录
cd fast-socialfi

# 创建 .env 文件
cp .env.example .env

# 编辑 .env 文件，填入你的配置
# 特别注意：
# - SEPOLIA_RPC_URL: 你的 Infura/Alchemy RPC URL
# - PRIVATE_KEY: 你的钱包私钥（测试账户）
# - DB_PASSWORD: MySQL 密码（如果有）
```

### 2. 安装依赖

```bash
# 安装 Solidity 依赖
forge install

# 安装 Go 依赖
cd backend
go mod download
cd ..
```

### 3. 设置数据库

```bash
# 创建数据库
mysql -u root -p

# 在 MySQL 命令行中：
CREATE DATABASE socialfi_db;
exit;

# 运行迁移脚本
mysql -u root -p socialfi_db < database/migrations/001_initial_schema.sql

# 插入测试数据
mysql -u root -p socialfi_db < database/seeds/001_test_data.sql
```

### 4. 编译并测试智能合约

```bash
# 编译合约
forge build

# 运行测试
forge test -vvv

# 查看测试覆盖率
forge coverage

# 查看 gas 报告
forge test --gas-report
```

### 5. 部署合约到本地测试网

```bash
# 终端 1: 启动本地区块链
anvil

# 终端 2: 部署合约
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast

# 复制输出的合约地址并更新 .env 文件
# FACTORY_ADDRESS=<工厂合约地址>
# BONDING_CURVE_ADDRESS=<曲线合约地址>
```

### 6. 启动后端服务

```bash
cd backend

# 运行服务
go run cmd/api/main.go

# 或者构建后运行
go build -o socialfi-api cmd/api/main.go
./socialfi-api
```

服务将在 `http://localhost:8080` 启动

### 7. 测试 API

```bash
# 健康检查
curl http://localhost:8080/health

# 应该返回：
# {"status":"healthy","time":1234567890}

# 获取测试用户
curl http://localhost:8080/api/v1/users/0x742d35cc6634c0532925a3b844bc9e7595f0beb1
```

## 🧪 运行测试

### Solidity 测试
```bash
# 单元测试
forge test -vvv

# 测试特定合约
forge test --match-contract CircleFactoryTest -vvv

# 测试特定函数
forge test --match-test testCreateCircle -vvv

# Fuzz 测试
forge test --fuzz-runs 1000

# Gas 快照
forge snapshot
```

### Go 测试
```bash
cd backend

# 运行所有测试
go test ./... -v

# 运行特定包的测试
go test ./internal/services -v

# 测试覆盖率
go test ./... -cover

# 生成覆盖率报告
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

## 🌐 部署到测试网 (Sepolia)

### 1. 准备工作

```bash
# 确保你有测试 ETH
# 获取测试 ETH: https://sepoliafaucet.com/
# 或: https://cloud.google.com/application/web3/faucet/ethereum/sepolia

# 确认你的 .env 文件包含：
# SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
# PRIVATE_KEY=your_private_key
# ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 2. 部署合约

```bash
# 部署并验证合约
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

# 记录合约地址到 docs/deployments.md
```

### 3. 更新配置

```bash
# 将部署的合约地址添加到 .env
FACTORY_ADDRESS=<sepolia_factory_address>
BONDING_CURVE_ADDRESS=<sepolia_bonding_curve_address>
NETWORK=sepolia
```

### 4. 启动后端

```bash
cd backend
go run cmd/api/main.go
```

## 🔍 常见问题

### Q: `forge: command not found`
```bash
# 安装 Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Q: MySQL 连接失败
```bash
# 检查 MySQL 服务是否运行
# Windows: 打开服务管理器，启动 MySQL 服务

# 检查 .env 中的数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=socialfi_db
```

### Q: 合约编译失败
```bash
# 清理缓存
forge clean

# 重新安装依赖
rm -rf lib
forge install

# 重新编译
forge build
```

### Q: Go 依赖下载失败
```bash
# 设置 Go 代理（中国用户）
go env -w GOPROXY=https://goproxy.cn,direct

# 清理模块缓存
go clean -modcache

# 重新下载
go mod download
```

## 📚 下一步

1. **阅读文档**
   - [API 文档](../docs/api.md)
   - [架构文档](../docs/architecture.md)
   - [安全文档](../docs/security.md)

2. **创建测试圈子**
   ```bash
   # 使用 Web3 钱包连接到你的本地/测试网
   # 调用 CircleFactory.createCircle() 创建你的第一个圈子
   ```

3. **开发前端**
   - 参考 API 端点文档
   - 使用 wagmi/ethers.js 连接智能合约
   - 使用 axios 调用后端 API

4. **运行负载测试**
   ```bash
   # 安装 k6
   # 运行性能测试
   k6 run tests/load/api_load.test.js
   ```

5. **安全审计**
   ```bash
   # 静态分析
   slither contracts/

   # Gas 优化
   forge test --gas-report

   # 查看审计检查清单
   cat docs/security.md
   ```

## 🎯 功能演示脚本

### 创建圈子示例
```bash
# 使用 cast 命令创建圈子
cast send $FACTORY_ADDRESS \
  "createCircle(string,string,string,uint8,uint256,uint256,uint256,uint256)" \
  "Tech Enthusiasts" \
  "TECH" \
  "A community for tech lovers" \
  0 \
  1000000000000000 \
  1000000000000000 \
  0 \
  0 \
  --value 0.01ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### 购买代币示例
```bash
# 获取代币地址
TOKEN_ADDRESS=$(cast call $FACTORY_ADDRESS "circles(uint256)" 1 --rpc-url $SEPOLIA_RPC_URL | head -n 2 | tail -n 1)

# 购买代币
cast send $BONDING_CURVE_ADDRESS \
  "buyTokens(address,uint256)" \
  $TOKEN_ADDRESS \
  0 \
  --value 0.1ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

## 🛠 开发工具

### 推荐的 IDE 和扩展

**VS Code:**
- Go (官方)
- Solidity (Juan Blanco)
- Prettier
- GitLens
- Thunder Client (API 测试)

**其他工具:**
- Remix IDE (合约开发)
- Hardhat (可选，作为 Foundry 补充)
- Postman (API 测试)
- DBeaver (数据库管理)
- MetaMask (Web3 钱包)

## 📞 获取帮助

- 📖 查看 [完整文档](../docs/)
- 🐛 提交 [Issue](https://github.com/your-repo/issues)
- 💬 加入社区讨论
- 📧 联系开发团队

## 🎉 成功！

如果你能够：
- ✅ 编译智能合约
- ✅ 运行测试（全部通过）
- ✅ 部署合约到本地/测试网
- ✅ 启动后端服务
- ✅ 成功调用 API

**恭喜你！SocialFi 后端平台已经成功运行！** 🚀

下一步：根据你的需求扩展功能，或开始开发前端应用。

---

**最后更新**: 2025-10-31
**版本**: 1.0.0
