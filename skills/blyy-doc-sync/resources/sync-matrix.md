# 代码变更→文档更新映射矩阵

本文件是通用的同步矩阵，适用于任何项目。项目可通过 `docs/doc-maintenance.md` 覆盖或扩展本矩阵。

## 映射矩阵

| 代码变更类型 | 需更新的文档 | 更新内容 |
|-------------|-------------|---------|
| 新增源文件 | `docs/code-map.md` | 在对应表格加一行 |
| 重命名源文件 | `docs/code-map.md` | 更新所有引用 |
| 删除源文件 | `docs/code-map.md` | 移除对应行，扫描死引用 |
| 新增/修改配置项 | `docs/config.md` | 更新配置项列表 |
| 删除配置项 | `docs/config.md` | 移除对应行 |
| 组件关系变化 | `docs/ARCHITECTURE.md` | 更新架构图 |
| 数据流变化 | `docs/ARCHITECTURE.md` | 更新数据流图 |
| 新增模块 | `docs/modules.md` + 按评分创建对应文档 | 评分→注册表加一行 + 按级别创建文档（Core=目录/Standard=单文件/Lightweight=内联） |
| 删除模块 | `docs/modules.md` + 对应模块文档 | 移除注册表行 + 归档模块文档（无论何种级别） |
| 模块级别升级 | `docs/modules.md` + 模块文档 + `docs/doc-maintenance.md` | 转换文档形态（单文件→目录/内联→单文件）+ 更新注册表分组 + 更新基线 |
| 模块级别降级 | `docs/modules.md` + 模块文档 + `docs/doc-maintenance.md` | 合并文档形态（目录→单文件/单文件→内联）+ 更新注册表分组 + 更新基线 |
| 模块职责变更 | `docs/modules.md`（或模块级 `README.md`） | 更新职责描述 |
| 跨模块业务流程变化 | `docs/core-flow.md` | 更新流程图和说明 |
| 模块内业务流程变化 | `docs/modules/<name>/flow.md` | 更新模块内流程 |
| 数据库表结构变更（公共） | `docs/data-model.md` | 更新公共模型 |
| 数据库表结构变更（模块内） | `docs/modules/<name>/data-model.md` | 更新模块内模型 |
| 新增功能 | `docs/features.md` | 功能列表加一行 |
| 移除功能 | `docs/features.md` | 标记为已废弃 |
| 构建/运行/测试命令变化 | `AGENTS.md` + `README.md` | 更新命令部分 |
| 新增架构决策 | `docs/DECISIONS.md` | 新增 ADR 条目 |
| 发现新的运维故障模式 | `docs/runbook.md` | 新增事故剧本 |
| 发布新版本 | `CHANGELOG.md` | 新增版本条目 |
| 部署流程变化 | `docs/deployment.md` | 更新部署步骤 |
| API 接口变更（模块内） | `docs/modules/<name>/api-reference.md` + `docs/api-reference.md`（索引） | 更新模块接口列表 + 全局索引接口数 |
| API 认证/限流策略变更（全局） | `docs/api-reference.md` | 更新认证与限流章节 |
| API 限流策略变更（模块级） | `docs/modules/<name>/api-reference.md` | 更新模块限流规则 |
| 公共数据库表新增/修改 | `docs/data-model.md` + `docs/database/` | 更新公共模型 + 同步 schema 文件 |
| 模块数据库表新增/修改 | `docs/modules/<name>/data-model.md` + `docs/modules/<name>/database/` | 更新模块模型 + 同步 schema 文件 |
| 缓存 key/结构变更 | `docs/data-model.md` | 更新非关系型数据模型章节 |
| 消息/事件 schema 变更 | `docs/data-model.md` | 更新消息/事件 Schema 章节 |
| 测试策略/框架变更 | `docs/testing.md` | 更新测试分层和工具信息 |
| 测试覆盖率要求变更 | `docs/testing.md` | 更新覆盖率要求 |
| 监控指标变更 | `docs/monitoring.md`（若存在） | 更新核心指标表 |
| 告警规则变更 | `docs/monitoring.md`（若存在） | 更新告警规则表 |
| 新增/重命名核心实体类 | `docs/glossary.md` | 在「业务术语 ↔ 代码符号」表新增/更新映射行 |
| 新增/废弃业务术语 | `docs/glossary.md` | 更新术语表，废弃项标注 deprecated |
| 引入新缩写或别名 | `docs/glossary.md` | 在「同义词/缩写」段补充 |
| 新增/修改文档文件 | `docs/ARCHITECTURE.md` | 更新文档索引和 AI 任务路由表 |
| 模块入向/出向依赖变化 | `docs/modules/<name>/README.md` + `docs/modules.md` | 更新依赖表两端 |

## YAML 元数据更新规则

每次更新文档时，必须同步更新 YAML front matter 中的字段：

```yaml
---
last_updated: YYYY-MM-DD              # ← 更新为当天日期
last_synced_commit: <git rev-parse HEAD>  # ← 更新为当前 commit hash
code_anchors:                          # ← 若变更涉及文件移动/重命名，同步更新
  - src/path/to/dir
---
```

> `last_synced_commit` 是防线 1 增量识别变更范围的关键字段，**禁止省略更新**。

## 结构化 TODO/UNVERIFIED 标记格式

文档中的占位符必须使用结构化格式（详见 `blyy-init-docs/resources/doc-guide.md` 七、Front Matter 字段标准）：

```markdown
<!-- TODO[priority,type,owner]: 简述 -->
<!-- UNVERIFIED: 简述 -->
```

- `priority` ∈ `{p0, p1, p2, p3}`
- `type` ∈ `{fact, decision, owner, review}`
- `owner` 为责任人或 `unassigned`

防线 1 Step 4 按 priority 顺序处理；防线 3 Step 4 按上述维度聚合统计。

## 列表型字段「代码位置」列同步规则

所有文档中的列表型字段（实体表、文件清单、流程步骤、API 端点、配置项等）都包含「源文件」/「定义位置」/「代码位置」列，使用 `path/to/file.ext:line` 格式。

代码变更时必须同步：

| 变更 | 同步动作 |
|------|---------|
| 文件重命名/移动 | grep 所有文档中旧路径 → 替换为新路径 |
| 类/函数重命名 | 同上 |
| 行号大幅偏移（> 50 行） | 防线 3 时更新（防线 1 不强制，避免噪音） |
| 文件删除 | 该文件相关行从文档中移除，并扫描死引用 |

## 死引用扫描规则

以下操作后应扫描全部文档中的交叉引用：

1. 重命名/移动源文件
2. 重命名/移动文档文件
3. 删除模块

**扫描范围：**
- `docs/` 下所有 `.md` 文件
- `README.md`、`AGENTS.md`

**检查项：**
- Markdown 链接目标文件是否存在
- Mermaid 图中引用的组件名是否与代码一致
