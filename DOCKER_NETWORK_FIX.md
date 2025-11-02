# Docker 网络问题解决方案

## 问题诊断

你遇到的错误是：
```
Error response from daemon: Get "https://registry-1.docker.io/v2/":
context deadline exceeded / connection timeout
```

这表明 Docker 无法连接到 Docker Hub 拉取镜像。

## 解决方案

### 方案 1: 配置 Docker 镜像加速器（推荐）

#### 步骤 1: 打开 Docker Desktop 设置

1. 打开 Docker Desktop
2. 点击右上角的设置图标（齿轮⚙️）
3. 选择左侧的 "Docker Engine"

#### 步骤 2: 配置镜像源

在 JSON 配置中添加以下内容（完整配置示例）：

```json
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live",
    "https://hub.rat.dev",
    "https://docker.anyhub.us.kg",
    "https://dockerhub.icu"
  ]
}
```

#### 步骤 3: 应用并重启

1. 点击 "Apply & Restart" 按钮
2. 等待 Docker Desktop 完全重启（大约 30-60 秒）

#### 步骤 4: 验证配置

打开 PowerShell 或 CMD，运行：
```bash
docker info | findstr "Registry Mirrors"
```

应该能看到配置的镜像源。

#### 步骤 5: 重新启动 Docker 服务

运行：
```bash
docker-start.bat
```

---

### 方案 2: 使用阿里云镜像加速器（中国用户推荐）

#### 步骤 1: 获取专属加速地址

1. 访问：https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors
2. 登录你的阿里云账号（免费）
3. 获取你的专属加速器地址（例如：https://xxxxx.mirror.aliyuncs.com）

#### 步骤 2: 配置加速器

在 Docker Desktop 的 "Docker Engine" 中配置：

```json
{
  "registry-mirrors": [
    "https://你的ID.mirror.aliyuncs.com"
  ]
}
```

---

### 方案 3: 配置网络代理

如果你有 HTTP/HTTPS 代理：

#### 步骤 1: 在 Docker Desktop 中配置

1. 打开 Docker Desktop 设置
2. 选择 "Resources" → "Proxies"
3. 启用 "Manual proxy configuration"
4. 填写代理信息：
   - Web Server (HTTP): http://代理地址:端口
   - Secure Web Server (HTTPS): http://代理地址:端口

#### 步骤 2: 应用并重启

点击 "Apply & Restart"

---

### 方案 4: 使用本地数据库服务（临时方案）

如果暂时无法解决网络问题，可以使用本地已安装的 MySQL 和 Redis：

#### 前提条件

确保本地已安装并运行：
- MySQL (端口 3306)
- Redis (端口 6379)

#### 启动步骤

运行以下脚本：
```bash
docker-start-local.bat
```

这将只启动 Backend 容器，连接到本地的 MySQL 和 Redis。

---

### 方案 5: 手动下载镜像（高级用户）

如果可以通过其他方式获取 Docker 镜像文件：

1. 下载以下镜像的 tar 文件：
   - mysql:8.0
   - redis:7-alpine
   - node:18-alpine

2. 加载镜像：
```bash
docker load -i mysql-8.0.tar
docker load -i redis-7-alpine.tar
docker load -i node-18-alpine.tar
```

3. 运行启动脚本：
```bash
docker-start.bat
```

---

## 推荐的镜像源列表（2024-2025）

### 国内可用镜像源

```json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",       # DaoCloud
    "https://docker.1panel.live",         # 1Panel
    "https://hub.rat.dev",                # Rat
    "https://docker.anyhub.us.kg",        # AnyHub
    "https://dockerhub.icu",              # DockerHub ICU
    "https://docker.rainbond.cc"          # Rainbond
  ]
}
```

### 备用镜像源

如果上述源失效，可以尝试：
- https://hub-mirror.c.163.com (网易)
- https://mirror.ccs.tencentyun.com (腾讯云)
- https://docker.mirrors.ustc.edu.cn (中科大)

---

## 验证和测试

### 1. 测试网络连接

```bash
# 测试是否能连接到镜像源
curl -I https://docker.m.daocloud.io/v2/

# 应该返回 200 OK
```

### 2. 测试拉取镜像

```bash
# 尝试拉取一个小镜像测试
docker pull hello-world

# 成功后测试所需镜像
docker pull mysql:8.0
docker pull redis:7-alpine
docker pull node:18-alpine
```

### 3. 启动服务

```bash
docker-start.bat
```

---

## 故障排除

### 问题 1: 配置后仍然无法拉取

**解决：**
1. 确保完全重启了 Docker Desktop
2. 尝试不同的镜像源
3. 检查防火墙设置

### 问题 2: 镜像源不可用

**解决：**
镜像源可能会失效，尝试列表中的其他源，或使用阿里云专属镜像。

### 问题 3: 代理配置不生效

**解决：**
1. 确保代理服务器正在运行
2. 检查代理地址和端口是否正确
3. 尝试同时配置 HTTP 和 HTTPS 代理

---

## 当前配置文件位置

- **docker-compose.yml** - 完整 Docker 配置（需要拉取镜像）
  - MySQL 端口：13306 (避免与本地冲突)
  - Redis 端口：16379 (避免与本地冲突)
  - Backend 端口：8080

- **docker-compose.local.yml** - 使用本地数据库的配置
  - 连接本地 MySQL (3306)
  - 连接本地 Redis (6379)
  - Backend 端口：8080

---

## 推荐操作流程

1. **首选：** 配置镜像加速器（方案 1 或 2）
2. **备选：** 如果网络问题无法解决，使用本地数据库（方案 4）
3. **最后：** 使用代理或手动下载镜像（方案 3 或 5）

---

## 需要帮助？

1. 运行 `docker-fix-network.bat` 查看详细说明
2. 检查 Docker Desktop 日志
3. 查看本文档的故障排除部分

---

## 配置成功后

运行以下命令启动所有服务：

```bash
# 使用完整 Docker 配置
docker-start.bat

# 或使用本地数据库模式
docker-start-local.bat
```

服务启动后访问：
- Backend API: http://localhost:8080
- MySQL: localhost:13306 (Docker) 或 localhost:3306 (本地)
- Redis: localhost:16379 (Docker) 或 localhost:6379 (本地)
