---
name: blyy-init-docs
description: 为项目一次性初始化完整的文档体系。当用户要求"初始化文档 / 建立文档骨架 / doc init / 生成文档结构"，或项目从零开始建立文档、从遗留项目接手梳理文档时触发。扫描代码生成架构/模块/数据模型/部署等全套文档，已有 docs/ 自动迁移到 docs-old/ 再做结构化提取。每个项目只运行一次；日常维护用 blyy-doc-sync，不要重复执行本 skill。
---

# blyy-init-docs — 项目文档初始化 Skill

## 概述

本 Skill 用于为项目生成**完整的文档架构**并**自动填充初始内容**。执行后交付一套可用的文档集，而非空壳模板。

> **多工具兼容**：本 Skill 采用 SKILL.md 标准格式，兼容 Gemini、Codex、Cursor、Claude Code 等主流 AI 编程工具。

所有项目均采用**主 agent + 子代理并行**模式加速文档生成。针对不同规模自动调整执行策略：
- **标准项目**（≤ 500 文件）：Phase 2 全量扫描，主 agent 编排 + 子代理并行填充
- **大型项目**（> 500 文件）：Phase 2A-2D 分层聚焦 + 子代理并行分析

## 前置条件

- 项目已有可编译/可运行的代码
- 项目根目录已确定

## 执行流程

### 断点续跑检测（每次执行自动触发，Phase 0 之前）

> 文档初始化可能因会话中断、上下文压缩或用户主动暂停而未完成。此步骤检测是否存在未完成的初始化进度并恢复。

**检测步骤：**

1. 检查 `.init-docs/master-task.md` 是否存在（大型项目模式进度文件）
2. 检查 `docs/.init-temp/progress.md` 是否存在（标准模式进度文件）
3. **若任一存在**：
   - 读取进度文件，解析当前阶段和完成状态
   - 向用户展示进度摘要：
     ```
     📋 检测到未完成的文档初始化：
     - 模式: 标准模式 / 大型项目模式
     - 进度: Phase 2 — Layer 2（已完成 2/4 模块：Orders, Users）
     - 上次执行: 2026-04-08
     
     继续上次进度 / 从头开始？(继续 | 重新开始)
     ```
   - 用户选择「继续」→ 从断点 Phase/Layer 恢复执行（跳过已完成的步骤）
   - 用户选择「重新开始」→ 清理 `.init-docs/` 或 `docs/.init-temp/`，正常执行 Phase 0
4. **若均不存在** → 正常执行 Phase 0

**恢复策略：**

| 中断阶段 | 恢复方式 |
|---------|---------|
| Phase 0 / Phase 1 | 从头执行（这两个阶段耗时短，不值得恢复） |
| Phase 1.5 | 检查 `extractions/` 目录中已完成的提取文件，仅补充缺失的提取任务 |
| Phase 2 子代理分析 | 读取已落盘的分析文件（`analysis-*.md` 或 `modules/*-analysis.md`），仅重新分发未完成的子代理 |
| Phase 2 填充前审查关卡 | 读取 `clarifications.md`（若存在），跳过已完成的 T3 澄清 |
| Phase 2 Layer N 交付 | 检查 `docs/` 中已生成的文档，从未完成的 Layer/模块继续 |
| Phase 3 | 重新执行 Phase 3（验证阶段耗时短） |

---

### Phase 0 — 项目环境评估

在开始文档初始化前，完成以下评估：

#### 0.1 开发工具 /init 命令检测

检查当前运行环境的开发工具是否自带文档初始化命令：

| 工具 | 初始化命令 | 产物 |
|------|----------|------|
| Gemini (Google) | 自动生成 | `AGENTS.md` |
| Codex (OpenAI) | 自动生成 | `AGENTS.md` |
| Claude Code | `/init` | `CLAUDE.md` |
| Cursor | 自动/手动 | `.cursorrules` 或 `CURSOR.md` |
| Copilot | — | — |
| Windsurf | 自动 | `.windsurfrules` |

**执行策略（硬性前置）：**
1. 对照上表检查当前工具。若工具支持初始化命令（如 Claude Code 的 `/init`）：
   - **必须先执行**工具自带的初始化命令，等待其完成后才能进入 Phase 0.2
   - 若执行失败，向用户报告错误并询问：重试 or 跳过（用户明确选择跳过才可继续）
   - 记录生成的文件（如 `CLAUDE.md`）供 Phase 1 整合
2. 若工具确实不支持初始化（如 Copilot）或为未识别工具 → 跳过，但**必须明确告知用户**："当前工具不支持 /init，已跳过此步"
3. **禁止静默跳过** — 无论执行还是跳过，都必须向用户输出结果

#### 0.2 AI 上下文记忆文件识别

不同 AI 编码工具使用不同的上下文记忆文件。检测项目中是否已存在：

| 文件 | 工具 |
|------|------|
| `AGENTS.md` | Gemini / Codex (OpenAI) |
| `CLAUDE.md` | Claude Code |
| `CURSOR.md` / `.cursorrules` | Cursor |
| `.windsurfrules` | Windsurf |
| `COPILOT.md` | GitHub Copilot |
| `.github/copilot-instructions.md` | GitHub Copilot |

