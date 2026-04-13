# 变更日志

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 格式。

## [0.6.0] — 2026-04-13

### 重构 — Hub-and-Spoke 架构（三级渐进式披露）

将 ai-docs/ 产物从 v1 扁平结构（7 个全局文件）重构为 v2 Hub-and-Spoke 结构（INDEX.md Hub + 每模块独立详情文件 Spoke），大幅降低 AI 单次任务的上下文读取量。

**核心改动**：

- **Hub-and-Spoke 文件结构**：INDEX.md 作为唯一路由中心，每个 Core/Standard 模块有独立详情文件 `modules/{slug}.md`；Lightweight 模块仅在 INDEX.md 登记一行
- **模块内溢出机制**：单个模块内容超 200 行时自动拆分为目录结构 `modules/{slug}/_index.md` + topic 子文件（terms/flows/decisions），实现模块内的三级渐进式披露
- **子模块拆分检测**：Phase A1 和 Mode C Phase C1.7 检测大模块内部子领域边界（≥3 子目录各 ≥15 文件），建议用户拆分为独立模块
- **布局自动演化**：Mode B 新增 Phase B3.5 / Mode C 新增 Phase C1.7，自动检测模块文件是否需要在单文件/目录模式间转换
- **滞回区间防震荡**：升级阈值 >200 行 / 降级阈值 ≤160 行（40 行缓冲带），topic 溢出 >60 行 / 回收 ≤30 行
- **v1 兼容检测**：Mode B 检测到 v1 平面结构时提示用户升级到 v2
- **阅读路径优化**：Bug fix 场景从 ~950 行降至 ~350 行（缩减 63%）；Onboarding 从 ~850 行降至 ~200 行起步（缩减 76%）

**删除的模板**（内容拆入 INDEX.md + 模块详情文件）：

- `templates/modules.md.template`
- `templates/glossary.md.template`
- `templates/flows.md.template`
- `templates/decisions.md.template`

**新增的模板**：

- `templates/module-detail.md.template` — 单文件模式的模块详情
- `templates/module-index.md.template` — 目录溢出模式的 _index.md（摘要 + 路由）

**SKILL.md 变更**：

- 概述新增 v2 架构说明和渐进式披露原则
- Phase A1 新增子模块拆分检测步骤
- Phase A5 重写为 Hub-and-Spoke 写入流程（modules/ → INDEX.md → MANIFEST）
- Phase A6 自检扩展至 11 项（新增布局一致性、Flow Catalog 覆盖等）
- Mode B 新增 Phase B0 v1 兼容检测
- Mode B 新增 Phase B3.5 布局演化检测
- Mode C 新增 Phase C1.7 布局演化 + 子模块拆分建议
- 核心铁律新增第 13 条（布局自动演化）和第 14 条（anchors.docs 精确到模块文件）

**MANIFEST.yaml 变更**：

- `ai_docs_version` 升为 2
- `modules[]` 新增 `detail_file`、`layout`（file/directory/none）、`overflow_files` 字段
- `anchors[].docs` 反向索引精确到模块文件路径
- `history[].event` 新增 `layout-upgrade` / `layout-downgrade` 枚举

**Resource 文件变更**：

- `sync-matrix.md`：变更类型映射更新为模块文件级
- `anti-hallucination.md`：自查清单扩展至 18 项，文件引用更新
- `module-tiering.md`：新增子模块拆分检测规则（Section 五）；分级表更新产物列
- `large-project-mode.md`：Phase A5-L 写入顺序更新为 Hub-and-Spoke

---

## [0.5.0] — 2026-04-13

### 重构 — 合并为单一技能 `blyy-ai-docs`

将 `blyy-init-docs` 和 `blyy-doc-sync` 的精华融入 `blyy-ai-docs`，删除这两个技能，仓库从"三个技能"简化为"一个技能三种模式"。

**迁移的核心概念**：

