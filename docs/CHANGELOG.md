# 变更日志

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 格式。

## [0.3.2] — 2026-04-10

### 新增

- **模块复杂度分级体系**：Phase 2 模块识别后自动对每个模块评分，按得分决定文档形态，解决大型项目（40+ 模块）生成 280 个 md 文件过重的问题。
  - **Core**（≥3 分）：完整目录 `modules/<m>/`，6 个子文件，适合核心复杂模块
  - **Standard**（1-2 分）：单文件 `modules/<m>.md`，所有章节合并，适合中等复杂度模块
  - **Lightweight**（0 分）：无独立文件，内联到 `modules.md`，适合工具/简单 CRUD 模块
  - 评分维度：模块源文件数（>15: +2 / 5-15: +1）、有数据库实体（+1）、有 API 端点（+1）、被 ≥3 模块依赖（+1）
  - 预计减少文档数约 70-80%（以 43 模块为例：278 → ~65）
- **新增 `templates/modules-single.md.template`**：Standard 级别模块专用单文件模板，合并概述、职责边界、对外接口、依赖关系、代码地图、业务流程、数据模型、API 参考为一个文档
- **doc-sync 防线 1 Step 2.5 — 模块级别升级信号检测**：每次代码变更涉及模块内文件增删时，对该模块快速重评分，若触达升级阈值则提示用户确认并执行文档形态转换（Lightweight→Standard→Core）
- **doc-sync 防线 3 Step 2.5 — 模块分级全量复评**：定期审计时对所有模块重新评分，与基线对比，批量输出升级/降级建议（含降级方向，防止 Core 模块缩水后文档虚重）

### 改进

- **AGENTS.md 模板加入「Task Entry Protocol」章节**：明确要求 AI 工具做任何任务前必须先读 `docs/ARCHITECTURE.md`，禁止直接 Grep/Glob 搜索作为任务第一步，解决 AI 上手项目时绕过文档索引直接搜代码的问题
- **`modules.md.template`**：模块注册表按 Core/Standard/Lightweight 三组展示，Lightweight 模块以展开段落内联（含职责、代码位置、关键类、依赖方）
- **`doc-maintenance.md.template`**：基线快照增加 `module_tiers` 字段记录各模块级别；历史趋势表增加分级分布列（C/S/L）
- **`ARCHITECTURE.md.template` 任务路由表**：增加模块路径约定说明，适配三种文档形态的不同路径
- **`sync-matrix.md`**：新增模块级别升级/降级的同步映射规则
- **`doc-guide.md`**：新增模块复杂度评分规则、三级文档形态说明、级别升降规则；更新全局与模块文档分工表

---

## [0.3.1] — 2026-04-09

### 修复

- **data-model.md「说明」列留空问题**：补充字段说明提取规则，子代理现在必须按优先级从代码注释、数据注解、迁移文件注释中提取字段语义。各技术栈注释来源矩阵（C# `/// <summary>`、Java `/** */`、Python `help_text=`、TypeORM `comment:`、EF Core `[Comment]` 等）已写入 `doc-guide.md` 和 `data-model.md.template`，禁止将说明列留空。

### 新增

- **api-reference.md 模块级拆分**：参照 data-model.md 的双层设计，新增 `templates/modules/api-reference.md.template`（模块接口详情）。全局 `api-reference.md` 重构为索引型（Base URL、认证方式、错误码格式 + 模块接口数汇总表），各模块接口详情迁移到 `modules/<m>/api-reference.md`。同步更新文档分工矩阵、条件化生成清单（Layer 2 按需生成）、sync-matrix.md。
- **标准模式断点续跑**：在 Phase 0 前新增「断点续跑检测」步骤，检测 `docs/.init-temp/progress.md`（标准模式）或 `.init-docs/master-task.md`（大型模式），向用户展示上次进度并询问继续/重新开始。每个 Layer 交付点更新 `progress.md`，T3 澄清结果持久化到 `docs/.init-temp/clarifications.md`，避免跨会话重复提问。

### 改进

- 模块级 README.md 的「相关文档」增加 api-reference.md 链接
- `large-project-mode.md` Phase 2C 子代理执行步骤补充字段说明提取

---

## [0.3.0] — 2026-04-08

### 重构 — SKILL.md 渐进式加载架构

为避免大型 SKILL.md 一次性加载撑爆 AI 上下文窗口，按「主入口 + 按需 resource」的模式拆分两个 Skill 的指令文件。

