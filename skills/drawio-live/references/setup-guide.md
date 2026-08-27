# drawio-live 详细安装指南

本指南逐步说明如何在本机安装并启用 `drawio-live` MCP server，使 Hermes 能够连接**可见的 draw.io 桌面窗口**实时绘制架构图。

## 一、前置条件

| 依赖 | 要求 | 验证命令 |
|:----|:----|:----|
| draw.io 桌面版 | 任意近期版本 | 见下文"二、查找 draw.io 安装路径" |
| Node.js | v18+（Hermes 自带 node 亦可） | `node --version` |
| Hermes | 已安装并可运行 CLI | `hermes --version` |
| git | 用于克隆插件仓库 | `git --version` |

## 二、查找 draw.io 安装路径

### 第一步：自动检测默认安装地址

按平台依次检查以下**默认安装位置**，存在即采用：

**Windows（依次检查，第一个存在的即选中）**

| 优先级 | 路径 |
|:----|:----|
| 1 | `%ProgramFiles%\draw.io\draw.io.exe` |
| 2 | `%ProgramFiles(x86)%\draw.io\draw.io.exe` |
| 3 | `%LOCALAPPDATA%\Programs\draw.io\draw.io.exe` |
| 4 | `%LOCALAPPDATA%\draw.io\draw.io.exe` |

**macOS（依次检查）**

| 优先级 | 路径 |
|:----|:----|
| 1 | `/Applications/draw.io.app/Contents/MacOS/draw.io` |
| 2 | `~/Applications/draw.io.app/Contents/MacOS/draw.io` |

**Linux（依次检查）**

| 优先级 | 路径 |
|:----|:----|
| 1 | `/usr/bin/drawio` |
| 2 | `/usr/local/bin/drawio` |
| 3 | `/snap/bin/drawio` |
| 4 | `/opt/drawio/drawio` |

可用命令快速检查（以 Windows 为例）：

```bash
ls "$ProgramFiles/draw.io/draw.io.exe" \
  "$ProgramFiles(x86)/draw.io/draw.io.exe" \
  "$LOCALAPPDATA/Programs/draw.io/draw.io.exe" \
  "$LOCALAPPDATA/draw.io/draw.io.exe" 2>/dev/null
```

### 第二步：默认路径均不存在时，询问用户

若以上默认路径全部不存在，**不要臆测路径**，直接向用户询问：

> 「未在默认位置检测到 draw.io 桌面版，请提供 draw.io 可执行文件的完整路径（例如 `D:\Program Files\draw.io\draw.io.exe`），或告知安装方式（如通过包管理器安装）。」

用户在 `D:\Program Files\draw.io\` 等非标准位置安装时，可用 `DRAWIO_PATH` 环境变量显式指定（见下文第四步）。

### 环境变量确认

若用户没有 draw.io 桌面版，提示前往 https://www.drawio.com/ 下载安装，或通过包管理器安装（`winget install drawio` / `brew install --cask drawio` / `apt install drawio`）。

## 三、克隆插件仓库

科学绘图插件仓库包含 drawio-live MCP server 源码，克隆到稳定位置（不要放临时目录，避免被系统清理）：

```bash
git clone --depth 1 https://github.com/icebird1998/scientific-illustrator ~/scientific-illustrator
```

关键文件：

```
scientific-illustrator/
└── plugins/
    └── scientific-illustrator/
        └── scripts/
            ├── live-server.mjs   ← MCP server 主程序（纯 Node 内置模块，无额外依赖）
            └── drawio-path.mjs   ← draw.io 路径解析（自动检测 + DRAWIO_PATH 覆盖）
```

## 四、注册 MCP server

### 1. 确定 node 可执行文件

优先使用 Hermes 自带 node（随 Hermes Desktop 安装），例如：

```
C:\Users\<user>\.hermes-web-ui\desktop-runtime\hermes\<VERSION>\win-x64\node\node.exe
```

验证：`<node路径> --version`

### 2. 执行 hermes mcp add

```bash
hermes mcp add drawio-live \
  --command "<node可执行文件路径>" \
  --env "DRAWIO_PATH=<draw.io可执行文件路径>" \
  --connect-timeout 60 \
  --args "<~/scientific-illustrator/plugins/scientific-illustrator/scripts/live-server.mjs>"
```

> **⚠️ 参数顺序铁律**：`--args` 必须是**最后一个**选项，`--env` 必须放在 `--args` 之前。顺序错误会导致环境变量被吞掉、draw.io 启动报 ENOENT。

若未指定 DRAWIO_PATH（跳过 `--env`），server 会按上文"默认安装位置"自动检测。

### 3. 验证配置写入

```bash
hermes mcp list          # 应看到 drawio-live
```

config.yaml 中应出现类似片段（完整示例见 `templates/config-example.yaml`）：

```yaml
drawio-live:
  command: <node路径>
  args:
    - <live-server.mjs路径>
  env:
    DRAWIO_PATH: <draw.io路径>
  connect_timeout: 60.0
  enabled: true
```

## 五、热重载 / 重启

- 当前会话内：执行斜杠命令 `/reload-mcp`
- 或重启 Hermes 会话

重载后，会话应能看到 26 个 `mcp__drawio_live__*` 工具。若工具调用异常（fetch failed 等），可尝试直接用 `tool_call` 路径调用 `drawio_live_launch`，通常能绕过旧进程正常连接。

## 六、验证安装

1. 调用 `drawio_live_launch` — 应打开/连接到可见的 draw.io 窗口
2. 调用 `drawio_live_status` — 应返回 `graph_ready: true`
3. 画一个简单形状，确认用户在窗口中实时看到变化

## 七、卸载

```bash
hermes mcp remove drawio-live
```

## 常见问题（FAQ）

**Q: 「fetch failed」/ MCP 工具调用失败？**
A: 先 `/reload-mcp`；仍失败则用 `tool_call` 直接调用 `drawio_live_status` 检查。确认 config.yaml 中 `DRAWIO_PATH` 已正确写入。

**Q: draw.io 装在 D 盘 / 非默认位置？**
A: 已默认检测不到时（第二步询问用户），把完整路径通过 `--env "DRAWIO_PATH=..."` 指定即可。

**Q: 提示没有 draw.io？**
A: 前往 https://www.drawio.com/ 下载桌面版，或用 `winget install drawio` 安装，再重新执行第二步检测。