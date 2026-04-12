# 架构说明

> 本文档描述 **blyy-doc-skills 仓库自身**的架构。如果你只是想*使用*这两个技能，请看 [usage-guide.md](usage-guide.md)；想*扩展*它们，请看 [customization.md](customization.md)。

## 仓库结构

```
blyy-doc-skills/
├── README.md                      ← 仓库入口（双语），含安装、场景对比
├── LICENSE                        ← MIT
├── install.sh                     ← Linux/macOS 安装脚本
├── install.ps1                    ← Windows 安装脚本
├── docs/                          ← 本仓库的项目文档
│   ├── usage-guide.md             ← 使用指南
│   ├── customization.md           ← 自定义扩展
│   ├── architecture.md            ← 架构说明（本文件）
│   └── CHANGELOG.md               ← 变更日志
└── skills/
    ├── blyy-init-docs/            ← Skill 1：文档初始化（人类 + AI 共用的 docs/）
    │   ├── SKILL.md               ← AI 入口（每次调用必加载）
    │   ├── resources/             ← 按需加载的详细流程
    │   │   ├── doc-guide.md
    │   │   ├── legacy-extraction.md
    │   │   ├── large-project-mode.md
    │   │   ├── phase3-verification.md
    │   │   └── operational-conventions.md
    │   └── templates/             ← 文档模板
    │       ├── root/              ← 根目录文档（README/AGENTS/CHANGELOG/...）
    │       ├── docs/              ← docs/ 下文档
    │       ├── modules/           ← Core 模块完整目录模板（6 个子文件）
    │       └── modules-single.md.template  ← Standard 模块单文件模板
    ├── blyy-doc-sync/             ← Skill 2：持续同步（维护 docs/）
    │   ├── SKILL.md               ← AI 入口
    │   └── resources/
    │       ├── sync-matrix.md
    │       └── defense-line-3-audit.md
    └── blyy-ai-docs/              ← Skill 3：纯 AI 索引（维护 ai-docs/）
        ├── SKILL.md               ← 单入口三模式分派（Init/Sync/Audit）
        ├── resources/
        │   ├── tech-stack-matrix.md      ← 技术栈探测 + 锚点矩阵
        │   ├── query-recipes.md          ← 8 大栈 fd/rg 命令库
        │   ├── anti-hallucination.md     ← T1/T2/T3 + 锚点强制 + 禁枚举
        │   ├── anchor-extraction.md      ← 8 语言符号定位 + body 提取
        │   └── self-invalidation.md      ← 4-tier 失效检测算法
        └── templates/
            ├── INDEX.md.template
            ├── modules.md.template
            ├── glossary.md.template
            ├── flows.md.template
            ├── decisions.md.template
            ├── code-queries.md.template
            └── MANIFEST.yaml.template
```

## 三个 Skill 的职责边界

| 维度 | blyy-init-docs | blyy-doc-sync | blyy-ai-docs |
|------|---------------|---------------|-------------|
| 输出目录 | `docs/` | `docs/` | `ai-docs/`（默认 gitignore） |
| 目标读者 | 人类 + AI | 人类 + AI | **仅 AI** |
| 触发时机 | Day 0，一次性 | Day 1+，每次代码变更 + 定期审计 | 任何时间，按 MANIFEST 状态自动分派 |
| 主要目标 | 从零建立完整文档集 | 维持 docs/ 与代码的一致性 | 生成不重复代码事实、自失效的 AI 索引 |
| 主要产出 | 完整文档骨架 + 填充内容 + 基线快照 | 增量更新 + 差异修复 + 趋势报告 | INDEX + modules + glossary + flows + decisions + code-queries + MANIFEST |
| 反幻觉机制 | Pre-Fill Review Gate（T1/T2/T3） | 沿用 init 的 T 分级 | 强制 `[file#Symbol]` 锚点 + UNVERIFIED 包裹 + 禁枚举铁律 |
| 自失效机制 | — | 三道防线（sync matrix / 门禁 / 审计） | 4-tier（file 存在性 / sha256 / body sha256 / 范围） |
| 与其他 skill 依赖 | 无 | 依赖 init 写入的基线 | **完全独立**，可单独安装 |
| 是否含模板 | ✅ | ❌ | ✅ |
| 是否调用子代理 | ✅ 大量并行 | ❌ 主 agent 主导 | ✅ 每个模块一个子代理 |

