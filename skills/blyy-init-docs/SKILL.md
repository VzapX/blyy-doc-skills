---
name: blyy-init-docs
description: 初始化项目文档骨架并基于代码分析自动填充内容，一次性交付完整可用的文档集
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

**执行策略：**
- 若当前工具支持 `/init`，**先执行工具自带的初始化**，让工具生成其专属上下文文件
- 初始化完成后，将产物纳入后续 Phase 1 的已有文档整合流程
- 若工具不支持或无法判断，跳过此步

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
| 源代码文件 ≤ 500 且 子项目 ≤ 5 | 标准模式（Phase 1 → Phase 2 → Phase 3） |
| 源代码文件 > 500 或 子项目 > 5 | 大型项目模式（Phase 1 → Phase 2A-2D → Phase 3） |

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
    ├── ARCHITECTURE.md
    ├── code-map.md          ← 总览简述 + 各模块链接
    ├── modules.md
    ├── core-flow.md
    ├── config.md
    ├── features.md
    ├── DECISIONS.md
    ├── doc-maintenance.md
    ├── data-model.md        ← 公共数据模型 + 模块索引
    ├── runbook.md
    ├── deployment.md
    ├── api-reference.md     ← 按需
    ├── database/            ← 公共/跨模块表 + 各模块链接
    └── modules/
        └── <module-name>/
            ├── README.md
            ├── flow.md
            ├── data-model.md
            ├── code-map.md      ← 该模块的文件→职责映射
            └── database/        ← 该模块的表 schema
