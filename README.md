# myHermesSkills

基于我在使用 Hermes 过程中用到的一些 skill 的记录，方便在迁移或调试 Hermes 时快速取用。

## 分类目录

| 目录 | 分类 | 说明 | 条目数 |
|---|---|---|---|
| [browser/](browser/) | 浏览器控制 | 通过 browser-use CDP 控制 Chrome，实现自动化、抓取、截图、表单操作 | 2 |
| [docs/](docs/) | 文档心得 | Hermes Agent 使用配置、工作流、技巧记录 | 1 |
| 更多分类 | — | 待扩充（见 [INDEX.md](INDEX.md)） | 0 |

## 快速开始

### 1. 安装依赖（browser-use）

```bash
uv tool install browser-use --python 3.12 --upgrade --force
export PATH="$HOME/.local/bin:$PATH"
```

### 2. 连接 Chrome（CDP 远程调试）

1. 打开 `chrome://inspect/#remote-debugging`
2. 勾选 **"Allow remote debugging for this browser instance"**
3. 弹出权限框时点 **Allow**
4. 运行 `browser-use --doctor` 验证

### 3. 使用 skill

阅读对应分类目录下的 `.md` 文件，按步骤操作。

## 核心要点速览

- **调用方式**：`browser-use <<'PY' ... PY` 传入 Python 代码，helper 自动预导入
- **`js()` 限制**：对箭头函数、IIFE、正则、对象字面量会报错，需用 `function(){}` 返回字符串/数组/数字
- **`fill_input(selector, text)`**：selector 是 **CSS 选择器**，不是占位文本
- **文件上传**：必须用 CDP `DOM.setFileInputFiles` 绕过后端文件选择器
- **路径**：Windows 用 `C:\...`，`/tmp` 不存在

## 安全提示

上传 skill 前请检查 `.md` 文件中是否包含：
- 本地用户名、主机名、硬编码路径
- 密码、token、API Key 等凭证信息
- 内网 IP/域名、服务器地址

> 如有以上内容，替换为占位符后再提交。

## 许可证

MIT