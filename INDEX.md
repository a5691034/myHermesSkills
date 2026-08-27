# INDEX — myHermesSkills 完整索引

> 按分类浏览所有 skill。每个 skill 是一个独立的 `.md` 文件，平铺在对应分类目录下。

---

## browser/ — 浏览器控制与自动化

通过 `browser-use`（browser-harness，CDP 协议）控制普通 Chrome 浏览器。

| Skill | 说明 | 依赖 |
|---|---|---|
| [browser-use](browser/browser-use.md) | 通用浏览器 CDP 控制：自动化、抓取、截图、表单操作 | `browser-use` v0.1.8 |
| [weibo-publish](browser/weibo-publish.md) | 新浪微博图文自动发布 | `browser-use` + 微博登录态 |

---

## docs/ — 文档与心得

Hermes Agent 使用配置、工作流、技巧记录。

| Skill | 说明 |
|---|---|
| [agent profile 的配置心得](docs/agent%20profile的配置心得.md) | Hermes Agent 使用中遇到的问题及处理方案 |

---

## research/ — 研究搜索

并行搜索技能，多平台同时检索后汇总。

| Skill | 说明 | 依赖 |
|---|---|---|
| [skill-search-parallel](research/skill-search-parallel.md) | 并行搜索：同时从多个技能平台搜索，汇总去重后反馈 | `delegate_task` |

---

## creative/ — 创意设计

架构图、图表、可视化等绘图与创意技能。

| Skill | 说明 | 依赖 |
|---|---|---|
| [drawio-live](creative/drawio-live.md) | 在可见的 draw.io 画布上实时绘制/编辑架构图（零重叠连线、大字体、可保存 .drawio） | drawio-live MCP + draw.io 桌面版 |

---

## presentation/ — 演示文稿 / PPT 制作

PPT 自动化制作技能包（ppt-master 总框架 + 国企风格子技能）。

| Skill | 说明 | 依赖 |
|---|---|---|
| [ppt-master](presentation/ppt-master.md) | PPT 制作总框架：SVG→PPTX 流水线、批量生成工作流、模板管理 | python-pptx |
| [state-owned-enterprise-ppt](presentation/state-owned-enterprise-ppt.md) | 国企风格 PPT 子技能：字体字号规范、页码编排、SVG 流水线备注 | ppt-master |

---

## 其他分类（待扩充）

| 分类目录 | 用途 | 当前条目 |
|---|---|---|
| `github/` | GitHub 操作（认证、PR、Issue、CI/CD） | 空 |
| `development/` | 软件开发流程（TDD、调试、代码审查） | 空 |
| `productivity/` | 办公效率（文档、表格、邮件、日历） | 空 |
| `media/` | 媒体处理（图片、视频、音频） | 空 |
| `mlops/` | 机器学习运维（训练、推理、评估） | 空 |
| `monitoring/` | 巡检监控（告警、系统检查） | 空 |

---

## 文件命名规则

- 文件名：`<skill-name>.md`（小写、连字符）
- 每个 skill 一个文件，平铺在分类目录下
- 分类目录名：单数、小写（如 `browser/` 而非 `browsers/`）

## 添加新 Skill 的流程

1. 确定所属分类，放入对应目录
2. 文件命名：`<skill-name>.md`
3. 更新本 INDEX.md，在对应分类下添加条目
4. 如果涉及新分类，在 README.md 的分类表中也添加一行