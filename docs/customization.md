# 自定义扩展指南

## 概述

blyy-skills-doc 的所有技能均支持自定义扩展。你可以修改模板、覆盖同步矩阵、添加新的技术栈锚点等，以适应你的项目需求。

---

## 自定义文档模板

### 模板位置

**在本仓库中：**

```
skills/blyy-init-docs/templates/
├── root/          ← 根目录文档模板（README.md、AGENTS.md 等）
├── docs/          ← docs/ 目录模板（ARCHITECTURE.md、config.md 等）
└── modules/       ← 模块级文档模板（README.md、flow.md 等）
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
| `<!-- TODO: xxx -->` | 需人工补充的内容 |

### 自定义方式

直接编辑模板文件即可。建议：

1. **保留必要的占位符**：`{{PROJECT_NAME}}`、`{{DATE}}` 等核心占位符保持原样
2. **调整文档结构**：可以增删章节，调整排列顺序
3. **添加项目特有内容**：如公司规范、团队约定等
4. **Fork 后修改**：建议 fork 本仓库后修改，方便后续跟踪上游更新

---

## 覆盖同步矩阵

### 内置矩阵

`skills/blyy-doc-sync/resources/sync-matrix.md` 定义了通用的代码变更→文档更新映射。

### 项目级覆盖

在目标项目中创建 `docs/doc-maintenance.md` 即可覆盖内置矩阵。`blyy-doc-sync` 的读取优先级：

```
优先级 1: 项目内 docs/doc-maintenance.md     ← 项目定制版
优先级 2: skill 内 resources/sync-matrix.md   ← 通用 fallback
```

### 扩展矩阵示例

在 `docs/doc-maintenance.md` 中可以添加自定义规则：

```markdown
## 自定义同步规则

| 代码变更类型 | 需更新的文档 | 更新内容 |
|-------------|-------------|---------|
| 修改通知模板 | `docs/notification.md` | 更新通知模板列表 |
| 新增定时任务 | `docs/scheduler.md` | 加一行任务描述 |
```

---

## 添加新的技术栈支持

### 锚点矩阵位置

`skills/blyy-init-docs/resources/doc-guide.md` 中的「锚点文件矩阵」定义了各技术栈的关键文件识别规则。

### 添加新技术栈

1. 在 `doc-guide.md` 的「技术栈识别」表中添加新行
2. 在「锚点文件矩阵」中添加对应的后端/前端锚点
3. 在「模块识别策略」中补充该技术栈的模块识别特征
4. 在「配置识别策略」中添加配置文件识别规则

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
```

---

## 创建新的 Skill

如果你想在本仓库中添加全新的 Skill：

### 1. 创建目录结构

```
skills/blyy-<skill-name>/
├── SKILL.md              ← 必须，主指令文件
├── resources/            ← 可选，参考资源
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
...
```

### 3. 更新安装脚本

在 `install.ps1` 和 `install.sh` 中更新默认技能列表。

### 4. 更新 README

在 `README.md` 的技能列表中添加新技能的介绍。
