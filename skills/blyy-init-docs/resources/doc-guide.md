# 文档架构指南（入口文件）

本文档是 `blyy-init-docs` skill 的参考资源入口，说明文档架构设计理念、各文档职责、全局与模块分工以及项目类型适配。

> **v1.0.0 定位**：业务知识文档。只生成 AI 读代码读不出的业务知识层（业务术语、架构决策、跨模块流程、模块业务职责）。代码级文档（code-map / api-reference / data-model / database / testing 等）和运营级文档（deployment / runbook / monitoring）一律不再生成——AI 直接读源码或运维系统即可获取。

v0.3.3 起本文件已拆分，具体的技术栈矩阵、填充规则与 YAML Front Matter 规范另见：

| 子资源文件 | 内容 |
|-----------|------|
| `tech-stack-matrix.md` | 确定性清点命令矩阵、字段说明提取矩阵、技术栈/锚点/模块识别策略、配置识别策略 |
| `fact-classification.md` | Phase 2 填充原则、三级事实分类（T1/T2/T3）、子代理输出格式 |
| `front-matter-spec.md` | 模板占位符、YAML Front Matter 字段、AI 提示块、结构化 TODO（type/priority/owner 枚举的唯一权威来源） |

Phase 0/1/2/3 各阶段需要读哪一份，见 `SKILL.md` 末尾的「资源文件索引」。

---

## 一、文档架构总览

```
项目根目录/
├── README.md              ← 项目入口：快速了解项目
├── AGENTS.md              ← AI/开发者指南：构建、运行、代码规范
├── CHANGELOG.md           ← 版本变更记录
├── CONTRIBUTING.md        ← 贡献指南（可选）
├── SECURITY.md            ← 安全策略（按需）
└── docs/
    ├── ARCHITECTURE.md    ← 系统总览 + 任务路由表 + 文档索引（入口文档）
    ├── modules.md         ← 模块注册表 + 功能列表 + 模块间依赖
    ├── glossary.md        ← 业务术语 ↔ 代码符号 + 字段业务语义
    ├── core-flow.md       ← 跨模块业务流程
    ├── config.md          ← 配置项业务语义（不记值/默认）
    ├── DECISIONS.md       ← 架构决策记录（ADR）
    ├── doc-maintenance.md ← 文档维护规则（AI 工具专用）
    └── modules/           ← 模块业务文档
        └── <module>.md    ← 每个模块一个单文件（5 章节：概述/职责与边界/依赖关系/核心业务流程/代码锚点）
```

**v1.0 不再生成的文档**（AI 自己读代码即可，文档体系不重复造）：

- `code-map.md` —— AI 用 grep/find 即可
- `api-reference.md` —— AI 读 Controller / handler 即可
- `data-model.md` / `database/` —— AI 读实体类/migration 即可；字段**业务语义**集中到 `glossary.md` 字段语义章节
- `deployment.md` / `runbook.md` / `monitoring.md` —— 属运维职责，不在 AI 辅助编码所需范围
- `testing.md` —— AI 读 `tests/` 目录即可
- `features.md` —— 合并到 `modules.md` 的「功能列表」章节

---

## 二、各文档职责定义

### 根目录文档

| 文档 | 目标读者 | 核心职责 | 必要性 |
|------|---------|---------|--------|
| `README.md` | 所有人 | 项目第一印象：做什么、怎么用、怎么跑 | 必须 |
| `AGENTS.md` | AI 工具 + 开发者 | **任务入口协议**（必须先读 `docs/ARCHITECTURE.md`）+ 构建/运行/测试命令、项目结构、编码规范 | 必须 |
| `CHANGELOG.md` | 用户 + 开发者 | 每个版本的变更记录 | 必须 |
| `CONTRIBUTING.md` | 外部贡献者 | 如何参与项目 | 可选 |
| `SECURITY.md` | 安全研究者 | 漏洞报告流程、安全策略 | 按需 |

### docs/ 目录文档

| 文档 | 核心职责 | 更新触发器 |
|------|---------|-----------|
| `ARCHITECTURE.md` | 系统总览 + AI 任务路由表 + **文档索引入口** | 模块结构变动、文档结构变动、任务路由表调整 |
| `modules.md` | 模块注册表 + 功能列表 + 模块间依赖 | 模块/功能增/删/职责变更 |
| `glossary.md` | 业务术语 ↔ 代码符号 + 字段业务语义 | 新增核心实体/服务、字段业务含义变化 |
| `core-flow.md` | 跨模块业务流程 | 业务流程变化 |
| `config.md` | 配置项业务语义（**只记业务语义，不记值/默认/类型——这些直接读代码**） | 配置项业务语义变更 |
| `DECISIONS.md` | 架构决策记录（ADR 格式） | 新决策 |
| `doc-maintenance.md` | AI 文档维护规则 + 基线快照 | 规则变更（基线快照由 doc-sync 维护） |

### 模块级文档（统一单文件）

v1.0 起所有模块统一使用 `docs/modules/<m>.md` 单文件，使用 `templates/modules/_module.md.template`。固定 5 个章节：

