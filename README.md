# VM Station New API

自动化 HTTP API 连接管理工具，通过 ngrok 建立远程 HTTP 访问隧道，实现内网 API 服务的公网访问。

## 功能特性

- 🚀 自动启动和管理 ngrok HTTP 隧道（端口 2009）
- 📝 自动记录连接信息到日志文件
- 🔄 支持 Git 自动提交和推送连接信息
- 🪟 跨平台支持（Linux 服务端 + Windows 客户端）
- 📋 Windows 端自动复制 URL 到剪贴板

## 文件说明

- **connect.sh** - Linux/Unix 主启动脚本
  - 停止旧的 ngrok 进程
  - 启动新的 ngrok HTTP 隧道（端口 2009）
  - 获取公共访问 URL
  - 保存连接信息到日志文件
  - 自动 Git 提交和推送

- **update.bat** - Windows 客户端更新脚本
  - 从 Git 拉取最新连接信息
  - 读取并显示 HTTP API URL
  - 自动保存 URL 到本地配置文件
  - 自动复制 URL 到剪贴板
  - **自动更新 Claude Desktop 配置文件** (`.claude/settings.json`)
    - 更新 `ANTHROPIC_BASE_URL` 字段
    - 如果配置文件不存在，自动创建模板

- **update.sh** - Linux 客户端更新脚本
  - 从 Git 拉取最新连接信息
  - 读取并显示 HTTP API URL
  - 自动保存 URL 到本地配置文件
  - 自动复制 URL 到剪贴板（需要 xclip 或 xsel）
  - **自动更新 Claude Desktop 配置文件** (`~/.claude/settings.json`)
    - 使用 jq 或 sed 更新 `ANTHROPIC_BASE_URL` 字段
    - 如果配置文件不存在，自动创建模板

- **connected_info.log** - 当前连接信息
  - 存储 ngrok 生成的公共 HTTP URL

- **connecting_details.log** - 连接详细日志
  - ngrok 启动和运行的详细输出

## 使用方法

### Linux/Unix 系统

```bash
# 启动 ngrok 隧道并推送连接信息
./connect.sh
```

### Windows 系统

```batch
# 拉取最新 URL 并保存到本地
update.bat
```

### Linux 系统（客户端）

```bash
# 拉取最新 URL 并保存到本地
./update.sh
```

连接信息会保存在 `connected_info.log` 中，格式如：
```
https://your-subdomain.ngrok-free.dev
```

- **Windows 端**：URL 保存到 `%USERPROFILE%\.vm-station-new-api\api_url.txt` 并自动复制到剪贴板
- **Linux 端**：URL 保存到 `~/.vm-station-new-api/api_url.txt`，如果安装了 xclip/xsel 会自动复制到剪贴板

## 前置要求

### Linux 服务端
- ngrok 已安装并配置 authtoken
- Git 已安装并配置用户信息
- jq（JSON 解析工具）
- 端口 2009 上运行的 HTTP 服务

### Windows 客户端
- Git 已安装
- 已克隆本仓库到 `%USERPROFILE%\.vm-station-new-api`

### Linux 客户端
- Git 已安装
- jq（JSON 解析工具，推荐但不必需）
- 已克隆本仓库到 `~/.vm-station-new-api`
- 可选：xclip 或 xsel（用于剪贴板功能）

## Claude Desktop 配置

### Windows 端配置

`update.bat` 会自动管理 Claude Desktop 的配置文件。

### 自动配置
运行 `update.bat` 后，脚本会：
1. 自动创建 `%USERPROFILE%\.claude\` 目录（如果不存在）
2. 自动创建或更新 `settings.json` 文件
3. 将 ngrok 的 HTTP URL 写入 `ANTHROPIC_BASE_URL` 字段

### 首次使用
如果是第一次运行，脚本会创建如下模板：
```json
{
  "env": {
    "ANTHROPIC_API_KEY": "your-api-key",
    "ANTHROPIC_BASE_URL": "https://xxx.ngrok-free.dev",
    ...
  }
}
```

**重要**：首次使用时，请手动将 `your-api-key` 替换为您的实际 API 密钥。

### 后续使用
之后每次运行 `update.bat`，只会更新 `ANTHROPIC_BASE_URL` 字段，其他配置保持不变。

### Linux 端配置

`update.sh` 也会自动管理 Claude Desktop 的配置文件。

#### 自动配置
运行 `./update.sh` 后，脚本会：
1. 自动创建 `~/.claude/` 目录（如果不存在）
2. 自动创建或更新 `settings.json` 文件
3. 使用 jq（如有）或 sed 更新 `ANTHROPIC_BASE_URL` 字段

#### 首次使用
如果是第一次运行，脚本会创建与 Windows 端相同的配置模板。

**重要**：首次使用时，请手动编辑 `~/.claude/settings.json`，将 `your-api-key` 替换为您的实际 API 密钥。

#### 后续使用
后续每次运行 `update.sh`，只会更新 `ANTHROPIC_BASE_URL` 字段，其他配置保持不变。

## 工作流程

1. **Linux 端（服务器）**：
   - 确保端口 2009 上有 HTTP 服务运行
   - 运行 `./connect.sh`
   - ngrok 创建 HTTP 隧道指向 localhost:2009
   - 公网 HTTPS URL 自动保存并推送到 Git 仓库

2. **Windows 端（客户端）**：
   - 运行 `update.bat`
   - 从 Git 拉取最新的 ngrok URL
   - URL 自动保存到本地文件并复制到剪贴板
   - **自动更新 Claude Desktop 配置**：
     - 更新 `%USERPROFILE%\.claude\settings.json` 中的 `ANTHROPIC_BASE_URL`
     - 如果是首次使用，会创建配置文件模板（API key 需手动填写）
   - 直接使用该 URL 访问内网 API 服务

3. **Linux 端（客户端）**：
   - 运行 `./update.sh`
   - 从 Git 拉取最新的 ngrok URL
   - URL 自动保存到本地文件（xclip/xsel 可选复制到剪贴板）
   - **自动更新 Claude Desktop 配置**：
     - 使用 jq 或 sed 更新 `~/.claude/settings.json` 中的 `ANTHROPIC_BASE_URL`
     - 如果是首次使用，会创建配置文件模板（API key 需手动填写）
   - 直接使用该 URL 访问内网 API 服务

## 注意事项

- ⚠️ ngrok 免费版隧道 URL 会在每次重启时变化
- ⚠️ 确保端口 2009 上有服务运行，否则访问会失败
- ⚠️ 连接信息会自动推送到远程仓库，请注意 API 安全
- 💡 建议在 API 服务中实现认证机制保护接口
- 💡 ngrok 免费版有请求速率限制，生产环境建议升级

## 仓库信息

- **远程仓库**: git@github.com:station2026/vm-station-new-api.git
- **用户**: station
- **邮箱**: mumadofihi69963@google.com

## License

MIT License
