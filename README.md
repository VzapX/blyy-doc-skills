# blyy-skills-doc

[English](#english) | [中文](#中文)

---

## English

### What is this?

**blyy-skills-doc** is an AI coding tool skill for automated project documentation management. It works with mainstream AI coding tools including **Gemini**, **Codex**, **Cursor**, and **Claude Code**.

### Skill

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| **blyy-ai-docs** | Generate/maintain an AI-only `ai-docs/` index (no duplicated code facts, self-invalidating, anchor-required) | Any time — auto-dispatches to Init / Sync / Audit |

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

The script will auto-detect which AI tools your project uses and copy the skill to the correct directory.

#### Option B: Manual Install

Copy the skill folder into your project's skill directory:

| AI Tool | Target Directory |
|---------|-----------------|
| Gemini / Codex / Cursor | `.agents/skills/` |
| Claude Code | `.claude/skills/` |

```bash
# Example: Install for Gemini
cp -r skills/blyy-ai-docs .agents/skills/

# Example: Install for Claude Code
cp -r skills/blyy-ai-docs .claude/skills/
```

### How It Works

**blyy-ai-docs** produces a lightweight `ai-docs/` folder consumed by AI tools only. A single skill auto-dispatches between three modes based on `MANIFEST.yaml` state:

- **Mode A — Init**: First-time generation. Scans your codebase, identifies modules with complexity-based tiering, runs sub-agents for business analysis, then writes the full doc set with a Pre-Fill Review Gate for uncertain content.
- **Mode B — Sync**: Triggered when `last_synced_commit ≠ HEAD`. Runs 4-tier self-invalidation (file existence → file sha256 → symbol body sha256 → range fallback), rewrites only stale paragraphs.
- **Mode C — Audit**: Full-scope verification. Re-validates all anchors, detects decay trends, and surfaces rot signals.

**Core principles**:

1. **AI quick indexing** — entry points and business context, not exhaustive file scans
2. **Record invisible facts** — business glossary, cross-module flows, design decisions, invariants — things code can't express directly
3. **Never repeat code facts** — entity lists, endpoint tables, file inventories are replaced by executable `fd`/`rg` query recipes in `code-queries.md`
4. **Long-term freshness** — 4-tier self-invalidation algorithm ensures docs don't drift over years of iteration. Every claim carries a `[file#Symbol]` anchor; unanchored speculation is refused at write time.

### Usage

Mention the skill in your AI coding tool:

```
请使用 blyy-ai-docs 为本项目生成 AI 索引
```

Or equivalent:

```
Generate AI docs index for this project
```

The skill automatically detects project state and picks the right mode (Init / Sync / Audit).

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

**blyy-skills-doc** 是一个 AI 编程工具技能，用于自动化项目文档管理。兼容主流 AI 编程工具：**Gemini**、**Codex**、**Cursor**、**Claude Code**。

### 技能

| 技能 | 用途 | 使用时机 |
|------|------|---------|
| **blyy-ai-docs** | 生成 / 维护纯 AI 用的 `ai-docs/` 索引（不重复代码事实、自失效、强制锚点） | 任何时间 — 自动分派 Init / Sync / Audit |

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

将技能文件夹复制到项目的技能目录中：

| AI 工具 | 目标目录 |
|---------|---------|
| Gemini / Codex / Cursor | `.agents/skills/` |
| Claude Code | `.claude/skills/` |

```bash
# 示例：为 Gemini 安装
cp -r skills/blyy-ai-docs .agents/skills/

# 示例：为 Claude Code 安装
cp -r skills/blyy-ai-docs .claude/skills/
```

### 工作原理

**blyy-ai-docs** 生成一份轻量的 `ai-docs/` 文件夹，**仅供 AI 工具阅读**。单个技能根据 `MANIFEST.yaml` 状态自动分派三种模式：

- **Mode A — Init**：首次生成。扫描代码库、识别模块并按复杂度分级、通过子代理并行业务分析，最终写入完整文档集。不确定内容经 Pre-Fill Review Gate 由用户确认。
- **Mode B — Sync**：当 `last_synced_commit ≠ HEAD` 时触发。跑 4-tier 自失效检测（文件存在性 → 文件 sha256 → 符号 body sha256 → 范围兜底），只重写过期段落。
- **Mode C — Audit**：全量验证。重新校验所有锚点、检测腐烂趋势、输出腐烂信号。

**核心原则**：

1. **AI 快速索引** — 入口文件和业务上下文，不做全项目穷举扫描
2. **记录不可见事实** — 业务术语表、跨模块流程、设计决策、不变式——代码无法直接表达的内容
3. **不重复代码事实** — 实体清单、端点表、文件清单一律改写为 `code-queries.md` 中可执行的 `fd`/`rg` 查询配方
4. **长期不腐烂** — 4-tier 自失效算法确保多年迭代仍不偏移。每条断言必须带 `[file#Symbol]` 锚点，无锚点的推测在写入阶段即被拒绝

### 使用方式

在 AI 工具中直接对话即可触发：

```
请使用 blyy-ai-docs 为本项目生成 AI 索引
```

技能会自动检测项目状态，选择正确的模式（Init / Sync / Audit）。

### 文档

- [使用指南](docs/usage-guide.md) — 详细使用说明
- [自定义指南](docs/customization.md) — 如何自定义模板和扩展规则
- [架构说明](docs/architecture.md) — 仓库结构与渐进式加载设计
- [变更日志](docs/CHANGELOG.md) — 版本历史

### 许可证

[MIT](LICENSE)
