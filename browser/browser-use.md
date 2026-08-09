---
name: browser-use
description: 用 browser-use CDP 控制普通 Chrome。网页自动化、抓取、截图、表单操作。
---

# browser-use 浏览器控制

通过 `browser-use`（底层 browser-harness v0.1.8）协议控制普通 Chrome 浏览器。已在 Windows 10 + Chrome 上验证通过。

## 适用场景

- 网页自动化操作（登录、发帖、表单填写）
- 网页数据抓取 / 巡检
- 截图取证
- 任何需要控制真实浏览器的任务

## 前置条件

### 1. 安装

```bash
# 安装 browser-use（uv tool，全系统命令）
uv tool install browser-use --python 3.12 --upgrade --force

# 确认安装
browser-use --version          # 应为 0.1.8
browser-use doctor             # 诊断
```

**注意**：browser-use 装在 uv 隔离虚拟环境（`~/.local/bin/`），不污染系统 Python。使用时需 `export PATH="$HOME/.local/bin:$PATH"`。

### 2. 浏览器 CDP 连接

用户需在 Chrome 浏览器中：
1. 打开 `chrome://inspect/#remote-debugging`
2. 勾选 **"Allow remote debugging for this browser instance"**
3. 如果弹出权限框，点 **Allow**
4. 然后运行 `browser-use --doctor` 验证连接

**诊断结果解读**：`chrome running` 为 OK 即可。`daemon alive` FAIL 可能是 doctor 的探测方式偏严格造成的假阴性——以 `page_info()` 能否返回实际数据为准。

### 3. 登录态

浏览器 cookie 持久化在用户的 Chrome profile 中，登录只需一次（手动完成），后续 session 自动保持。

## 用法

### 基础调用

```bash
export PATH="$HOME/.local/bin:$PATH"

# 单行命令
browser-use <<'PY'
print(page_info())
PY
```

### 预导入的 helper

所有 helper 通过 `browser-use <<'PY' ... PY` 传入 Python 代码，自动预导入：

| helper | 作用 | 注意事项 |
|---|---|---|
| `page_info()` | 返回当前 tab 的 URL、标题、尺寸 | 返回 dict |
| `new_tab(url)` | 打开新标签页并导航 | 首次导航用这个，不用 `goto_url` |
| `goto_url(url)` | 当前标签页跳转 | 需先 `new_tab` 创建 tab |
| `capture_screenshot(path)` | 截图保存到磁盘 | Windows 用 `C:\...`，`/tmp` 不存在 |
| `fill_input(selector, text)` | 填充输入框 | **selector 是 CSS 选择器，不是占位文本** |
| `type_text(text)` | 模拟键盘输入 | 光标需已在输入框内 |
| `click_at_xy(x, y)` | 坐标点击 | 坐标最好通过 `getBoundingClientRect()` 计算 |
| `js(expression)` | 执行 JavaScript | **见下方"js() 坑"** |
| `cdp(method, **params)` | 直接调用 Chrome DevTools Protocol 命令 | 用于 `DOM.setFileInputFiles` 等高级操作 |
| `scroll(direction)` | 滚动页面 | direction: 'up' / 'down' |
| `press_key(key)` | 键盘按键 | 'Enter', 'Tab', 'Escape' 等 |
| `list_tabs()` | 列出所有标签页 | |
| `switch_tab(id)` | 切换到指定标签页 | |
| `close_tab()` | 关闭当前标签页 | |

### 核心陷阱

#### `js()` 对复杂表达式极敏感

以下写法**会报 SyntaxError**：
- 箭头函数 `() => {}`
- IIFE `(function(){})()`
- 正则字面量 `/pattern/`
- 对象字面量作为返回值 `return {a:1}`
- `.find(function(b){...}).something` 链式调用

**对策**：用 `function(){}` 代替箭头函数，返回字符串/数组/数字，不要返回 DOMRect 对象或对象字面量。

