# 架构说明

> 本文档描述 **blyy-doc-skills 仓库自身**的架构。如果你只是想*使用*技能，请看 [usage-guide.md](usage-guide.md)；想*扩展*它，请看 [customization.md](customization.md)。

## 仓库结构

```
blyy-doc-skills/
├── README.md                      ← 仓库入口（双语），含安装说明
├── LICENSE                        ← MIT
├── install.sh                     ← Linux/macOS 安装脚本
├── install.ps1                    ← Windows 安装脚本
├── docs/                          ← 本仓库的项目文档
│   ├── usage-guide.md             ← 使用指南
│   ├── customization.md           ← 自定义扩展
│   ├── architecture.md            ← 架构说明（本文件）
│   └── CHANGELOG.md               ← 变更日志
└── skills/
    └── blyy-ai-docs/              ← 纯 AI 索引技能（三模式：Init/Sync/Audit）
        ├── SKILL.md               ← 单入口三模式分派
        ├── resources/
        │   ├── tech-stack-matrix.md      ← 技术栈探测 + 架构布局检测 + 跨层业务域提取
        │   ├── query-recipes.md          ← 8 大栈 fd/rg 命令库
        │   ├── anti-hallucination.md     ← T1/T2/T3 + 锚点强制 + 禁枚举 + 结构化 TODO
        │   ├── anchor-extraction.md      ← 8 语言符号定位 + body 提取
        │   ├── self-invalidation.md      ← 4-tier 失效检测算法
        │   ├── module-tiering.md         ← 模块复杂度分级（6 分制 → 分析深度映射）
        │   ├── large-project-mode.md     ← 大型项目模式（>500 文件分阶段执行）
        │   └── sync-matrix.md            ← 同步矩阵（代码变更 → 文档更新映射）
        └── templates/
            ├── INDEX.md.template              ← Hub：路由 + 模块注册 + 流程目录 + 全局决策
            ├── module-detail.md.template      ← 单文件模式的模块详情
            ├── module-index.md.template       ← 目录溢出模式的 _index.md
            ├── code-queries.md.template
            └── MANIFEST.yaml.template
```

## blyy-ai-docs 职责

| 维度 | 说明 |
|------|------|
| 输出目录 | `ai-docs/`（默认 gitignore） |
| 目标读者 | **仅 AI** |
| 触发时机 | 任何时间，按 MANIFEST 状态自动分派 |
| 主要目标 | 生成不重复代码事实、自失效的 AI 索引 |
| 主要产出 | INDEX.md（Hub）+ modules/{slug}.md（Spoke）+ code-queries.md + MANIFEST.yaml |
| 文件结构 | **Hub-and-Spoke**：INDEX.md 路由中心 + 每模块独立详情文件；大模块溢出为目录 |
| 反幻觉机制 | 强制 `[file#Symbol]` 锚点 + UNVERIFIED 包裹 + 禁枚举铁律 + Pre-Fill Review Gate |
| 自失效机制 | 4-tier（file 存在性 / sha256 / body sha256 / 范围） |
| 模块分级 | Core/Standard/Lightweight 控制**分析深度** + **文件存在性**（Lightweight 无独立文件） |
| 布局演化 | Mode B Phase B3.5 / Mode C Phase C1.7 自动检测 file↔directory 转换（滞回区间防震荡） |

**blyy-ai-docs 内部状态契约**（v0.6.0）：

- `ai-docs/MANIFEST.yaml.ai_docs_version` — 文档格式版本（v2 = Hub-and-Spoke）
- `ai-docs/MANIFEST.yaml.last_synced_commit` — 上次同步后的 HEAD，Mode B 据此做 `git diff` 增量
- `ai-docs/MANIFEST.yaml.anchors[*].sha256` — 每个被文档引用的文件的 `git hash-object` 结果
- `ai-docs/MANIFEST.yaml.anchors[*].symbols[*].body_sha256` — 符号体归一化后的 hash，符号级失效判定核心
- `ai-docs/MANIFEST.yaml.anchors[*].docs` — 反向锚点索引（精确到模块文件，如 `modules/orders.md`）
- `ai-docs/MANIFEST.yaml.modules[*].tier` / `complexity_score` — 模块复杂度分级
- `ai-docs/MANIFEST.yaml.modules[*].detail_file` / `layout` / `overflow_files` — 模块文件布局追踪
- `ai-docs/MANIFEST.yaml.trend` — 审计趋势追踪（连续 3 次 TODO 上升 → 腐烂信号）
- `ai-docs/MANIFEST.yaml.history` — 事件追加日志（init / sync / audit / layout-upgrade / layout-downgrade）

