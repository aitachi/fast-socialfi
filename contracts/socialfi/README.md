# Fast SocialFi 智能合约

## 概览

Fast SocialFi 是一个去中心化社交金融平台的智能合约系统,包含 5 个核心合约。

## 核心合约

### 1. SocialToken (ERC20)
**文件**: `core/SocialToken.sol`
**地址**: 0x8110ff880fa5a49Ba6C64B01258fD39bC76654c6

治理代币,具有以下特性:
- 总供应量: 1,000,000,000 SOCIAL
- ERC20Votes (治理投票)
- Pausable (紧急暂停)
- 反女巫攻击 (转账冷却)

### 2. SocialNFT (ERC721)
**文件**: `core/SocialNFT.sol`
**地址**: 0x7D13829EF503AC0A9d935a708c1948e9cAEe1b3c

内容 NFT,具有以下特性:
- ERC2981 版税标准
- 铸造费用: 0.001 ETH
- IPFS 元数据存储
- 白名单机制

### 3. ContentRegistry
**文件**: `core/ContentRegistry.sol`
**地址**: 0xA9b895C81ba07de36BA567E06351D4F23aE196af

内容版权注册和打赏系统:
- 内容版权登记
- ETH/SOCIAL 打赏
- 平台费率: 2.5%
- 授权管理

### 4. Staking
**文件**: `core/Staking.sol`
**地址**: 0x7c9C7ED2363A76D0209c4c815E80f9784c29a0B5

质押挖矿系统:
- 基础 APY: 10%
- 多种锁定期 (7/30/90 天)
- 倍数系统 (1x/1.5x/2x)
- 提前解锁惩罚: 20%

### 5. Governance
**文件**: `core/Governance.sol`
**地址**: 0x4a5e2bD11D59a97f74635972c83Eef08E115d8FD

DAO 治理系统:
- 提案门槛: 100,000 SOCIAL
- 投票期: 3 天
- 时间锁: 2 天
- 法定人数: 10%

## 部署

```bash
# 编译合约
npx hardhat compile

# 部署到 Sepolia
npx hardhat run scripts/socialfi/deploy.ts --network sepolia

# 验证合约
npx hardhat run scripts/socialfi/verify.ts --network sepolia

# 测试合约
npx hardhat run scripts/socialfi/interact.ts --network sepolia
```

## 安全特性

- ReentrancyGuard (防重入攻击)
- Pausable (紧急暂停)
- Ownable (访问控制)
- Timelock (时间锁)
- Max Supply (供应量限制)

## 文档

详见 `SEPOLIA_TEST_REPORT.md` 获取完整部署和测试报告。
