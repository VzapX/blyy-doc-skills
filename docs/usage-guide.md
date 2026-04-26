# 使用指南

> 适用版本：v1.0.0+

## 概述

**blyy-skills-doc** 包含两个互补的 AI 编程工具技能：

- **blyy-init-docs**：项目文档初始化（Day 0，一次性）
- **blyy-doc-sync**：文档持续同步维护（Day 1+，每次代码变更）

两者通过 `docs/doc-maintenance.md` 中的**基线快照**进行数据衔接，形成完整的「初始化 → 实时同步 → 定期审计」闭环。

## 兼容的 AI 工具

| AI 工具 | 安装目录 | 触发方式 |
|---------|---------|---------|
| Gemini (Google) | `.agents/skills/` | 自动识别 SKILL.md |
| Codex (OpenAI) | `.agents/skills/` | 自动识别 SKILL.md |
| Cursor | `.agents/skills/` | 自动识别 SKILL.md |
| Claude Code | `.claude/skills/` | 自动识别 |

## 安装

参见 [README.md](../README.md) 的安装说明。

---

## 使用 blyy-init-docs

### 适用场景

- 新项目（0→1）：希望文档与代码同步成长
- 存量项目：可能存在过时的 `docs/` 目录，需要重新建立可信文档集
- 接手遗留项目：快速理解代码结构

### 渐进式加载（v0.3.0 架构）

为避免 SKILL.md 过大撑爆 AI 上下文，本技能采用**渐进式加载**策略：

```
SKILL.md（~470 行，每次调用必加载）
    ├─ 触发 Phase 1.5  → Read resources/legacy-extraction.md
    ├─ 触发大型项目模式 → Read resources/large-project-mode.md
    ├─ 进入 Phase 3    → Read resources/phase3-verification.md
    ├─ 子代理调度时    → Read resources/operational-conventions.md
    └─ Phase 1/2 填充时 → Read resources/doc-guide.md
```

每个 resource 文件顶部明确标注「何时读取」，AI 可按需精准加载。

### 执行流程

```
断点续跑检测（Phase 0 之前，自动触发）
  ├── 检测 docs/.init-temp/progress.md（标准模式进度文件）
  ├── 检测 .init-docs/master-task.md（大型项目模式进度文件）
  ├── 若存在 → 展示上次进度摘要，询问「继续 / 重新开始」
  └── 若不存在 → 正常进入 Phase 0

Phase 0 — 项目环境评估
  ├── 0.1 检测 AI 工具 /init 命令（Claude /init / Gemini AGENTS.md / ...）
  ├── 0.2 识别已存在的上下文文件（CLAUDE.md / AGENTS.md / .cursorrules）
  └── 0.3 评估项目规模（≤500 文件 → 标准模式 / >500 → 大型项目模式）

Phase 1 — 骨架生成
  ├── 旧文档迁移（docs/ → docs-old/）
  ├── 项目类型识别（backend-service / microservice / fullstack / cli-tool / ...）
  ├── 按 applicable_project_types 字段过滤模板（不必要的文档自动跳过）
  ├── 创建文档骨架
  └── 跳过清单确认（让用户决定是否追加生成）

Phase 1.5 — 旧文档结构化提取（仅当 docs-old/ 存在）
  ├── 旧文档清点 + 自动分类
  ├── 子代理并行穷举提取（架构/术语/配置/功能/其他）
  ├── 交叉校验（差异 > 20% 自动重新分发）
  └── 提取产物供 Phase 2 使用

Phase 2 — 代码分析填充（标准模式）
  ├── 确定性清单预扫描（fd/rg shell 命令，不依赖 AI）+ 初始化 progress.md
  ├── 子代理并行分析（按任务类型 + 按模块）
  ├── 每个条目标注 T1/T2/T3 事实级别（实体类字段同步提取注释→「说明」列）
  ├── Phase 2.5 填充前审查关卡：清单覆盖率检查 + T3 推测项批量用户澄清 + 澄清结果持久化
  └── 渐进式分层交付（Layer 1 核心 → Layer 2 模块 → Layer 3 汇总）
      每个 Layer 交付点更新 progress.md（断点续跑锚点）

Phase 2A-2D — 大型项目模式（替代 Phase 2）
  ├── 2A 项目轮廓扫描（不读业务代码）
  ├── 2B 锚点文件识别 + 模块清单 ✓ 用户检查点
  ├── 2C 子代理隔离上下文模块分析 ✓ 填充前审查关卡
  └── 2D 渐进式分层文档生成
  （进度持久化到 .init-docs/，可跨会话恢复）

Phase 3 — 最终检查与完成报告
  ├── 12 项确定性清单比对（模块/业务术语/用户可见功能/配置项/旧文档回收率）
  ├── 文档可信度统计（T1/T2/T3 占比）
  ├── 写入基线快照 YAML 块到 docs/doc-maintenance.md（供 doc-sync 防线 3 使用）
  └── 生成一次性 INIT-REPORT.md
```