**init-docs ↔ doc-sync 数据契约**（v0.2.0 起）：

- `docs/doc-maintenance.md` 中的**基线快照 YAML 块** — init-docs 写入 / doc-sync 防线 3 读取并追加
- 各文档 front matter 的 **`last_synced_commit`** — init-docs 初始化为 `init`，doc-sync 防线 1 每次更新
- 各文档 front matter 的 **`code_anchors`** — init-docs 填充实际代码路径，doc-sync 防线 1 用于过滤变更范围
- **结构化 TODO 标记** — init-docs 留下未填充项，doc-sync 持续递减

**blyy-ai-docs 内部状态契约**（v0.4.0 起）：

- `ai-docs/MANIFEST.yaml.last_synced_commit` — 上次同步后的 HEAD，Mode B 据此做 `git diff` 增量
- `ai-docs/MANIFEST.yaml.anchors[*].sha256` — 每个被文档引用的文件的 `git hash-object` 结果
- `ai-docs/MANIFEST.yaml.anchors[*].symbols[*].body_sha256` — 符号体归一化后的 hash，符号级失效判定核心
- `ai-docs/MANIFEST.yaml.anchors[*].docs` — 反向锚点索引（STALE → 段落定位）
- `ai-docs/MANIFEST.yaml.history` — 事件追加日志（init / sync / audit）

## 渐进式加载架构（v0.3.0）

### 问题

AI Skill 的入口文件 `SKILL.md` 在每次调用时都会被完整加载到上下文。如果包含全部细节，会撑爆上下文窗口（特别是对 Haiku/Sonnet 等小窗口模型）。

### 解决方案

