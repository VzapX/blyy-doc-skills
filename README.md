# blyy-skills-doc

[English](#english) | [中文](#中文)

---

## English

### What is this?

**blyy-skills-doc** is a collection of AI coding tool skills for automated project documentation management. It works with mainstream AI coding tools including **Gemini**, **Codex**, **Cursor**, and **Claude Code**.

### Skills Included

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| **blyy-init-docs** | Initialize complete project documentation from code analysis | Day 0 — One-time setup |
| **blyy-doc-sync** | Keep documentation in sync with code changes | Day 1+ — Ongoing maintenance |
| **blyy-ai-docs** | Generate/maintain an AI-only `ai-docs/` index (no duplicated code facts, self-invalidating, anchor-required) | Any time — auto-dispatches to init/sync/audit |

### Quick Install

#### Option A: Using Install Script

**Windows (PowerShell):**
```powershell
# Navigate to this repo, then run:
.\install.ps1 -TargetProject "C:\path\to\your\project"
```

**Linux / macOS (Bash):**
```bash
# Navigate to this repo, then run:
./install.sh /path/to/your/project
```

The script will auto-detect which AI tools your project uses and copy skills to the correct directory.

#### Option B: Manual Install

Copy the desired skill folder into your project's skill directory:

| AI Tool | Target Directory |
|---------|-----------------|
| Gemini / Codex / Cursor | `.agents/skills/` |
| Claude Code | `.claude/skills/` |

```bash
# Example: Install both skills for Gemini
cp -r skills/blyy-init-docs .agents/skills/
cp -r skills/blyy-doc-sync .agents/skills/
```

### How It Works

- **blyy-init-docs**: Scans your codebase, identifies modules, and generates a complete documentation set (architecture, code map, data model, deployment guide, etc.) with a baseline snapshot
- **blyy-doc-sync**: After each code change, checks what documentation needs updating using a three-line-of-defense strategy (real-time sync / pre-commit gate / periodic audit)
- **blyy-ai-docs**: Produces a lightweight `ai-docs/` folder consumed by AI tools only. Skips everything derivable from the code itself (entity lists, endpoint tables, file inventories) and persists only what code can't express: business glossary, cross-module flows, decisions, invariants. Stays fresh via a 4-tier self-invalidation algorithm (file existence → file sha256 → symbol body sha256 → range fallback). Every claim carries a `[file#Symbol]` anchor; unanchored speculation is refused at write time. A single skill auto-dispatches between **Init / Sync / Audit** modes based on `MANIFEST.yaml` state.

### Usage Scenarios

The two skills cover the full lifecycle. Pick the right entry point depending on whether you're starting fresh or onboarding a legacy codebase.

#### Scenario A — Greenfield project (0→1)

Use this when you've just initialized a repo and want documentation to grow alongside the code.

1. **Day 0 — once, after the first meaningful commit**
   - Invoke `blyy-init-docs`
   - It scans whatever code already exists, generates the full doc skeleton (`docs/`, module folders, AI context files), and writes a baseline snapshot into `doc-maintenance.md`
   - Most fields will start as structured `TODO[priority,type,owner]` markers — that's the **documentation roadmap** for your project
2. **Day 1+ — every code change**
   - Invoke `blyy-doc-sync` (or let your AI tool trigger it automatically after each task)
   - **Defense line 1**: real-time sync. Updates affected docs based on the change matrix. Fills in `TODO[…,fact,…]` markers as the relevant code lands
   - **Defense line 2**: pre-commit gate. Runs deterministic shell checks (dead links, module registry vs directory, `last_updated` freshness)
   - As features get built, the TODO count goes down — the docs reach completion at the same pace as the code

#### Scenario B — Legacy / brownfield project

Use this when you're onboarding a project that already has months or years of code, possibly with outdated `docs/`.

1. **Day 0 — onboarding pass**
   - Invoke `blyy-init-docs`
   - If a `docs/` directory exists, it's automatically moved to `docs-old/` (never deleted)
   - **Phase 1.5** runs an exhaustive structured extraction over `docs-old/` — every entity, config item, endpoint, and module description gets recorded
   - **Phase 2** scans current code in parallel, cross-references it with the extracted facts, and flags drift (`[code-only]` / `[old-doc-only]` / `[both]`)
   - **Phase 2.5** Pre-Fill Review Gate batches all T3 (speculative) items for one-shot user confirmation
   - Final output: a clean doc set + a baseline snapshot capturing today's reality
2. **Day 1+ — every code change**
   - Same defense lines 1 & 2 as Scenario A
3. **Monthly / quarterly — drift audit**
   - Invoke `blyy-doc-sync` defense line 3
   - It re-runs the deterministic inventory, compares against the baseline trend table in `doc-maintenance.md`, and surfaces rot signals (rising TODO counts, shrinking coverage, stale modules)
   - Writes a new snapshot row so you can watch the long-term curve

> **Rule of thumb**: `blyy-init-docs` runs **once per project**. `blyy-doc-sync` runs **every time code changes** (defense lines 1 & 2) plus **periodically** (defense line 3). If you ever feel docs are out of sync after a long break, defense line 3 is the catch-up tool — you do **not** re-run `init-docs`.

### Documentation

- [Usage Guide](docs/usage-guide.md) — Detailed usage instructions
- [Customization Guide](docs/customization.md) — How to customize templates and extend rules
- [Architecture](docs/architecture.md) — Repository structure and progressive-loading design
- [Changelog](docs/CHANGELOG.md) — Version history

### License

[MIT](LICENSE)

---

## 中文

### 这是什么？

**blyy-skills-doc** 是一套 AI 编程工具技能包，用于自动化项目文档管理。兼容主流 AI 编程工具：**Gemini**、**Codex**、**Cursor**、**Claude Code**。

### 包含的技能

| 技能 | 用途 | 使用时机 |
|------|------|---------|
| **blyy-init-docs** | 基于代码分析初始化完整项目文档 | Day 0 — 一次性初始化 |
| **blyy-doc-sync** | 保持文档与代码变更同步 | Day 1+ — 持续维护 |
| **blyy-ai-docs** | 生成 / 维护纯 AI 用的 `ai-docs/` 索引（不重复代码事实、自失效、强制锚点） | 任何时间 — 自动分派 init/sync/audit |

### 快速安装

#### 方式 A：使用安装脚本

**Windows (PowerShell):**
```powershell
# 进入本仓库目录，然后运行：
.\install.ps1 -TargetProject "C:\path\to\your\project"
```

**Linux / macOS (Bash):**
```bash
# 进入本仓库目录，然后运行：
./install.sh /path/to/your/project
```

脚本会自动检测目标项目使用的 AI 工具，并将技能复制到对应目录。

#### 方式 B：手动安装

将所需技能文件夹复制到项目的技能目录中：

| AI 工具 | 目标目录 |
|---------|---------|
| Gemini / Codex / Cursor | `.agents/skills/` |
| Claude Code | `.claude/skills/` |

```bash
# 示例：为 Gemini 安装两个技能
cp -r skills/blyy-init-docs .agents/skills/
cp -r skills/blyy-doc-sync .agents/skills/
```

### 工作原理

- **blyy-init-docs**：扫描代码库，识别模块，生成完整文档集（架构总览、代码地图、数据模型、部署指南等），并写入基线快照
- **blyy-doc-sync**：每次代码变更后，通过三道防线策略检查哪些文档需要更新（实时同步 / 提交前门禁 / 定期审计）
- **blyy-ai-docs**：生成一份轻量的 `ai-docs/` 文件夹，**仅供 AI 工具阅读**。放弃所有可从代码推出的信息（实体清单、端点表、文件清单），只持久化代码无法表达的内容：业务术语表、跨模块流程、设计决策、不变式。通过 4-tier 自失效算法（文件存在性 → 文件 sha256 → 符号 body sha256 → 范围兜底）确保多年迭代仍不腐烂。每条断言必须带 `[file#Symbol]` 锚点，无锚点的推测在写入阶段即被拒绝。单个技能根据 `MANIFEST.yaml` 状态自动分派 **Init / Sync / Audit** 三种模式。

### 使用场景

两个技能覆盖项目的完整生命周期。请根据项目状态（全新 vs 存量）选择正确的入口。

#### 场景 A：全新项目（0→1）

适用于刚初始化代码仓库、希望文档与代码同步成长的情况。

1. **Day 0 — 一次性，第一次有意义的提交后立即执行**
   - 调用 `blyy-init-docs`
   - 它会扫描当前已有的代码，生成完整的文档骨架（`docs/`、模块文件夹、AI 上下文文件），并把基线快照写入 `doc-maintenance.md`
   - 大部分字段会以结构化 `TODO[priority,type,owner]` 标记起步 — 这就是你的**文档路线图**
2. **Day 1+ — 每次代码变更**
   - 调用 `blyy-doc-sync`（或让 AI 工具在每个任务后自动触发）
   - **防线 1**：实时同步。根据变更矩阵更新受影响的文档；当对应代码落地后，自动填充 `TODO[…,fact,…]` 标记
   - **防线 2**：提交前门禁。执行确定性 shell 检查（死链、模块注册表 vs 目录、`last_updated` 新鲜度）
   - 随着功能逐步实现，TODO 数量持续下降 — 文档与代码以同样的节奏走向完整

#### 场景 B：存量 / 老旧项目

适用于已经积累了几个月甚至几年代码、可能还带着过时 `docs/` 的项目。

1. **Day 0 — 一次性接管扫描**
   - 调用 `blyy-init-docs`
   - 若已存在 `docs/` 目录，自动迁移到 `docs-old/`（不删除）
   - **Phase 1.5** 对 `docs-old/` 执行穷举式结构化提取 — 每个实体、配置项、接口、模块描述都被记录
   - **Phase 2** 并行扫描当前代码，与提取出的事实交叉对照，标记差异（`[code-only]` / `[old-doc-only]` / `[both]`）
   - **Phase 2.5** 填充前审查关卡批量呈现所有 T3（推测性）条目，用户一次性确认
   - 最终产物：干净的新文档集 + 当下事实的基线快照
2. **Day 1+ — 每次代码变更**
   - 同场景 A 的防线 1 与防线 2
3. **每月 / 每季度 — 漂移审计**
   - 调用 `blyy-doc-sync` 防线 3
   - 重新执行确定性清点，与 `doc-maintenance.md` 中的基线趋势表对比，识别腐烂信号（TODO 数持续上涨、覆盖率下降、模块陈旧）
   - 追加一行新快照，便于观察长期曲线

> **使用规则**：`blyy-init-docs` **每个项目只运行一次**。`blyy-doc-sync` 在**每次代码变更后运行**（防线 1、2），并**定期运行**（防线 3）。即使你长期未维护文档导致严重不同步，正确的恢复方式是跑防线 3，而**不是重新运行 init-docs**。

### 文档

- [使用指南](docs/usage-guide.md) — 详细使用说明
- [自定义指南](docs/customization.md) — 如何自定义模板和扩展规则
- [架构说明](docs/architecture.md) — 仓库结构与渐进式加载设计
- [变更日志](docs/CHANGELOG.md) — 版本历史

### 许可证

[MIT](LICENSE)
