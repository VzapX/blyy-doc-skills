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

使用 `blyy-init-docs/resources/tech-stack-matrix.md` 一、确定性清点命令矩阵，对整个项目重新执行文件级清点：

```
📊 定期审计 — 全量清点:
- 实体/模型文件: {N} 个
- 控制器/路由文件: {M} 个
- 服务文件: {K} 个
- 配置文件: {L} 个
- 模块数量: {P} 个
```

## Step 2 — 文档比对

将清点结果与各文档中的条目数量逐一比对：

| 维度 | 代码清点 | 文档覆盖 | 差异 |
|------|---------|---------|------|
| 模块 (`modules.md`) | N | M | ±X |
| 实体 (`data-model.md`) | N | M | ±X |
| 控制器/API (`api-reference.md`) | N | M | ±X |
| 配置 (`config.md`) | N | M | ±X |
| 服务 (`code-map.md`) | N | M | ±X |

## Step 2.5 — 模块分级全量复评

> 对所有模块重新执行复杂度评分，与 `doc-maintenance.md` 基线中记录的 `module_tiers` 对比，发现级别漂移。

**执行步骤：**

1. **读取当前分级基线**：从 `docs/doc-maintenance.md` 基线快照的 `module_tiers` 字段中提取每个模块的级别
2. **全量重评分**：对每个模块执行复杂度评分（规则见 `blyy-init-docs/resources/doc-guide.md` 二、模块复杂度评分规则）：
   - 统计模块源文件数
   - 检查是否有 Entity/Model 文件
   - 检查是否有 Controller/Handler 文件
   - 统计反向依赖数
3. **比对输出**：

```
📊 模块分级复评（共 {N} 个模块）：

⬆️ 升级建议:
  - Payments: Standard(2分) → Core(4分) — 文件数 8→22, 新增 5 张表, 新增 3 个 Controller
  - Notifications: Lightweight(0分) → Standard(2分) — 文件数 2→7, 新增 1 个 Handler

⬇️ 降级建议:
  - LegacyImport: Standard(2分) → Lightweight(0分) — 文件数 12→3（大部分已删除）

✅ 级别不变: {M} 个模块
```

4. **用户确认**：将升降级建议一次性呈现，用户可逐个确认或批量操作
5. **执行变更**：
   - 升级：按防线 1 Step 2.5 的升级执行步骤操作
   - 降级：
     - **Core → Standard**：将 `modules/<m>/` 目录下各子文件内容合并为 `modules/<m>.md` 单文件；删除原目录；更新 `modules.md` 注册表分组和链接
     - **Standard → Lightweight**：将 `modules/<m>.md` 中的关键信息提取到 `modules.md` 对应的 Lightweight 内联段落；删除原单文件；更新 `modules.md`
     - **Core → Lightweight**：先 Core → Standard，再 Standard → Lightweight
6. **更新基线**：将新的分级结果写入 `doc-maintenance.md` 基线快照的 `module_tiers` 字段

## Step 3 — 详细检查

1. 检查 `code-map.md` 路径是否全部有效
2. 检查 `modules.md` 是否覆盖所有实际模块
3. 检查 `features.md` 是否反映最新功能
4. 检查 `CHANGELOG.md` 是否覆盖最新发布版本
5. 检查 `config.md` 是否与实际配置类一致
6. 检查模块级文档是否与模块代码一致
7. 检查 `data-model.md` 索引是否覆盖所有模块
8. 检查 `database/` 下的 schema 文件是否与实际表结构一致
9. 检查 `testing.md` 测试策略是否反映当前测试框架和覆盖率要求
10. 检查 `monitoring.md`（若存在）监控指标和告警规则是否与实际配置一致
11. 检查 `api-reference.md`（若存在）是否覆盖所有当前 API 端点

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
- 实体: {N1} → {N2} ({diff})
- 服务: {K1} → {K2} ({diff})
- TODO 总数: {X1} → {X2} ({diff})  ← 持续上升 = 文档腐烂
- UNVERIFIED 总数: {Y1} → {Y2} ({diff})
- 文档覆盖率: {C1}% → {C2}%
- 模块分级: Core {c1}→{c2}, Standard {s1}→{s2}, Lightweight {l1}→{l2}

🚨 腐烂信号:
- {如果 TODO 持续上升 3 次以上 → 列出问题文档}
- {如果某模块覆盖率连续下降 → 列出该模块}
- {如果模块分级变更未执行（Step 2.5 建议了升降级但用户未确认） → 列出滞后模块}
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

1. 更新「基线快照」YAML 块为本次结果（覆盖旧值），同时更新 `last_synced_commit`、`snapshot_date` 和 `module_tiers`
2. 在「历史快照趋势」表格末尾**追加一行**（不删除历史行），便于长期观察腐烂曲线（含分级分布列）
3. 若历史行超过 12 条，归档最早的几行到 `doc-maintenance.md` 末尾的「归档」段落，保持表格简洁