| 章节 | 内容 |
|------|------|
| 概述 | 模块定位（一句话） |
| 职责与边界 | 模块负责什么、不负责什么 |
| 依赖关系 | 入向/出向依赖（来自静态扫描） |
| 核心业务流程 | 模块内主要业务流程 |
| 代码锚点 | 模块入口、主要 Service / Controller / 实体 / migration 位置 |

> 详细信息（API 详情、文件→职责映射、表结构等）AI 直接读源码获取，不重复在文档里维护。

---

## 三、全局与模块文档分工

| 维度 | 全局文档 | 模块文档 |
|------|---------|---------|
| **业务流程** | `core-flow.md`：跨模块流程 | `modules/<m>.md` 的「核心业务流程」章节 |
| **业务术语** | `glossary.md`：术语映射 + 字段业务语义 | `modules/<m>.md` 中提到的术语都需在 glossary 登记 |
| **模块** | `modules.md`：注册表 + 功能列表 + 依赖 | `modules/<m>.md`：模块业务文档 |
| **架构决策** | `DECISIONS.md`：ADR | — |
| **配置** | `config.md`：业务语义 | — |
| **代码细节** | — | 由 AI 直接读源码（`代码锚点` 章节给出入口） |

---

## 四、Phase 2 填充规则（已拆分）

Phase 2 填充相关的全部内容已拆分到两个子资源文件，**不要在本文件查找**：

- **填充原则、三级事实分类（T1/T2/T3）、子代理输出格式** → `fact-classification.md`
- **确定性清点命令矩阵、字段说明提取矩阵、技术栈识别、锚点文件矩阵、模块识别策略（Step 1-4，含分层架构跨层提取）、配置识别策略** → `tech-stack-matrix.md`

子代理分发前，主 agent 必须将这两份文件（以及 `front-matter-spec.md` 的 TODO 格式部分）纳入子代理上下文。

---

## 五、项目类型适配指南

不同类型的项目对文档的侧重点不同。Phase 0 识别技术栈后，应根据项目类型调整文档生成策略。

### 适配矩阵（v1.0 简化版）

v1.0 文档清单本身已极简，所有项目类型生成的文档清单基本一致。差异只在每份文档的内容侧重：

| 项目类型 | 内容侧重 |
|----------|---------|
| **标准后端服务 / 微服务** | 默认模式 |
| **全栈项目** | 前后端分别作为模块；`core-flow.md` 含跨端业务流程 |
| **CLI 工具/库** | `modules.md` 的功能列表侧重命令/参数；`glossary.md` 字段语义可能较少 |
| **数据管道/ETL** | `core-flow.md` 侧重数据流而非业务流；`glossary.md` 字段语义重点放在数据 schema |
| **前端 SPA** | `modules.md` 功能列表侧重页面/路由；模块按功能分区 |
| **基础设施项目** | `config.md` 侧重环境变量和 IaC 变量的业务语义 |

### 适配规则

1. Phase 0 识别技术栈后，自动匹配上表中的项目类型
2. 若匹配结果不确定（如全栈 vs 纯后端），向用户确认
3. v1.0 所有文档（`ARCHITECTURE.md`、`modules.md`、`glossary.md`、`core-flow.md`、`config.md`、`DECISIONS.md`、`doc-maintenance.md`、`modules/<m>.md`）始终生成

### 模板条件化生成清单

Phase 1 骨架生成时，按以下规则实例化模板：

| 文档 | 生成条件 | 渐进层级 |
|------|---------|---------|
| `README.md` | 始终生成 | Layer 1 |
| `AGENTS.md` / AI 上下文 | 始终生成 | Layer 1 |
| `ARCHITECTURE.md` | 始终生成 | Layer 1 |
| `modules.md` | 始终生成 | Layer 1 |
| `modules/<name>.md` | 每个识别到的模块生成一个 | Layer 2 |
| `core-flow.md` | 始终生成 | Layer 3 |
| `config.md` | 始终生成 | Layer 3 |
| `glossary.md` | 始终生成 | Layer 3 |
| `DECISIONS.md` | 始终生成 | Layer 3 |
| `doc-maintenance.md` | 始终生成 | Layer 3 |
| `CHANGELOG.md` | 始终生成（内容用户可选） | Layer 3 |
| `CONTRIBUTING.md` | 用户确认后生成 | Layer 3 |
| `SECURITY.md` | 用户确认后生成 | Layer 3 |

---

## 六、模板占位符与 YAML Front Matter（已拆分）

原 `doc-guide.md` 六、七两章的内容已迁移到 `front-matter-spec.md`，包含：

- 文档模板占位符完整清单
- YAML Front Matter 字段标准（`last_updated` / `audience` / `read_priority` / `max_lines` 等）
- 文档头部 AI 提示块（AI-READ-HINT / AI-RULE）
- **结构化 TODO 格式**（priority / type / owner 枚举，**唯一权威来源**）
- 体积约束（max_lines）的执行

所有对 TODO `type` 枚举的引用（包括 `blyy-doc-sync` 的 `sync-matrix.md` 与 `SKILL.md` 防线 1 Step 4）均指向 `front-matter-spec.md` 七.4，不再在本文件定义。
