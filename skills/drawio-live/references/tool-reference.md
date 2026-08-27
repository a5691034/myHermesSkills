# drawio-live 工具速查表

MCP server 启用后提供 26 个 `mcp__drawio_live__*` 工具。下表为常用工具及调用要点。

## 会话与连接

| 工具 | 用途 | 要点 |
|:----|:----|:----|
| `drawio_live_launch` | 启动/连接可见的 draw.io 窗口 | 首次必调；通过 CDP 控制，用户能实时看到操作 |
| `drawio_live_status` | 检查连接状态 | 返回 `graph_ready`、viewPort、zoom、元素数 |
| `drawio_live_get_capabilities` | 读取可用能力 | 排查环境问题 |
| `drawio_live_close_session` | 关闭 draw.io 进程 | 需 `confirm=true`，拒绝关闭外部用户会话 |

## 图形操作

| 工具 | 用途 | 要点 |
|:----|:----|:----|
| `drawio_live_add_shape` | 添加一个形状 | 指定 id、x/y/width/height、style、label；label 支持 `<br>` 换行 |
| `drawio_live_add_edge` | 添加一条连线 | 指定 source/target + style |
| `drawio_live_add_table` | 添加表格 | 行列数、表头、单元格内容 |
| `drawio_live_add_image` | 插入图片 | 支持本地路径/URL |
| `drawio_live_add_chart` | 添加数据图表 | 常规量化图表，可编辑 |
| `drawio_live_draw_sequence` | **批量顺序执行**（推荐） | `[{id,type,parent,...}]` 数组，一次完成添加/更新/连线 |
| `drawio_live_add_line` | 添加自由连线 | 与 shapes 无关的附加线 |

## 编辑与排版

| 工具 | 用途 | 要点 |
|:----|:----|:----|
| `drawio_live_update_cell` | 更新单个元素 | 可改 label、style、geometry；改字号用 style 里 `fontSize=N` |
| `drawio_live_update_table_cell` | 更新表格单元格 | |
| `drawio_live_update_table_layout` | 精确列宽行高 | |
| `drawio_live_align_cells` | 对齐两个以上元素 | 边缘对齐 |
| `drawio_live_distribute_cells` | 等距分布 | 3 个以上元素 |
| `drawio_live_group_cells` | 分组 | 返回稳定语义 group id |
| `drawio_live_ungroup_cell` | 取消分组 | 返回成员 id |
| `drawio_live_duplicate_cell` | 复制元素 | |
| `drawio_live_set_z_order` | 调整层级 | 前置/后置/置顶/置底 |

## 检查与输出

| 工具 | 用途 | 要点 |
|:----|:----|:----|
| `drawio_live_inspect` | 读取当前画布清单 | 每个 cell 的 id、label、geometry、style |
| `drawio_live_screenshot` | 截图当前画布 | 返回图片路径供检查 |
| `drawio_live_fit` | 适配全部内容到窗口 | 指定 zoom 或自动（92% 效果常见） |
| `drawio_live_save_snapshot` | 保存 .drawio 文件 | `output_path` + `overwrite=true`；从可见会话序列化 |
| `drawio_live_clear` | 清空当前页 | **需 `confirm=true`**；无单边删除接口 |

## 连线风格速查（零重叠关键）

| 参数 | 说明 |
|:----|:----|
| `edgeStyle=orthogonalEdgeStyle` | 正交走向（水平+垂直） |
| `exitX=0.2; exitY=1; entryX=0.2; entryY=0` | 起点/终点锚点：水平 20%/50%/80% 错开，垂直从底(1)到顶(0) |
| `rounded=0` | 直角 |
| `strokeWidth=2` | 线宽 |
| `dashed=1` | 虚线（语义：反哺/间接） |
| `endArrow=block` | 箭头 |
| `fontSize=15~16` | 连线标签字号（用户偏好大字体） |

## 典型抽帧：批量更新字体

```json
[
  {"id": "t1", "type": "update", "style": "fontSize=38;fontStyle=1;..."},
  {"id": "box1", "type": "update", "style": "fontSize=26;..."},
  {"id": "s1a", "type": "update", "style": "fontSize=19;..."}
]
```

## 典型抽帧：批量添加形状

```json
[
  {"id": "t1", "type": "add", "x": 600, "y": 20, "width": 720, "height": 90,
   "style": "rounded=0;whiteSpace=wrap;html=1;fillColor=#1a1a2e;fontSize=38;fontColor=#ffffff;",
   "label": "恒风传媒 × 火山引擎 场景谋划"},
  {"id": "box1", "type": "add", "x": 40, "y": 200, "width": 560, "height": 480,
   "style": "rounded=0;whiteSpace=wrap;html=1;fillColor=#f5f5f5;fontSize=26;",
   "label": "场景一 电商赋能"}
]
```