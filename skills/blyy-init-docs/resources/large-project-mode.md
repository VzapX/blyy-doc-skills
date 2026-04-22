# 大型项目模式 — Phase 2A-2D 详细执行流程

> **何时读取本文件**：当 Phase 0.3 判定为**大型项目模式**（源代码文件 > 500 或子项目 > 5）时。
>
> **目标**：通过分层聚焦 + 任务持久化，在跨会话场景下完成大型项目的文档梳理。
>
> 标准模式（Phase 2）请勿读取本文件，直接使用 SKILL.md 的标准流程。

## Phase 2A — 项目轮廓扫描

> 目标：快速建立项目全局画像，**不读业务代码**。由主 agent 串行完成。

**执行步骤：**

1. **读项目清单文件** — `.sln`、`.csproj`、`package.json`、`go.mod`、`pom.xml`、`Cargo.toml`、`pyproject.toml` 等，提取项目名称、技术栈、子项目列表、依赖关系
2. **生成目录树**（限深度 2-3 层） — 使用 `fd`，排除 `node_modules/`、`bin/`、`obj/`、`.git/`、`vendor/`、`dist/`、`packages/` 等
3. **文件统计** — 按扩展名统计文件数量和分布
4. **读构建/CI 配置** — `Dockerfile`、`docker-compose.yml`、`Makefile`、`.github/workflows/`、`Jenkinsfile`、`*.ps1` 等
5. **加载旧文档提取产物** — 若 Phase 1.5 已执行，从 `.init-docs/extractions/` 读取结构化提取结果的摘要信息；同时读取根目录 `README.md` 等已有文档
6. **输出轮廓报告** — 汇总上述信息

**输出：** 项目轮廓报告 → 持久化到 `.init-docs/project-profile.md`

> **检查点 ①**：将项目轮廓报告呈现给用户确认

## Phase 2B — 锚点文件识别与智能索引

> 目标：找到每个模块的「骨架文件」，不逐个读所有文件。由主 agent 为主。

**执行步骤：**

1. 根据 Phase 2A 识别的技术栈，从锚点矩阵中选择对应规则（详见 `resources/tech-stack-matrix.md` 四、锚点文件矩阵）
2. 使用 `fd` / `rg` + 文件名 glob 或内容模式批量搜索锚点文件
3. **架构布局检测**（Step 2.5）：判断项目是领域组织还是分层组织（详见 `resources/tech-stack-matrix.md` 五、模块识别策略）
4. **模块识别**：对于领域组织项目，阅读入口点文件推导模块清单；对于分层架构项目，**必须使用跨层业务领域提取（Step 2.6）**从文件命名中提取业务模块
5. 按模块聚合锚点文件
6. 生成模块清单草案 → 持久化到 `.init-docs/module-list.md`

> **检查点 ②**：将模块清单草案呈现给用户确认（模块边界、职责描述等）

7. **确定性清单预扫描**：模块确认后，执行确定性清单预扫描（同标准模式，命令详见 `resources/tech-stack-matrix.md` 一、确定性清点命令矩阵），按模块拆分清单，持久化到 `.init-docs/inventory.md`

## Phase 2C — 模块级聚焦分析

> 目标：逐模块深入分析。**此阶段高度并行**，是子代理的主战场。

**主 agent 编排：**
1. 根据模块清单为每个模块准备子代理任务描述（含目录范围、锚点文件列表、分析模板、**该模块的确定性清单子集（强制检查表）**、**Phase 1.5 中该模块相关的提取结果**）
2. 按模块规模决定分组策略：< 20 文件合并、20-100 一对一、> 100 拆分子模块
3. 并行分发给子代理（建议并行度 3-5）

**子代理执行（每个模块独立上下文）：**
1. 仅在分配的模块目录范围内工作
2. **核对确定性清单**：以接收到的文件清单为检查表，逐一读取分析
3. 读锚点文件 → 核心服务 → 数据模型 → 测试（抽样）
4. 将 Phase 1.5 提取产物中该模块相关条目与代码扫描结果**逐条对照合并**（合并规则同标准模式）
5. **每个分析条目标注 T1/T2/T3 事实级别**和代码依据（详见 `resources/fact-classification.md` 二、三级事实分类）
5.1. **字段说明提取**：扫描实体类/模型类时，必须同时提取每个属性的注释文本（文档注释、数据注解、迁移文件注释），作为 `data-model.md`「说明」列的值（详见 `resources/tech-stack-matrix.md` 二、字段说明提取矩阵）
6. 输出标准化模块分析报告 → **立即持久化**到 `.init-docs/modules/<name>-analysis.md`
7. T3 推测性条目单独汇总在报告末尾的「待澄清项」区域
8. **进度输出**：每 5 个文件一行进度，每个子类别完成一行小结，完成时输出结构化摘要（含清单覆盖率）