## 渐进式加载架构

### 问题

AI Skill 的入口文件 `SKILL.md` 在每次调用时都会被完整加载到上下文。如果包含全部细节，会撑爆上下文窗口（特别是对 Haiku/Sonnet 等小窗口模型）。

### 解决方案

将 SKILL.md 拆分为：
- **常驻部分**（SKILL.md）— 核心流程概述、触发条件判断、关键铁律摘要
- **按需部分**（resources/*.md）— 各 Phase 的详细执行流程、模板、表格

每个 resource 文件顶部明确标注「**何时读取**」触发条件，AI 仅在满足条件时通过 Read 工具加载。

### 加载时机映射

```
blyy-ai-docs/SKILL.md（~470 行，每次必加载；含三模式分派逻辑）
    │
    ├─ Phase 0 断点续跑检测
    │     └─ 检测 .init-temp/master-task.yaml
    │
    ├─ Mode A Phase A0/A1 技术栈与模块识别
    │     ├─ Read resources/tech-stack-matrix.md（架构布局检测 + 跨层业务域提取）
    │     └─ Read resources/module-tiering.md（模块复杂度分级评分）
    │
    ├─ Mode A Phase A0 文件数 > 500 → 大型项目模式
    │     └─ Read resources/large-project-mode.md（分阶段执行 + 跨会话持久化）
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
    ├─ Mode B Phase B1 主动映射
    │     └─ Read resources/sync-matrix.md
    │
    ├─ Mode B Phase B1 / Mode C Phase C0 失效检测
    │     └─ Read resources/self-invalidation.md
    │
    └─ Mode C Phase C1.5 模块分级全量复评
          └─ Read resources/module-tiering.md
```

### 设计铁律

1. **SKILL.md 必须自洽** — 即使 AI 不展开任何 resource，也能完成基础执行。SKILL.md 中保留每个 resource 的核心摘要 + 关键铁律
2. **资源文件清单必须明示「何时读取」** — SKILL.md 的「资源文件」表格采用三列结构（文件 / 何时读取 / 用途），让 AI 一眼判断是否需加载
3. **避免循环引用** — resource 文件之间不互相 Read，仅由 SKILL.md 路由
4. **资源文件单一职责** — 每个文件聚焦一个 Phase 或一类规范，命名需体现触发场景

## 模块复杂度分级体系

模块按 6 分制评分，控制**分析深度**和**文件存在性**：

| 级别 | 条件（评分） | 分析深度 | ai-docs 产物 |
|------|------------|---------|-------------|
| **Core** | ≥ 3 分 | 子代理全量业务分析（5 类） | `modules/{slug}.md` 或溢出为 `modules/{slug}/` 目录 |
| **Standard** | 1-2 分 | 适度分析（3 类） | `modules/{slug}.md`（通常单文件） |
| **Lightweight** | 0 分 | 主 agent 直接写 1 行业务定位 | 无独立文件，仅 INDEX.md 单行 |

**评分信号**（全部基于 shell 命令，不依赖 AI 判断）：源文件数 >15（+2）/5-15（+1）、有 Entity/Model 文件（+1）、有 Controller/Handler 文件（+1）、被 ≥3 模块依赖（+1）。

**动态复评闭环**：
- **Mode B Phase B3**：新模块计算分级；已有模块检测升级信号（仅升级方向）→ 链式触发 **Phase B3.5 布局演化检测**
- **Mode C Phase C1.5**：全量复评（升降双向）→ **Phase C1.7 布局演化 + 子模块拆分建议**

## 多 AI 工具兼容策略

本仓库不针对单一 AI 工具优化，而是采用所有主流工具都遵守的 SKILL.md 标准格式：

```yaml
---
name: blyy-ai-docs
description: 一句话描述触发时机
---

# 技能正文 markdown
```

不同工具的安装路径由 `install.sh` / `install.ps1` 自动检测：

| AI 工具 | 安装目录 |
|---------|---------|
| Gemini / Codex / Cursor | `.agents/skills/` |
| Claude Code | `.claude/skills/` |

## 版本演进策略

- **主版本**（1.x）：当前为 0.x，接口可能不兼容变更
- **次版本**（0.x.0）：新增 Phase / 新增 resource 文件 / SKILL.md 重构
- **修订版本**（0.x.y）：模板修复、措辞优化、bug 修复

每次发版必须：
1. 更新 `docs/CHANGELOG.md`
2. 同步更新 SKILL.md 中的版本号引用
