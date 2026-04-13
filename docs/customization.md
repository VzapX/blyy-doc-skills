# 自定义扩展指南

> 适用版本：v0.6.0+

## 概述

blyy-ai-docs 支持自定义扩展。可以修改模板、添加新的技术栈锚点、调整资源文件等，以适应你的项目需求。

---

## 一、自定义文档模板

### 模板位置

**在本仓库中：**

```
skills/blyy-ai-docs/templates/
├── INDEX.md.template              ← Hub：路由 + 模块注册 + 流程目录 + 全局决策
├── module-detail.md.template      ← 单文件模式的模块详情（≤200 行）
├── module-index.md.template       ← 目录溢出模式的 _index.md（摘要 + 路由）
├── code-queries.md.template       ← fd/rg 查询配方库
└── MANIFEST.yaml.template         ← 状态契约 v2（含 detail_file / layout / overflow_files）
```

> 溢出模块的 topic 子文件（`terms.md`、`flows.md`、`decisions.md`）复用 `module-detail.md.template` 中对应章节的格式，不需要独立模板。

**安装到目标项目后：**

| AI 工具 | 模板路径 |
|---------|---------|
| Gemini / Codex / Cursor | `.agents/skills/blyy-ai-docs/templates/` |
| Claude Code | `.claude/skills/blyy-ai-docs/templates/` |

### 模板占位符

模板中使用以下占位符，在 Mode A 写入阶段会被替换为实际内容：

| 占位符 | 含义 |
|--------|------|
| `{{DATE}}` | 当前日期（YYYY-MM-DD） |
| `{{MODULE_NAME}}` | 模块名称 |
| `{{MODULE_PATH}}` | 模块代码根目录 |
| `{{CODE_ROOT}}` | 模块代码根目录（INDEX.md 中使用） |
| `{{BUSINESS_SUMMARY}}` / `{{ONE_LINE}}` / `{{ONE_LINE_SUMMARY}}` | 模块 1 行业务定位 |
| `{{MODULE_ENTRY_ANCHOR}}` / `{{ENTRY_ANCHOR}}` | 模块入口符号锚点 |
| `{{ENTRY_PURPOSE}}` | 入口符号用途说明 |
| `{{OTHER_MODULE}}` | 依赖的其他模块名 |
| `{{IMPORT_ANCHOR}}` / `{{IMPORT_FILE_ANCHOR}}` | import/using 锚点 |
| `{{STACK_PRIMARY}}` | 主技术栈 |
| `{{PKG_MGR}}` | 包管理器 |
| `{{INIT_COMMIT_SHA}}` / `{{SHA_SHORT}}` | Git commit hash |
| `{{LAST_SYNCED_SHORT_SHA}}` / `{{LAST_SYNCED_DATE}}` / `{{LAST_AUDITED_DATE}}` | 新鲜度指标 |
| `{{ANCHOR_COUNT}}` / `{{STALE_COUNT}}` / `{{TOTAL_DOC_COUNT}}` / `{{UNVERIFIED_COUNT}}` / `{{TODO_COUNT}}` / `{{TREND_ROW_COUNT}}` | 统计指标 |
| `{{N}}` / `{{M}}` / `{{K}}` / `{{L}}` / `{{T}}` | 通用数值占位 |
| `<!-- UNVERIFIED: ... -->` | 不可信内容包裹 |
| `<!-- TODO[pN, type]: desc -->` | 结构化 TODO 标记 |

### YAML Front Matter 字段

模板的 YAML front matter 字段：

**INDEX.md / module-detail.md**：
```yaml
---
ai_docs_version: 2               # 文档格式版本（v2 = Hub-and-Spoke）
last_synced_commit: init          # Mode B 增量识别基准
last_audited: YYYY-MM-DD         # 上次 Mode C 审计日期
audience: ai-only                # 目标读者（固定为 ai-only）
max_lines: 200                   # 文件软上限行数
code_anchors: []                 # 关注的代码锚点
---
```

