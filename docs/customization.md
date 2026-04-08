# 自定义扩展指南

> 适用版本：v0.3.0+

## 概述

blyy-skills-doc 的所有技能均支持自定义扩展。可以修改模板、覆盖同步矩阵、添加新的技术栈锚点、调整资源文件等，以适应你的项目需求。

---

## 一、自定义文档模板

### 模板位置

**在本仓库中：**

```
skills/blyy-init-docs/templates/
├── root/          ← 根目录文档模板（README.md、AGENTS.md、CHANGELOG.md、CONTRIBUTING.md、SECURITY.md）
├── docs/          ← docs/ 目录模板（含 ARCHITECTURE.md、testing.md、monitoring.md、api-reference.md、runbook.md、glossary.md 等）
└── modules/       ← 模块级文档模板（README.md、flow.md、data-model.md、code-map.md、database/）
```

**安装到目标项目后：**

| AI 工具 | 模板路径 |
|---------|---------|
| Gemini / Codex / Cursor | `.agents/skills/blyy-init-docs/templates/` |
| Claude Code | `.claude/skills/blyy-init-docs/templates/` |

### 模板占位符

模板中使用以下占位符，在 Phase 2 填充阶段会被替换为实际内容：

| 占位符 | 含义 |
|--------|------|
| `{{PROJECT_NAME}}` | 项目名称 |
| `{{DATE}}` | 当前日期（YYYY-MM-DD） |
| `{{MODULE_NAME}}` | 模块名称 |
| `{{RUNTIME}}` | 运行时（如 .NET 8、Node.js 20） |
| `{{BUILD_COMMAND}}` | 构建命令 |
| `{{RUN_COMMAND}}` | 运行命令 |
| `{{TEST_COMMAND}}` | 测试命令 |
| `{{LANGUAGE}}` | 编程语言 |
| `{{FRAMEWORK}}` | 框架 |
| `{{PROJECT_STRUCTURE}}` | 项目目录结构 |
| `<!-- Phase 2 自动填充 -->` | 代码分析阶段自动填充 |
| `<!-- INCLUDE-IF: 条件 -->` | 条件段落，不满足则整段删除 |
| `<!-- TODO[priority,type,owner]: 简述 -->` | 结构化 TODO 标记（v0.2.0+） |

### 结构化 TODO 标记规范

**v0.2.0** 起所有 TODO 必须使用结构化格式：

```html
<!-- TODO[p1,business-context,user]: 订单创建后是否触发库存锁定 -->
```

| 字段 | 取值 | 含义 |
|------|------|------|
| **priority** | `p0` | 必须立即处理（阻塞文档可信度） |
| | `p1` | 阻塞文档可用性 |
| | `p2` | 重要但可暂缓 |
| | `p3` | 可延期 |
| **type** | `business-context` | 业务上下文（用户领域知识） |
| | `design-rationale` | 设计决策（"为什么这样做"） |
| | `ops-info` | 运维信息（部署/监控/告警细节） |
| | `security-info` | 安全信息（漏洞流程/密钥管理） |
| | `external-link` | 外部链接（看板/Wiki/Slack） |
| | `metric-baseline` | 指标基线（SLO/性能数据） |
| **owner** | `user` / `dev-team` / `ops-team` / `security-team` / 具体负责人名 | 由谁来填充 |

`blyy-doc-sync` 会按 priority 顺序检查这些标记，按 type 路由到对应的处理策略。

### YAML Front Matter 字段（v0.2.0+）

模板的 YAML front matter 扩展了多个新字段，**请勿删除**：

```yaml
---
last_updated: YYYY-MM-DD          # doc-sync 防线 1 维护
last_synced_commit: <hash>        # doc-sync 防线 1 增量识别基准
audience: dev | ops | mixed       # 目标读者
read_priority: high | medium | low # AI 加载优先级
max_lines: 200                    # 软上限，超出建议拆分
parent_doc: ../ARCHITECTURE.md    # 父文档反向链接
code_anchors:                     # 关注的代码路径
  - src/orders/
  - src/orders/migrations/
applicable_project_types:         # Phase 1 骨架过滤依据
  - backend-service
  - microservice
---
```

#### applicable_project_types 项目类型过滤

Phase 1 会**根据 front matter 的 `applicable_project_types` 字段自动过滤模板**，无需依赖 AI 自由判断。可选值：

| 值 | 含义 |
|----|------|
| `backend-service` | 后端服务 |
| `microservice` | 微服务 |
| `fullstack` | 全栈应用 |
| `frontend-spa` | 前端 SPA |
| `cli-tool` | CLI 工具 |
| `library` | 库 / SDK |
| `data-pipeline` | 数据管道 |
| `infrastructure` | 基础设施 |

若字段省略 → 视为「全类型适用」。

### 自定义建议

1. **保留必要的占位符与 front matter** — 移除会破坏自动填充
2. **调整文档结构** — 可增删章节，调整排列顺序
3. **添加项目特有内容** — 公司规范、团队约定等
4. **Fork 后修改** — 建议 fork 本仓库后修改，方便后续跟踪上游更新

---

## 二、覆盖同步矩阵

### 内置矩阵

`skills/blyy-doc-sync/resources/sync-matrix.md` 定义了通用的代码变更→文档更新映射。

### 项目级覆盖

在目标项目中创建 `docs/doc-maintenance.md` 即可覆盖内置矩阵。`blyy-doc-sync` 的读取优先级：

```
优先级 1: 项目内 docs/doc-maintenance.md     ← 项目定制版（含基线快照）
优先级 2: skill 内 resources/sync-matrix.md   ← 通用 fallback
```

