# OpenZeppelin v5 兼容性修复指南

## 问题说明

OpenZeppelin v5.x 引入了重大的 Breaking Changes，主要包括：

1. **目录结构变化**: `security/` → `utils/`
2. **Ownable 构造函数**: 需要传入 `initialOwner` 参数
3. **ERC20 Hooks**: `_beforeTokenTransfer` → `_update`

## 快速修复方法

### 方法1: 使用 OpenZeppelin v4.x（推荐）

```bash
# 卸载 v5
rm -rf lib/openzeppelin-contracts

# 安装 v4.9.6（稳定版）
forge install OpenZeppelin/openzeppelin-contracts@v4.9.6
```

### 方法2: 更新代码以兼容 v5.x

#### 1. 更新 BondingCurve.sol
```solidity
// 修改第48行
constructor(address _factory) Ownable(msg.sender) {  // 添加 Ownable(msg.sender)
    require(_factory != address(0), "Invalid factory");
    factory = _factory;
    transferOwnership(_factory);
}
```

#### 2. 更新 CircleFactory.sol
```solidity
// 修改第50行
constructor(address _platformTreasury) Ownable(msg.sender) {  // 添加 Ownable(msg.sender)
    require(_platformTreasury != address(0), "Invalid treasury");
    platformTreasury = _platformTreasury;
    bondingCurveImpl = address(new BondingCurve(address(this)));
}
```

#### 3. 更新 CircleToken.sol

```solidity
// 修改第69-82行构造函数
constructor(
    string memory name,
    string memory symbol,
    address _circleOwner,
    address _factory,
    address _bondingCurve,
    address _platformTreasury,
    uint256 _circleId
) ERC20(name, symbol) Ownable(_circleOwner) {  // 添加 Ownable(_circleOwner)
    require(_circleOwner != address(0), "Invalid owner");
    // ... rest of constructor
}

// 删除第236-239行的 _beforeTokenTransfer 函数
// 替换为 _update 函数：
function _update(
    address from,
    address to,
    uint256 value
) internal virtual override whenNotPaused {
    super._update(from, to, value);
}
```

## 完整修复脚本

将以下内容保存为 `fix_oz_v5.sh` 并运行：

```bash
#!/bin/bash

# 方法1: 切换到 v4.9.6（最简单）
echo "Removing OpenZeppelin v5..."
rm -rf lib/openzeppelin-contracts

echo "Installing OpenZeppelin v4.9.6..."
forge install OpenZeppelin/openzeppelin-contracts@v4.9.6 --no-commit

echo "Building contracts..."
forge build

echo "Done! If build succeeds, you're ready to go."
```

## 运行修复

```bash
chmod +x fix_oz_v5.sh
./fix_oz_v5.sh
```

## 验证修复

```bash
# 编译合约
forge build

# 运行测试
forge test -vvv

# 如果一切正常，你应该看到：
# ✓ Compiled 33 files with Solc 0.8.20
# ✓ All tests passed
```

## 相关链接

- [OpenZeppelin v5 Migration Guide](https://docs.openzeppelin.com/contracts/5.x/upgrades)
- [Breaking Changes in v5](https://github.com/OpenZeppelin/openzeppelin-contracts/releases/tag/v5.0.0)
- [Foundry Book](https://book.getfoundry.sh/)

## 备注

推荐使用 **方法1（降级到 v4.9.6）**，因为：
1. 更稳定，生产环境广泛使用
2. 无需修改现有代码
3. 文档和社区支持更完善
4. 与大多数项目兼容

如果你需要 v5 的新特性，建议在项目成熟后再进行升级。
