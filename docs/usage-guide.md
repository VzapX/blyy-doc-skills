# 使用指南

> 适用版本：v0.5.0+

## 概述

**blyy-skills-doc** 包含一个 AI 编程工具技能：**blyy-ai-docs**，用于生成和维护纯 AI 消费的 `ai-docs/` 索引。

技能根据 `MANIFEST.yaml` 状态自动分派三种模式，覆盖完整生命周期：

| 模式 | 触发条件 | 用途 |
|------|---------|------|
| **Mode A — Init** | `ai-docs/MANIFEST.yaml` 不存在 | 首次生成完整文档集 |
| **Mode B — Sync** | `last_synced_commit ≠ HEAD` | 增量同步，只重写过期段落 |
| **Mode C — Audit** | 显式调用或距上次 audit > 90 天 | 全量锚点验证 + 腐烂趋势检测 |

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

## Mode A — Init（首次生成）

### 适用场景

- 新项目或存量项目：希望让 AI 工具快速了解项目业务和代码入口
- 接手遗留项目：快速建立 AI 可消费的索引层

### 执行流程

```
Phase 0 — 断点续跑检测（自动触发）
  ├── 检测 ai-docs/.init-temp/master-task.yaml
  ├── 若存在 → 展示上次进度摘要，询问「继续 / 重新开始」
  └── 若不存在 → 正常进入 Phase A0

Phase A0 — 环境探测
  ├── 技术栈识别（依赖文件探测 + 架构布局检测）
  ├── 文件数检测（>500 → 读取 large-project-mode.md 进入大型项目模式）
  └── .gitignore 追加 ai-docs/

Phase A1 — 模块识别与分级
  ├── 架构布局检测（Layered vs Domain-driven）
  ├── 模块发现（Domain → 直接按目录；Layered → 跨层业务域提取）
  ├── 模块复杂度评分（6 分制）
  ├── 分级：Core (≥3) / Standard (1-2) / Lightweight (0)
  └── 分级结果呈现给用户确认

Phase A2 — 生成 code-queries.md
  └── 按栈写入 fd/rg 查询配方（不含执行结果）

Phase A3 — 子代理并行业务提取
  ├── Core 模块：5 类提取（业务定位 + 术语 + 流程 + 决策 + 依赖）
  ├── Standard 模块：3 类提取（业务定位 + 术语 + 依赖）
  ├── Lightweight 模块：跳过子代理，主 agent 直接写 1 行定位
  └── 产出写入 ai-docs/.init-temp/analysis-{MODULE}.md

Phase A4 — Pre-Fill Review Gate
  ├── 收集所有 T3 推测项
  ├── 按类型分组，一次性呈现给用户
  └── 确认 → T2 / 纠正 → T1 / 跳过 → UNVERIFIED

Phase A5 — 写文档 + MANIFEST
  ├── 写入 7 个文档文件（INDEX / modules / glossary / flows / decisions / code-queries / MANIFEST）
  ├── MANIFEST 含模块分级 + 锚点 sha + trend 初始行
  └── modules.md 按分级分组显示

Phase A6 — 自检
  └── 7 项自检（锚点验证 / 禁枚举 / 分级一致性 / TODO 格式 / 临时目录清理等）
```

### 三级事实分类（T1/T2/T3）

| 级别 | 含义 | 示例 |
|------|------|------|
| **T1** 确定性事实 | 直接从代码提取，可 grep 验证 | "OrderService 定义在 `src/Orders/OrderService.cs:12`" |
| **T2** 强推断 | ≥2 个独立代码信号支撑 | "`CreateOrderAsync` 创建订单"（函数名 + 返回 OrderEntity） |
| **T3** 弱推断 | 仅 1 个信号或间接信号 | "订单创建后会通知库存" |

T3 条目在 Phase A4 **Pre-Fill Review Gate** 统一呈现给用户批量确认，**禁止 AI 自由臆测写入**。

### 结构化 TODO 标记

无法锚定的内容使用结构化标记：

```html
<!-- TODO[p1, business-context]: 支付模块的对外承诺 -->
```

| 字段 | 取值 |
|------|------|
| **priority** | `p0`（必须）/ `p1`（阻塞可用性）/ `p2`（重要）/ `p3`（可延期） |
| **type** | `business-context` / `design-rationale` / `invariant-gap` |

Mode B 同步时会顺手检查相关 TODO 是否可填充。

### 产物文件结构

```
项目根目录/
└── ai-docs/                     ← gitignored，纯 AI 消费
    ├── INDEX.md                 ← 任务路由表 + 新鲜度概览
    ├── modules.md               ← 模块注册表（按分级分组）
    ├── glossary.md              ← 业务术语 ↔ 代码符号映射
    ├── flows.md                 ← 跨模块业务流程
    ├── decisions.md             ← 设计决策 + 不变式
    ├── code-queries.md          ← 按栈写入的 fd/rg 配方库
    └── MANIFEST.yaml            ← 状态契约
```