### 扩展矩阵示例

在 `docs/doc-maintenance.md` 中可以添加自定义规则：

```markdown
## 自定义同步规则

| 代码变更类型 | 需更新的文档 | 更新内容 |
|-------------|-------------|---------|
| 修改通知模板 | `docs/notification.md` | 更新通知模板列表 |
| 新增定时任务 | `docs/scheduler.md` | 加一行任务描述 + 代码位置 |
```

### 基线快照（v0.2.0+ 必须）

`docs/doc-maintenance.md` **必须包含** `blyy-init-docs` Phase 3 写入的基线快照 YAML 块和历史趋势表。`blyy-doc-sync` 防线 3 依赖此数据进行趋势对比。完整 schema 见 `skills/blyy-init-docs/resources/phase3-verification.md`。

---

## 三、添加新的技术栈支持

### 锚点矩阵位置

`skills/blyy-init-docs/resources/doc-guide.md` 中的「锚点文件矩阵」定义了各技术栈的关键文件识别规则。

### 添加新技术栈

1. 在 `doc-guide.md` 的「技术栈识别」表中添加新行
2. 在「锚点文件矩阵」中添加对应的后端/前端锚点
3. 在「模块识别策略」中补充该技术栈的模块识别特征
4. 在「确定性清点命令矩阵」中添加 `fd`/`rg` 命令（供 Phase 2 预扫描和 doc-sync 防线 3 使用）

示例（添加 Elixir/Phoenix 支持）：

```markdown
# 技术栈识别
| `mix.exs` | Elixir | Phoenix |

# 后端锚点
| **入口点** | `lib/*/application.ex`, `lib/*_web/router.ex` |
| **配置** | `config/*.exs` |
| **模型** | `lib/*/schemas/*.ex` |
| **控制器** | `lib/*_web/controllers/*.ex` |
| **迁移** | `priv/repo/migrations/*.exs` |

# 确定性清点命令
| 实体/模型 | `fd -e ex -p "schemas" --type f` |
| 控制器   | `fd -e ex -p "controllers" --type f` |
```

---

## 四、自定义资源文件（v0.3.0 渐进式加载）

### 资源文件清单

v0.3.0 起 SKILL.md 的详细流程已拆分到独立资源文件，AI 按需加载：

**blyy-init-docs/resources/**

| 文件 | 何时被读取 |
|------|-----------|
| `doc-guide.md` | Phase 1/2 填充时 |
| `legacy-extraction.md` | Phase 1.5 触发时 |
| `large-project-mode.md` | 进入大型项目模式时 |
| `phase3-verification.md` | 进入 Phase 3 时 |
| `operational-conventions.md` | 子代理调度 + 全程参考 |

**blyy-doc-sync/resources/**

| 文件 | 何时被读取 |
|------|-----------|
| `sync-matrix.md` | 防线 1 fallback |
| `defense-line-3-audit.md` | 触发防线 3 时 |

### 自定义建议

- **不要直接修改 SKILL.md** — 它是 AI 工具识别技能的入口，结构变化可能破坏触发
- **优先修改 resource 文件** — 想调整某个 Phase 的细节，编辑对应 resource 即可
- **新增 resource 文件需更新 SKILL.md 的「资源文件」表** — 否则 AI 不会知道要读它，并在表中明确「何时读取」的触发条件

---

## 五、创建新的 Skill

如果你想在本仓库中添加全新的 Skill：

### 1. 创建目录结构

```
skills/blyy-<skill-name>/
├── SKILL.md              ← 必须，主指令文件（保持精简，~300 行内）
├── resources/            ← 可选，详细流程 + 参考资料
└── templates/            ← 可选，模板文件
```

### 2. 编写 SKILL.md

```markdown
---
name: blyy-<skill-name>
description: 一句话描述技能用途和触发时机
---

# blyy-<skill-name> — 技能标题

> **多工具兼容**：本 Skill 采用 SKILL.md 标准格式，兼容 Gemini、Codex、Cursor、Claude Code。

## 概述
...

## 执行流程
... 核心步骤 + 触发 Read resources/xxx.md 的条件 ...

## 资源文件
| 文件 | 何时读取 | 用途 |
|------|---------|------|
| `resources/xxx.md` | <触发条件> | <用途> |
```

### 3. 更新安装脚本

在 `install.ps1` 和 `install.sh` 中更新默认技能列表。

### 4. 更新文档

- `README.md` 的技能列表中添加新技能介绍
- `docs/usage-guide.md` 中补充使用示例
- `docs/CHANGELOG.md` 记录新增

---

## 六、常见自定义场景

| 场景 | 修改文件 |
|------|---------|
| 新增项目类型枚举（如 `mobile-app`） | `skills/blyy-init-docs/resources/doc-guide.md` 项目类型适配章节 + 各 template 的 `applicable_project_types` 字段 |
| 调整 Phase 1.5 提取的子代理类别 | `skills/blyy-init-docs/resources/legacy-extraction.md` 子代理任务表 |
| 调整大型项目模式的检查点 | `skills/blyy-init-docs/resources/large-project-mode.md` |
| 调整 Phase 3 完整性校验项 | `skills/blyy-init-docs/resources/phase3-verification.md` |
| 调整防线 3 趋势报告格式 | `skills/blyy-doc-sync/resources/defense-line-3-audit.md` |
| 调整子代理进度通报格式 | `skills/blyy-init-docs/resources/operational-conventions.md` 第一节 |
| 调整文件过滤排除规则 | `skills/blyy-init-docs/resources/operational-conventions.md` 第四节 |
