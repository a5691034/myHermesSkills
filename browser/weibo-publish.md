---
name: weibo-publish
description: 用 browser-use CDP 发微博（文字+图片），含传图与点击发送。
---

# 微博发布 (weibo-publish)

通过 `browser-use`（底层 browser-harness v0.1.8）控制普通 Chrome，发布新浪微博文字 + 图片。已在 Windows 10 + Chrome 上验证通过。

## 前置条件

1. **browser-use 已安装**：`uv tool install browser-use --python 3.12`（可执行文件在 `~/.local/bin`，需 `export PATH="$HOME/.local/bin:$PATH"`）。
2. **Chrome 已开 CDP 远程调试**：用户需在 Chrome 打开 `chrome://inspect/#remote-debugging` 勾选 "Allow remote debugging"，点 Allow，然后用 `browser-use doctor` 验证连接。
3. **已登录微博**。cookie 持久化在用户的独立 Chrome profile。

## 关键机制（务必记住）

- helper 通过 `browser-use <<'PY' ... PY` 喂 Python 代码，预导入：`page_info, new_tab, capture_screenshot, fill_input, cdp, js, click_at_xy, type_text, scroll`。
- **`fill_input(selector, text)` 的 selector 是 CSS 选择器，不是占位文本**。微博发帖框 class 会变，用 `document.querySelector('textarea')` 探查。
- **`js()` 对复杂表达式极敏感**：IIFE、箭头函数、正则、对象字面量、`.find().something` 链、`getBoundingClientRect()` 直接返回对象 → 都会报 SyntaxError。**对策**：用 `function(){}` 而非箭头、返回简单值(字符串/数组/数字)、不返回 DOMRect 对象（改为手动拼 `rect.x+','+rect.y`）。
- **发图必须用 CDP `DOM.setFileInputFiles`**，绕过后端文件选择器：
  ```python
  doc = cdp("DOM.getDocument", depth=3)
  rootId = doc["root"]["nodeId"]
  fileNodeId = cdp("DOM.querySelector", nodeId=rootId, selector="input[type=file]")["nodeId"]
  backendNodeId = cdp("DOM.describeNode", nodeId=fileNodeId)["node"]["backendNodeId"]
  cdp("DOM.setFileInputFiles", backendNodeId=backendNodeId, files=[IMG])
  ```
  `setFileInputFiles` 成功返回 `{}`（空 dict 是正常成功）。
- **发送按钮**：`[].slice.call(document.querySelectorAll('button')).find(function(b){return (b.innerText||'').trim()==='发送'}).click()`。JS `.click()` 已验证可用。
- **路径**：Windows 上脚本跑在 Windows（`os.path.exists(win_path)` 为 True），图片用 Windows 绝对路径（`C:\...`）。`/tmp` 不可用，截图用 `C:\Users\...\xxx.png`。

## 完整发布流程

```bash
export PATH="$HOME/.local/bin:$PATH"
browser-use <<'PY'
import time
TEXT = "立秋快乐！！"
IMG  = r"C:\path\to\image.jpg"

# 1. 打开首页（已登录）
new_tab("https://weibo.com/")
time.sleep(2)

# 2. 点击中央发帖输入框（"有什么新鲜事想分享给大家？"，约 x=850,y=165）
click_at_xy(850, 165)
time.sleep(1)

# 3. 填文案（用 CSS 选择器，先探查 textarea class）
fill_input("textarea[placeholder]", TEXT, clear_first=True)
time.sleep(1)

# 4. 注入图片（CDP DOM.setFileInputFiles）
doc = cdp("DOM.getDocument", depth=3)
fileNodeId = cdp("DOM.querySelector", nodeId=doc["root"]["nodeId"], selector="input[type=file]")["nodeId"]
backendNodeId = cdp("DOM.describeNode", nodeId=fileNodeId)["node"]["backendNodeId"]
cdp("DOM.setFileInputFiles", backendNodeId=backendNodeId, files=[IMG])
time.sleep(2)

# 5. 截图确认文案+配图已就位
capture_screenshot(path=r"C:\Users\你的用户名\bu_shot\check.png")

# 6. 点击"发送"
js("[].slice.call(document.querySelectorAll('button')).find(function(b){return (b.innerText||'').trim()==='发送'}).click()")
time.sleep(3)
capture_screenshot(path=r"C:\Users\你的用户名\bu_shot\after_send.png")
PY
```

## 验证发布成功

截屏后用 `vision_analyze` 检查：信息流顶部第一条是否为新微博（含文案 + 配图 + 「刚刚 来自 微博网页版」）。若发帖框已清空 + 信息流出现该微博 = 成功。

## 常见坑

- **`fill_input` 报 "element not found"**：传了占位文本而非 CSS 选择器。改用 `textarea` 标签或探查出的 class。
- **`js()` SyntaxError**：见"关键机制"。简化表达式，避免箭头/IIFE/正则/DOMRect。
- **微博反自动化**：`openLoginLayer=1` 会被强制改回 0，不直接弹登录层。需先从首页点击"登录/注册"按钮跳转。登录页地址 `passport.weibo.com/sso/signin`。
- **`capture_screenshot` 路径**：Windows 用 `C:\...`，`/tmp` 不存在。
- **坐标点击可能点偏**：优先用 CDP/DOM 定位 + JS click，坐标 `click_at_xy` 作为兜底。

## 诊断

连接问题跑 `browser-use --doctor`；`daemon alive` FAIL 但实际能用时，以 `page_info()` 能否返回为准（doctor 探测逻辑偏严格）。