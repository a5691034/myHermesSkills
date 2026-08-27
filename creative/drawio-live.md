---
name: drawio-live
description: "在可见的 draw.io 画布上实时绘制/编辑架构图（drawio-live MCP）。触发词：架构图、流程图、drawio、实时画布。支持零重叠连线设计、字体调大、保存 .drawio。"
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [drawio, architecture, diagram, mcp, visualization]
    related_skills: [architecture-diagram, excalidraw]
---

# drawio-live — 可见画布实时绘图

通过 `drawio-live` MCP server 连接**用户可见的 draw.io 桌面窗口**，在画布上一步步实时绘制、编辑、调整架构图。与"静默导出 PNG"模式不同，每一步操作用户都能实时看到图形变化，适合需要反复打磨的汇报架构图。

## 触发条件

- 用户要求"画架构图/流程图，我能看到过程"
- 需要连线不出错、字体大、布局清晰的汇报用图
- 已有 draw.io 桌面版，希望直接在窗口里实时画图

## 快速上手

```bash
# 1. 克隆科学绘图插件仓库（含 drawio-live MCP server）
git clone --depth 1 https://github.com/icebird1998/scientific-illustrator ~/scientific-illustrator

# 2. 注册 MCP server（注意：--env 必须在 --args 之前，--args 必须是最后一个选项）
hermes mcp add drawio-live \
  --command <node可执行文件路径> \
  --env "DRAWIO_PATH=<draw.io可执行文件路径>" \
  --connect-timeout 60 \
  --args <~/scientific-illustrator/plugins/scientific-illustrator/scripts/live-server.mjs>

# 3. 重载 MCP（或重启会话）
/reload-mcp
```

> 以上为速览；**完整安装步骤（含 drawio 路径检测逻辑）见 `references/setup-guide.md`**，工具速查表见 `references/tool-reference.md`。

## 核心工作流（零重叠连线设计）

1. **launch** — 启动/连接可见的 draw.io 窗口（MCP 通过 CDP 控制，用户能看到每个动作）
2. **layout 规划** — 先想好整体布局再动手。推荐**三列横排 + 顶部底座 + 底部目标**的"三明治"结构：横向最多 3 个场景容器并排，连线全部走垂直方向
3. **draw_sequence 画形状** — 标题 → 底座/容器 → 场景容器 → 子项，一步一批
4. **draw_sequence 画连线** — 给每条边设置**明确锚点**（exitX/exitY/entryX/entryY），水平锚点错开为 20%/50%/80%（对应左/中/右列中心），实现**零交叉零重叠**
5. **fit 适配画布** — 全部画完执行 `fit`
6. **screenshot 确认** — 截图检查布局/字体，不满意用 update 微调
7. **save_snapshot 保存** — 输出为 .drawio 文件

## 连线零重叠设计原理

| 要素 | 设计 |
|:----|:----|
| 布局 | 底座横条 → 三列场景容器（各约 560 宽）→ 目标横条，垂直堆叠 |
| 连线 | 全部使用 `edgeStyle=orthogonalEdgeStyle`，纯垂直走向 |
| 锚点 | 左列 20% / 中列 50% / 右列 80%，由上向下严格错开 |
| 标签 | 连线标签放在短线段上，字号 15-16，颜色与线色一致 |
| 跨容器 | 不画跨容器的长线（重叠元凶），用短竖线 + 语义对齐表达关系 |

## 案例分析：恒风传媒场景谋划架构图

已用本 skill 画出"恒风传媒场景谋划架构图"（.drawio 保存于工作区），结构示例：

```
恒风传媒×火山引擎 场景谋划 · 要素争取       ← 标题 38pt，黑体
副标题（支撑词元数科 × 火山引擎）             ← 20pt
┌─ 底座横条（能力支撑：火山算力/应用/渠道） ─┐  ← 22pt
│  场景一 电商赋能  场景二 数字新媒体  场景三 广告聚合平台 │  ← 26pt，三列并排
│  6 个子项        3 个子项        3 个子项   │  ← 19pt
└─ 目标横条（要素争取：数据/权责/算力补贴）  ─┘  ← 22pt
```

## 常见问题（Pitfalls）

1. **`--args` 必须是 hermes mcp add 的最后一个选项**，否则 `--env` 会被当成 args 吞掉，环境变量不生效，draw.io 启动报 ENOENT。
2. **draw.io 装在非标准路径**（如 D 盘）：配置 `DRAWIO_PATH` 环境变量指向 exe 完整路径。检测逻辑：先查默认安装地址，查不到再询问用户（见 setup-guide）。
3. **MCP 状态异常时**：`tool_call` 直接调用 `mcp__drawio_live__*` 通常能绕过旧进程正常工作；配置改动后执行 `/reload-mcp`。
4. **连线重叠**：不要画跨容器长线、不要多条线共用同一锚点。用错开的垂直锚点。
5. **删除元素**：没有单独删除单条边的接口，需要 `clear confirm=true` 清空整页重画——所以布局一定要先想清楚。
6. **字体调大**：所有文字统一调大时用 draw_sequence 批量 update style 里的 `fontSize`，标题 38 / 容器 26 / 子项 19 / 连线标签 15-16 效果较好（用户偏好大字体）。

## 验证步骤

- [ ] draw.io 窗口可见，图形实时出现（用户在观看）
- [ ] `fit` 后整体布局无溢出
- [ ] 截图确认：连线无交叉、无重叠
- [ ] 所有文字可读（字号达标）
- [ ] `save_snapshot` 输出 .drawio 文件成功