**module-detail.md 额外字段**：
```yaml
---
module: orders                   # 模块 slug
tier: Core                       # 模块分级
code_root: src/Orders/           # 模块代码根目录
layout: file                     # file（单文件）或 directory（目录溢出模式）
---
```

### 自定义建议

1. **保留必要的占位符与 front matter** — 移除会破坏自动填充
2. **调整文档结构** — 可增删章节，调整排列顺序
3. **Fork 后修改** — 建议 fork 本仓库后修改，方便后续跟踪上游更新

---

## 二、添加新的技术栈支持

### 锚点矩阵位置

`skills/blyy-ai-docs/resources/tech-stack-matrix.md` 定义了各技术栈的依赖文件探测、后端/前端锚点矩阵、架构布局检测和跨层业务域提取规则。

### 添加新技术栈

1. 在 `tech-stack-matrix.md` 的 Section I「依赖文件探测」中添加新行
2. 在 Section II/III「后端/前端锚点矩阵」中添加对应的锚点文件
3. 在 Section IV「模块根目录启发」中补充该技术栈的模块识别特征
4. 在 Section VI「架构布局检测」中添加 Layered/Domain 关键词
5. 在 Section VII「跨层业务域提取」中添加文件名后缀剥离规则

同时更新 `resources/query-recipes.md`，添加对应的 `fd`/`rg` 命令。

---

## 三、自定义资源文件

### 资源文件清单

SKILL.md 的详细流程已拆分到独立资源文件，AI 按需加载：

| 文件 | 何时被读取 | 用途 |
|------|-----------|------|
| `resources/tech-stack-matrix.md` | Mode A Phase A0/A1 | 技术栈探测 + 架构布局检测 + 跨层业务域提取 |
| `resources/query-recipes.md` | Mode A Phase A2 | 8 大栈 fd/rg 命令库 |
| `resources/anti-hallucination.md` | Mode A Phase A3 子代理分发前 | T1/T2/T3 + 锚点强制 + 禁枚举 + 结构化 TODO |
| `resources/anchor-extraction.md` | Mode A Phase A5 / Mode B/C | 8 语言符号定位 + body 提取 |
| `resources/self-invalidation.md` | Mode B Phase B1 / Mode C Phase C0 | 4-tier 失效检测算法 |
| `resources/module-tiering.md` | Mode A Phase A1 / Mode B Phase B3 / Mode C Phase C1.5 | 模块复杂度分级评分 |
| `resources/large-project-mode.md` | Mode A Phase A0 文件数 > 500 | 大型项目分阶段执行 + 跨会话持久化 |
| `resources/sync-matrix.md` | Mode B Phase B1 | 代码变更 → 文档更新映射 + 渐进式 TODO 填充 |

### 自定义建议

- **不要直接修改 SKILL.md** — 它是 AI 工具识别技能的入口，结构变化可能破坏触发
- **优先修改 resource 文件** — 想调整某个 Phase 的细节，编辑对应 resource 即可
- **新增 resource 文件需更新 SKILL.md 的「资源文件」表** — 否则 AI 不会知道要读它，并在表中明确「何时读取」的触发条件

---

## 四、常见自定义场景

| 场景 | 修改文件 |
|------|---------|
| 添加新技术栈的 fd/rg 命令 | `resources/query-recipes.md` + `resources/tech-stack-matrix.md` |
| 调整模块复杂度评分规则 | `resources/module-tiering.md` |
| 调整大型项目模式阈值或分阶段流程 | `resources/large-project-mode.md` |
| 调整同步矩阵映射规则 | `resources/sync-matrix.md` |
| 调整反幻觉/锚点规则 | `resources/anti-hallucination.md` |
| 调整自失效检测算法 | `resources/self-invalidation.md` |
| 调整锚点提取正则 | `resources/anchor-extraction.md` |
| 修改产物文档结构/格式 | `templates/*.template` |
| 调整模块文件溢出阈值（默认 200 行）| `SKILL.md` Phase A5 + Phase B3.5 |
| 调整滞回区间（默认 40 行缓冲带）| `SKILL.md` Phase B3.5 |