- **模块复杂度分级**（来自 init-docs）：新建 `resources/module-tiering.md`，6 分制评分控制**分析深度**（Core=子代理全量分析 / Standard=适度分析 / Lightweight=跳过子代理），不控制文件结构
- **架构布局检测**（来自 init-docs）：融入 `resources/tech-stack-matrix.md` Section VI-VII，支持 Layered vs Domain-driven 检测 + 跨层业务域提取
- **大型项目模式**（来自 init-docs）：新建 `resources/large-project-mode.md`，>500 文件触发分阶段执行 + 跨会话持久化（`.init-temp/master-task.yaml`）
- **同步矩阵**（来自 doc-sync）：新建 `resources/sync-matrix.md`，代码变更→文档更新映射（简化为 ~15 条映射 ai-docs 的 7 个文件）
- **基线趋势追踪**（来自 doc-sync）：MANIFEST.yaml 新增 `trend` 节，连续 3 次审计 TODO 上升 → 标记腐烂信号
- **结构化 TODO**（来自 doc-sync）：简化为 `<!-- TODO[p0-p3, type]: desc -->`（去掉 owner，AI-only 无人类负责人）
- **渐进式 TODO 填充**（来自 doc-sync）：Mode B 同步时顺手填充相关 TODO
- **断点续跑**（来自 init-docs）：新增 Phase 0 检测 `.init-temp/master-task.yaml`

**明确不迁移（违反核心原则"不重复代码事实"）**：

- 确定性清单预扫描 + 物化基线计数
- 14 项完成度检查中的覆盖率验证
- 人类运维文档（deployment/runbook/monitoring）
- 28 个面向人类的文档模板
- 旧文档结构化提取（legacy-extraction）
- Per-document `last_synced_commit`
- Pre-commit validation gate

**SKILL.md 变更**：

- 删除"与现有 skill 的关系"章节
- 新增 Phase 0 断点续跑检测
- Phase A0 新增文件数检测（>500 触发大型项目模式）
- Phase A1 重写为"模块识别与分级"，含架构布局检测 + 跨层业务域提取 + 分级评分
- Phase A3 按分级调整子代理任务深度
- Mode B Phase B1 重写为"主动映射 + 被动失效检测"
- Mode B 新增 Phase B2 渐进式 TODO 填充 + Phase B3 分级演化检测
- Mode C 新增 Phase C1.5 模块分级全量复评 + Phase C3 趋势追踪
- 资源文件表从 5 个扩展到 8 个
- 核心铁律新增"结构化 TODO 格式"

**模板变更**：

- `MANIFEST.yaml.template`：modules 条目新增 tier + complexity_score；新增 trend 节
- `modules.md.template`：按分级分组显示（Core 完整块 / Standard 适度块 / Lightweight 表格行）
- `INDEX.md.template`：新鲜度概览新增 TODO markers + Trend rows

**仓库级变更**：

- `install.sh` / `install.ps1`：默认只安装 `blyy-ai-docs`
- `README.md`：从"三个技能"重写为"一个技能三种模式"
- `CLAUDE.md`：重写为单技能描述 + 四条核心原则
- `docs/architecture.md`：仓库结构图仅保留 ai-docs；删除三技能边界表/数据契约
- `docs/usage-guide.md`：重写为 Mode A/B/C 使用指南
- `docs/customization.md`：更新为 ai-docs 模板路径和资源文件清单

**删除**：

- `skills/blyy-init-docs/` — 整个目录
- `skills/blyy-doc-sync/` — 整个目录

---

## [0.4.0] — 2026-04-12

### 新增 — 第三个 Skill：`blyy-ai-docs`

新增一个**纯 AI 用**的轻量索引技能，生成独立的 `ai-docs/` 目录，与 `blyy-init-docs` / `blyy-doc-sync` 维护的 `docs/` 并存且完全独立。

**核心承诺**：

