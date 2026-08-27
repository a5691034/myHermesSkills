#!/usr/bin/env bash
# =============================================================================
# drawio-live 一键安装脚本
#
# 功能：
#   1. 检查前置依赖（git / node / hermes CLI / draw.io）
#   2. 自动检测 draw.io 默认安装路径；检测不到则向用户询问
#   3. 克隆 scientific-illustrator 插件仓库
#   4. 注册 drawio-live MCP server
#   5. 提示重载 MCP
#
# 用法：
#   bash setup.sh
#
# 说明：Hermes CLI 若不在 PATH 中，请先设置 HERMES_CMD 环境变量指向 hermes 启动器。
# =============================================================================
set -euo pipefail

HERMES_CMD="${HERMES_CMD:-hermes}"
REPO_URL="https://github.com/icebird1998/scientific-illustrator"
INSTALL_DIR="${DRAWIO_PLUGIN_DIR:-$HOME/scientific-illustrator}"
SERVER_SCRIPT="$INSTALL_DIR/plugins/scientific-illustrator/scripts/live-server.mjs"

c_red='\033[31m'; c_green='\033[32m'; c_yellow='\033[33m'; c_cyan='\033[36m'; c_reset='\033[0m'
info()  { printf "${c_cyan}[INFO]${c_reset} %s\n" "$*"; }
ok()    { printf "${c_green}[ OK ]${c_reset} %s\n" "$*"; }
warn()  { printf "${c_yellow}[WARN]${c_reset} %s\n" "$*"; }
fail()  { printf "${c_red}[FAIL]${c_reset} %s\n" "$*"; exit 1; }

# -----------------------------------------------------------------------------
# 1. 前置依赖检查
# -----------------------------------------------------------------------------
command -v git  >/dev/null 2>&1 || fail "未找到 git，请先安装"
command -v node >/dev/null 2>&1 || {
  # Hermes 自带 node 兜底
  for cand in \
    "$LOCALAPPDATA/.hermes-web-ui/desktop-runtime/hermes"/*/win-x64/node/node.exe \
    "$HOME/.hermes-web-ui/desktop-runtime/hermes"/*/win-x64/node/node.exe; do
    [ -x "$cand" ] && NODE_BIN="$cand" && break
  done
  [ -z "${NODE_BIN:-}" ] && fail "未找到 node，请先安装 Node.js v18+"
  ok "使用 Hermes 自带 node: $NODE_BIN"
}
NODE_BIN="${NODE_BIN:-$(command -v node)}"
command -v "$HERMES_CMD" >/dev/null 2>&1 || fail "未找到 hermes CLI，请设置 HERMES_CMD 环境变量"

# -----------------------------------------------------------------------------
# 2. 查找 draw.io 安装路径：先查默认位置，查不到再询问用户
# -----------------------------------------------------------------------------
detect_drawio() {
  local os="$(uname -s)"
  case "$os" in
    MINGW*|MSYS*|CYGWIN*)
      local candidates=(
        "$ProgramFiles/draw.io/draw.io.exe"
        "$ProgramFiles(x86)/draw.io/draw.io.exe"
        "$LOCALAPPDATA/Programs/draw.io/draw.io.exe"
        "$LOCALAPPDATA/draw.io/draw.io.exe"
      )
      ;;
    Darwin)
      local candidates=(
        "/Applications/draw.io.app/Contents/MacOS/draw.io"
        "$HOME/Applications/draw.io.app/Contents/MacOS/draw.io"
      )
      ;;
    Linux)
      local candidates=(
        "/usr/bin/drawio" "/usr/local/bin/drawio"
        "/snap/bin/drawio" "/opt/drawio/drawio"
      )
      ;;
    *) warn "未知操作系统: $os"; return 1 ;;
  esac
  local c
  for c in "${candidates[@]}"; do
    [ -x "$c" ] && echo "$c" && return 0
  done
  return 1
}

DRAWIO_PATH=""
if [ -n "${DRAWIO_PATH:-}" ] && [ -x "${DRAWIO_PATH:-}" ]; then
  ok "使用环境变量 DRAWIO_PATH: $DRAWIO_PATH"
elif DRAWIO_PATH="$(detect_drawio)"; then
  ok "检测到默认安装路径: $DRAWIO_PATH"
else
  # 默认位置均不存在 → 询问用户
  warn "未在默认安装位置检测到 draw.io 桌面版。"
  warn "请安装 draw.io（https://www.drawio.com/ 或 winget install drawio），或提供其可执行文件完整路径。"
  while :; do
    printf "${c_yellow}[ASK]${c_reset} 请输入 draw.io 可执行文件完整路径（直接回车跳过，跳过将不带 DRAWIO_PATH 注册）: "
    read -r user_path
    if [ -z "$user_path" ]; then
      warn "跳过 DRAWIO_PATH，将由 drawio-path.mjs 自动检测。"
      DRAWIO_PATH=""
      break
    fi
    if [ -x "$user_path" ]; then
      DRAWIO_PATH="$user_path"
      ok "采用用户提供路径: $DRAWIO_PATH"
      break
    fi
    warn "路径不存在或不可执行: $user_path"
  done
fi

# -----------------------------------------------------------------------------
# 3. 克隆插件仓库
# -----------------------------------------------------------------------------
if [ -f "$SERVER_SCRIPT" ]; then
  ok "插件仓库已存在: $INSTALL_DIR"
else
  info "克隆插件仓库: $REPO_URL"
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

# -----------------------------------------------------------------------------
# 4. 注册 MCP server
# -----------------------------------------------------------------------------
MCP_ARGS=(
  add drawio-live
  --command "$NODE_BIN"
  --connect-timeout 60
)
if [ -n "$DRAWIO_PATH" ]; then
  # 注意：--env 必须在 --args 之前，--args 必须是最后一个选项
  MCP_ARGS+=(--env "DRAWIO_PATH=$DRAWIO_PATH")
fi
MCP_ARGS+=(--args "$SERVER_SCRIPT")

info "注册 MCP server: $HERMES_CMD ${MCP_ARGS[*]}"
"$HERMES_CMD" "${MCP_ARGS[@]}"

# -----------------------------------------------------------------------------
# 5. 收尾提示
# -----------------------------------------------------------------------------
ok "安装完成！请执行以下操作："
printf "  1. 在会话中执行 ${c_cyan}/reload-mcp${c_reset}（或重启 Hermes）\n"
printf "  2. 调用 drawio_live_launch 打开可见的 draw.io 窗口\n"
printf "  3. 调用 drawio_live_status 验证 graph_ready: true\n"