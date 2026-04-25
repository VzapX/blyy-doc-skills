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

检查当前运行环境的开发工具是否自带文档初始化命令；若支持，**必须先执行**工具自带命令再进入 Phase 0.2。**禁止静默跳过** — 无论执行还是跳过都必须向用户输出结果。

> **执行**：进入 Phase 0.1 时**必须 Read `resources/tool-init-detection.md`** 获取完整的工具/init 检测表（Gemini / Codex / Claude Code / Cursor / Copilot / Windsurf）和硬性前置执行策略。

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
    ├── modules.md           ← 模块注册表 + 功能列表 + 依赖关系
    ├── glossary.md          ← 业务术语 ↔ 代码符号 + 字段业务语义
    ├── core-flow.md         ← 跨模块业务流程
    ├── config.md            ← 配置项业务语义（不记值/默认）
    ├── DECISIONS.md         ← 架构决策记录（ADR）
    ├── doc-maintenance.md   ← 含基线快照（供 doc-sync 防线 3 使用）
    └── modules/
        └── <module-name>.md ← 每个模块一个单文件（5 章节：概述/职责与边界/依赖关系/核心业务流程/代码锚点）
```

> **v1.0.0 文档定位**：业务知识文档。只生成 AI 读代码读不出的业务知识（业务术语、架构决策、跨模块流程、模块业务职责）。代码级文档（code-map / api-reference / data-model / database / testing 等）和运营级文档（deployment / runbook / monitoring）**不再生成**——AI 直接读源码或运维系统即可获取。

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
   - 此过滤完全基于 front matter，**禁止 AI 自由判断**「这个项目应不应该有某文档」
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
   - 模块: 8 个
   - 实体/服务类（业务术语候选）: 41 个
   - 用户可见功能（控制器/CLI/页面入口）: 12 个
   - 配置文件: 5 个
   ```

4. **清单持久化** — 将完整清单写入临时文件：
   - 标准模式：`docs/.init-temp/inventory.md`
   - 大型项目模式：`.init-docs/inventory.md`

5. **按模块拆分清单** — 根据模块识别结果，将清单按模块分组，形成每个模块的子清单

6. **初始化进度文件**（标准模式）— 在 `docs/.init-temp/progress.md` 创建进度追踪文件：

   ```yaml
   ---
   project_name: {{PROJECT_NAME}}
   project_type: {{识别到的项目类型}}
   mode: standard
   started_at: {{当前日期}}
   current_phase: phase2-analysis
   current_layer: 0
   modules: [{{模块列表}}]
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
   - [ ] Phase 3 — 最终检查
   ```

> **关键原则**：此步骤使用 shell 命令而非 AI 阅读，确保 100% 不遗漏文件。后续子代理以此清单为准。

**子代理并行执行（按任务类型拆分）：**

每个子代理同时接收**代码扫描范围**、**确定性清单（强制检查表）**和**旧文档提取产物**（若存在）作为输入：

| 子代理任务 | 代码扫描范围 | 旧文档输入（若有） | 输出 |
|-----------|------------|------------------|------|
| 配置扫描 | 配置类/配置文件/环境变量 | Phase 1.5 配置提取结果 | `config.md` 填充素材（仅业务语义，不记值/默认） |
| 实体/术语扫描 | 实体类/ORM/迁移/核心服务类 | Phase 1.5 实体/术语提取结果 | `glossary.md` 术语表 + 字段业务语义素材 |
| 功能扫描 | 公共 API/CLI 命令/Web 页面入口 | Phase 1.5 功能提取结果 | `modules.md` 功能列表填充素材 |
| 单模块分析（**按模块并行拆分**） | 该模块源代码 | 该模块相关的架构提取结果 | 该模块 `modules/<m>.md` 的填充素材（5 章节） |

**子代理通用指令（附加到每个子代理的任务描述中）：**

> **检查表核对要求**：你接收到的确定性清单是通过 shell 命令生成的完整文件列表。你**必须**为清单中的每一个文件产出对应条目。完成分析后，逐一核对清单，确保输出条目数与清单条目数一致。若某个文件确实不包含有价值的信息，仍需在输出中列出并标注原因。
>
> **事实级别标注要求**：每个分析条目必须标注 T1/T2/T3 级别和代码依据（详见 `resources/fact-classification.md` 二、三级事实分类）。T3 条目单独汇总在输出末尾的「待澄清项」区域。
>
> **字段业务语义提取要求**：扫描实体类/模型类时，**仅提取字段名推断不出业务含义的字段**（如 Status 枚举值、Type 编码、复杂业务约束），将其注释文本作为 `glossary.md` 字段业务语义表「业务含义」列的值。常见字段（id、created_at 等）不要列入。提取优先级和各技术栈注释来源详见 `resources/tech-stack-matrix.md` 二、字段说明提取矩阵。
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

> 在所有子代理分析完成后、开始文档填充之前，主 agent **必须**执行此审查关卡：清单覆盖率检查 → T3 推测性内容收集 → 批量用户澄清 → 用户响应整合 → 澄清结果持久化。**此步骤完成前禁止开始文档填充。**
>
> **执行**：进入此关卡时**必须 Read `resources/pre-fill-review.md`** 获取完整的 5 步流程、用户呈现格式和持久化规则。若无 T3 条目（所有内容均为 T1/T2），跳过 Step 2-4 直接进入文档填充。