将 SKILL.md 拆分为：
- **常驻部分**（SKILL.md）— 核心流程概述、触发条件判断、关键铁律摘要
- **按需部分**（resources/*.md）— 各 Phase 的详细执行流程、模板、表格

每个 resource 文件顶部明确标注「**何时读取**」触发条件，AI 仅在满足条件时通过 Read 工具加载。

### 加载时机映射

```
blyy-init-docs/SKILL.md（~470 行，约 6.7K tokens，每次必加载）
    │
    ├─ Phase 1/2 填充时
    │     └─ Read resources/doc-guide.md（710 行）
    │
    ├─ docs-old/ 存在 → Phase 1.5 触发
    │     └─ Read resources/legacy-extraction.md（73 行）
    │
    ├─ 文件数 > 500 → 大型项目模式
    │     └─ Read resources/large-project-mode.md（128 行）
    │
    ├─ 子代理调度时
    │     └─ Read resources/operational-conventions.md（143 行）
    │
    └─ 进入 Phase 3
          └─ Read resources/phase3-verification.md（157 行）

blyy-doc-sync/SKILL.md（~250 行，约 3.5K tokens，每次必加载）
    │
    ├─ 防线 1 fallback（项目无 doc-maintenance.md）
    │     └─ Read resources/sync-matrix.md（103 行）
    │
    └─ 触发防线 3 定期审计
          └─ Read resources/defense-line-3-audit.md（124 行）

blyy-ai-docs/SKILL.md（~360 行，每次必加载；含三模式分派逻辑）
    │
    ├─ Mode A Phase A0/A1 技术栈与模块识别
    │     └─ Read resources/tech-stack-matrix.md
    │
    ├─ Mode A Phase A2 生成 code-queries.md
    │     └─ Read resources/query-recipes.md
    │
    ├─ Mode A Phase A3 子代理分发前
    │     └─ Read resources/anti-hallucination.md
    │
    ├─ Mode A Phase A5 / Mode B Phase B1 / Mode C Phase C0
    │     └─ Read resources/anchor-extraction.md
    │
    └─ Mode B Phase B1 / Mode C Phase C0 失效检测
          └─ Read resources/self-invalidation.md
```

### 设计铁律

1. **SKILL.md 必须自洽** — 即使 AI 不展开任何 resource，也能完成基础执行。SKILL.md 中保留每个 resource 的核心摘要 + 关键铁律
2. **资源文件清单必须明示「何时读取」** — SKILL.md 的「资源文件」表格采用三列结构（文件 / 何时读取 / 用途），让 AI 一眼判断是否需加载
3. **避免循环引用** — resource 文件之间不互相 Read，仅由 SKILL.md 路由
4. **资源文件单一职责** — 每个文件聚焦一个 Phase 或一类规范，命名需体现触发场景

## 模块复杂度分级体系（v0.3.2）

模块文档采用三级形态，根据复杂度评分自动决定，解决大型项目文档过多的问题：

| 级别 | 条件（评分） | 文档形态 | 文件数/模块 |
|------|------------|---------|-----------|
| **Core** | ≥ 3 分 | 完整目录 `modules/<m>/`（README + flow + code-map + data-model + api-reference + database） | 6 |
| **Standard** | 1-2 分 | 单文件 `modules/<m>.md`，所有章节合并 | 1 |
| **Lightweight** | 0 分 | 无独立文件，内联到 `modules.md` | 0 |

**评分信号**（全部基于 shell 命令，不依赖 AI 判断）：源文件数 >15（+2）/5-15（+1）、有 Entity/Model 文件（+1）、有 Controller/Handler 文件（+1）、被 ≥3 模块依赖（+1）。

**动态复评闭环**：
- **防线 1 Step 2.5**：每次代码变更后检测升级信号（实时，仅升级方向）
- **防线 3 Step 2.5**：定期全量复评（月/季度，升降双向）

## 三道防线的层级

```
┌─────────────────────────────────────────────────────────────┐
│ 防线 1：触发式同步（实时）                                     │
│ ─ 每次代码变更后立即执行                                       │
│ ─ 基于 last_synced_commit 增量识别变更                        │
│ ─ 用 fd/rg 做确定性扫描验证                                    │
│ ─ 按 priority 顺序检查并填充 TODO                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 防线 2：提交前验证（门禁）                                     │
│ ─ 完成一轮修改后用 shell 命令自检                              │
│ ─ 死链 / 注册表一致性 / last_updated 新鲜度                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 防线 3：定期审计（兜底，每月/每季度）                          │
│ ─ 全量重扫 + 与基线快照对比                                    │
│ ─ TODO 健康度按 priority/type/owner 聚合                       │
│ ─ 输出腐烂信号 + 维护优先级                                    │
│ ─ 追加新基线到历史趋势表                                        │
└─────────────────────────────────────────────────────────────┘
```

## 多 AI 工具兼容策略

本仓库不针对单一 AI 工具优化，而是采用所有主流工具都遵守的 SKILL.md 标准格式：

```yaml
---
name: blyy-init-docs
description: 一句话描述触发时机
---

# 技能正文 markdown
```

不同工具的安装路径由 `install.sh` / `install.ps1` 自动检测：

| AI 工具 | 安装目录 |
|---------|---------|
| Gemini / Codex / Cursor | `.agents/skills/` |
| Claude Code | `.claude/skills/` |

工具特异性差异（如 Claude Code 的 `/init` 命令）在 `Phase 0.1` 中通过条件判断处理，不写死在指令中。

## 版本演进策略

- **主版本**（1.x）：当前为 0.x，接口可能不兼容变更
- **次版本**（0.x.0）：新增 Phase / 新增 resource 文件 / SKILL.md 重构
- **修订版本**（0.x.y）：模板修复、措辞优化、bug 修复

每次发版必须：
1. 更新 `docs/CHANGELOG.md`
2. 同步更新 `phase3-verification.md` 中的 `skill_version` 字段
3. 同步更新 `SKILL.md` 中的「模板架构变更要点」版本号引用
