---
name: state-owned-enterprise-ppt
description: 制作国企培训/汇报PPT（python-pptx + .pptx），含配色方案、内容结构、拆分技巧和案例卡片模板。
---

# 国企培训/汇报 PPT 制作

## When to Use

用户需要制作国企内部培训、安全宣讲、工作汇报类PPT，要求.pptx格式、包含逐字稿（speaker notes）、正式但可读。

## 核心配色方案（国企正式场景）

| 角色 | 颜色 | Hex | 用途 |
|:---|:---|:---|:---|
| 主色 | 品牌蓝 | `#016BFF` | 封面背景、标题强调、分隔页背景 |
| 次色 | 紫蓝 | `#565BFF` | 渐变搭配（可选） |
| 背景 | 浅灰 | `#F6F6F6` | 内容页背景（替代纯白减少视觉疲劳） |
| 卡片底 | 白色 | `#FFFFFF` | 局部卡片背景 |
| 警告/处罚 | 红色 | `#C00000` | 罚款金额、违规描述、"红线"行为 |
| 正确/安全 | 绿色 | `#28A745` | 正确做法、安全提示 |
| 深色 | 深蓝 | `#1B2A4A` | 封面/结束页备选深色底 |

## JSON spec 拆分技巧

python-pptx 通过 JSON spec 创建PPT时，spec文件过大（>16KB）会导致 `write_file` 超时。

**解决方法**：按逻辑模块拆分为多个 JSON 文件（每个 < 20KB），再用一个 Python 脚本合并并执行创建。

```python
# 合并脚本模板
all_slides = []
for part_file in ["ppt_part1.json", "ppt_part2.json", "ppt_part3.json"]:
    with open(part_file, encoding="utf-8") as f:
        part = json.load(f)
    all_slides.extend(part["slides"])

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
for spec in all_slides:
    build_slide(prs, spec)
prs.save("out.pptx")
```

**拆分原则**：按内容模块分（封面+第一部分 / 第二部分+第三部分 / 案例+总结），每部分 8-10 页。

## python-pptx Bullet 样式

在 JSON spec 中通过 `bullets` 数组的字典项设置：

```json
{
  "text": "标题行",
  "level": 0,
  "bold": true,
  "size": 18,
  "color": "016BFF"
}
```

| 字段 | 说明 |
|:---|:---|
| `level` | 缩进层级 0-4 |
| `size` | 字号（pt） |
| `bold` | 是否加粗 |
| `color` | 十六进制颜色（6位） |
| `text` | 内容 |
| `font` | 字体名（可选） |
| `link` | URL超链接（可选） |

**颜色编码约定**：
- 红色 `C00000` → 处罚金额、违规描述、红线行为
- 品牌蓝 `016BFF` → 小节标题、强调项
- 无 color 字段 → 默认黑色正文

## 内容结构模板（国企培训类）

### 标准结构
```
封面 → 目录 → PART 01（分隔页→内容→...）→ PART 02 → PART 03 → PART 04 → 总结 → 结尾
```

### 案例卡片页模板
每个案例一页，用三段式结构：

```
【事件经过】具体、有时间地点人物（去标识化）
【危害分析】量化后果 + 机制解释
【防范要求】可操作的具体措施
```

**扩写原则**：
- 加入**时间线**（具体日期、时间段）
- 加入**场景化描述**（发生了什么，受害者体验）
- 加入**数据细节**（罚款金额、影响范围）
- 加入**攻击路径拆解**（多步流程，每步一句话）
- 加入**教训/启示**（最后一句话点明）

### 法规页模板
涉及多部法律时，每页 2-3 部法律，每部法律包含：
- 法律名称（加粗 + 品牌蓝）
- 施行时间
- 核心义务（1-2句）
- 处罚力度（红色 + 加粗 + 具体金额）

### 总结页模板
用"铁律"或"要点"列表，每条：
- 标题（加粗 + 品牌蓝，20pt）
- 关键词说明（缩进，14pt）

## 逐字稿规范

- 每页 100-300 字
- 口语化、用"我们""大家"
- 避免罗列（"第一...第二..."可以，但要用完整句子）
- 每页结尾有过渡句（引导到下一页）
- 写在 JSON spec 的 `notes` 字段中
- 生成后验证每页 notes 不为空

## 验证检查清单

生成后执行：

```python
from pptx import Presentation
pr = Presentation("out.pptx")
print(f"总页数: {len(pr.slides._sldIdLst)}")
for i, s in enumerate(pr.slides):
    title = s.shapes.title.text if s.shapes.title else "(无标题)"
    notes = s.notes_slide.notes_text_frame.text if s.notes_slide else ""
    print(f"P{i+1:2d} [{'✓' if notes.strip() else '✗'}] {title[:50]}  |  逐字稿{len(notes)}字")
```

确认：
- [ ] 所有页有标题
- [ ] 所有页有逐字稿（notes 不为空）
- [ ] 页数与预期一致
- [ ] 颜色编码正确（红色用于警告/处罚）

## 中间插入页面的重编号工作流

详见 `references/ppt-insert-pages-renumbering.md`。关键步骤：
1. 新页面用 `_new` 后缀暂存
2. 被后移的旧页面用 `_tmp` 中转
3. 分三阶段 rename（移走旧文件 → 填入新页 → tmp 移到新位置）
4. 页码修复先 `replace` 补坏格式再 `re.sub` 统一
5. 同步更新 TOC、章节分隔页、notes 文件名

## 文件命名约定

| 文件 | 说明 |
|:---|:---|
| `ppt_part1.json` | spec 第一部分（封面+第1-2部分） |
| `ppt_part2.json` | spec 第二部分（第3部分+案例） |
| `ppt_part3.json` | spec 第三部分（总结+结尾） |
| `build_ppt.py` | 合并生成脚本 |
| `培训主题_单位.pptx` | 最终输出 |
| `培训方案.md` | 内容方案文档 |