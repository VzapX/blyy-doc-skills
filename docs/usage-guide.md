# 使用指南

## 概述

**blyy-skills-doc** 包含两个互补的 AI 编程工具技能：

- **blyy-init-docs**：项目文档初始化（Day 0）
- **blyy-doc-sync**：文档持续同步维护（Day 1+）

## 兼容的 AI 工具

| AI 工具 | 安装目录 | 触发方式 |
|---------|---------|---------|
| Gemini (Google) | `.agents/skills/` | 自动识别 SKILL.md |
| Codex (OpenAI) | `.agents/skills/` | 自动识别 SKILL.md |
| Cursor | `.agents/skills/` | 自动识别 SKILL.md |
| Claude Code | `.claude/skills/` | 自动识别 |

## 安装

参见 [README.md](../README.md) 的安装说明。

## 使用 blyy-init-docs

### 适用场景

- 新项目需要建立文档体系
- 已有项目缺少系统化文档
- 接手遗留项目，需要快速理解代码结构

### 执行流程

```
Phase 0 — 项目环境评估
  ├── 检测 AI 工具上下文文件
  ├── 评估项目规模（标准 vs 大型）
  └── 决定执行模式

Phase 1 — 骨架生成
  ├── 迁移旧文档到 docs-old/
  ├── 根据模板创建文档结构
  └── 整合已有根目录文档

Phase 2 — 代码分析填充
  ├── 识别技术栈和模块
  ├── 子代理并行分析（配置、数据模型、部署等）
  └── 主 agent 整合填充所有文档

Phase 3 — 最终检查
  ├── 验证文档完整性
  └── 生成初始化报告
```

### 生成的文档结构

```
项目根目录/
├── README.md
├── AGENTS.md / CLAUDE.md
├── CHANGELOG.md
└── docs/
    ├── ARCHITECTURE.md      ← 系统总览 + 文档索引
    ├── code-map.md          ← 代码地图
    ├── modules.md           ← 模块注册表
    ├── core-flow.md         ← 核心业务流程
    ├── config.md            ← 配置参考
    ├── features.md          ← 功能列表
    ├── data-model.md        ← 数据模型
    ├── deployment.md        ← 部署指南
    ├── runbook.md           ← 运维手册
    ├── DECISIONS.md         ← 架构决策记录
    ├── doc-maintenance.md   ← 文档维护规则
    └── modules/             ← 模块级文档
        └── <module>/
            ├── README.md
            ├── flow.md
            ├── data-model.md
            └── code-map.md
```

### 使用方式

在 AI 工具中直接对话即可触发：

```
请使用 blyy-init-docs 为本项目初始化文档
```

或等效表述：

```
帮我初始化项目文档
```

AI 工具会根据技能描述自动匹配并执行。

---

## 使用 blyy-doc-sync

### 适用场景

每次代码变更后，自动检查并同步更新文档。

### 三道防线

#### 防线 1：触发式同步（实时）

每次代码变更后立即执行：
1. 识别代码变更类型
2. 对照同步矩阵确定受影响文档
3. 更新对应文档章节
4. 更新 `last_updated` 元数据

#### 防线 2：提交前验证（门禁）

完成一轮修改后自检：
- 文件路径引用是否有效
- 配置项是否与代码一致
- 文档间交叉引用是否完整

#### 防线 3：定期审计（兜底）

建议每月/每季度全面检查一次文档覆盖度。

### 同步矩阵示例

| 代码变更 | 需更新的文档 |
|---------|------------|
| 新增源文件 | `code-map.md` |
| 新增/修改配置项 | `config.md` |
| 新增模块 | `modules.md` + 模块级文档 |
| 数据库变更 | `data-model.md` |
| 新增功能 | `features.md` |
| 部署流程变化 | `deployment.md` |

完整矩阵见 `skills/blyy-doc-sync/resources/sync-matrix.md`。

---

## 常见问题

### 技能没有被 AI 工具识别？

1. 确认技能文件夹在正确位置（参见兼容性表格）
2. 确认 `SKILL.md` 文件存在且格式正确
3. 部分工具可能需要重启才能发现新技能

### 已有文档会被覆盖吗？

不会直接覆盖。`blyy-init-docs` 会先将已有 `docs/` 迁移至 `docs-old/`，并在填充阶段参考旧文档内容。

### 两个技能可以只安装一个吗？

可以。它们是独立的，但推荐一起使用以获得完整的文档管理体验。