**主 agent 整合：**
1. 从落盘文件中读取每份报告（格式、一致性、冲突检测）
2. **清单覆盖率检查**：对比确定性清单 vs 各子代理报告覆盖的条目数，未覆盖的重新分发补充
3. 补充跨模块关联
4. 收集所有 T3 推测性条目，按类别分组

> **检查点 ③（填充前审查关卡）**：同标准模式的填充前审查关卡，执行清单覆盖率检查 + T3 推测性内容批量用户澄清。用户确认后 T3 升级为 T2 或按修正更新。**此步骤完成后才进入 Phase 2D 文档生成。** 澄清结果记录到 `.init-docs/clarifications.md`

## Phase 2D — 渐进式文档生成与填充

> 目标：基于已确认的分析结果，**按层级渐进式**填充文档框架。同标准模式的 Layer 1-4 分层策略。

| 层级 | 文档 | 执行者 |
|------|------|--------|
| **Layer 1 核心** | `README.md`, `AGENTS.md`, `ARCHITECTURE.md`, `modules.md`, `code-map.md` | 主 agent |
| **Layer 2 模块** | `modules/<m>/README.md`, `flow.md`, `code-map.md`, `data-model.md`, `api-reference.md`(按需), `database/` | 子代理并行 |
| **Layer 3 汇总** | `core-flow.md`, `config.md`, `data-model.md`(全局), `features.md`, `DECISIONS.md`, `database/`(全局), `CHANGELOG.md` | 主 agent |
| **Layer 4 运营** | `deployment.md`, `testing.md`, `runbook.md`, `monitoring.md`, `api-reference.md`, `doc-maintenance.md` | 主 agent |

每层交付后询问用户是否继续。用户可在任意层后暂停（大型模式下进度已持久化到 `.init-docs/`，可跨会话恢复）。

**填充原则同标准模式**（详见 `resources/fact-classification.md` 一、填充原则）。

---

## 任务持久化机制

大型项目的文档梳理可能跨越多个会话，通过 `.init-docs/` 目录持久化进度：

```
项目根目录/
└── .init-docs/
    ├── master-task.md           ← 主任务清单（YAML 元数据 + checklist）
    ├── project-profile.md       ← Phase 2A 输出的项目轮廓报告
    ├── module-list.md           ← Phase 2B 输出的模块清单（用户已确认）
    ├── inventory.md             ← 确定性清单预扫描结果（各类别文件完整列表 + 按模块分组）
    ├── clarifications.md        ← 用户澄清记录（T3 确认结果，避免跨会话重复提问）
    ├── docs-old-manifest.md     ← Phase 1.5 旧文档清单
    ├── extractions/             ← Phase 1.5 结构化提取结果
    │   ├── extraction-architecture.md
    │   ├── extraction-data-model.md
    │   ├── extraction-config.md
    │   ├── extraction-features.md
    │   ├── extraction-testing.md
    │   ├── extraction-deployment.md
    │   └── extraction-other.md
    └── modules/
        ├── <name>-analysis.md   ← 各模块分析报告（含子任务清单 + T1/T2/T3 标注）
        └── ...
```

**`master-task.md` 格式**：YAML 头部记录项目名、技术栈、当前阶段；正文为按 Phase 分组的 checklist（`[x]`/`[/]`/`[ ]`）。

**断点续做**：新会话开始时检查 `.init-docs/master-task.md` 是否存在 → 读取进度 → 恢复上下文（轮廓报告、模块清单、已完成分析） → 从中断点继续。

**关键原则**：每完成一个步骤立即更新 `master-task.md`；子代理完成后立即写入分析报告。

---

## 模式自动升级（标准 → 大型）

> 关于标准模式何时自动升级到大型模式，详见 `operational-conventions.md` 三、异常处理与容错策略 → "模式自动升级（标准 → 大型）"。本文件不再重复以避免两处失真。