```

**操作步骤：**

1. **旧文档迁移**（条件执行）：
   - **前置检查**：检查项目根目录下是否**已存在** `docs/` 目录
   - **若 `docs/` 已存在** → 将整个 `docs/` 目录移动（重命名）为 `docs-old/`
     - 若 `docs-old/` 也已存在，使用带时间戳的目录名 `docs-old-YYYYMMDD-HHmmss/` 避免冲突
     - 移动完成后，向用户汇报迁移结果（迁移了多少个文件）
     - **递归列出** `docs-old/` 下所有 `.md` 文件清单，以便 Phase 2 填充阶段参考
   - **若 `docs/` 不存在** → **跳过迁移，不创建 `docs-old/`**，直接进入步骤 2
2. 阅读 `templates/root/`、`templates/docs/`、`templates/modules/` 下的所有模板
3. 在全新的 `docs/` 目录下按模板创建完整文档结构
4. **根目录已有文档整合**：对于项目中已存在的根目录文档（`README.md`、`AGENTS.md`/`CLAUDE.md` 等、`CHANGELOG.md`）
   - 阅读已有文件，提取其中有价值的内容（项目描述、构建命令、配置说明、变更记录等）
   - 按模板结构重新组织这些内容，生成符合规范的新版本
   - 将新旧内容的差异摘要呈现给用户，说明哪些内容被保留、哪些被重组、哪些是新增
   - 用户确认后，覆盖原文件
   - 若 Phase 0.1 中工具 `/init` 生成了上下文文件，将其内容整合进对应文档
5. 对于可选文档（`CONTRIBUTING.md`、`SECURITY.md`、`api-reference.md`），询问用户是否需要

---

### Phase 2 — 代码分析填充（标准模式）

> 仅当 Phase 0.3 判定为**标准模式**时使用。大型项目请跳至 Phase 2A-2D。
>

扫描项目代码，为每个文档填充与项目相关的实际内容。**采用主 agent + 子代理并行分工加速。**

**主 agent 负责：**

1. **识别技术栈**：扫描项目清单文件，确认语言和框架（详见 `resources/doc-guide.md` 技术栈识别表）
2. **两级模块识别**：先识别项目（第一级），再分析项目内部是否有子模块（第二级）（详见 `resources/doc-guide.md` 模块识别策略）
3. **收集已有文档素材**：若 Phase 1 迁移生成了 `docs-old/`，**递归读取其中所有 `.md` 文件**（含子目录），提取有价值的信息作为填充参考
4. **分配子代理任务**：将可并行的分析工作分发给子代理

**子代理并行执行（按任务类型拆分）：**

主 agent 将以下独立工作分配给不同子代理并行执行：

| 子代理任务 | 输出 |
|-----------|------|
| 扫描配置类/配置文件 | `config.md` 填充素材 |
| 扫描实体类/ORM/迁移文件 | `data-model.md` 填充素材 |
| 扫描构建脚本/CI 配置/发布脚本 | `deployment.md` + `README.md` 构建命令 |
| 扫描公共 API / 命令行参数 | `features.md` 填充素材 |
| 各模块内部分析（接口、服务、流程） | 模块级文档填充素材 |

**主 agent 整合后填充：**

| 文档 | 填充来源 |
|------|---------|
| `README.md` | 项目名称、技术栈、构建命令、项目简介 |
| `AGENTS.md` 等上下文文件 | 项目结构、构建/运行/测试命令、代码规范 |
| `code-map.md` | 项目总览目录树 + 各模块 code-map 链接 |
| `modules.md` | 两级模块识别结果 → 模块注册表 |
| `core-flow.md` | 入口点分析 → 核心业务流程骨架 |
| `config.md` | 子代理产出 → 配置项列表 |
| `data-model.md` | 子代理产出 → 公共数据模型概览 + 模块索引 |
| `features.md` | 子代理产出 → 功能列表 |
| `ARCHITECTURE.md` | 模块识别结果 → 系统总览 + Mermaid 组件图 + 文档索引 |
| `CHANGELOG.md` | **用户可选**：询问用户是否从 Git 提交/标签历史自动填充；若用户拒绝则保留模板 |
| `database/` | 公共/跨模块表 + 各模块 database 链接 |
| `deployment.md` | 子代理产出 → 部署流程 |
| 模块级 `code-map.md` | 子代理产出 → 该模块的文件→职责映射 |
| 模块级 `database/` | 子代理产出 → 该模块的表 schema |
| 模块级其他文档 | 子代理产出直接转化 |

> **已有文档优先**：填充每个文档时，应先检查 `docs-old/` 中是否有对应或相关的旧文档。若有，优先从旧文档中提取有意义的信息（如架构说明、流程描述、配置文档等）融入新文档，而非完全从零分析。

**填充原则：**

- 基于**代码事实**填充，不臆测不编造
- **已有文档优先**：`docs-old/` 中的旧文档（含所有子目录）是重要参考素材，应递归扫描并提取有价值信息
- **不确定必澄清**：从已有文档或代码中提取信息写入新文档时，若对内容的准确性、完整性存在不确定（包括但不限于：重要业务流程、模块边界与职责划分、关键设计决策、数据流向等），**必须先向用户澄清确认后再写入**，不得自行推测
- 无法自动推断且用户暂未确认的部分，保留 `<!-- TODO: 请补充 xxx -->` 占位符
- 每个文档的 YAML 元数据中 `last_updated` 设为当天日期

---

### Phase 2A-2D — 代码分析填充（大型项目模式）

> 仅当 Phase 0.3 判定为**大型项目模式**时使用。

#### Phase 2A — 项目轮廓扫描

> 目标：快速建立项目全局画像，**不读业务代码**。由主 agent 串行完成。

**执行步骤：**

1. **读项目清单文件** — `.sln`、`.csproj`、`package.json`、`go.mod`、`pom.xml`、`Cargo.toml`、`pyproject.toml` 等，提取项目名称、技术栈、子项目列表、依赖关系
2. **生成目录树**（限深度 2-3 层） — 使用 `fd`，排除 `node_modules/`、`bin/`、`obj/`、`.git/`、`vendor/`、`dist/`、`packages/` 等
3. **文件统计** — 按扩展名统计文件数量和分布
4. **读构建/CI 配置** — `Dockerfile`、`docker-compose.yml`、`Makefile`、`.github/workflows/`、`Jenkinsfile`、`*.ps1` 等
5. **读已有文档** — 若存在 `docs-old/`，**递归读取其中所有 `.md` 文件**（含任意深度子目录），提取项目描述、架构说明、流程文档等有价值的信息；同时读取根目录 `README.md` 等已有文档
6. **输出轮廓报告** — 汇总上述信息

**输出：** 项目轮廓报告 → 持久化到 `.init-docs/project-profile.md`

> **检查点 ①**：将项目轮廓报告呈现给用户确认

#### Phase 2B — 锚点文件识别与智能索引

> 目标：找到每个模块的「骨架文件」，不逐个读所有文件。由主 agent 为主。

**执行步骤：**

1. 根据 Phase 2A 识别的技术栈，从锚点矩阵中选择对应规则（详见 `resources/doc-guide.md` 锚点矩阵）
2. 使用 `fd` / `rg` + 文件名 glob 或内容模式批量搜索锚点文件
3. 优先阅读入口点文件，推导出模块清单
4. 按模块聚合锚点文件
5. 生成模块清单草案 → 持久化到 `.init-docs/module-list.md`

> **检查点 ②**：将模块清单草案呈现给用户确认（模块边界、职责描述等）

#### Phase 2C — 模块级聚焦分析

> 目标：逐模块深入分析。**此阶段高度并行**，是子代理的主战场。

**主 agent 编排：**
1. 根据模块清单为每个模块准备子代理任务描述（含目录范围、锚点文件列表、分析模板）
2. 按模块规模决定分组策略：< 20 文件合并、20-100 一对一、> 100 拆分子模块
3. 并行分发给子代理（建议并行度 3-5）

**子代理执行（每个模块独立上下文）：**
1. 仅在分配的模块目录范围内工作
2. 读锚点文件 → 核心服务 → 数据模型 → 测试（抽样）
3. 输出标准化模块分析报告 → 持久化到 `.init-docs/modules/<name>-analysis.md`
4. 标注不确定项

**主 agent 整合：**
1. 审查每份报告（格式、一致性、冲突检测）
2. 补充跨模块关联
3. 汇总不确定项

> **检查点 ③**：将所有不确定项批量呈现给用户确认 → 记录到 `.init-docs/clarifications.md`

#### Phase 2D — 文档生成与填充

> 目标：基于已确认的分析结果填充文档框架。

| 文档类型 | 执行者 | 数据来源 |
|----------|--------|---------|
| 跨模块文档（`ARCHITECTURE.md`、`core-flow.md`、`modules.md`） | 主 agent | 项目轮廓 + 模块清单 + 各模块核心流程 |
| 汇总型文档（`config.md`、`data-model.md`、`features.md`） | 主 agent | 各模块分析报告合并 |
| 模块级文档（`modules/<m>/README.md` 等） | 子代理并行 | 各自模块分析报告直接转化 |
| 其他文档（`code-map.md` 等） | 主 agent | 目录树等 |
| `CHANGELOG.md` | 主 agent | **用户可选**：询问是否从 Git 历史自动填充 |

**填充原则同标准模式**（基于代码事实、不确定必澄清、保留 TODO 占位符）。

---

### Phase 3 — 最终检查与完成报告

**检查项：**

1. 确认所有文档的 YAML 元数据正确
2. 确认 `ARCHITECTURE.md` 文档索引覆盖所有生成的文档
3. 确认 `modules.md` 注册表覆盖所有识别到的模块
4. 确认 `data-model.md` 索引覆盖所有模块级数据模型
5. 确认无断链引用
6. 大型项目模式下，清理 `.init-docs/` 目录（或保留供后续参考，由用户决定）

**生成完成报告**（`docs/INIT-REPORT.md`）：

此报告为**一次性文档**，仅用于交付文档初始化结果，不参与后续功能开发。

报告内容：

```markdown
# 文档初始化报告