**可行的写法**：
```python
# ✅ 返回数组
js("Array.from(document.querySelectorAll('button')).map(function(b){return (b.innerText||'').trim()})")

# ✅ 返回字符串
js("document.title")

# ✅ 返回数字
js("document.querySelectorAll('input').length")

# ✅ 返回坐标字符串
js("[].slice.call(document.querySelectorAll('button')).find(function(b){return (b.innerText||'').trim()==='发送'}).getBoundingClientRect().x+','+[].slice.call(document.querySelectorAll('button')).find(function(b){return (b.innerText||'').trim()==='发送'}).getBoundingClientRect().y")
```

#### `fill_input(selector, text)` 的 selector 是 CSS 选择器

```python
# ✅ 正确
fill_input("textarea[placeholder]", "文案内容", clear_first=True)

# ❌ 错误：传了占位文本而非 CSS 选择器
fill_input("有什么新鲜事想分享给大家？", "文案内容")
```

#### 文件上传：必须用 CDP

普通 `input[type=file]` 点击会弹出系统文件选择器，无法自动化。必须用 CDP 的 `DOM.setFileInputFiles` 注入：

```python
doc = cdp("DOM.getDocument", depth=3)
rootId = doc["root"]["nodeId"]
fileNodeId = cdp("DOM.querySelector", nodeId=rootId, selector="input[type=file]")["nodeId"]
backendNodeId = cdp("DOM.describeNode", nodeId=fileNodeId)["node"]["backendNodeId"]
cdp("DOM.setFileInputFiles", backendNodeId=backendNodeId, files=[r"C:\path\to\image.jpg"])
# 成功返回 {}（空 dict 是正常值）
# 上传多张图：files=[IMG1, IMG2, IMG3]
```

#### 路径

Windows 环境下：`/tmp` 不存在，`capture_screenshot` 用 `C:\Users\...\xxx.png`。图片路径用 Windows 绝对路径。

## 常见模式

### 导航 + 截图
```python
new_tab("https://example.com")
import time; time.sleep(2)
capture_screenshot(path=r"C:\Users\...\screenshot.png")
```

### 表单填写 + 提交
```python
click_at_xy(850, 165)   # 点击输入框
fill_input("textarea", "内容", clear_first=True)
js("document.querySelector('button[type=submit]').click()")
```

### 探查页面元素
```python
print("输入框:", js("document.querySelectorAll('input').length"))
print("按钮:", js("Array.from(document.querySelectorAll('button')).map(function(b){return (b.innerText||'').trim()})"))
print("链接:", js("Array.from(document.querySelectorAll('a')).map(function(a){return (a.innerText||'').trim()}).filter(function(t){return t.length>0}).slice(0,20)"))
```

### 获取元素坐标
```python
# 返回 "x,y,w,h" 字符串
r = js("[].slice.call(document.querySelectorAll('button')).find(function(b){return (b.innerText||'').trim()==='目标按钮文本'}).getBoundingClientRect().x+','+[].slice.call(document.querySelectorAll('button')).find(function(b){return (b.innerText||'').trim()==='目标按钮文本'}).getBoundingClientRect().y+','+[].slice.call(document.querySelectorAll('button')).find(function(b){return (b.innerText||'').trim()==='目标按钮文本'}).getBoundingClientRect().width+','+[].slice.call(document.querySelectorAll('button')).find(function(b){return (b.innerText||'').trim()==='目标按钮文本'}).getBoundingClientRect().height")
```

## 复用的 skill 体系

| skill | 用途 |
|---|---|
| `browser-use`（本 skill） | 通用浏览器控制，掌握 CDP 调用、helper 用法、js() 坑 |
| `weibo-publish` | 用 browser-use 在微博发图文帖 |

## 故障排查

```bash
browser-use --doctor
```

- `chrome running` FAIL → 打开 Chrome
- `daemon alive` FAIL → 用户去 `chrome://inspect` 勾选远程调试，点 Allow。若实际功能正常可忽略
- `active browser connections` 0 → daemon 未连上，检查 CDP 权限
- 更新：`browser-use --update -y`