# 从 v0.3.x 升级到 v1.0 指南

> v1.0.0 是从"全量文档生成器"到"业务知识文档 Skill"的重大定位调整。升级涉及**破坏性变更**。
>
> **是否应该升级？** 见本文最后一节的决策矩阵。

---

## 主要变更概览

### 文档类型

| 类型 | v0.3.x | v1.0 |
|------|--------|------|
| `ARCHITECTURE.md` | ✅ | ✅ |
| `modules.md` | ✅ | ✅（合并了 features） |
| `glossary.md` | ✅ | ✅（新增字段语义章节） |
| `core-flow.md` | ✅ | ✅ |
| `config.md` | ✅ | ✅（仅业务语义，不记值） |
| `DECISIONS.md` | ✅ | ✅ |
| `doc-maintenance.md` | ✅ | ✅ |
| `features.md` | ✅ | ❌（合并进 modules.md） |
| `code-map.md` | ✅ | ❌ |
| `api-reference.md` | ✅ | ❌ |
| `data-model.md` | ✅ | ❌（字段业务语义迁入 glossary） |
| `database/` | ✅ | ❌ |
| `deployment.md` | ✅ | ❌ |
| `runbook.md` | ✅ | ❌ |
| `monitoring.md` | ✅ | ❌ |
| `testing.md` | ✅ | ❌ |
| `modules/<m>/` 目录形态（Core） | ✅ | ❌（统一为单文件） |
| `modules/<m>.md` 单文件（Standard） | ✅ | ✅（所有模块） |

### 模块级变化

v0.3.x 的三级分化（Core/Standard/Lightweight）**全部移除**。所有模块统一为 `modules/<m>.md` 单文件，5 个章节：概述 / 职责与边界 / 依赖关系 / 核心业务流程 / 代码锚点。

### Skill 指令

- `SKILL.md` 的 `description` 字段重写
- `sync-matrix.md` / `phase3-verification.md` / `defense-line-3-audit.md` 同步收缩
- 基线快照 YAML 删除 `module_tiers` 字段

## 升级步骤

### 方案 A：保留旧文档，只升级 Skill（推荐给"已有稳定项目文档"的用户）

1. `git pull` 新版 skill 到 `.claude/skills/` 或 `.agents/skills/`
2. 旧项目中已生成的 `code-map.md`、`api-reference.md`、`data-model.md`、`deployment.md` 等**保留原地**——新 skill 不会主动删除它们
3. 新 skill 的 `blyy-doc-sync` 将**不再自动维护**这些文档——用户需自行决定是维持人工维护还是逐步淘汰
4. 对项目中的 `modules/<m>/` 完整目录形态（Core 模块），可**选择保留**，新 skill 不强制合并；`blyy-doc-sync` 会把它们视为单个模块的"目录形式"处理（但不会新生成此形态）

### 方案 B：完全对齐 v1.0 结构（推荐给"想彻底简化"的用户）

1. 在项目中运行：
   ```bash
   mkdir -p docs-legacy-v0
   mv docs/code-map.md docs-legacy-v0/ 2>/dev/null
   mv docs/api-reference.md docs-legacy-v0/ 2>/dev/null
   mv docs/data-model.md docs-legacy-v0/ 2>/dev/null
   mv docs/database docs-legacy-v0/ 2>/dev/null
   mv docs/deployment.md docs-legacy-v0/ 2>/dev/null
   mv docs/runbook.md docs-legacy-v0/ 2>/dev/null
   mv docs/monitoring.md docs-legacy-v0/ 2>/dev/null
   mv docs/testing.md docs-legacy-v0/ 2>/dev/null
   # features 的内容手工合并进 modules.md 的功能列表后
   mv docs/features.md docs-legacy-v0/ 2>/dev/null
   ```

2. 对 `modules/<m>/` 目录形态的模块，手工合并为单文件：
   - 创建 `modules/<m>.md`
   - 把目录内的 README.md / flow.md 的有价值内容合并进去（按新的 5 章节结构）
   - `code-map.md` / `data-model.md` / `api-reference.md` 中的**业务含义**迁移到 `glossary.md` 的字段语义章节或各处合适位置；纯代码结构信息丢弃
   - 移动整个目录到 `docs-legacy-v0/modules-old/<m>/` 备份

3. 在一次 AI 会话中让 blyy-doc-sync 防线 3 做一次全量审计，更新 `doc-maintenance.md` 基线

### 方案 C：完全重建（适合"旧文档已经很乱"的场景）

```bash
# 1. 备份整个 docs/
mv docs docs-legacy-full

# 2. 重新运行 blyy-init-docs
# 新 skill 会把 docs-legacy-full 作为 docs-old 处理，执行 Phase 1.5 结构化提取
```

## 应该升级吗？

| 当前状态 | 建议 |
|---------|------|
| 还在 v0.1 / v0.2 | ✅ 升级，收益明显 |
| v0.3.x，文档已稳定且低维护成本 | 🟡 评估后决定，不紧急 |
| v0.3.x，代码级文档（data-model 等）经常漂移或被忽视 | ✅ 升级，v1.0 的精简能缓解这些问题 |
| v0.3.x，团队已深度依赖 api-reference / data-model 等被砍文档 | ❌ 不要升级（或切换到专门工具如 Swagger） |
| 新项目 | ✅ 直接用 v1.0 |

## 遇到问题？

升级过程中遇到未列出的问题，请开 Issue。项目已进入维护模式，响应可能较慢。