**执行策略：**
- 自动扫描项目根目录，识别已存在的上下文文件
- 若已存在 → 在 Phase 1 中作为已有文档整合处理
- 若不存在 → 列出上述常见选项，让用户选择需要生成哪些（至少生成一个）
- 模板中 `AGENTS.md` 作为通用默认项，其他上下文文件按用户选择额外生成

#### 0.3 项目规模评估

```bash
fd --type f --exclude .git --exclude node_modules --exclude bin --exclude obj --exclude dist --exclude build --exclude target --exclude packages | wc -l
```

| 条件 | 模式 |
|------|------|
| 源代码文件 ≤ 500 且 子项目 ≤ 5 | 标准模式（Phase 0 → 1 → 1.5（条件） → 2 → 3） |
| 源代码文件 > 500 或 子项目 > 5 | 大型项目模式（Phase 0 → 1 → 1.5（条件） → 2A-2D → 3） |

> 大型项目模式下，在项目根目录创建 `.init-docs/` 目录用于**任务持久化**（详见「任务持久化机制」章节）。

---

### Phase 1 — 骨架生成

根据 `templates/` 下的模板，在项目中创建完整文档目录结构：

```
项目根目录/
├── README.md
├── AGENTS.md                ← 或其他 AI 上下文文件（Phase 0.2 确定）
├── CHANGELOG.md             ← 可选自动填充
├── CONTRIBUTING.md          ← 可选，用户确认后生成
├── SECURITY.md              ← 按需，用户确认后生成
└── docs/
    ├── ARCHITECTURE.md      ← 文档导航根节点（含 AI 任务路由表，≤150 行）
    ├── code-map.md          ← 总览简述 + 各模块链接
    ├── modules.md
    ├── glossary.md          ← 业务术语 ↔ 代码符号映射
    ├── core-flow.md
    ├── config.md            ← 含配置优先级、密钥管理、环境差异
    ├── features.md
    ├── DECISIONS.md
    ├── doc-maintenance.md   ← 含基线快照（供 doc-sync 防线 3 使用）
    ├── data-model.md        ← 关系型 + 非关系型（缓存/消息/文档数据库，按需展开）
    ├── testing.md           ← 测试策略、覆盖率、E2E 场景、安全扫描
    ├── runbook.md           ← 健康检查 + 故障剧本（基础版）
    ├── deployment.md        ← 含环境清单、回滚方案、密钥管理
    ├── monitoring.md        ← 按需：核心指标、告警规则、仪表盘（告警的单一来源）
    ├── api-reference.md     ← 按需：公共信息（认证/错误码）+ 模块接口索引
    ├── database/            ← 公共/跨模块表 + 各模块链接
    └── modules/
        └── <module-name>/
            ├── README.md       ← 含入向/出向依赖
            ├── flow.md         ← 步骤含代码位置列
            ├── data-model.md
            ├── api-reference.md ← 按需：该模块的接口详情
            ├── code-map.md     ← 该模块的文件→职责映射
            └── database/       ← 该模块的表 schema
```

> **模板架构变更要点（v0.2.0+）**：
> - 所有 `docs/*.template` 与 `modules/*.template` 的 YAML front matter 扩展了新字段：`audience` / `read_priority` / `max_lines` / `parent_doc` / `code_anchors` / `applicable_project_types` / `last_synced_commit`，详见 `resources/front-matter-spec.md` 七、YAML Front Matter 字段标准
> - **Phase 1 骨架按 `applicable_project_types` 字段自动过滤**：识别项目类型后，仅生成 front matter 中包含该类型的模板，无需依赖 AI 阅读项目类型适配指南
> - 所有列表型字段必须包含「代码位置」列（`file:line` 格式）
> - 所有 `<!-- TODO -->` 必须使用结构化格式 `<!-- TODO[priority,type,owner]: ... -->`

> **项目类型适配**：不同类型的项目对文档的侧重点不同，详见 `resources/doc-guide.md` 项目类型适配指南。部分文档可根据项目类型跳过。

**操作步骤：**

1. **旧文档迁移**（条件执行）：
   - **前置检查**：检查项目根目录下是否**已存在** `docs/` 目录
   - **若 `docs/` 已存在** → 将整个 `docs/` 目录移动（重命名）为 `docs-old/`
     - 若 `docs-old/` 也已存在，使用带时间戳的目录名 `docs-old-YYYYMMDD-HHmmss/` 避免冲突
     - 移动完成后，向用户汇报迁移结果（迁移了多少个文件）
     - **递归列出** `docs-old/` 下所有 `.md` 文件清单，以便 Phase 2 填充阶段参考
   - **若 `docs/` 不存在** → **跳过迁移，不创建 `docs-old/`**，直接进入步骤 2