### 三级事实分类（T1/T2/T3）

为避免 AI「编造内容」，本技能强制对每个填充的事实标注可信度级别：

| 级别 | 含义 | 示例 |
|------|------|------|
| **T1** 确定性事实 | 直接从代码、文件、配置提取 | 实体类的字段、配置键名、API 路由路径 |
| **T2** 高置信推断 | 从命名、框架模式、调用链推断 | "OrderService 应该负责订单创建" |
| **T3** 未验证推测 | 业务流程、设计意图等无法从代码确认 | "订单创建后是否通知仓库" |

T3 条目在 Phase 2.5 **填充前审查关卡**统一呈现给用户批量确认，**禁止 AI 自由臆测写入**。

### 结构化 TODO 标记

无法自动填充的内容统一使用结构化标记：

```html
<!-- TODO[priority,type,owner]: 简述 -->
```

| 字段 | 取值 |
|------|------|
| **priority** | `p0`（必须）/ `p1`（阻塞可用性）/ `p2`（重要）/ `p3`（可延期） |
| **type** | `business-context` / `design-rationale` / `ops-info` / `security-info` / `external-link` / `metric-baseline` |
| **owner** | `user` / `dev-team` / `ops-team` / `security-team` / 具体负责人 |

`blyy-doc-sync` 会按 priority 顺序检查这些标记，按 type 路由到对应处理策略。

### 生成的文档结构

```
项目根目录/
├── README.md
├── AGENTS.md / CLAUDE.md / .cursorrules    ← 按检测的 AI 工具（Phase 0.2）
├── CHANGELOG.md
├── CONTRIBUTING.md（按需）
├── SECURITY.md（按需）
└── docs/
    ├── ARCHITECTURE.md      ← 文档导航根节点 + AI 任务路由表（≤150 行）
    ├── modules.md           ← 模块注册表 + 功能列表 + 依赖关系
    ├── glossary.md          ← 业务术语 ↔ 代码符号 + 字段业务语义
    ├── core-flow.md         ← 跨模块核心业务流程
    ├── config.md            ← 配置项业务语义（不记值/默认）
    ├── DECISIONS.md         ← 架构决策记录（ADR）
    ├── doc-maintenance.md   ← 同步矩阵 + 基线快照 YAML + 历史趋势表
    ├── modules/
    │   └── <m>.md           ← 每个模块一个单文件（概述/职责/依赖/核心业务流程/代码锚点）
    └── INIT-REPORT.md       ← 一次性初始化报告（可在确认后删除）
```

> **v1.0 定位**：仅生成**业务知识文档**（AI 读代码读不出的业务语义层）。代码级文档（code-map / api-reference / data-model / database / testing 等）和运营级文档（deployment / runbook / monitoring）**不再生成**——AI 直接读源码或运维系统即可获取。

### 使用方式

在 AI 工具中直接对话即可触发：

```
请使用 blyy-init-docs 为本项目初始化文档
```

或等效表述：

```
帮我初始化项目文档
```

---

## 使用 blyy-doc-sync

### 三道防线

#### 防线 1：触发式同步 + 确定性验证（实时）

每次代码变更后立即执行：

1. **变更识别**：基于文档 front matter 的 `last_synced_commit` 增量识别
   - `git diff --name-only <last_synced_commit>..HEAD`
   - 若有 `code_anchors` 字段，仅过滤这些路径下的变更
2. **确定性扫描**：用 `fd`/`rg` 扫描受影响区域，与文档条目数对比，列出数量差异
3. **更新文档**：补充遗漏 / 清理过时引用 / 更新代码位置（`file:line`）
4. **更新 front matter**：`last_updated` → 当天日期，`last_synced_commit` → 当前 commit hash
5. **TODO 递减**：按 priority 顺序检查附近的 `<!-- TODO[…] -->` 是否能被本次变更填充

#### 防线 2：提交前验证（门禁）

完成一轮修改后用 shell 命令自检：

- 文档间交叉引用无死链
- `modules.md` 注册表 vs `docs/modules/` 目录是否一致
- 修改过的文档 `last_updated` 是否为当天
- ARCHITECTURE.md 文档索引是否覆盖所有文档

