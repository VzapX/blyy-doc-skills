# 文档架构指南（入口文件）

本文档是 `blyy-init-docs` skill 的参考资源入口，说明文档架构设计理念、各文档职责、全局与模块分工以及项目类型适配。

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
    ├── ARCHITECTURE.md    ← 系统总览 + 文档索引（入口文档）
    ├── code-map.md        ← 总览简述 + 各模块链接
    ├── modules.md         ← 模块注册表 + 模块间依赖
    ├── core-flow.md       ← 跨模块核心业务流程
    ├── config.md          ← 配置项参考
    ├── features.md        ← 功能列表 + 术语表
    ├── DECISIONS.md       ← 架构决策记录（ADR）
    ├── doc-maintenance.md ← 文档维护规则（AI 工具专用）
    ├── data-model.md      ← 公共数据模型 + 模块索引
    ├── runbook.md         ← 运维手册
    ├── deployment.md      ← 部署流程
    ├── api-reference.md   ← API 参考（按需）
    ├── database/          ← 公共/跨模块表 + 各模块链接
    └── modules/           ← 模块级文档
        └── <module>/
            ├── README.md      ← 模块职责与边界
            ├── flow.md        ← 模块内业务流程
            ├── data-model.md  ← 模块内数据模型
            ├── code-map.md    ← 模块内文件→职责映射
            └── database/      ← 模块内表 schema
