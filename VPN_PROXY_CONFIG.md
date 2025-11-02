# Docker VPN 代理配置指南

## 你的 VPN 信息
- 端口: 7897

## 快速配置步骤

### 方法 1: 通过 Docker Desktop 图形界面（推荐）

1. **打开 Docker Desktop**

2. **进入设置**
   - 点击右上角的设置图标（⚙️齿轮）

3. **配置代理**
   - 左侧选择 "Resources"
   - 点击 "Proxies"
   - 选择 "Manual proxy configuration"

4. **填写代理信息**
   ```
   Web Server (HTTP):
   http://127.0.0.1:7897

   Secure Web Server (HTTPS):
   http://127.0.0.1:7897
   ```

5. **应用设置**
   - 点击 "Apply & Restart"
   - 等待 Docker 完全重启（约 30-60 秒）

### 方法 2: 使用环境变量（临时）

在运行 Docker 命令前设置环境变量：

```powershell
# PowerShell
$env:HTTP_PROXY="http://127.0.0.1:7897"
$env:HTTPS_PROXY="http://127.0.0.1:7897"
$env:NO_PROXY="localhost,127.0.0.1"

# 然后运行 Docker 命令
docker pull mysql:8.0
```

### 方法 3: 配置 Docker Daemon（永久）

编辑或创建文件 `C:\Users\你的用户名\.docker\daemon.json`：

```json
{
  "proxies": {
    "http-proxy": "http://127.0.0.1:7897",
    "https-proxy": "http://127.0.0.1:7897",
    "no-proxy": "localhost,127.0.0.1"
  }
}
```

保存后重启 Docker Desktop。

## 验证配置

### 1. 检查代理设置

```bash
docker info | findstr "Proxy"
```

### 2. 测试连接

```bash
# 测试拉取小镜像
docker pull hello-world

# 如果成功，拉取项目所需镜像
docker pull mysql:8.0
docker pull redis:7-alpine
docker pull node:18-alpine
```

### 3. 查看 Docker 配置

```powershell
# PowerShell
Get-Content "$env:USERPROFILE\.docker\daemon.json"
```

## 常见 VPN 代理端口

不同的 VPN 软件使用不同的默认端口：

| VPN 软件 | 默认 HTTP 端口 | 默认 SOCKS 端口 |
|---------|--------------|----------------|
| Clash   | 7890         | 7891          |
| V2Ray   | 10809        | 10808         |
| Shadowsocks | 1080     | 1080          |
| 你的 VPN | 7897        | -             |

**请根据你的实际 VPN 配置调整端口号！**

## 检查 VPN 是否正常工作

### PowerShell 测试

```powershell
# 测试代理连接
curl -x http://127.0.0.1:7897 http://www.google.com

# 如果成功，会返回 Google 首页 HTML
```

### 检查代理监听

```bash
netstat -ano | findstr "7897"
```

应该看到类似输出：
```
TCP    127.0.0.1:7897    0.0.0.0:0    LISTENING    [PID]
```

## 故障排除

### 问题 1: 代理配置后仍然无法拉取镜像

**解决方案：**
1. 确认 VPN 正在运行
2. 确认端口号正确（7897）
3. 尝试重启 Docker Desktop
4. 检查 VPN 是否允许 Docker 访问

### 问题 2: 端口不对

**解决方案：**
1. 打开你的 VPN 软件
2. 查找 "端口设置" 或 "代理设置"
3. 找到 HTTP 代理端口
4. 用实际端口替换 7897

### 问题 3: VPN 软件显示不同的端口

**解决方案：**

常见 VPN 软件的端口查看方法：

**Clash:**
- 打开 Clash
- 查看 "General" 或"常规"
- 找到 "Port" 或"HTTP 代理端口"

**V2RayN:**
- 打开 V2RayN
- 参数设置 → 本地监听端口
- 查看 HTTP 代理端口

**Shadowsocks:**
- 打开 Shadowsocks
- 编辑服务器
- 查看本地端口

## 配置成功后的操作

### 1. 拉取所有需要的镜像

```bash
# 拉取 MySQL
docker pull mysql:8.0

# 拉取 Redis
docker pull redis:7-alpine

# 拉取 Node.js
docker pull node:18-alpine
```

### 2. 启动服务

```bash
# 运行启动脚本
docker-start.bat
```

### 3. 验证服务

```bash
# 查看容器状态
docker ps

# 查看日志
docker-compose logs -f
```

## 重要提示

⚠️ **使用代理的注意事项：**

1. **VPN 必须保持运行**
   - Docker 拉取镜像时 VPN 必须开启
   - 容器运行后可以关闭 VPN（如果容器不需要外网访问）

2. **性能影响**
   - 通过代理拉取可能较慢
   - 考虑配置镜像加速器作为补充

3. **No Proxy 设置**
   - `localhost` 和 `127.0.0.1` 应该在 no-proxy 列表中
   - 避免本地通信也走代理

## 推荐配置（综合方案）

同时配置代理和镜像加速器，效果最好：

```json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live"
  ],
  "proxies": {
    "http-proxy": "http://127.0.0.1:7897",
    "https-proxy": "http://127.0.0.1:7897",
    "no-proxy": "localhost,127.0.0.1,docker.m.daocloud.io,docker.1panel.live"
  }
}
```

这样配置后：
- 优先尝试使用国内镜像源（快速）
- 如果镜像源没有，通过代理访问 Docker Hub
- 本地通信不走代理

## 下一步

配置完成后，请运行：

```bash
# 测试配置
docker pull hello-world

# 启动项目
docker-start.bat

# 查看状态
docker-status.bat
```
