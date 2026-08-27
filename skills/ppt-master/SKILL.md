---
name: ppt-master
description: AI驱动的PPT生成工作流。生成可编辑原生PPTX，支持SVG设计、模板填充、原生增强。
---

# PPT Master

> 来源：https://github.com/hugohe3/ppt-master
> 版本：5.0.0 | 许可证：MIT

> **`${PPT_MASTER_DIR}` 占位符说明**：指 ppt-master 的实际安装目录（本机安装如 `~/ppt-learning/ppt-master/skills/ppt-master/`）。使用前请先替换为真实路径。

## 安装确认

依赖已安装（pip install -r requirements.txt）。核心依赖：python-pptx, lxml, skia-pathops, uharfbuzz, edge-tts, PyMuPDF, openpyxl 等。

## 核心能力

1. **SVG → 原生PPTX** — 将SVG设计编译为可编辑的PowerPoint对象（非贴图）
2. **模板填充** — 用内容填充现有的.pptx模板，保持品牌风格
3. **原生增强** — 对已有PPT进行美化、添加动画、旁白音频
4. **图像→PPTX** — 从图片重建PPT内容

## 工作流路由

| 用户意图 | 工作流文件 |
|:---|:---|
| 从文档生成PPT | `workflows/generate-pptx.md` |
| 快速生成PPT | `workflows/profiles/quick-generate.md` |
| 美化已有PPT | `workflows/profiles/beautify-pptx.md` |
| 填充模板 | `workflows/template-fill-pptx.md` |
| 增强原生PPT | `workflows/native-enhance-pptx.md` |
| 创建模板 | `workflows/create-template.md` |

## 关键脚本

位于 `${PPT_MASTER_DIR}/scripts/`：

| 脚本 | 用途 |
|:---|:---|
| `svg_to_pptx.py` | SVG转原生PPTX（核心编译工具） |
| `attribution_guard.py` | 完整性校验（每次执行前必须运行） |
| `beautify_inventory.py` | PPT美化清单生成 |
| `beautify_identity.py` | PPT品牌识别 |
| `notes_to_audio.py` | 逐页旁白音频生成 |
| `image_gen.py` | AI图片生成 |
| `finalize_svg.py` | SVG最终化处理 |

## 使用方式

```bash
# SVG转PPTX
python "${PPT_MASTER_DIR}/scripts/svg_to_pptx.py" --help

# 查看完整工作流
cat "${PPT_MASTER_DIR}/workflows/generate-pptx.md"
```

## 关键理念（对本项目的借鉴）

1. **"可编辑只是基本要求，原生深度才是差异化"**
2. **SVG↔PowerPoint原生映射** — 每页先设计精确SVG，再编译成原生PPTX
3. **先推理论点结构，再设计视觉表达**
4. **风格即系统** — 每种风格对应一套色板+字体+布局原则