2. **项目类型识别**（Phase 1 骨架过滤的前置步骤）：
   - 根据 Phase 0.3 的项目清点结果，结合 `resources/doc-guide.md` 五.适配矩阵 + 「条件判断方法」表，自动判定项目类型（取一个或多个枚举值：`backend-service` / `microservice` / `fullstack` / `frontend-spa` / `cli-tool` / `library` / `data-pipeline` / `infrastructure`）
   - 向用户确认识别结果：`"识别到的项目类型: {types}。是否正确？(Y/纠正)"` — 用户纠正后才进入步骤 3
   - 将识别结果记录到 `.init-docs/project-type.md`（大型模式）或在主 agent 上下文中保留（标准模式）
3. 阅读 `templates/root/`、`templates/docs/`、`templates/modules/` 下的所有模板
4. **按 `applicable_project_types` 过滤模板**：
   - 对每个模板文件，读取其 YAML front matter 的 `applicable_project_types` 字段
   - 若该字段**包含**步骤 2 识别的项目类型之一 → 创建该文档骨架
   - 若该字段**不包含**任何识别的类型 → **跳过创建**，并在「跳过清单」中记录
   - 若 front matter 中无 `applicable_project_types` 字段 → 视为「全类型适用」，创建
   - 此过滤完全基于 front matter，**禁止 AI 自由判断**「这个项目应不应该有 monitoring」
5. 在全新的 `docs/` 目录下按过滤结果创建文档骨架
6. **根目录已有文档整合**：对于项目中已存在的根目录文档（`README.md`、`AGENTS.md`/`CLAUDE.md` 等、`CHANGELOG.md`）
   - 阅读已有文件，提取其中有价值的内容（项目描述、构建命令、配置说明、变更记录等）
   - 按模板结构重新组织这些内容，生成符合规范的新版本
   - **强制检查**：生成的 `AGENTS.md`（或对应 AI 上下文文件）必须包含「Task Entry Protocol」章节；若整合已有内容后该章节丢失，必须从模板补充
   - 将新旧内容的差异摘要呈现给用户，说明哪些内容被保留、哪些被重组、哪些是新增
   - 用户确认后，覆盖原文件
   - 若 Phase 0.1 中工具 `/init` 生成了上下文文件，将其内容整合进对应文档
7. **跳过清单确认**：将步骤 4 中所有被跳过的文档列出（含跳过原因），询问用户是否需要追加生成（「可跳过」不等于「禁止生成」）：
   ```
   📋 根据项目类型 [backend-service]，以下文档被跳过：
   - frontend-routing.md（仅适用 frontend-spa）
   - 是否需要追加生成？(选择需要的 / N=全部跳过)
   ```

---

### Phase 1.5 — 旧文档结构化提取（条件执行）

> **触发条件**：仅当 Phase 1 产生了 `docs-old/` 目录时执行。若无旧文档，跳过此阶段直接进入 Phase 2，**不要读取 legacy-extraction.md**。
>
> **目标**：从旧文档中**穷举提取**所有有价值的信息，生成结构化提取产物，供 Phase 2 各子代理使用。
>
> **执行**：满足触发条件后，**必须 Read `resources/legacy-extraction.md`** 获取完整的 4 步流程（清点 → 子代理并行提取 → 交叉校验 → 提取产物传递）和 fallback 策略。

**输出位置：** 标准模式 → `docs/.init-temp/`；大型项目模式 → `.init-docs/extractions/`

---

### Phase 2 — 代码分析填充（标准模式）

> 仅当 Phase 0.3 判定为**标准模式**时使用。大型项目请跳至 Phase 2A-2D。
>

扫描项目代码，为每个文档填充与项目相关的实际内容。**采用主 agent + 子代理并行分工加速。**

**主 agent 负责：**

1. **识别技术栈**：扫描项目清单文件，确认语言和框架（详见 `resources/tech-stack-matrix.md` 三、技术栈识别）
2. **两级模块识别**：先识别项目（第一级），再通过**架构布局检测**（Step 2.5）判断项目是领域组织还是分层组织，然后使用对应策略识别子模块。**对于分层架构项目，必须使用跨层业务领域提取（Step 2.6）**而非目录级识别（详见 `resources/tech-stack-matrix.md` 五、模块识别策略）
3. **确定性清单预扫描**：模块识别完成后、分配子代理任务前，执行确定性清单预扫描（详见下方）
4. **加载旧文档提取产物**：若 Phase 1.5 生成了提取结果，读取各提取文件的摘要和条目清单，作为子代理任务分配的依据
5. **分配子代理任务**：将可并行的分析工作分发给子代理，每个子代理同时接收代码扫描范围、**确定性清单（作为强制检查表）**和对应的旧文档提取产物

#### 确定性清单预扫描

> 在分配子代理任务之前，主 agent **必须**使用 shell 命令（`fd`/`rg`）建立项目的完整文件清单。此清单是确定性的（不依赖 AI 阅读），用于解决 AI 上下文丢失导致的内容遗漏问题。

**执行步骤：**

1. **文件级清点** — 根据识别的技术栈，从 `resources/tech-stack-matrix.md` 一、确定性清点命令矩阵中选择对应命令，统计各类别文件精确数量：

   ```bash
   # 示例输出格式（主 agent 需执行并记录结果）
   echo "=== 确定性清单 ==="
   echo "实体/模型文件:" && fd -e cs -p "Entity|Model" --type f | sort
   echo "控制器文件:" && fd -e cs -p "Controller" --type f | sort
   echo "服务文件:" && fd -e cs -p "Service" --type f | sort
   echo "配置文件:" && fd "appsettings" --type f | sort
   ```