1. **不重复代码事实**：实体清单 / 端点表 / 文件清单一律改写为 `code-queries.md` 中的查询配方（按栈持久化的 `fd` / `rg` 命令），由 AI 按需执行而非持久化结果
2. **多年不腐烂**：基于 `MANIFEST.yaml` + 4-tier 自失效算法（文件存在性 → 文件 sha256 → 符号 body sha256 → 范围兜底）精确定位过期段落，只重写必要内容
3. **不幻觉**：每条非 boilerplate 内容必须带 `[file#Symbol]` 锚点；无法锚定 → 强制 `<!-- UNVERIFIED -->` 包裹；禁止 > 20 行的列表型段落

**三模式分派**（单 SKILL.md 根据 MANIFEST 状态自动选择）：

- **Mode A — Init**：首次生成 `ai-docs/`（Phase A0 环境探测 → A1 模块识别 → A2 生成 code-queries.md → A3 子代理并行业务提取 → A4 Pre-Fill Review Gate → A5 写文档 + MANIFEST → A6 自检）
- **Mode B — Sync**：`last_synced_commit ≠ HEAD` 时触发，跑 4-tier 失效检测，只对 STALE 段落整段重写、对 REVIEW 段落仅修正矛盾
- **Mode C — Audit**：显式调用或距上次 audit > 90 天，执行全量锚点验证 + 抽样 query 比对 + 触发 Mode B 流程处理 STALE

**产物文件结构**（7 个文件，扁平）：

- `INDEX.md` — 任务路由表 + 新鲜度概览
- `modules.md` — 模块注册表（name → code_root → 1-2 句业务定位 + 依赖图）
- `glossary.md` — 业务术语 ↔ 代码符号映射
- `flows.md` — 跨模块业务流程
- `decisions.md` — 设计决策 + 不变式
- `code-queries.md` — 按栈写入的 `fd` / `rg` 配方库（不含执行结果）
- `MANIFEST.yaml` — 状态契约（`last_synced_commit` + anchors sha256 + symbols body_sha256 + history）

**资源文件**（按需加载）：

- `resources/tech-stack-matrix.md` — 8 大栈依赖文件探测 + 后端/前端锚点矩阵 + 模块根目录启发
- `resources/query-recipes.md` — C# / Java / Python / Go / TS / Rust / Ruby / PHP 的 fd/rg 命令库（每条带 find/grep fallback）
- `resources/anti-hallucination.md` — T1/T2/T3 分类 + 锚点强制规则 + 禁枚举铁律 + Pre-Fill Review Gate + 子代理通用指令
- `resources/anchor-extraction.md` — 8 语言符号定位正则 + body 范围提取 + 归一化算法
- `resources/self-invalidation.md` — 4-tier 完整算法伪代码 + 反向锚点索引 + 性能注解

**默认行为**：

- `ai-docs/` 自动追加到 `.gitignore`——视为本地 AI 索引缓存，每个开发者按需重生成
- 与 `blyy-init-docs` / `blyy-doc-sync` **完全独立**，可单独安装；同时安装时互不依赖
- 文件级 sha 统一使用 `git hash-object`（跨平台、零依赖），不使用 `sha256sum` / `Get-FileHash`

### 改进

- `install.sh` / `install.ps1` 默认安装三个 skill；支持 `--skills blyy-ai-docs` 单独安装
- `README.md` 双语技能表加入第三行；「工作原理」章节补充 blyy-ai-docs 的反幻觉/自失效机制说明
- `docs/architecture.md` 仓库结构图加入 `skills/blyy-ai-docs/` 层级；职责边界表由两列扩展为三列；新增 blyy-ai-docs 内部状态契约与渐进式加载映射

---

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

[0.6.0]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.6.0
[0.5.0]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.5.0
[0.4.0]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.4.0
[0.3.2]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.3.2
[0.3.1]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.3.1
[0.3.0]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.3.0
[0.2.0]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.2.0
[0.1.1]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.1.1
[0.1.0]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.1.0