```

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
| `ARCHITECTURE.md` | 系统总览 + 架构图 + **文档索引入口** | 模块/数据流/文件变动 |
| `code-map.md` | 总览简述 + 各模块 code-map 链接 | 文件增/删/重命名 |
| `modules.md` | 模块注册表：模块摘要 + 链接到模块文档 | 模块增/删/职责变更 |
| `core-flow.md` | **跨模块**主业务流程 | 业务流程变化 |
| `config.md` | 所有配置项参考 | 配置变更 |
| `features.md` | 功能清单 + 术语表 | 功能增/删 |
| `DECISIONS.md` | 架构决策记录（ADR 格式） | 新决策 |
| `doc-maintenance.md` | AI 文档维护规则 | 规则变更 |
| `data-model.md` | 公共数据模型 + **模块索引** | 数据结构变更 |
| `runbook.md` | 运维手册 + 事故剧本 | 故障/运维变更 |
| `deployment.md` | 部署流程 + 回滚方案 | 部署方式变更 |
| `api-reference.md` | API 公共信息 + **模块索引** | 全局认证/错误码变更 |

### 模块级文档（按复杂度分级）

模块文档采用**三级文档形态**，根据模块复杂度评分自动决定：

#### 模块复杂度评分规则

| 信号 | 检测方式 | 得分 |
|------|---------|------|
| 模块源文件数 > 15 | `fd --type f <module_dir> \| wc -l` | +2 |
| 模块源文件数 5-15 | 同上 | +1 |
| 模块源文件数 < 5 | 同上 | 0 |
| 有数据库实体/模型文件 | 确定性清单中检测 | +1 |
| 有 API 端点（Controller/Handler） | 确定性清单中检测 | +1 |
| 被 ≥ 3 个其他模块依赖 | 反向引用扫描 | +1 |

#### 三级文档形态

| 总分 | 级别 | 文档形态 | 文件数 |
|------|------|---------|--------|
| ≥ 3 | **Core** | 完整目录 `modules/<m>/`（见下表） | 6 |
| 1-2 | **Standard** | 单文件 `modules/<m>.md`（所有章节合并） | 1 |
| 0 | **Lightweight** | 无独立文件，内联到 `modules.md` | 0 |

**Core 模块文档清单**（完整目录）：

| 文档 | 核心职责 |
|------|---------|
| `README.md` | 模块概述、职责、边界、对外接口 |
| `flow.md` | 模块内部业务流程 |
| `data-model.md` | 模块内数据模型、表结构 |
| `api-reference.md` | 模块内 API 接口详情 |
| `code-map.md` | 模块内文件→职责映射 |
| `database/` | 模块内表 schema |

**Standard 模块文档**（单文件 `modules/<m>.md`）：

使用 `templates/modules-single.md.template`，将上述 6 个文件的内容合并为一个文档的不同 H2 章节：概述 → 职责与边界 → 对外接口 → 依赖关系 → 代码地图 → 业务流程 → 数据模型 → API 参考。无内容的章节可删除（如无 API 的模块删除 API 参考章节）。

**Lightweight 模块**（内联到 `modules.md`）：

不生成独立文件。在 `modules.md` 模块注册表的 Lightweight 区域以展开段落呈现：职责、代码位置、文件数、关键类/函数、依赖方。

#### 级别升降规则

模块复杂度会随项目演进变化。级别变更由 `blyy-doc-sync` 检测触发：
- **升级**（如 Standard → Core）：创建模块目录，将单文件内容拆分为子文件
- **降级**（如 Core → Standard）：将目录下子文件合并为单文件，删除原目录
- 详见 `blyy-doc-sync` 防线 1 升级信号检测 + 防线 3 全量复评

---

## 三、全局与模块文档分工

> 下表中「模块文档」列仅适用于 **Core** 级别模块。Standard 模块的对应内容在单文件中以章节呈现，Lightweight 模块的内容内联在 `modules.md` 中。

| 维度 | 全局文档 | 模块文档（Core 级别） |
|------|---------|---------|
| **流程** | `core-flow.md`：跨模块主流程 | `modules/<m>/flow.md`：模块内部流程 |
| **数据** | `data-model.md`：公共模型 + 索引 | `modules/<m>/data-model.md`：模块内模型 |
| **模块** | `modules.md`：注册表 + Lightweight 内联 | `modules/<m>/README.md`：详细说明 |
| **代码地图** | `code-map.md`：总览 + 模块链接 | `modules/<m>/code-map.md`：模块内映射 |
| **API** | `api-reference.md`：公共信息 + 模块索引 | `modules/<m>/api-reference.md`：模块接口详情 |
| **数据库** | `database/`：公共表 + 模块链接 | `modules/<m>/database/`：模块内表 schema |

---

## 四、Phase 2 填充规则（已拆分）

Phase 2 填充相关的全部内容已拆分到两个子资源文件，**不要在本文件查找**：

- **填充原则（6 条）、三级事实分类（T1/T2/T3）、子代理输出格式** → `fact-classification.md`
- **确定性清点命令矩阵、字段说明提取矩阵、技术栈识别、锚点文件矩阵、模块识别策略（Step 1-4，含分层架构跨层提取）、配置识别策略** → `tech-stack-matrix.md`

子代理分发前，主 agent 必须将这两份文件（以及 `front-matter-spec.md` 的 TODO 格式部分）纳入子代理上下文。

---

## 五、项目类型适配指南

不同类型的项目对文档的侧重点不同。Phase 0 识别技术栈后，应根据项目类型调整文档生成策略。

### 适配矩阵

| 项目类型 | 必须生成 | 建议生成 | 可跳过 | 特殊说明 |
|----------|---------|---------|--------|---------|
| **标准后端服务** | 全部基础文档 | `api-reference.md`、`monitoring.md` | — | 默认模式 |
| **全栈项目** | 全部基础文档 | `api-reference.md`、`testing.md` | — | 前后端分别作为模块处理 |
| **CLI 工具/库** | 基础文档（不含 `deployment.md`、`runbook.md`） | `api-reference.md`（作为 CLI 参数参考） | `monitoring.md`、`runbook.md` | `features.md` 侧重命令/参数列表 |
| **微服务** | 全部基础文档 + `monitoring.md` | `api-reference.md` | — | 每个服务作为一个模块；`deployment.md` 需覆盖多服务编排 |
| **数据管道/ETL** | 基础文档 | `monitoring.md` | `api-reference.md` | `core-flow.md` 侧重数据流而非业务流；`data-model.md` 侧重 schema 演化 |
| **前端 SPA** | 基础文档（不含数据库相关） | `testing.md` | `database/`、`data-model.md`、`runbook.md` | `features.md` 侧重页面/路由；模块按功能分区 |
| **基础设施项目** | 基础文档 | `monitoring.md` | `api-reference.md`、`data-model.md` | `deployment.md` 是核心文档；`config.md` 侧重环境变量和 IaC 变量 |

### 适配规则

1. Phase 0 识别技术栈后，自动匹配上表中的项目类型
2. 若匹配结果不确定（如全栈 vs 纯后端），向用户确认
3. **「可跳过」不等于「禁止生成」** — 用户明确要求时仍应生成
4. 无论项目类型，`ARCHITECTURE.md`、`code-map.md`、`modules.md`、`doc-maintenance.md` 始终生成

### 模板条件化生成清单

Phase 1 骨架生成时，根据项目类型决定哪些模板实例化。以下为各文档的生成条件：

| 文档 | 生成条件 | 渐进层级 |
|------|---------|---------|
| `README.md` | 始终生成 | Layer 1 |
| `AGENTS.md` / AI 上下文 | 始终生成 | Layer 1 |
| `ARCHITECTURE.md` | 始终生成 | Layer 1 |
| `modules.md` | 始终生成 | Layer 1 |
| `code-map.md` | 始终生成 | Layer 1 |
| `modules/<name>/*` | 每个识别到的模块 | Layer 2 |
| `modules/<name>/api-reference.md` | 模块有 API 接口（控制器/路由） | Layer 2 |
| `core-flow.md` | 始终生成 | Layer 3 |
| `config.md` | 始终生成 | Layer 3 |
| `data-model.md` | 项目有数据库或 ORM | Layer 3 |
| `features.md` | 始终生成 | Layer 3 |
| `DECISIONS.md` | 始终生成 | Layer 3 |
| `database/` | 项目有数据库 | Layer 3 |
| `CHANGELOG.md` | 始终生成（内容用户可选） | Layer 3 |
| `deployment.md` | 非 CLI/库项目 | Layer 4 |
| `testing.md` | 项目有测试目录或测试框架 | Layer 4 |
| `runbook.md` | 非 CLI/库/前端 SPA 项目 | Layer 4 |
| `monitoring.md` | 项目有监控配置或为微服务 | Layer 4 |
| `api-reference.md` | 项目有 API（控制器/路由） | Layer 4 |
| `doc-maintenance.md` | 始终生成 | Layer 4 |
| `CONTRIBUTING.md` | 用户确认后生成 | Layer 4 |
| `SECURITY.md` | 用户确认后生成 | Layer 4 |

**条件判断方法**（Phase 0/1 执行）：

| 条件 | 判断命令 |
|------|---------|
| 项目有数据库 | 存在迁移文件、ORM 配置、`database.yml`、`*.dbcontext*` 等 |
| 项目有 API | 存在控制器/路由文件（确定性清点结果中控制器数量 > 0） |
| 项目有测试 | 存在 `tests/`、`__tests__/`、`*_test.*`、`*.spec.*` 等 |
| 项目有监控 | 存在 `prometheus`、`grafana`、`datadog`、`newrelic` 相关配置 |
| 非 CLI/库 | 不满足 CLI/库条件（无 `bin/` 入口、非 npm 包等） |

**Phase 1 骨架生成时**：
1. 根据上表自动判断，仅创建满足条件的文档骨架
2. 向用户展示将要生成的文档清单，标注哪些被跳过及原因
3. 用户可追加被跳过的文档（`「可跳过」不等于「禁止生成」`）

---

## 六、模板占位符与 YAML Front Matter（已拆分）

原 `doc-guide.md` 六、七两章的内容已迁移到 `front-matter-spec.md`，包含：

- 文档模板占位符完整清单
- YAML Front Matter 字段标准（`last_updated` / `audience` / `read_priority` / `max_lines` 等）
- 文档头部 AI 提示块（AI-READ-HINT / AI-RULE）
- **结构化 TODO 格式**（priority / type / owner 枚举，**唯一权威来源**）
- 体积约束（max_lines）的执行

所有对 TODO `type` 枚举的引用（包括 `blyy-doc-sync` 的 `sync-matrix.md` 与 `SKILL.md` 防线 1 Step 4）均指向 `front-matter-spec.md` 七.4，不再在本文件定义。
