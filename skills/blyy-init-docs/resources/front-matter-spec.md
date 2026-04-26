# 占位符、YAML Front Matter 与结构化 TODO 标准

本文档从 `doc-guide.md` 六、七 拆分而来，集中存放**文档模板占位符清单、YAML Front Matter 字段标准、AI 提示块与结构化 TODO 格式**。

> **本文件是结构化 TODO `type` 枚举的唯一权威来源。** `blyy-doc-sync/resources/sync-matrix.md` 与 `blyy-doc-sync/SKILL.md` 的防线 1 Step 4 路由逻辑均引用本文件七.4 的枚举值，不允许重复定义以避免漂移。

---

## 一、文档模板占位符说明

| 占位符 | 含义 |
|--------|------|
| `{{PROJECT_NAME}}` | 项目名称 |
| `{{DATE}}` | 当前日期（YYYY-MM-DD） |
| `{{MODULE_NAME}}` | 模块名称 |
| `{{TABLE_NAME}}` | 数据库表名 |
| `{{RUNTIME}}` | 运行时（如 .NET 8、Node.js 20） |
| `{{VERSION}}` | 运行时版本 |
| `{{BUILD_COMMAND}}` | 构建命令 |
| `{{RUN_COMMAND}}` | 运行命令 |
| `{{TEST_COMMAND}}` | 测试命令 |
| `{{INSTALL_COMMAND}}` | 安装命令 |
| `{{PUBLISH_COMMAND}}` | 发布命令 |
| `{{INDENT_STYLE}}` | 缩进风格 |
| `{{LANGUAGE}}` | 编程语言 |
| `{{FRAMEWORK}}` | 框架 |
| `{{PROJECT_STRUCTURE}}` | 项目目录结构 |
| `{{DATABASE_TYPE}}` | 数据库类型（如 PostgreSQL、MongoDB、SQLite） |
| `{{DEPLOYED_URL}}` | 部署访问地址（各环境） |
| `{{MONITORING_DASHBOARD_URL}}` | 监控仪表盘地址 |
| `{{LOG_SYSTEM}}` | 日志聚合系统（如 ELK、Loki、DataDog） |
| `{{RELEASE_CADENCE}}` | 发布节奏（如 每周、每两周、持续部署） |
| `{{SKILL_VERSION}}` | 当前 Skill 版本号（由 Phase 3 从 `skills/blyy-init-docs/VERSION` 读取替换） |
| `<!-- Phase 2 自动填充 -->` | Phase 2 阶段由代码分析自动填充 |
| `<!-- TODO[priority,type,owner]: xxx -->` | 需要人工补充的内容（结构化 TODO，详见七.4） |
| `<!-- UNVERIFIED: xxx -->` | T3 推测性内容，待用户确认 |
| `<!-- AI-READ-HINT ... -->` | 文档头部 AI 阅读提示块（详见七.3） |
| `<!-- AI-RULE: xxx -->` | 针对 AI 的硬约束（详见七.3） |

---

## 二、YAML Front Matter 字段标准

> 所有 `docs/*.md` 与 `docs/modules/<m>/*.md` 模板的 YAML front matter 必须遵循下方的标准字段集。
> 字段分为两类：**结构性字段**（影响 AI 路由与渐进式披露）和**维护性字段**（影响 doc-sync 同步）。

### 七.1 标准字段集

```yaml
---
# === 维护性字段 ===
last_updated: 2026-04-08          # 文档最后修改日期（YYYY-MM-DD）
last_synced_commit: a1b2c3d        # 最后一次与代码同步时的 Git short SHA（doc-sync 防线 3 用于趋势对比）

# === 结构性字段 ===
audience: ai-and-human             # 取值: ai-only | human-only | ai-and-human
read_priority: 2                   # 取值: 1-4，对应 Layer 1-3 渐进式披露层级（4 = 按需查阅，不属于任何交付层）
max_lines: 200                     # 体积硬约束。doc-sync 防线 2 在超标时告警，提示拆分
parent_doc: ARCHITECTURE.md        # 文档树上的父节点，根节点为空
code_anchors:                      # 本文档对应的代码路径（用于 AI 反向定位）
  - src/Modules/Orders/
  - src/Services/OrderService.cs
applicable_project_types:          # 适用的项目类型，用于 Phase 1 骨架按 front matter 自动过滤
  - backend-service
  - microservice
  - fullstack

# === 同步触发器 ===
change_triggers:
  - 业务流程变化
  - 模块边界调整
---
```

### 七.2 字段释义

