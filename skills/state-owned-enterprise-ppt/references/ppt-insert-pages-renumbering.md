# 中间插入页面导致的全局页码重编号工作流

## 场景

PPT 已写完 N 页，需要在中部插入 M 页新内容，总页数变为 N+M。

## 标准步骤

### 1. 创建新页面（用临时文件名）

用 `_new` 后缀暂存，避免与现有文件冲突：
```
17_new_content.svg    # 新 P17
18_new_content.svg    # 新 P18
```

### 2. 分三阶段重命名（避免文件冲突）

**阶段A**：将被后移的旧文件改为 `_tmp` 后缀
```python
rename_map = {
    '17_content.svg': '17_tmp.svg',   # 旧P17→P19
    '18_section.svg': '18_tmp.svg',   # 旧P18→P20
    '19_content.svg': '19_tmp.svg',   # 旧P19→P21
    ... # 直到最后一页
}
```

**阶段B**：将新文件（`_new`）放到目标位置
```python
os.rename('17_new_content.svg', '17_content.svg')
os.rename('18_new_content.svg', '18_content.svg')
```

**阶段C**：将 `_tmp` 文件放到后移后的最终位置
```python
rename_final = {
    '17_tmp.svg': '19_content.svg',
    '18_tmp.svg': '20_section.svg',
    ...
}
```

### 3. 批量更新页码

```python
import re
for fname in sorted(svg_files):
    num = int(fname[:2])
    c = read(fname)
    c = c.replace('>/ 27<', f'>PAGE {num:02d} / 27<')
    c = re.sub(r'PAGE \d+ / \d+', f'PAGE {num:02d} / 27', c)
    write(fname, c)
```

### 4. 同步更新引用页码的文件

- **TOC 目录页**：更新章节的页面范围（如 `P15 — P17` → `P15 — P18`）
- **章节分隔页**：同上
- **notes/ 目录**：对应改名（同样需要 tmp 中转）

### 5. 运行 quality check + export

`svg_quality_checker.py` 必须通过 0 errors，然后 `svg_to_pptx.py` 导出，最后注入 notes。

## 坑：页码正则替换会破坏文本

**事故**：用 `re.sub(r'PAGE \d+ / 25', f'/ {total}', c)` 时，留下的文本变成只有 `/ 27`，丢失了 `PAGE XX`。

**原因**：旧文件里 `PAGE 04 / 25` 是完整文本元素内容，正则替换后只留下 `/ 27`。

**修复**：先用 `string.replace` 补全坏格式，再用正则统一：
```python
c = c.replace('>/ 27<', f'>PAGE {num:02d} / 27<')  # 先补坏格式
c = re.sub(r'PAGE \d+ / \d+', f'PAGE {num:02d} / 27', c)  # 再统一
```

## 坑：Windows os.rename 文件冲突

当目标文件名已存在时（如旧 19_content.svg 存在，想重命名 17_content.svg → 19_content.svg），`os.rename` 抛出 `FileExistsError`。必须用三阶段 tmp 中转。

## 新页 SVG 内容规范

- 字号遵守 `ppt-font-size-standard.md`（标题 36pt、一级 24-28pt、二级 20pt）
- 包含 `data-pptx-page-role="content"` 属性
- 包含 `PAGE XX / NN` 页码文本
- 不使用 `<strong>` 等 HTML 标签（SVG 不支持）
- notes 文件命名与 SVG 一一对应