2. **名称提取** — 对每个类别生成完整的文件名逐项清单（不读文件内容，仅列名）

3. **清单汇报** — 向用户展示清点结果：
   ```
   📊 项目清点完成（确定性扫描）:
   - 实体/模型文件: 23 个
   - 控制器/路由文件: 12 个
   - 服务文件: 18 个
   - 配置文件: 5 个
   - 测试文件: 40 个
   - 数据库迁移: 15 个
   ```

4. **清单持久化** — 将完整清单写入临时文件：
   - 标准模式：`docs/.init-temp/inventory.md`
   - 大型项目模式：`.init-docs/inventory.md`

5. **按模块拆分清单** — 根据模块识别结果，将清单按模块分组，形成每个模块的子清单

6. **模块复杂度评分与分级** — 根据拆分后的子清单，对每个模块自动评分并确定文档形态：

   **评分规则**（全部基于确定性清单的 shell 命令结果，不依赖 AI 判断）：

   | 信号 | 检测方式 | 得分 |
   |------|---------|------|
   | 模块源文件数 > 15 | `fd --type f <module_dir> \| wc -l` | +2 |
   | 模块源文件数 5-15 | 同上 | +1 |
   | 模块源文件数 < 5 | 同上 | 0 |
   | 有数据库实体/模型文件 | 清单中该模块含 Entity/Model 文件 | +1 |
   | 有 API 端点（Controller/Handler） | 清单中该模块含 Controller/Handler 文件 | +1 |
   | 被 ≥ 3 个其他模块依赖 | 反向引用扫描（`rg "import.*<module>" --type-add ...`） | +1 |

   **分级结果**：

   | 总分 | 级别 | 文档形态 | 说明 |
   |------|------|---------|------|
   | ≥ 3 | **Core** | 完整目录 `modules/<m>/`（6 个子文件） | 当前模板不变 |
   | 1-2 | **Standard** | 单文件 `modules/<m>.md` | 使用 `modules-single.md.template` |
   | 0 | **Lightweight** | 无独立文件，内联到 `modules.md` | 在模块注册表中展开为详细段落 |

   **执行步骤**：

   a. 对每个模块执行评分命令，计算总分
   b. 向用户展示分级结果并确认：
      ```
      📊 模块复杂度分级（共 {N} 个模块）：
      
      Core（完整文档目录）— {n1} 个：
        - Orders (5分): 22文件, 8表, 12端点, 被5个模块依赖
        - Users (4分): 18文件, 5表, 8端点, 被7个模块依赖
        ...
      
      Standard（单文件文档）— {n2} 个：
        - Notifications (2分): 8文件, 2表
        - Logging (1分): 6文件
        ...
      
      Lightweight（内联到 modules.md）— {n3} 个：
        - StringUtils (0分): 2文件
        - Constants (0分): 1文件
        ...
      
      预计文档数: {Core×6 + Standard×1 + 全局} 个（vs 无分级: {N×6 + 全局} 个）
      
      确认分级？(Y | 调整某模块级别)
      ```
   c. 用户确认后，将分级结果持久化：
      - 标准模式：`docs/.init-temp/module-tiers.md`
      - 大型项目模式：`.init-docs/module-tiers.md`
   d. Phase 1 骨架生成时，按分级结果决定每个模块的文档结构

   > **分级结果影响 Phase 1 骨架**：Core 模块创建完整 `modules/<m>/` 目录；Standard 模块创建单个 `modules/<m>.md` 文件；Lightweight 模块不创建独立文件。

7. **初始化进度文件**（标准模式）— 在 `docs/.init-temp/progress.md` 创建进度追踪文件：

   ```yaml
   ---
   project_name: {{PROJECT_NAME}}
   project_type: {{识别到的项目类型}}
   mode: standard
   started_at: {{当前日期}}
   current_phase: phase2-analysis
   current_layer: 0
   modules: [{{模块列表}}]
   module_tiers:
     core: [{{Core 模块列表}}]
     standard: [{{Standard 模块列表}}]
     lightweight: [{{Lightweight 模块列表}}]
   completed_modules: []
   t3_clarified: false
   ---
   ## Phase 进度
   - [x] Phase 0 — 项目环境评估
   - [x] Phase 1 — 骨架生成
   - [ ] Phase 1.5 — 旧文档提取（跳过/执行中/已完成）
   - [/] Phase 2 — 代码分析
     - [x] 确定性清单预扫描
     - [ ] 子代理并行分析
     - [ ] 填充前审查关卡
     - [ ] Layer 1 核心文档
     - [ ] Layer 2 模块文档
     - [ ] Layer 3 汇总文档
     - [ ] Layer 4 运营文档
   - [ ] Phase 3 — 最终检查
   ```

> **关键原则**：此步骤使用 shell 命令而非 AI 阅读，确保 100% 不遗漏文件。后续子代理以此清单为准。