**blyy-init-docs：**
- `SKILL.md` 从 893 行精简至 472 行（约 ↓47%，~12.6K → ~6.7K tokens）
- 新增 `resources/legacy-extraction.md`（73 行）— Phase 1.5 旧文档结构化提取详细流程
- 新增 `resources/large-project-mode.md`（128 行）— Phase 2A-2D 完整流程 + 任务持久化机制
- 新增 `resources/phase3-verification.md`（157 行）— 14 项检查 + 基线快照 YAML schema + INIT-REPORT 模板
- 新增 `resources/operational-conventions.md`（143 行）— 进度通报、上下文保护「边读边落盘」、异常容错、文件过滤规则

**blyy-doc-sync：**
- `SKILL.md` 从 354 行精简至 251 行（约 ↓29%，~5K → ~3.5K tokens）
- 新增 `resources/defense-line-3-audit.md`（124 行）— 防线 3 Step 0-6 详细流程

**关键设计原则：**
- 每个新 resource 文件顶部明确标注「何时读取」触发条件
- SKILL.md 中保留触发条件 + 核心铁律摘要，确保即便 AI 不展开 resource 也能遵循关键规则
- 资源文件表升级为三列（文件 / 何时读取 / 用途）

### 文档

- 重写 `docs/usage-guide.md`：反映新 Phase 模型、三道防线细节、T1/T2/T3、结构化 TODO、基线快照、resource 文件
- 更新 `docs/customization.md`：补充资源文件清单、YAML front matter 字段、`applicable_project_types` 项目类型过滤
- 新增 `docs/CHANGELOG.md`（本文件）
- 新增 `docs/architecture.md`：解释仓库内部结构与渐进式加载机制

---

## [0.2.0]

### 新增

- **三级事实分类（T1/T2/T3）**：每个填充的事实必须标注可信度级别，禁止 AI 自由臆测
- **Phase 2.5 填充前审查关卡**：T3 推测项批量呈现给用户一次性确认，避免逐条打断
- **Phase 1.5 旧文档结构化提取**：对 `docs-old/` 执行穷举式提取，作为 Phase 2 的输入
- **结构化 TODO 标记** `<!-- TODO[priority,type,owner]: ... -->`：按 priority/type/owner 三轴分类
  - priority: `p0` / `p1` / `p2` / `p3`
  - type: `business-context` / `design-rationale` / `ops-info` / `security-info` / `external-link` / `metric-baseline`
  - owner: `user` / `dev-team` / `ops-team` / `security-team` / 具体负责人
- **基线快照 YAML 块**：Phase 3 自动写入 `docs/doc-maintenance.md`，含 `inventory` / `markers` / `layer_distribution` / `fact_levels` 四类数据，供 doc-sync 防线 3 程序化解析
- **历史快照趋势表**：doc-sync 防线 3 每次执行后追加一行，便于发现腐烂趋势
- **YAML front matter 扩展字段**：`audience` / `read_priority` / `max_lines` / `parent_doc` / `code_anchors` / `applicable_project_types` / `last_synced_commit`
- **`applicable_project_types` 项目类型过滤**：Phase 1 骨架按字段自动过滤模板，无需 AI 自由判断
- **代码位置列必填**：所有列表型字段必须包含「源文件」/「定义位置」列，使用 `file:line` 格式
- **`last_synced_commit` 增量识别**：doc-sync 防线 1 基于该字段执行 `git diff` 增量识别变更范围
- **大型项目模式 Phase 2A-2D**：项目轮廓 → 锚点识别 → 模块聚焦分析 → 渐进式生成
- **任务持久化机制**：大型项目模式将进度持久化到 `.init-docs/` 目录，可跨会话恢复
- **确定性清单预扫描**：Phase 2 启动前用 shell 命令建立完整文件清单，作为子代理的强制检查表

### 改进

- 子代理改为隔离上下文执行，结果立即落盘到 `.init-temp/` 或 `.init-docs/`
- 进度通报规范化：主 agent 用 Phase 级输出，子代理用 `├─` 缩进区分

---

## [0.1.1]

### 修复

- 文档优化与初始化流程稳定性改进

---

## [0.1.0]

### 新增

- 初始版本发布
- `blyy-init-docs` Skill — 项目文档初始化
- `blyy-doc-sync` Skill — 文档持续同步维护
- 基础三道防线模型
- 多 AI 工具兼容（Gemini / Codex / Cursor / Claude Code）
- Windows / Linux / macOS 安装脚本

[0.3.2]: https://github.com/VzapX/blyy-doc-skills/releases/tag/v0.3.2
[0.3.1]: https://github.com/VzapX/blyy-doc-skills/releases/tag/v0.3.1
[0.3.0]: https://github.com/VzapX/blyy-doc-skills/releases/tag/v0.3.0
[0.2.0]: https://github.com/VzapX/blyy-doc-skills/releases/tag/v0.2.0
[0.1.1]: https://github.com/VzapX/blyy-doc-skills/releases/tag/v0.1.1
[0.1.0]: https://github.com/VzapX/blyy-doc-skills/releases/tag/v0.1.0
