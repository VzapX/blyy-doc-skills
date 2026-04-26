# 代码变更→文档更新映射矩阵

本文件是通用的同步矩阵，适用于任何项目。项目可通过 `docs/doc-maintenance.md` 覆盖或扩展本矩阵。

## 映射矩阵

| 代码变更类型 | 需更新的文档 | 更新内容 |
|-------------|-------------|---------|
| 新增/删除模块 | `docs/modules.md` + `modules/<m>.md` | 注册表加减 + 创建/归档单文件 |
| 模块职责/边界变更 | `modules/<m>.md` | 更新职责与边界章节 |
| 跨模块业务流程变化 | `docs/core-flow.md` | 更新流程图与说明 |
| 模块内业务流程变化 | `modules/<m>.md` 的「核心业务流程」章节 | 更新模块内流程 |
| 新增/移除用户可见功能 | `docs/modules.md` 的功能列表 | 功能表加/改一行（移除项标注 deprecated） |
| 配置项的业务语义变更 | `docs/config.md` | 更新说明列（不记值/默认/类型） |
| 新增架构决策 | `docs/DECISIONS.md` | 新增 ADR 条目 |
| 新增/重命名核心实体类 | `docs/glossary.md` | 在「业务术语 ↔ 代码符号」表新增/更新映射行 |
| 新增/废弃业务术语 | `docs/glossary.md` | 更新术语表，废弃项标注 deprecated |
| 数据库字段增加/改变业务含义 | `docs/glossary.md` 的「字段业务语义」章节 | 新增/更新字段业务含义条目 |
| 引入新缩写或别名 | `docs/glossary.md` | 在「同义词/缩写」段补充 |
| 模块入向/出向依赖变化 | `modules/<m>.md` 的「依赖关系」章节 + `docs/modules.md` 模块间依赖表 | 更新依赖表两端 |
| 构建/运行/测试命令变化 | `AGENTS.md` + `README.md` | 更新命令部分 |
| 新增/修改文档文件 | `docs/ARCHITECTURE.md` | 更新文档索引和 AI 任务路由表 |
| 发布新版本 | `CHANGELOG.md` | 新增版本条目 |

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

文档中的占位符必须使用结构化格式：

```markdown
<!-- TODO[priority,type,owner]: 简述 -->
<!-- UNVERIFIED: 简述 -->
```

`priority` / `type` / `owner` 的完整枚举值定义在 `blyy-init-docs/resources/front-matter-spec.md` 七.4，**本文件不重复定义以避免两处失真**（v1.0.0 起从 doc-guide.md 拆分）。

防线 1 Step 4 按 priority 顺序处理；防线 3 Step 4 按三维度聚合统计。

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