**子代理并行执行（按任务类型拆分）：**

每个子代理同时接收**代码扫描范围**、**确定性清单（强制检查表）**和**旧文档提取产物**（若存在）作为输入：

| 子代理任务 | 代码扫描范围 | 旧文档输入（若有） | 输出 |
|-----------|------------|------------------|------|
| 配置扫描 | 配置类/配置文件/环境变量 | Phase 1.5 配置提取结果 | `config.md` 填充素材（含优先级、密钥、环境差异） |
| 实体/数据模型扫描 | 实体类/ORM/迁移/缓存配置/消息 schema | Phase 1.5 实体/数据模型提取结果 | `data-model.md` 填充素材（含非关系型） |
| 构建/部署/监控扫描 | 构建脚本/CI 配置/发布脚本/监控配置 | Phase 1.5 部署/运维提取结果 | `deployment.md` + `monitoring.md` + `README.md` 构建命令 |
| API/功能扫描 | 公共 API/命令行参数/认证配置 | Phase 1.5 API/功能提取结果 | `features.md` + `api-reference.md` 填充素材 |
| 测试扫描 | 测试目录/测试框架配置/CI 测试步骤 | Phase 1.5 对应提取结果 | `testing.md` 填充素材 |
| 单模块分析（**按模块并行拆分**） | 该模块源代码 | 该模块相关的架构提取结果 | 该模块的文档填充素材 |

**子代理通用指令（附加到每个子代理的任务描述中）：**

> **检查表核对要求**：你接收到的确定性清单是通过 shell 命令生成的完整文件列表。你**必须**为清单中的每一个文件产出对应条目。完成分析后，逐一核对清单，确保输出条目数与清单条目数一致。若某个文件确实不包含有价值的信息，仍需在输出中列出并标注原因。
>
> **事实级别标注要求**：每个分析条目必须标注 T1/T2/T3 级别和代码依据（详见 `resources/fact-classification.md` 二、三级事实分类）。T3 条目单独汇总在输出末尾的「待澄清项」区域。
>
> **字段说明提取要求**：扫描实体类/模型类时，**必须同时提取每个属性/字段的注释文本**（文档注释、数据注解、迁移文件注释），作为 `data-model.md` 表结构详情表「说明」列的值。提取优先级和各技术栈注释来源详见 `resources/tech-stack-matrix.md` 二、字段说明提取矩阵。禁止将说明列留空。
>
> **进度输出要求**：
> 1. 每处理完 5 个文件，输出一行进度（含已处理/总数和最近处理的文件名）
> 2. 每完成一个分析子类别（实体/服务/控制器等），输出该类别的小结（含发现的条目数和清单覆盖率）
> 3. 完成时输出结构化摘要（含各类别条目数和清单覆盖率）
> 4. 进度输出使用缩进格式（`├─` 前缀），与主 agent 的 Phase 级进度在视觉上区分

**合并规则：** 每个子代理在分析代码后，**必须**将旧文档提取条目与代码扫描结果**逐条对照**。最终输出必须包含两者的**并集**，并标注每个条目的来源：
- `[代码]` — 仅在代码中发现
- `[旧文档]` — 仅在旧文档中提到（可能已删除或重命名，需用户确认）
- `[两者]` — 代码和旧文档均有

**模块级并行策略：**
- 模块数量 ≤ 3：合并为一个子代理任务
- 模块数量 4-8：每个模块一个独立子代理（与上述 4 个类型任务并行）
- 模块数量 > 8：分批执行，每批最多 5 个模块并行，批间串行；类型任务在第一批中并行启动

> **落盘规则**：每个子代理完成分析后，必须将结果写入临时文件（标准模式：`docs/.init-temp/analysis-{任务名}.md`，大型项目模式：`.init-docs/` 对应文件）。主 agent 从文件读取子代理产出，不依赖上下文传递。

#### 填充前审查关卡（Pre-Fill Review Gate）

> 在所有子代理分析完成后、开始文档填充之前，主 agent **必须**执行此审查关卡。**此步骤完成前禁止开始文档填充。**

**Step 1 — 清单覆盖率检查：**

1. 从确定性清单文件中读取各类别的文件总数
2. 从各子代理的落盘分析产出中统计已覆盖的条目数
3. 对比：若覆盖率 < 100%，列出未覆盖的具体文件名，重新分发给子代理补充分析
4. 向用户汇报覆盖率：
   ```
   📊 清单覆盖率检查：
   - 实体/模型: 23/23 ✓
   - 控制器: 12/12 ✓
   - 服务: 17/18 ✗ → 缺失: PaymentService.cs（重新分析中...）
   ```

**Step 2 — T3 推测性内容收集：**

1. 从所有子代理的落盘产出中收集所有 T3（推测性）条目
2. 按类别分组（业务流程类、模块边界类、数据模型类、配置类、设计决策类等）

**Step 3 — 批量用户澄清：**

将所有 T3 条目一次性呈现给用户，格式：

