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
| 新增模块 | `docs/modules.md` + `docs/modules/<name>/` | 注册表加一行 + 创建模块级文档 |
| 删除模块 | `docs/modules.md` + `docs/modules/<name>/` | 移除注册表行 + 归档模块级文档 |
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
| API 接口变更 | `docs/api-reference.md` | 更新接口列表 |
| API 认证/限流策略变更 | `docs/api-reference.md` | 更新认证与限流章节 |
| 公共数据库表新增/修改 | `docs/data-model.md` + `docs/database/` | 更新公共模型 + 同步 schema 文件 |
| 模块数据库表新增/修改 | `docs/modules/<name>/data-model.md` + `docs/modules/<name>/database/` | 更新模块模型 + 同步 schema 文件 |
| 缓存 key/结构变更 | `docs/data-model.md` | 更新非关系型数据模型章节 |
| 消息/事件 schema 变更 | `docs/data-model.md` | 更新消息/事件 Schema 章节 |
| 测试策略/框架变更 | `docs/testing.md` | 更新测试分层和工具信息 |
| 测试覆盖率要求变更 | `docs/testing.md` | 更新覆盖率要求 |
| 监控指标变更 | `docs/monitoring.md`（若存在） | 更新核心指标表 |
| 告警规则变更 | `docs/monitoring.md`（若存在） | 更新告警规则表 |
| 新增/修改文档文件 | `docs/ARCHITECTURE.md` | 更新文档索引 |

## YAML 元数据更新规则

每次更新文档时，必须同步更新 YAML front matter 中的 `last_updated` 字段：

```yaml
---
last_updated: YYYY-MM-DD  # ← 更新为当天日期
---
```

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
