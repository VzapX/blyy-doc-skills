# 防线 3 — 定期审计详细流程

> **何时读取本文件**：执行防线 3（每月/每季度的定期审计）时。
>
> 防线 1/2（实时同步与提交前门禁）不需要读取本文件，相关流程在 SKILL.md 中已完整。

## 概述

防线 3 本质上是 `blyy-init-docs` Phase 3 的独立运行版本。它重新执行确定性清点，与 `docs/doc-maintenance.md` 中的**基线快照**进行**趋势对比**，发现日常同步遗漏的差异和文档腐烂趋势。

执行结束后追加一行新基线，长期可见文档健康度曲线。

## Step 0 — 加载基线快照

读取 `docs/doc-maintenance.md` 的「基线快照」YAML 块和「历史快照趋势」表格，提取：
- `inventory.*` — 上次记录的代码清点基线
- `markers.todo_total` / `unverified_total` — 上次记录的标记总数
- `last_synced_commit` — 上次同步的 commit hash
- `layer_distribution` — 上次记录的文档分层数量

若 `doc-maintenance.md` 中无基线快照（项目未通过 init-docs 初始化），跳到 Step 1 直接执行全量扫描，扫描后**首次写入基线快照**。

## Step 1 — 全量确定性重扫

使用 `blyy-init-docs/resources/tech-stack-matrix.md` 一、确定性清点命令矩阵，对整个项目重新执行文件级清点（v1.0 只关注业务知识相关清单）：

```
📊 定期审计 — 全量清点:
- 模块数量: {P} 个
- 实体/服务类（业务术语候选）: {N} 个
- 用户可见功能（控制器/CLI/页面入口）: {F} 个
- 配置项: {L} 个
```

## Step 2 — 文档比对

将清点结果与各文档中的条目数量逐一比对：

| 维度 | 代码清点 | 文档覆盖 | 差异 |
|------|---------|---------|------|
| 模块 (`modules.md` 注册表) | P | M | ±X |
| 业务术语 (`glossary.md`) | N | M | ±X |
| 用户可见功能 (`modules.md` 功能列表) | F | M | ±X |
| 配置项 (`config.md`) | L | M | ±X |

## Step 3 — 详细检查

1. 检查 `modules.md` 注册表是否覆盖所有实际模块；功能列表是否反映最新功能
2. 检查 `glossary.md` 业务术语表是否覆盖所有核心实体/服务类；字段业务语义表是否反映最新业务含义变化
3. 检查 `config.md` 配置项业务语义是否与实际配置类一致（不检查值/默认/类型——这些直接读代码）
4. 检查 `modules/<m>.md` 5 章节内容是否与模块代码一致
5. 检查 `core-flow.md` 跨模块流程是否与代码调用链一致
6. 检查 `DECISIONS.md` 是否覆盖近期重要架构变更
7. 检查 `CHANGELOG.md` 是否覆盖最新发布版本

## Step 4 — TODO/UNVERIFIED 健康度报告（按优先级）

按结构化 TODO 的 `priority` 分组统计所有文档中残留的标记：

```
📋 文档健康度（按优先级）:
- TODO[p0]: {N0} 个 — 必须立即处理
- TODO[p1]: {N1} 个 — 阻塞文档可用性
- TODO[p2]: {N2} 个
- TODO[p3]: {N3} 个 — 可延期
- UNVERIFIED: {K} 个（其中 {J} 个现在可从代码确认）

按类型分组:
- business-context: {N1} 个 — 等待业务上下文补充
- design-rationale: {N2} 个 — 等待 ADR/设计决策
- ops-info: {N3} 个 — 等待运维信息
- security-info: {N4} 个 — 等待安全团队
- external-link: {N5} 个 — 等待外部 URL
- metric-baseline: {N6} 个 — 等待指标基线

按 owner 聚合:
- user: {N} 个
- dev-team: {M} 个
- ops-team: {K} 个
- security-team: {L} 个

文档总覆盖率: {X}%（清点基线 vs 文档条目）
```

## Step 5 — 趋势对比与维护建议

将本次扫描与基线快照对比，识别**腐烂趋势**：

```
📊 趋势对比（vs 上次基线 {snapshot_date}, commit {short_hash}）:
- 模块: {P1} → {P2} ({diff})
- 业务术语: {N1} → {N2} ({diff})
- 用户可见功能: {F1} → {F2} ({diff})
- TODO 总数: {X1} → {X2} ({diff})  ← 持续上升 = 文档腐烂
- UNVERIFIED 总数: {Y1} → {Y2} ({diff})
- 文档覆盖率: {C1}% → {C2}%

🚨 腐烂信号:
- {如果 TODO 持续上升 3 次以上 → 列出问题文档}
- {如果某模块覆盖率连续下降 → 列出该模块}
```

输出维护建议：

```
📊 维护优先级建议:
- P1 紧急修复: {列出数量差异 > 20% 的文档}
- P2 建议更新: {列出有残留 TODO[p0/p1] 且代码已实现的文档}
- P3 可选清理: {列出 UNVERIFIED 标记可确认的文档}
- 低活跃文档: {列出 last_updated 超过 90 天且无代码变更关联的文档}
```

## Step 6 — 写入新基线快照

将本次扫描结果**追加**到 `docs/doc-maintenance.md`：

1. 更新「基线快照」YAML 块为本次结果（覆盖旧值），同时更新 `last_synced_commit`、`snapshot_date`
2. 在「历史快照趋势」表格末尾**追加一行**（不删除历史行），便于长期观察腐烂曲线
3. 若历史行超过 12 条，归档最早的几行到 `doc-maintenance.md` 末尾的「归档」段落，保持表格简洁