```
📋 填充前审查：发现 {N} 个推测性内容（T3）需确认

**业务流程类** ({n1} 项):
1. [T3] 订单创建流程顺序
   最佳猜测: 创建 → 库存锁定 → 支付 → 确认 (置信度: 中)
   代码依据: OrderService.CreateAsync() 调用链
   → 确认 / 纠正: ___

2. [T3] ...

**模块边界类** ({n2} 项):
3. [T3] Auth 模块是否同时负责权限管理？
   最佳猜测: 是（AuthService 中包含 CheckPermission 方法）(置信度: 高)
   代码依据: AuthService.cs 第 45 行
   → 确认 / 纠正: ___

**设计决策类** ({n3} 项):
...
```

**Step 4 — 用户响应整合：**

- 用户确认的 T3 → 升级为 T2，正式写入文档（移除 `UNVERIFIED` 标记）
- 用户纠正的 T3 → 按用户输入修正后写入文档
- 用户选择跳过的 T3 → 保留 `<!-- UNVERIFIED: {简述} -->` 标记写入文档

> 若无 T3 条目（所有内容均为 T1/T2），直接跳过 Step 2-4，进入文档填充。

**Step 5 — 澄清结果持久化：**

将用户的 T3 澄清结果写入临时文件，避免跨会话重复提问：
- 标准模式：`docs/.init-temp/clarifications.md`
- 大型项目模式：`.init-docs/clarifications.md`（已有此规则）

同步更新进度文件中的 `t3_clarified: true`。

#### 渐进式分层交付

> **核心理念**：不一口气生成 25+ 文档，而是按优先级分层交付。每一层交付后都是**可用的**，用户可在任意层后暂停。后续层在前置层基础上增量生成。

**主 agent 按以下层级顺序整合填充：**

**Layer 1 — 核心文档（快速交付，无需深度代码分析）：**

| 文档 | 填充来源 | 说明 |
|------|---------|------|
| `README.md` | 项目名称、技术栈、构建命令 | 项目第一印象 |
| `AGENTS.md` 等上下文文件 | 项目结构、构建/运行/测试命令、代码规范；**必须包含「Task Entry Protocol」章节**（指示 AI 先读 `docs/ARCHITECTURE.md`） | AI 工具上下文 |
| `ARCHITECTURE.md` | 模块识别结果 → 系统总览 + 文档索引 | 文档入口 |
| `modules.md` | 两级模块识别结果 → 模块注册表（含 Lightweight 模块的内联详情） | 模块概览 |
| `code-map.md` | 项目总览目录树 + 各模块链接 | 代码导航 |

> **Layer 1 交付点**：向用户呈现 5 个核心文档，确认无误。此时 AI 工具已有基本上下文记忆，用户可立即开始使用。
> 询问用户：`"核心文档已就绪。继续生成模块级文档？(Y/继续 | 指定优先模块 | 暂停)"`
>
> **进度更新**：更新 `progress.md` — `current_layer: 1`，标记 `[x] Layer 1 核心文档`。

**Layer 2 — 模块级文档（按模块分级交付）：**

按模块复杂度分级（步骤 6 结果）采用不同的文档形态：

**Core 模块**（完整目录）：

| 文档 | 填充来源 |
|------|---------|
| 模块级 `README.md` | 子代理产出 → 模块职责、边界、接口 |
| 模块级 `flow.md` | 子代理产出 → 模块内业务流程 |
| 模块级 `code-map.md` | 子代理产出 → 文件→职责映射 |
| 模块级 `data-model.md` | 子代理产出 → 模块内数据模型 |
| 模块级 `api-reference.md` | 子代理产出 → 模块接口详情（仅有 API 的模块） |
| 模块级 `database/` | 子代理产出 → 模块内表 schema |

**Standard 模块**（单文件 `modules/<m>.md`）：

使用 `templates/modules-single.md.template`，将上述所有内容合并为一个文档的不同章节。子代理产出与 Core 模块相同，但主 agent 整合时写入单文件而非目录。

**Lightweight 模块**（内联到 `modules.md`）：

不生成独立文件。子代理产出中提取关键信息（职责、代码位置、关键类），以展开段落形式写入 `modules.md` 的模块注册表中。

**交付策略：**
- Core 模块优先交付（通常是核心业务模块，最需要完整文档）
- 若用户指定了优先模块 → 按指定顺序逐个生成
- 若未指定 → 先 Core（按代码量从大到小），再 Standard（批量交付），最后 Lightweight（在 Layer 1 的 `modules.md` 中已完成）
- 每个 Core 模块完成后单独向用户汇报；Standard 模块可批量汇报
- 用户可随时暂停

> **Layer 2 交付点**：Core 模块每完成一个即交付；Standard 模块可批量交付。`"✅ [订单模块](Core) 文档完成（6 个文件）。继续下一个？(Y | 跳到 Layer 3 | 暂停)"`
>
> **进度更新**：每完成一个模块，更新 `progress.md` — 将该模块加入 `completed_modules`，更新 `current_layer: 2`。

**Layer 3 — 跨模块汇总文档（需要跨模块理解）：**