| 字段 | 类型 | 必填 | 取值 | 用途 |
|------|------|------|------|------|
| `last_updated` | date | 是 | YYYY-MM-DD | 最后修改日期。doc-sync 每次更新必须刷新 |
| `last_synced_commit` | string | 是 | Git short SHA（7 位）或 `init` | 与代码同步基线。doc-sync 防线 3 据此判断"自上次同步是否真有相关变更" |
| `audience` | enum | 是 | `ai-only` / `human-only` / `ai-and-human` | AI 是否应读取此文档 |
| `read_priority` | int | 是 | 1 / 2 / 3 / 4 | Layer 层级。1 = 核心入口（每次都读），4 = 按需查阅 |
| `max_lines` | int | 是 | 推荐: 入口型 ≤150, 模块型 ≤400, 参考型 ≤500 | 体积上限。超标告警 |
| `parent_doc` | path | 否 | 相对路径或为空 | 文档树父节点，构建文档导航关系 |
| `code_anchors` | list | 否 | 文件/目录路径 | 反向定位代码用 |
| `applicable_project_types` | list | 否 | 见下表 | Phase 1 骨架按此过滤生成 |
| `change_triggers` | list | 是 | 自然语言描述 | 触发文档更新的事件清单 |

**项目类型枚举值**（与 `doc-guide.md` 五、项目类型适配指南对齐）：
- `backend-service` — 标准后端服务
- `microservice` — 微服务
- `fullstack` — 全栈项目
- `frontend-spa` — 前端 SPA
- `cli-tool` — CLI 工具
- `library` — 库
- `data-pipeline` — 数据管道/ETL
- `infrastructure` — 基础设施

**`audience` 字段使用规则：**
- `ai-only` — 只供 AI 工具使用，人类无需阅读（如 `doc-maintenance.md`）
- `human-only` — 只供人类阅读（如 `CONTRIBUTING.md` 部分章节）
- `ai-and-human` — 默认值，两者都需要

### 七.3 文档头部 AI 提示块（AI-READ-HINT）

每个 `read_priority ≥ 2` 的模板都应在 H1 标题后紧跟一个 AI 提示块，告诉 AI 何时读、何时跳过：

```markdown
# 业务术语 ↔ 代码符号映射

<!-- AI-READ-HINT
PURPOSE: 业务术语 ↔ 代码符号映射 + 字段业务语义。
READ-WHEN: 用户用业务术语提问或需要理解某个字段的业务含义时。
SKIP-WHEN: 用户已直接给出代码符号或文件名，且不涉及字段语义。
PAIRED-WITH: modules.md（功能列表）, modules/<m>.md（模块业务文档）
-->
```

针对模板内某个章节的硬约束，使用 `AI-RULE`：

```markdown
```mermaid
%% AI-RULE: 此图必须基于实际入口点分析生成。若无法生成 ≥3 个真实节点，删除整个代码块。
```
```

### 七.4 结构化 TODO 标记（唯一权威枚举来源）

旧的 `<!-- TODO: xxx -->` 升级为结构化格式（**位置参数，逗号分隔，无 `key=` 前缀**，便于正则解析）：

```markdown
<!-- TODO[p1,design-rationale,user]: 请补充订单创建后的通知策略 -->
```

格式：`<!-- TODO[<priority>,<type>,<owner>]: <简述> -->`

| 字段 | 取值 | 含义 |
|------|------|------|
| `priority` | `p0` / `p1` / `p2` / `p3` | p0 = 阻塞文档使用（必须立即处理），p1 = 阻塞文档可用性，p2 = 重要补充，p3 = 锦上添花 |
| `type` | 见下表 | TODO 的内容类型，决定 doc-sync 的处理路由 |
| `owner` | `user` / `dev-team` / `ops-team` / `security-team` / 具体负责人名 | 应由谁补充 |

**type 枚举值**：

| 值 | 含义 | doc-sync 处理策略 |
|----|------|------------------|
| `business-context` | 业务上下文（流程、规则、领域知识） | 防线 1 Step 4 检查代码事实，能填则填；否则按 owner 分组提问 |
| `design-rationale` | 设计决策与理由 | 等待 ADR 或代码注释支撑；满足则升级为正式条目 |
| `ops-info` | 运维操作信息（备份、剧本、维护窗口） | 等待 ops-team 输入或运维代码补充 |
| `security-info` | 安全相关信息（漏洞处理、密钥轮换） | 等待 security-team 输入；防线 1 不自动填充 |
| `external-link` | 外部资源 URL（仪表盘、文档站、注册中心） | 等待用户提供链接 |
| `metric-baseline` | 指标基线值（SLA、性能基准） | 等待实测或配置补充 |

doc-sync 防线 1 Step 4 按 `priority` 顺序处理（p0 → p3），按 `type` 路由处理策略并按 `owner` 分组提问；防线 3 Step 4 按 `priority`/`type`/`owner` 三维度聚合统计。

### 七.5 体积约束（max_lines）的执行

- Phase 3 验证时统计每个文档实际行数，超标列入完成报告
- doc-sync 防线 2（提交前验证）执行 `wc -l docs/**/*.md` 与 front matter 中的 `max_lines` 比对，超标即告警
- 超标处理建议：拆分为多个小文档 + 在原文档保留索引