---

## Mode B — Sync（增量同步）

### 触发条件

`ai-docs/MANIFEST.yaml` 存在且 `last_synced_commit ≠ HEAD`。

### 执行流程

1. **Phase B1 — 主动映射 + 被动失效检测**
   - 读取 `resources/sync-matrix.md`，根据代码变更类型主动定位需更新的文档
   - 跑 4-tier 失效检测（文件存在性 → 文件 sha256 → 符号 body sha256 → 范围兜底）
   - 合并两种检测结果，去重后按优先级排序

2. **Phase B2 — STALE/REVIEW 处理 + TODO 填充**
   - STALE 段落：整段重写，读取当前代码生成新内容
   - REVIEW 段落：仅修正与代码矛盾的部分
   - 顺手检查相关 TODO 是否可填充

3. **Phase B3 — 模块变更 + 分级演化检测**
   - 新增模块 → 计算分级，补充到 modules.md
   - 已有模块 → 检测升级信号（仅升级方向）

4. **Phase B4 — 更新 MANIFEST + 自检**
   - 更新 `last_synced_commit`
   - 更新变更了的锚点 sha
   - 追加 history 事件

---

## Mode C — Audit（全量审计）

### 触发条件

显式调用（用户说"审计"/"audit"），或距上次 audit > 90 天。

### 执行流程

1. **Phase C0 — 全量锚点验证**
   - 对 MANIFEST 中每个锚点跑 4-tier 检测
   - 统计 STALE / REVIEW / FRESH 分布

2. **Phase C1 — 抽样 query 比对**
   - 随机执行 code-queries.md 中的配方，验证结果是否与文档描述一致

3. **Phase C1.5 — 模块分级全量复评**
   - 对所有模块重新评分
   - 与 MANIFEST 中记录的分级对比
   - 输出升级/降级建议（双向）

4. **Phase C2 — 触发 Mode B 处理 STALE**
   - 对发现的 STALE 段落执行 Mode B 的 B2 处理流程

5. **Phase C3 — 趋势追踪 + 报告**
   - 追加 `trend` 行到 MANIFEST
   - 腐烂信号检测：连续 3 次审计 TODO 上升 → 标记
   - 输出审计报告摘要

---

## 渐进式加载

为避免 SKILL.md 过大撑爆 AI 上下文，技能采用**渐进式加载**策略：

```
SKILL.md（~470 行，每次调用必加载）
    ├─ Phase A0/A1      → Read resources/tech-stack-matrix.md
    ├─ Phase A1          → Read resources/module-tiering.md
    ├─ 文件数 > 500     → Read resources/large-project-mode.md
    ├─ Phase A2          → Read resources/query-recipes.md
    ├─ Phase A3 子代理前 → Read resources/anti-hallucination.md
    ├─ Phase A5/B1/C0    → Read resources/anchor-extraction.md
    ├─ Phase B1          → Read resources/sync-matrix.md
    └─ Phase B1/C0       → Read resources/self-invalidation.md
```

每个 resource 文件顶部明确标注「何时读取」，AI 可按需精准加载。

---

## 常见问题

### 技能没有被 AI 工具识别？

1. 确认技能文件夹在正确位置（参见兼容性表格）
2. 确认 `SKILL.md` 文件存在且 YAML front matter 格式正确
3. 部分工具可能需要重启才能发现新技能

### ai-docs/ 会提交到 git 吗？

不会。`ai-docs/` 默认追加到 `.gitignore`，视为本地 AI 索引缓存。每个开发者按需重生成。

### 如何避免文档腐烂？

三种模式的累积效应：
1. **Mode B** 在每次代码变更时增量同步 + 递减 TODO
2. **Mode C** 定期全量验证锚点 + 检测腐烂趋势
3. **4-tier 自失效算法** 精确定位过期段落，只重写必要内容

### 如何跨会话恢复中断的初始化？

大型项目模式（>500 文件）支持跨会话恢复：

| 文件 | 用途 |
|------|------|
| `ai-docs/.init-temp/master-task.yaml` | 进度持久化 |
| `ai-docs/.init-temp/clarifications.yaml` | T3 澄清记录 |
| `ai-docs/.init-temp/analysis-*.md` | 子代理分析产出 |

新会话开始时 AI 自动检测上述文件，展示上次进度并询问是否继续。

### 什么时候该跑 Mode C？

- 项目经历了大量代码变更后
- 距上次审计超过 90 天
- 怀疑文档已严重偏移时

Mode C 会自动触发 Mode B 处理发现的过期内容，不需要分开运行。