| 文档 | 填充来源 |
|------|---------|
| `core-flow.md` | 各模块流程分析 → 跨模块核心业务流程 |
| `config.md` | 子代理产出合并 → 全局配置项列表 |
| `data-model.md` | 子代理产出合并 → 公共数据模型 + 模块索引 |
| `features.md` | 子代理产出合并 → 功能列表 |
| `DECISIONS.md` | 架构决策识别 → ADR 条目 |
| `database/` | 公共/跨模块表 + 各模块链接 |
| `CHANGELOG.md` | **用户可选**：询问是否从 Git 历史自动填充 |

> **Layer 3 交付点**：`"汇总文档已完成。继续生成运营文档？(Y | 暂停)"`
>
> **进度更新**：更新 `progress.md` — `current_layer: 3`，标记 `[x] Layer 3 汇总文档`。

**Layer 4 — 运营与参考文档（按需，用户可选择跳过）：**

| 文档 | 填充来源 | 是否必须 |
|------|---------|---------|
| `deployment.md` | 子代理产出 → 部署流程 | 参考项目类型适配矩阵 |
| `testing.md` | 子代理产出 → 测试策略 | 参考项目类型适配矩阵 |
| `runbook.md` | 子代理产出 → 运维剧本 | 参考项目类型适配矩阵 |
| `monitoring.md` | 子代理产出 → 监控指标 | 可选 |
| `api-reference.md` | 子代理产出 → API 参考 | 可选 |
| `doc-maintenance.md` | 同步矩阵 + 基线清点 | 必须（供 doc-sync 使用） |

> **Layer 4 交付前**：根据 `resources/doc-guide.md` 项目类型适配矩阵，向用户推荐需要生成的文档，用户选择后生成。
>
> **Layer 4 交付后进度更新**：更新 `progress.md` — `current_layer: 4`，标记 `[x] Layer 4 运营文档`，`current_phase: phase3`。

**跨层规则：**
- 子代理在 Layer 2 启动时已并行分析所有模块，产出持久化到临时文件
- Layer 3/4 直接从临时文件读取子代理产出，不重新分析
- 用户暂停后，可在新会话中通过 `docs/.init-temp/progress.md`（标准模式）或 `.init-docs/master-task.md`（大型模式）恢复进度
- 已有文档优先：填充每个文档时先检查 Phase 1.5 提取产物中的对应信息

**填充原则：**（详见 `resources/fact-classification.md` 填充原则与三级事实分类 + `resources/front-matter-spec.md` YAML Front Matter 字段标准）

- 穷举式枚举 + 确定性清单保障
- 三级事实分类（T1/T2/T3）+ 填充前审查关卡
- 基于代码事实，不臆测不编造
- 已有文档优先
- T3 推测性内容经审查关卡统一处理
- **代码位置列必填**：所有列表型字段（实体表、文件清单、流程步骤、API 端点、配置项等）必须填充「源文件」或「定义位置」列，使用 `path/to/file.ext:行号` 格式（无确切行号时退化为 `path/to/file.ext`）。无代码位置的条目视为不可信，应标注 `<!-- UNVERIFIED -->`
- **结构化 TODO 格式**：未确认内容必须使用 `<!-- TODO[priority,type,owner]: 简述 -->` 位置参数格式，详见 `resources/front-matter-spec.md` 七.4 — `priority` ∈ {p0,p1,p2,p3}，`type` ∈ {business-context,design-rationale,ops-info,security-info,external-link,metric-baseline}，`owner` ∈ {user,dev-team,ops-team,security-team,具体负责人名}
- **front matter 完整性**：每个文档必须填充 `last_updated`（当前日期）、`last_synced_commit`（初始化时填 `init`，由 doc-sync 后续维护）、`audience`、`read_priority`、`code_anchors`（实际代码目录/文件路径）字段，禁止保留模板占位符
- **AI-READ-HINT 块完整性**：保留模板中的 `AI-READ-HINT` 块，根据当前文档实际内容调整 `READ-WHEN`/`SKIP-WHEN`/`PAIRED-WITH` 描述，禁止整块删除
- **INCLUDE-IF 条件段处理**：模板中标注 `<!-- INCLUDE-IF: 条件 -->` 的段落，若项目不满足条件直接整段删除；满足条件时移除标记并填充内容

---

### Phase 2A-2D — 代码分析填充（大型项目模式）

> **触发条件**：仅当 Phase 0.3 判定为**大型项目模式**时使用。标准模式跳过本节，继续 Phase 3。
>
> **执行**：满足触发条件后，**必须 Read `resources/large-project-mode.md`** 获取完整的 Phase 2A→2B→2C→2D 流程（项目轮廓 → 锚点识别 → 模块聚焦分析 → 渐进式生成）、3 个用户检查点和模式自动升级策略。

**核心特征：**
- 通过 `.init-docs/` 目录持久化任务进度（详见 `resources/large-project-mode.md` 任务持久化机制章节）
- 子代理在独立上下文中分析单个模块，结果立即落盘到 `.init-docs/modules/<name>-analysis.md`
- 填充阶段同标准模式 Layer 1-4，每层交付后用户可暂停，跨会话从 `.init-docs/master-task.md` 恢复

---

### Phase 3 — 最终检查与完成报告

