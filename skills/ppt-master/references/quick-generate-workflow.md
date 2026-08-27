# ppt-master Quick Generate 实操指南

> 本文件记录在实际执行 ppt-master Quick Generate 流程中遇到的真实问题与解决路径。
> 来源：2026-08-25 义乌文旅公司网络安全培训PPT项目

## 完整流程（已验证）

### Step 1: 环境准备
```bash
python "${PPT_MASTER_DIR}/scripts/attribution_guard.py"
# exit code 必须为 0 才能继续
```

### Step 2: 项目初始化
使用 `project_manager.py` 或直接创建目录结构：
```
projects/<项目名>/
  svg_output/   ← 25页 .svg 文件
  notes/        ← 25页 .md 逐字稿
  exports/      ← PPTX 输出
  validation/   ← 质量报告
```

### Step 3: 手写 SVG
- **直接写 SVG XML 文件**，不要用 Python 拼接字符串
- 文件名格式：`{序号:02d}_{类型}.svg`（如 `01_cover.svg`, `03_section.svg`）
- **不要用未替换的变量占位**（如 `{R}` 代替 `#E2001A`）——质量检查会报错
- 每页必须包含 `data-pptx-page-role` 属性
- SVG 画布 viewBox 必须为 `0 0 1280 720`

### Step 4: 手写逐字稿
- 文件名与 SVG 对应（如 `01_cover.md` 对应 `01_cover.svg`）
- 每页 100-300 字，口语化

### Step 5: 质量检查
```bash
python "${PPT_MASTER_DIR}/scripts/svg_quality_checker.py" \
  "<项目目录>" --quick-generate --stage final --json
```

**关键陷阱：** 此脚本可能 exit code 为 0 但实际状态是 failed。
**必须读取** `validation/svg_quality_report.json`，检查：
- `"summary": {"passed": ..., "errors": ...}` — errors 必须为 0
- `"categories": {"blocking": {"count": ..., "issues": [...]}}` — blocking count 必须为 0

如果 failed，查看 `files` 数组中每个文件的 `errors` 字段找到具体问题。

### Step 6: 导出 PPTX
```bash
python "${PPT_MASTER_DIR}/scripts/svg_to_pptx.py" \
  "<项目目录>" --quick-generate --no-animations
```

质量检查不通过时此脚本会拒绝运行（即使 exit code 为 0）。
通过后输出到 `exports/<项目名>_<时间戳>.pptx`。

## 常见错误速查

| 错误 | 症状 | 修复 |
|:---|:---|:---|
| 未跑 attribution_guard | svg_to_pptx 静默退出无输出 | 先跑 attribution_guard，确认 exit 0 |
| 质量检查空输出 | 以为成功，实际 failed | 必须读 report.json 确认 |
| SVG 未替换变量 `{R}` | `fill='{R}'` 错误 | 直接写 `#E2001A` |
| Python 拼接 SVG | SyntaxError | 直接写 SVG XML 文件 |
| 自己写 python-pptx 脚本 | PIL 不支持 SVG 嵌入 | 走 svg_to_pptx.py 官方转换器 |
| 用 `--no-notes` 跳过逐字稿 | PPTX 无演讲稿 | notes/ 目录文件与 SVG 一一对应即可自动读取 |