#### 渐进式分层交付

> **核心理念**：不一口气生成 25+ 文档，而是按优先级分层交付。每一层交付后都是**可用的**，用户可在任意层后暂停。后续层在前置层基础上增量生成。

**主 agent 按以下层级顺序整合填充：**

**Layer 1 — 核心文档（快速交付，无需深度代码分析）：**

| 文档 | 填充来源 | 说明 |
|------|---------|------|
| `README.md` | 项目名称、技术栈、构建命令 | 项目第一印象 |
| `AGENTS.md` 等上下文文件 | 项目结构、构建/运行/测试命令、代码规范；**必须包含「Task Entry Protocol」章节**（指示 AI 先读 `docs/ARCHITECTURE.md`） | AI 工具上下文 |
| `ARCHITECTURE.md` | 模块识别结果 → 系统总览 + 文档索引 | 文档入口 |
| `modules.md` | 模块识别结果 → 模块注册表 + 功能列表 + 模块间依赖 | 模块概览 |

> **Layer 1 交付点**：向用户呈现 4 个核心文档，确认无误。此时 AI 工具已有基本上下文记忆，用户可立即开始使用。
> 询问用户：`"核心文档已就绪。继续生成模块级文档？(Y/继续 | 指定优先模块 | 暂停)"`
>
> **进度更新**：更新 `progress.md` — `current_layer: 1`，标记 `[x] Layer 1 核心文档`。

**Layer 2 — 模块级文档（统一单文件）：**

为每个识别到的模块生成 `docs/modules/<m>.md`，使用 `templates/modules/_module.md.template`。子代理产出按 5 章节填充：

| 章节 | 填充来源 |
|------|---------|
| 概述 | 子代理产出 → 模块定位（一句话） |
| 职责与边界 | 子代理产出 → 模块负责什么 / 不负责什么 |
| 依赖关系 | 静态扫描结果 → 入向/出向依赖 |
| 核心业务流程 | 子代理产出 → 模块内主要业务流程 |
| 代码锚点 | 子代理产出 → 模块入口、主要 Service / Controller / 实体 / migration 位置 |

**交付策略：**
- 若用户指定了优先模块 → 按指定顺序逐个生成
- 若未指定 → 按代码量从大到小逐个生成，可批量汇报
- 用户可随时暂停

> **Layer 2 交付点**：每完成一个模块即交付，可批量汇报：`"✅ 已完成模块文档：orders / users / payments。继续？(Y | 跳到 Layer 3 | 暂停)"`
>
> **进度更新**：每完成一个模块，更新 `progress.md` — 将该模块加入 `completed_modules`，更新 `current_layer: 2`。

**Layer 3 — 跨模块汇总文档（需要跨模块理解）：**

| 文档 | 填充来源 |
|------|---------|
| `core-flow.md` | 各模块流程分析 → 跨模块业务流程 |
| `config.md` | 子代理产出合并 → 配置项业务语义（不记值/默认） |
| `glossary.md` | 实体/术语扫描合并 → 术语表 + 字段业务语义 |
| `DECISIONS.md` | 架构决策识别 → ADR 条目 |
| `doc-maintenance.md` | 同步矩阵 + 基线清点 | 必须（供 doc-sync 使用） |
| `CHANGELOG.md` | **用户可选**：询问是否从 Git 历史自动填充 |

> **Layer 3 交付点**：`"汇总文档已完成，文档体系已就绪。"`
>
> **进度更新**：更新 `progress.md` — `current_layer: 3`，标记 `[x] Layer 3 汇总文档`，`current_phase: phase3`。

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
| `templates/docs/` | `docs/` 目录下文档模板：`ARCHITECTURE.md`、`modules.md`、`glossary.md`、`core-flow.md`、`config.md`、`DECISIONS.md`、`doc-maintenance.md` |
| `templates/modules/` | 模块单文件模板：`_module.md.template`（每个模块一个 `modules/<m>.md`） |

## 资源文件

| 文件 | 何时读取 | 用途 |
|------|---------|------|
| `resources/tool-init-detection.md` | Phase 0.1 | 工具 /init 检测表（Gemini/Codex/Claude Code/Cursor/Copilot/Windsurf）+ 硬性前置执行策略 |
| `resources/doc-guide.md` | Phase 1/Phase 3 | 文档架构总览、各文档职责、项目类型适配（入口索引） |
| `resources/tech-stack-matrix.md` | Phase 0.3 / Phase 2 扫描前 | 确定性清点命令矩阵、字段业务语义提取矩阵、技术栈/锚点/模块识别策略（Step 1-4）、配置识别策略 |
| `resources/fact-classification.md` | Phase 2 子代理分发前 | Phase 2 填充原则、三级事实分类（T1/T2/T3）、子代理输出格式 |
| `resources/pre-fill-review.md` | Phase 2 子代理完成 → 文档填充前 | 填充前审查关卡 5 步流程（覆盖率检查/T3 收集/批量澄清/响应整合/持久化） |
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
