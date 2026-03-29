---
name: blyy-doc-sync
description: 代码-文档持续同步维护工具，执行三道防线策略确保文档不落后于代码
---

# blyy-doc-sync — 代码-文档持续同步 Skill

## 概述

本 Skill 用于在**每次代码变更后**检查并同步更新项目文档，确保文档不落后于代码。它通过三道防线策略实现持续维护。

> **与 `blyy-init-docs` 的关系：**
> - `blyy-init-docs` = Day 0，一次性初始化完整文档集
> - `blyy-doc-sync` = Day 1+，持续维护文档与代码的一致性

## 前置条件

- 项目已通过 `blyy-init-docs` 或手动方式建立文档体系
- 项目内存在 `docs/doc-maintenance.md`（项目定制版），或由本 skill 的 `resources/sync-matrix.md` 提供通用 fallback

> **多工具兼容**：本 Skill 采用 SKILL.md 标准格式，兼容 Gemini、Codex、Cursor、Claude Code 等主流 AI 编程工具。

## 执行时机

AI 工具在执行**任何代码修改任务**后，应自动触发 blyy-doc-sync 检查。

## 三道防线

### 防线 1: 触发式同步（实时）

**每次代码变更后立即执行。**

1. 确认本次代码变更的类型
2. 查阅同步矩阵（优先读 `docs/doc-maintenance.md`，fallback 到 `resources/sync-matrix.md`）
3. 根据矩阵确定需更新的文档列表
4. 逐一更新受影响的文档
5. 更新文档的 YAML `last_updated` 为当天日期

**执行清单：**

```
□ 识别代码变更类型
□ 对照同步矩阵确认受影响文档
□ 更新每个受影响文档的对应章节
□ 更新 last_updated 元数据
□ 若新增模块 → 在 modules.md 注册 + 创建模块级文档
□ 若删除模块 → 从 modules.md 移除 + 归档模块级文档
```

### 防线 2: 提交前验证（门禁）

**在完成一轮代码+文档修改后执行。**

```
□ code-map.md 中所有文件路径存在（无死引用）
□ config.md 中所有配置项与代码一致
□ 修改过的文档 last_updated 已更新
□ 无断链引用（文档间交叉引用有效）
□ 新增模块已在 modules.md 注册
□ data-model.md 模块索引完整
□ database/ schema 文件与代码中的表结构一致
□ ARCHITECTURE.md 文档索引覆盖所有文档
□ 新增/修改的 API 已在 api-reference.md 中更新（若存在）
```

### 防线 3: 定期审计（兜底）

**建议每月/每季度执行一次。**

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

## 资源文件

| 文件 | 用途 |
|------|------|
| `resources/sync-matrix.md` | 通用代码变更→文档更新映射矩阵（跨项目复用） |

## 与 doc-maintenance.md 的优先级

```
读取优先级：
1. 项目内 docs/doc-maintenance.md     ← 项目定制版（优先）
2. 本 skill 的 resources/sync-matrix.md ← 通用 fallback
```

## 注意事项

- 防线 1 是核心，每次代码变更必须执行
- 防线 2 用于自检，确保无遗漏
- 防线 3 是最后兜底，弥补日常遗漏
- 文档更新应与代码修改在**同一任务**中完成，不要拆分为独立任务
- 日常文档维护使用 `blyy-doc-sync`，项目初始化使用 `blyy-init-docs`
