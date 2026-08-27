# ppt-master SVG → PPTX Pipeline 实战笔记

基于 2026-08-26 文旅公司安全培训 PPT 制作实践。

## 标准流程（Quick Generate 模式）

```bash
# 1. 初始化项目
python3 "${SKILL_DIR}/scripts/project_manager.py" init <project_name> --format ppt169 --quick-generate

# 2. 手写 25 页 SVG 到 svg_output/ 目录
# 3. 写逐字稿到 notes/ 目录（文件名与 SVG 对应）

# 4. 质量检查（必须先跑！不跑的话 svg_to_pptx 会拒绝执行）
python3 "${SKILL_DIR}/scripts/svg_quality_checker.py" <project_dir> \
    --quick-generate --stage final --json

# 5. 检查质量报告中的 errors
#    如果有 error，修复对应 SVG 后重跑第 4 步

# 6. 导出 PPTX
python3 "${SKILL_DIR}/scripts/svg_to_pptx.py" <project_dir> \
    --quick-generate --no-animations

# 7. 后处理：注入 speaker notes（ppt-master 不自带）
```

## 关键发现

### svg_quality_checker 必须先于 svg_to_pptx 运行
`svg_to_pptx.py --quick-generate` 要求当前 `svg_output/` 有一份通过的最终质量报告。没有报告直接报错拒绝执行。质量检查会生成 `validation/svg_quality_report.json`。

### Speaker Notes 不会自动注入
ppt-master 的 `svg_to_pptx` 不会自动读取 `notes/` 目录注入 speaker notes。需要在 PPTX 生成后用 python-pptx 手动注入：

```python
from pptx import Presentation
import glob, os

prs = Presentation(pptx_path)
notes_files = sorted(glob.glob(notes_dir + '/*.md'))

for idx, slide in enumerate(prs.slides):
    if idx < len(notes_files):
        with open(notes_files[idx], 'r', encoding='utf-8') as f:
            slide.notes_slide.notes_text_frame.text = f.read().strip()

prs.save(pptx_path)
```

### 质量检查常见 error 类型

1. **文字超出 viewBox**（最常见）：
   - 错误信息格式：`<text> (x=660, y=291; text='...') exceeds the root viewBox`
   - 修复方法：缩短该行文本，或拆成两行

2. **不支持的颜色值**：
   - 如 `fill='{R}'`（Python 模板变量未替换）
   - 修复：搜索替换所有 `{R}` 为 `#E2001A`

### SVG 文件命名规范
- 文件必须按顺序命名：`01_cover.svg`、`02_toc.svg`、`03_section.svg`...
- 文件名决定幻灯片的顺序
- notes 文件命名必须与 SVG 一一对应

## 用户偏好（来自 session）

1. **质量优先于速度**：用户明确说"逐个写SVG，慢一点也没关系，要注重PPT质量"
2. **先理解再动手**：用户多次因"先试再说"而烦躁，要求"先看文档"
3. **停止信号**：当用户说"先停一下"时，立即停止，等待指示
4. **SVG 直接用 write_file 写**：不用 Python 拼接字符串（容易出错），直接写完整 SVG XML