#### 防线 3：定期审计 — 兜底（每月/每季度）

本质上是 `blyy-init-docs` Phase 3 的独立运行版本：

1. **加载基线快照**：读取 `docs/doc-maintenance.md` 的 YAML 块和历史趋势表
2. **全量重扫**：执行确定性清点
3. **趋势对比**：与基线对比 → 输出腐烂信号（TODO 持续上升、覆盖率下降等）
4. **TODO 健康度报告**：按 priority/type/owner 聚合
5. **维护建议**：P1 紧急 / P2 建议 / P3 可选 / 低活跃文档清单
6. **写入新基线**：追加一行到历史趋势表（不删除旧行），覆盖更新基线 YAML

### 与 init-docs 的数据衔接

| 数据 | 位置 | 用途 |
|------|------|------|
| 基线快照 YAML | `docs/doc-maintenance.md` | 防线 3 趋势对比基准 |
| 历史快照趋势表 | `docs/doc-maintenance.md` | 防线 3 检测腐烂趋势 |
| `last_synced_commit` | 各文档 front matter | 防线 1 增量识别 |
| `code_anchors` | 各文档 front matter | 防线 1 过滤变更范围 |
| 结构化 TODO/UNVERIFIED 标记 | 各文档中 | 持续递减闭环 |

### 同步矩阵

| 代码变更 | 需更新的文档 |
|---------|------------|
| 新增/修改配置项 | `config.md` |
| 新增模块 | `modules.md` 注册表 + 创建 `modules/<m>.md` |
| 删除模块 | `modules.md` 移除 + 归档 `modules/<m>.md` |
| 实体/服务类变更 | `glossary.md` 术语表 + 字段业务语义 |
| 对外接口/CLI 命令变更 | `modules.md` 功能列表 |
| 跨模块流程变化 | `core-flow.md` |
| 模块依赖变化 | `modules/<m>.md` 依赖关系章节 |
| 架构决策 | `DECISIONS.md` |

完整矩阵见 `skills/blyy-doc-sync/resources/sync-matrix.md`，项目可在 `docs/doc-maintenance.md` 中覆盖。

---

## 常见问题

### 技能没有被 AI 工具识别？

1. 确认技能文件夹在正确位置（参见兼容性表格）
2. 确认 `SKILL.md` 文件存在且 YAML front matter 格式正确
3. 部分工具可能需要重启才能发现新技能

### 已有文档会被覆盖吗？

不会。`blyy-init-docs` 会先将已有 `docs/` 迁移至 `docs-old/`，再通过 Phase 1.5 穷举提取旧文档信息，作为 Phase 2 填充的输入。最终生成的新文档同时包含代码事实和旧文档信息，并标注来源（`[code-only]` / `[old-doc-only]` / `[both]`）。

### 两个技能可以只安装一个吗？

可以。它们独立工作，但推荐一起使用：
- 仅装 `init-docs`：完成一次性初始化后无后续维护机制
- 仅装 `doc-sync`：可工作于手动建立的文档体系（fallback 到 `resources/sync-matrix.md`），但无基线快照可对比

### 如何避免文档腐烂？

依赖三道防线的累积效应：
1. **防线 1** 在每次代码变更时实时同步 + 递减 TODO
2. **防线 2** 在提交前用 shell 命令兜底验证
3. **防线 3** 每月/每季度对比历史基线，识别长期腐烂趋势

### 如何跨会话恢复中断的初始化？

**标准模式**（≤500 文件）和**大型项目模式**均支持跨会话恢复：

| | 标准模式 | 大型项目模式 |
|-|---------|------------|
| 进度文件 | `docs/.init-temp/progress.md` | `.init-docs/master-task.md` |
| 澄清记录 | `docs/.init-temp/clarifications.md` | `.init-docs/clarifications.md` |
| 分析产出 | `docs/.init-temp/analysis-*.md` | `.init-docs/modules/<name>-analysis.md` |

新会话开始时 AI 自动检测上述文件，展示上次进度摘要并询问是否继续。用户选择继续时跳过已完成步骤，直接从中断的 Layer/模块恢复。

大型项目模式的 `.init-docs/` 在 Phase 3 完成后由用户决定是否保留（可作为历史参考）。

### init-docs 应该跑几次？

**只跑一次**。即使文档已严重腐烂，正确的恢复方式是跑 `blyy-doc-sync` 防线 3，而不是重新运行 init-docs（会触发旧文档迁移并打乱 `last_synced_commit` 链路）。