> 本文档为一次性报告，仅记录 blyy-init-docs 执行结果，不参与后续开发参考。
> 确认无误后可安全删除。

## 总体情况
- 执行日期：YYYY-MM-DD
- 项目规模：N 个源文件，M 个模块
- 执行模式：标准 / 大型项目
- 生成文档数：X 个（含模块级文档）
- AI 上下文文件：AGENTS.md / CLAUDE.md / ...

## 已自动填充的文档
| 文档 | 填充程度 | 说明 |
|------|---------|------|
| README.md | ██████████ 100% | 已完整填充 |
| modules.md | ████████░░ 80% | 2 个模块职责待确认 |
| ... | ... | ... |

## 需要手动补充的内容

以下内容无法通过代码自动推断，需要人工补充：

| 待补充项 | 所在文档 | 位置链接 |
|---------|---------|----------|
| 项目愿景与目标 | README.md | [→ 前往补充](../README.md#项目简介) |
| 核心业务场景描述 | core-flow.md | [→ 前往补充](core-flow.md#主流程) |
| 运维联系人 | runbook.md | [→ 前往补充](runbook.md#联系人) |
| ... | ... | ... |

## CHANGELOG 填充状态
- [ ] 用户选择：已自动填充 / 用户选择手动维护
```

向用户呈现此报告，完成交付。

---

## 任务持久化机制（大型项目模式）

大型项目的文档梳理可能跨越多个会话，通过 `.init-docs/` 目录持久化进度：

```
项目根目录/
└── .init-docs/
    ├── master-task.md           ← 主任务清单（YAML 元数据 + checklist）
    ├── project-profile.md       ← Phase 2A 输出的项目轮廓报告
    ├── module-list.md           ← Phase 2B 输出的模块清单（用户已确认）
    ├── clarifications.md        ← 用户澄清记录（避免跨会话重复提问）
    └── modules/
        ├── <name>-analysis.md   ← 各模块分析报告（含子任务清单）
        └── ...
```

**`master-task.md` 格式**：YAML 头部记录项目名、技术栈、当前阶段；正文为按 Phase 分组的 checklist（`[x]`/`[/]`/`[ ]`）。

**断点续做**：新会话开始时检查 `.init-docs/master-task.md` 是否存在 → 读取进度 → 恢复上下文（轮廓报告、模块清单、已完成分析） → 从中断点继续。

**关键原则**：每完成一个步骤立即更新 `master-task.md`；子代理完成后立即写入分析报告。

---

## 文件过滤规则

所有扫描阶段应**默认排除**以下文件/目录：

```
# 依赖与构建产物
node_modules/, bin/, obj/, dist/, build/, out/, target/, packages/

# 版本控制
.git/, .svn/, .hg/

# IDE 配置
.vs/, .vscode/, .idea/, *.user, *.suo

# 生成代码（多语言）
*.Designer.cs, *.g.cs, *.generated.*     # C#
auto-generated/, __pycache__/, *.pyc      # Python
.next/, .nuxt/, .output/                  # 前端 SSR

# 二进制与媒体
*.dll, *.exe, *.pdb, *.jar, *.class
*.jpg, *.png, *.gif, *.ico, *.svg, *.woff, *.ttf

# 测试数据
**/testdata/, **/fixtures/, **/snapshots/, **/mocks/

# 历史迁移（仅读最新 3-5 个 + InitialCreate）
Migrations/*

# 锁文件
package-lock.json, yarn.lock, pnpm-lock.yaml, Gemfile.lock, poetry.lock
```

---

## 模板文件说明

| 目录 | 内容 |
|------|------|
| `templates/root/` | 根目录文档模板：`README.md`、`AGENTS.md`、`CHANGELOG.md`、`CONTRIBUTING.md`、`SECURITY.md` |
| `templates/docs/` | `docs/` 目录下所有文档模板 |
| `templates/modules/` | 模块级文档模板：`README.md`、`flow.md`、`data-model.md`、`code-map.md`、`database/` |

## 资源文件

| 文件 | 用途 |
|------|------|
| `resources/doc-guide.md` | 文档架构说明、各文档职责定义、多语言锚点矩阵、Phase 2 填充规则详解 |

## 进度通报规范

为避免用户在漫长的初始化过程中感到焦虑，**必须**在以下关键节点向用户输出进度信息：

| 时机 | 输出格式 |
|------|----------|
| 进入每个 Phase | `📋 Phase N — {阶段名} 开始...` |
| Phase 0 完成 | 汇报项目规模、执行模式（标准/大型）、检测到的 AI 工具 |
| Phase 1 旧文档迁移完成 | `📦 已迁移 N 个旧文档到 docs-old/`（或 `ℹ️ 无已有文档，跳过迁移`） |
| Phase 1 骨架创建完成 | `📁 已创建 N 个文档骨架文件` |
| Phase 2 每个子代理启动 | `🔄 正在分析: {任务名}...` |
| Phase 2 每个子代理完成 | `✅ {任务名} 分析完成` |
| Phase 2 主 agent 整合每个文档 | `📝 正在填充: {文档名}...` |
| Phase 3 完成 | 呈现最终完成报告 |

> **原则**：宁可多输出几行进度，也不要让用户长时间看不到任何反馈。每完成一个有意义的步骤都应告知用户当前状态。

---

## 注意事项

- 本 Skill 适用于项目初始化阶段，通常只运行一次
- 执行后的日常文档维护请使用 `blyy-doc-sync` skill
- 若项目已有 `docs/` 目录，Skill 会先将其迁移至 `docs-old/`，再生成全新文档骨架；旧文档内容（含所有子目录）会在填充阶段作为参考素材递归读取
- 若项目不存在 `docs/` 目录，**不会**创建 `docs-old/`
- 大型项目模式产生的 `.init-docs/` 目录可在最终检查通过后由用户决定是否保留