> **执行**：进入 Phase 3 时**必须 Read `resources/phase3-verification.md`** 获取完整的 14 项检查项、基线快照 YAML schema 和 INIT-REPORT 模板。
>
> **版本号占位符**：写入基线快照前，必须读取 `skills/blyy-init-docs/VERSION` 文件的内容，用其替换 YAML 模板中的 `{{SKILL_VERSION}}` 占位符，以免硬编码版本号与实际发版脱节。

**核心原则**：Phase 3 的完整性验证基于**确定性清单比对**（从 `inventory.md` 读取基线数量与文档实际覆盖比对），而非重新扫描代码。

**关键产出：**
1. 完整性校验报告（模块/实体/配置/API/测试/监控/旧文档回收率）
2. 文档可信度统计（T1/T2/T3 分布）
3. **基线快照写入 `docs/doc-maintenance.md`** — 必须采用 YAML 格式，含 `inventory` / `markers` / `layer_distribution` / `fact_levels` 四类数据，供 `blyy-doc-sync` 防线 3 程序化解析
4. 一次性完成报告 `docs/INIT-REPORT.md`（含未覆盖条目清单 + T3 待确认条目位置链接）
5. 临时目录清理（标准模式 `docs/.init-temp/`（含 `progress.md`、`clarifications.md`）自动清理；大型模式 `.init-docs/` 由用户决定）

---

## 模板文件说明

| 目录 | 内容 |
|------|------|
| `templates/root/` | 根目录文档模板：`README.md`、`AGENTS.md`、`CHANGELOG.md`、`CONTRIBUTING.md`、`SECURITY.md` |
| `templates/docs/` | `docs/` 目录下所有文档模板（含 `testing.md`、`monitoring.md`、`api-reference.md`、`runbook.md` 等） |
| `templates/modules/` | 模块级文档模板：`README.md`、`flow.md`、`data-model.md`、`code-map.md`、`database/` |

## 资源文件

| 文件 | 何时读取 | 用途 |
|------|---------|------|
| `resources/doc-guide.md` | Phase 1/Phase 3 | 文档架构总览、各文档职责、模块三级形态、项目类型适配（入口索引） |
| `resources/tech-stack-matrix.md` | Phase 0.3 / Phase 2 扫描前 | 确定性清点命令矩阵、字段说明提取矩阵、技术栈/锚点/模块识别策略（Step 1-4）、配置识别策略 |
| `resources/fact-classification.md` | Phase 2 子代理分发前 | Phase 2 填充原则（6 条）、三级事实分类（T1/T2/T3）、子代理输出格式 |
| `resources/front-matter-spec.md` | Phase 1 骨架生成 / Phase 2 填写占位符时 | 模板占位符、YAML Front Matter 字段标准、AI 提示块、结构化 TODO（type/priority/owner 枚举唯一权威来源） |
| `resources/legacy-extraction.md` | Phase 1.5 触发时 | 旧文档结构化提取的 4 步详细流程 |
| `resources/large-project-mode.md` | 进入大型项目模式时 | Phase 2A-2D 完整流程 + 任务持久化机制 |
| `resources/phase3-verification.md` | 进入 Phase 3 时 | 14 项检查项 + 基线快照 YAML schema + INIT-REPORT 模板 |
| `resources/operational-conventions.md` | 子代理调度 + 全程参考 | 进度通报规范、上下文保护「边读边落盘」、异常容错、文件过滤规则 |

## 进度通报、上下文保护、异常容错、文件过滤

> 详见 `resources/operational-conventions.md`。**主 agent 必须在 Phase 1 启动前 Read 此资源**，确保整个流程遵循统一的进度通报和上下文保护规则。

**关键铁律（无需展开本文件即生效）：**
- 每完成一个有意义的步骤必须输出进度通报；子代理用 `├─` 缩进与主 agent 的 Phase 级进度视觉区分
- 子代理完成分析后必须**立即落盘**到 `.init-temp/` 或 `.init-docs/`，主 agent 从文件读取摘要而非依赖上下文传递
- 单子代理输入超 800 行必须分批读取→提取→追加写入
- 所有扫描阶段默认排除 `node_modules/`、`bin/`、`obj/`、`.git/`、生成代码、二进制等（完整列表见 operational-conventions.md 第四节）
- Phase 1.5 提取失败时执行 fallback：报告原因 → 在 INIT-REPORT 中记录 `docs-old/` 路径 → Phase 2 仅基于代码扫描继续

---

## 注意事项

- 本 Skill 适用于项目初始化阶段，通常只运行一次
- 执行后的日常文档维护请使用 `blyy-doc-sync` skill
- 若项目已有 `docs/` 目录，Skill 会先将其迁移至 `docs-old/`，再生成全新文档骨架；旧文档内容通过 Phase 1.5 结构化提取后供 Phase 2 使用
- 若项目不存在 `docs/` 目录，**不会**创建 `docs-old/`，Phase 1.5 自动跳过
- 大型项目模式产生的 `.init-docs/` 目录可在最终检查通过后由用户决定是否保留
- 标准模式产生的 `docs/.init-temp/` 临时目录在 Phase 3 完成后自动清理
