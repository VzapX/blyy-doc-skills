# blyy-doc-skills v0.3.2 → v1.0.0 毕业版整改计划（终极版）

> **定位**：本项目毕业版，直接跳至 v1.0.0 发布，同时进入维护模式。
>
> **核心原则**：
> 1. 修必修 bug
> 2. 做精简到业务语义层的结构性收敛
> 3. 给 1.0.0 应有的稳定契约和完备体验
> 4. 明确维护模式状态，停止积极开发
>
> **精简后的最终定位**："**业务知识文档 Skill**"——只生成 AI 读代码读不出来的业务知识层（业务术语、架构决策、核心流程、模块边界），其他让 AI 直接读代码。
>
> **版本策略**：v1.0.0 发布后，仅接受 bug 修复以 v1.0.x patch 形式发布。1.x 不再有 minor 版本。若未来出现根本性方向变化（例如从文档转为 MCP），将作为独立项目 v2 开启新 repo。
>
> **术语统一**：全项目统一使用"**业务知识文档**"（business knowledge documentation）一个说法，不混用"业务语义层"、"业务知识沉淀"等变体。
>
> **使用方式**：交给 Claude Code CLI 按顺序执行。每个任务独立可验证。

---

## 工作前检查

Claude 开始前请：

1. 确认工作在仓库根目录（包含 `skills/`、`docs/`、`README.md`）
2. 确认 git 工作区干净，创建新分支 `refactor/v1.0.0-graduation`
3. 每完成一个任务提交一次 commit，message 格式：`task: <任务ID> - <一句话>`
4. 涉及删除模板文件的任务，删除前先运行一次完整的 grep 检查，避免遗漏引用（见 P1-3 步骤 0）
5. 执行中发现本文未预料的问题，**先停下来询问**

---

## P0 — 必修 bug（30 分钟）

### P0-1 修复 TODO type 枚举双处定义冲突

**问题**：`skills/blyy-doc-sync/resources/sync-matrix.md:73-75` 定义 `type ∈ {fact, decision, owner, review}`，但 `skills/blyy-init-docs/resources/doc-guide.md:776-786` 定义的是 `{business-context, design-rationale, ops-info, security-info, external-link, metric-baseline}`。`blyy-doc-sync/SKILL.md` 防线 1 Step 4 依赖后者。

**修改文件**：`skills/blyy-doc-sync/resources/sync-matrix.md`

**变更**：将第 64-77 行整段替换为：

```markdown
## 结构化 TODO/UNVERIFIED 标记格式

文档中的占位符必须使用结构化格式：

```markdown
<!-- TODO[priority,type,owner]: 简述 -->
<!-- UNVERIFIED: 简述 -->
```

`priority` / `type` / `owner` 的完整枚举值定义在 `blyy-init-docs/resources/doc-guide.md` 七.4，**本文件不重复定义以避免两处失真**。

防线 1 Step 4 按 priority 顺序处理；防线 3 Step 4 按三维度聚合统计。
```

**验证**：
- `grep -rn "type.*fact.*decision" skills/` 无结果

---

### P0-2 修复 skill_version 版本号脱节

**问题**：`skills/blyy-init-docs/resources/phase3-verification.md:34` 硬编码 `skill_version: blyy-init-docs v0.3.0`，当前已是 v0.3.2。

**修改文件**：`skills/blyy-init-docs/resources/phase3-verification.md`

将第 34 行改为：

```yaml
skill_version: blyy-init-docs v{{SKILL_VERSION}}
```

**新增文件**：
- `skills/blyy-init-docs/VERSION`，内容：`1.0.0`
- `skills/blyy-doc-sync/VERSION`，内容：`1.0.0`

**同步修改** `skills/blyy-init-docs/SKILL.md` Phase 3 入口处加一条：

> 写入基线快照前，从 `skills/blyy-init-docs/VERSION` 读取版本号替换 `{{SKILL_VERSION}}`。

**同步修改** `docs/architecture.md` 的"每次发版必须"章节（第 177-180 行）：

```markdown
每次发版必须：
1. 更新 `docs/CHANGELOG.md`
2. 更新 `skills/blyy-init-docs/VERSION` 和 `skills/blyy-doc-sync/VERSION`
```

**验证**：
- `cat skills/blyy-init-docs/VERSION` 返回 `1.0.0`
- `grep "skill_version" skills/blyy-init-docs/resources/phase3-verification.md` 输出占位符格式

---

### P0-3 修复 CHANGELOG 仓库 URL 用户名

**问题**：`docs/CHANGELOG.md:126-131` 链接到 `wugl/blyy-doc-skills`，实际是 `VzapX/blyy-doc-skills`。

**执行**：
1. 先跑 `git config --get remote.origin.url` 确认实际远端
2. 以实际为准统一：

```bash
sed -i 's|github.com/wugl/blyy-doc-skills|github.com/VzapX/blyy-doc-skills|g' docs/CHANGELOG.md
```

**验证**：`grep "github.com" docs/CHANGELOG.md` 全部一致。

---

## P1 — 结构性收敛（6-8 小时）

### P1-1 重写两个 SKILL.md 的 description

**修改文件 1**：`skills/blyy-init-docs/SKILL.md` 第 3 行

```yaml
description: 为项目一次性生成业务知识文档。当用户要求"初始化文档 / 建立文档骨架 / doc init / 生成文档结构"，或项目从零开始、从遗留项目接手梳理文档时触发。只生成业务语义层文档（架构总览、模块业务职责、业务术语映射、架构决策、跨模块流程），不生成 code-map、api-reference、data-model、deployment、runbook 等代码级或运营级文档——这些 AI 直接读代码或运维系统即可获取。已有 docs/ 自动迁移到 docs-old/ 再做结构化提取。每个项目只运行一次；日常维护用 blyy-doc-sync，不要重复执行。
```

**修改文件 2**：`skills/blyy-doc-sync/SKILL.md` 第 3 行

```yaml
description: 代码变更后保持业务知识文档与代码同步。任何新增/删除/修改源文件、配置、数据库 schema、业务流程后触发，以及用户说"同步文档 / 更新文档 / doc sync / 文档审计"时触发。执行三道防线：实时同步、提交前验证、定期审计。仅维护由 blyy-init-docs 生成的业务知识文档（glossary、modules、core-flow、DECISIONS 等），不管理 code-map、api-reference 等代码级文档（AI 直接读源码）。依赖项目已有 docs/doc-maintenance.md 基线，否则使用内置 fallback 矩阵。不要在没有任何文档体系的项目上强行执行。
```

**验证**：两处 description 都含明确触发条件、定位、负面边界。

---

### P1-2 明确 doc-sync 对 init-docs 的依赖

**修改文件**：`skills/blyy-doc-sync/SKILL.md`

在"前置条件"章节（第 18-21 行）后新增：

```markdown
## 依赖的 Skill

本 Skill 的确定性清点命令矩阵、技术栈锚点矩阵、TODO 枚举定义均**引用** `blyy-init-docs/resources/doc-guide.md`。因此：

- **必须同时安装** `blyy-init-docs` 到同一个技能目录。仅安装本 Skill 会导致资源路径失效。
- 安装脚本默认同时安装两者，不要单独跳过。
```

**修改** `install.sh` 和 `install.ps1`：若用户指定 `--skills blyy-doc-sync` 单独安装，打印警告但不阻止：

```
⚠️ 警告：blyy-doc-sync 依赖 blyy-init-docs 的资源文件。
  单独安装可能导致某些功能不可用。
  建议：./install.sh <project> --skills blyy-init-docs,blyy-doc-sync
```

**验证**：SKILL.md 前置条件提及依赖；单独安装有 warning。

---

### P1-3 用户项目文档精简（核心任务）

**目标**：砍掉 AI 能自推的文档类型，只保留业务知识层。

**精简后最终保留的文档**（7 个 + 根目录文档 + 模块单文件）：

```
项目根目录/
├── README.md                ← 保留
├── AGENTS.md / CLAUDE.md    ← 保留
├── CHANGELOG.md             ← 保留（可选）
├── CONTRIBUTING.md          ← 保留（用户确认）
├── SECURITY.md              ← 保留（用户确认）
└── docs/
    ├── ARCHITECTURE.md      ← 保留：文档入口 + 任务路由表
    ├── modules.md           ← 保留：模块注册表（含功能列表）
    ├── glossary.md          ← 保留：业务术语 ↔ 代码符号 + 字段语义
    ├── core-flow.md         ← 保留：跨模块业务流程
    ├── config.md            ← 保留：配置项的业务语义（不记值/默认）
    ├── DECISIONS.md         ← 保留：ADR
    ├── doc-maintenance.md   ← 保留：基线快照（AI 运行时依赖）
    └── modules/
        └── <module>.md      ← 每个模块一个单文件（见 P1-4）
```

**相比 v0.3.2 移除的文档**：

- `code-map.md`（全局+模块级）—— AI grep 即可
- `api-reference.md`（全局+模块级）—— AI 读 Controller 即可
- `data-model.md`（全局+模块级）—— AI 读实体/migration 即可；字段**业务语义**合并进 glossary.md
- `database/`（全局+模块级）—— schema 本来就是原文
- `deployment.md` / `runbook.md` / `monitoring.md` —— 运维职责，不是 AI 辅助编码所需
- `testing.md` —— AI 读测试目录即可
- `features.md` —— 合并进 `modules.md`，不再单独存在

#### 执行步骤

**步骤 0：执行前建立引用基线**（重要，防止改漏）

在开始删除任何文件前，先跑一遍引用全景扫描，把输出保存到工作笔记里：

```bash
# 记录所有对即将被删文档的引用
grep -rn "code-map\|api-reference\|data-model\|database/\|deployment\|runbook\|monitoring\|testing\|features\.md" \
  skills/ docs/ --include="*.md" --include="*.template" > /tmp/refs-before.txt

# 记录数量基线（便于任务结束时对比）
wc -l /tmp/refs-before.txt
```

完成所有步骤后，再次扫描，对比 `/tmp/refs-before.txt`，确保留下的引用都是"说明性"（CHANGELOG、STATUS、MIGRATION 等文档中的历史说明），而不是"行动性"（"请生成该文档"、"请更新该文档"）。

**步骤 1：删除冗余模板文件**

```bash
# 全局级模板
rm skills/blyy-init-docs/templates/docs/code-map.md.template
rm skills/blyy-init-docs/templates/docs/api-reference.md.template
rm skills/blyy-init-docs/templates/docs/data-model.md.template
rm skills/blyy-init-docs/templates/docs/testing.md.template
rm skills/blyy-init-docs/templates/docs/deployment.md.template
rm skills/blyy-init-docs/templates/docs/runbook.md.template
rm skills/blyy-init-docs/templates/docs/monitoring.md.template
rm skills/blyy-init-docs/templates/docs/features.md.template
rm -rf skills/blyy-init-docs/templates/docs/database/

# 模块级模板（P1-4 会进一步清理，此处先删掉被砍的）
rm skills/blyy-init-docs/templates/modules/code-map.md.template
rm skills/blyy-init-docs/templates/modules/api-reference.md.template
rm skills/blyy-init-docs/templates/modules/data-model.md.template
rm -rf skills/blyy-init-docs/templates/modules/database/
```

**步骤 2：修改 ARCHITECTURE.md.template**

修改 `skills/blyy-init-docs/templates/docs/ARCHITECTURE.md.template`：

**2.1 在 H1 标题后的 AI-READ-HINT 块之后**，增加定位说明段：

```markdown
> **本文档集定位**：业务知识文档。只沉淀 AI 读代码读不出的信息（业务术语、架构决策、跨模块流程、模块业务职责）。代码结构、API 详情、表结构请让 AI 直接读源码；数据库字段的业务语义集中在 [glossary.md](glossary.md)。
```

**2.2 任务路由表重写**（第 44-54 行附近）：

```markdown
| 任务类型 | 必读 | 按需读 | 不要读 |
|---------|------|--------|--------|
| 修复某模块 bug | `modules/<m>.md` | `core-flow.md`（涉及跨模块时） | 其他模块文档 |
| 新增功能 / API | `modules/<m>.md` → `glossary.md` | `DECISIONS.md`、`core-flow.md` | — |
| 修改配置项 | `config.md` | 调用方模块文档 | — |
| 新增/修改数据库表 | `glossary.md`（业务含义）+ 代码中的实体类/migration（字段定义） | `DECISIONS.md` | — |
| 理解整体架构 | 本文档 → `modules.md` | `core-flow.md`、`DECISIONS.md` | 模块内部 |
| 用业务语言找代码 | `glossary.md` → `modules/<m>.md` | — | — |
| 修改 API 接口 | `modules/<m>.md`（职责边界）+ 直接读 Controller 代码 | — | — |
```

**2.3 文档索引表重写**（第 58-75 行附近）：

```markdown
| 文档 | 目的 | Layer |
|------|------|-------|
| [modules.md](modules.md) | 模块注册表 + 功能列表 + 依赖关系 | 1 |
| [glossary.md](glossary.md) | 业务术语 ↔ 代码符号 + 字段业务语义 | 1 |
| [modules/](modules/) | 各模块业务文档 | 2 |
| [core-flow.md](core-flow.md) | 跨模块业务流程 | 3 |
| [config.md](config.md) | 配置项业务语义 | 3 |
| [DECISIONS.md](DECISIONS.md) | 架构决策记录（ADR） | 3 |
| [doc-maintenance.md](doc-maintenance.md) | 文档维护规则（AI 运行时） | 4 |
```

**步骤 3：修改 modules.md.template（含合并 features）**

修改 `skills/blyy-init-docs/templates/docs/modules.md.template`：

**3.1 去掉 Core/Standard/Lightweight 三组分类**（P1-4 会彻底处理，这一步先合并表格）

**3.2 在模块注册表后、模块间依赖前，增加"功能列表"章节**：

```markdown
## 功能列表

<!-- Phase 2 自动填充：从模块对外接口、CLI 命令、Web 页面等提取的用户可见功能 -->

| 功能 | 所属模块 | 状态 | 入口位置 |
|------|---------|------|---------|
| <!-- Phase 2 --> | | active/deprecated | `<!-- file:line -->` |
```

**3.3 文件头部的 AI-READ-HINT 调整**：
```
PURPOSE: 模块注册表 + 功能清单 + 依赖关系。AI 定位业务模块和功能的索引页。
```

**步骤 4：修改 glossary.md.template 增加字段语义章节**

修改 `skills/blyy-init-docs/templates/docs/glossary.md.template`，在现有术语表之后新增：

```markdown
## 字段业务语义

> 记录数据库/实体类字段中**字段名推断不出**的业务含义。字段定义、类型、约束请 AI 直接读实体类或 migration。

| 字段（实体.字段） | 业务含义 | 取值范围（如有） | 代码位置 |
|------------------|---------|----------------|---------|
| <!-- 例：Order.Status --> | <!-- 0=待支付 1=已支付 2=已发货 3=已完成 9=已取消 --> | | <!-- file:line --> |

> **只记录需要业务解释的字段**。`id`、`created_at` 这类常见字段不要列进来。
```

并在文件头部 AI-READ-HINT 更新：
```
PURPOSE: 业务术语 ↔ 代码符号映射 + 字段业务语义。AI 从业务语言定位代码，或理解代码字段的业务含义。
```

**步骤 5：更新 SKILL.md 的 Phase 1 骨架清单**

修改 `skills/blyy-init-docs/SKILL.md` 第 122-156 行的目录树，替换为精简后的清单。删除所有被砍文档，调整树形图。

**步骤 6：更新 doc-guide.md**

修改 `skills/blyy-init-docs/resources/doc-guide.md`：

- 第 7-37 行"文档架构总览"：更新目录树为精简版
- 第 55-68 行"各文档职责定义"表：删除所有被砍文档的行
- 第 574-641 行"项目类型适配指南"：
  - "适配矩阵"表中删除被砍文档的相关列
  - "模板条件化生成清单"表删除被砍文档
- 全文搜索并修复对 `code-map.md` / `api-reference.md` / `data-model.md` / `database/` / `deployment.md` / `runbook.md` / `monitoring.md` / `testing.md` / `features.md` 的所有**行动性引用**（改为"AI 读代码即可"或删除）

**步骤 7：更新 sync-matrix.md**

修改 `skills/blyy-doc-sync/resources/sync-matrix.md`，整个映射表简化为：

```markdown
## 映射矩阵

| 代码变更类型 | 需更新的文档 | 更新内容 |
|-------------|-------------|---------|
| 新增/删除模块 | `docs/modules.md` + `modules/<m>.md` | 注册表加减 + 创建/归档单文件 |
| 模块职责/边界变更 | `modules/<m>.md` | 更新职责与边界章节 |
| 跨模块业务流程变化 | `docs/core-flow.md` | 更新流程图与说明 |
| 模块内业务流程变化 | `modules/<m>.md` 的流程章节 | 更新模块内流程 |
| 新增/移除用户可见功能 | `docs/modules.md` 的功能列表 | 功能表加/改一行 |
| 配置项的业务语义变更 | `docs/config.md` | 更新说明列（不记值/默认） |
| 新增架构决策 | `docs/DECISIONS.md` | 新增 ADR 条目 |
| 新增/重命名核心实体类 | `docs/glossary.md` | 更新术语 ↔ 代码符号表 |
| 数据库字段增加/改变业务含义 | `docs/glossary.md` 字段语义表 | 新增/更新字段业务含义 |
| 模块入/出依赖变化 | `docs/modules.md` | 更新依赖表 |
| 发布新版本 | `CHANGELOG.md` | 新增版本条目 |
```

**步骤 8：更新 phase3-verification.md 检查清单**

修改 `skills/blyy-init-docs/resources/phase3-verification.md`，简化为：

```markdown
## 检查项清单

> **核心原则**：基于确定性清单比对，不重新扫描代码。

1. 确认所有文档的 YAML 元数据正确
2. 确认 `ARCHITECTURE.md` 文档索引覆盖所有生成的文档
3. 确认无断链引用
4. **模块完整性**：对比确定性清单识别的模块 vs `modules.md` 注册表
5. **术语完整性**：对比代码中核心实体类 vs `glossary.md` 条目
6. **功能完整性**：对比代码中对外接口/CLI 命令 vs `modules.md` 功能列表
7. **旧文档回收率**（仅当存在 `docs-old/` 时）
8. **文档可信度统计**（T1/T2/T3 分布）
9. **基线快照写入** `doc-maintenance.md`
10. 清理临时目录
```

基线快照 YAML schema 同步调整：

```yaml
inventory:
  modules: P
  entities: N          # 供 glossary 字段语义表完整性比对
  features: F          # 供 modules.md 功能列表比对
  config_items: L
```

（删除 `controllers`、`services`、`api_endpoints`、`tests`——这些条目本来是用于 data-model/api-reference/testing 等被砍文档的完整性校验的。）

**步骤 9：更新 defense-line-3-audit.md**

修改 `skills/blyy-doc-sync/resources/defense-line-3-audit.md`：
- Step 2 文档比对表只保留：模块、术语、功能、配置
- Step 3 详细检查删除对被砍文档的检查项

**步骤 10：更新 SKILL.md 的防线 1 Step 2 扫描表**

修改 `skills/blyy-doc-sync/SKILL.md` 第 52-58 行（"影响区域确定性扫描"表）：

```markdown
| 变更涉及的区域 | 确定性扫描动作 | 比对目标 |
|---------------|--------------|---------|
| 实体/模型文件 | `fd -e {ext} -p "Entity\|Model" --type f` | `docs/glossary.md` 的字段语义表条目覆盖度 |
| 配置文件 | `fd "appsettings\|config\|.env" --type f` | `docs/config.md` 中列出的配置项数量 |
| 模块目录 | 检查 `docs/modules/` 下文件 vs 代码中模块 | `docs/modules.md` 注册表条目数 |
```

**验证**：
- `ls skills/blyy-init-docs/templates/docs/` 只含：ARCHITECTURE / DECISIONS / config / core-flow / doc-maintenance / glossary / modules
- `ls skills/blyy-init-docs/templates/modules/` 只含（P1-4 之前）：README / flow
- 步骤 0 的引用基线 `/tmp/refs-before.txt` 重跑后，残余引用都在 CHANGELOG / STATUS / MIGRATION / 本任务注释中，没有遗留的"请生成/更新该文档"指令

---

### P1-4 砍掉模块三级分化，统一单文件

**方案**：所有模块统一用 `docs/modules/<m>.md` 单文件。删除 Core/Standard/Lightweight、复杂度评分、升降级检测。

#### 执行步骤

**步骤 1：处理模块模板**

1. 将 `skills/blyy-init-docs/templates/modules-single.md.template` 的内容作为新的模块统一模板基础
2. 删除所有模块级子文件模板：

```bash
rm skills/blyy-init-docs/templates/modules/README.md.template
rm skills/blyy-init-docs/templates/modules/flow.md.template
# modules/code-map/api-reference/data-model/database 已在 P1-3 删除
```

3. 将 `modules-single.md.template` 移动为唯一模块模板 `templates/modules/<MODULE_NAME>.md.template`（但文件名保持为占位符形式，实际生成时用模块名替换）。**简化做法**：新建 `templates/modules/_module.md.template` 作为唯一模板，SKILL.md 中明确"为每个识别到的模块生成 `modules/<m>.md`，使用此模板"。

```bash
mv skills/blyy-init-docs/templates/modules-single.md.template skills/blyy-init-docs/templates/modules/_module.md.template
```

4. 编辑 `templates/modules/_module.md.template`：

   **4.1** 删除 front matter 中 `module_tier: standard` 字段
   
   **4.2** 删除 AI-READ-HINT 块中的 `UPGRADE-HINT` 行
   
   **4.3** 调整 `max_lines` 到 400
   
   **4.4** 精简章节结构为 5 节（去掉"对外接口"章节，AI 直接读 Controller）：
   
   ```markdown
   ## 概述
   ## 职责与边界
   ## 依赖关系
   ## 核心业务流程
   ## 代码锚点
   ```

   "代码锚点"章节的内容指引：
   ```markdown
   ## 代码锚点
   
   > 本模块的关键代码位置。AI 可据此直接读源码获取详细信息，本文档不再重复。
   
   | 类型 | 位置 | 说明 |
   |------|------|------|
   | 模块入口 | <!-- 例：src/Modules/Orders/ --> | |
   | 主要 Service | <!-- OrderService.cs --> | |
   | 主要 Controller | <!-- OrderController.cs --> | |
   | 数据模型 | <!-- OrderEntity.cs --> | |
   | 数据库 migration | <!-- Migrations/*.Orders_*.cs --> | |
   ```

**步骤 2：改写 modules.md.template**

修改 `skills/blyy-init-docs/templates/docs/modules.md.template`：

**2.1** 删除 Core/Standard/Lightweight 三组分类，替换为统一注册表：

```markdown
## 模块注册表

| 模块 | 职责（一句话） | 代码根目录 | 模块文档 |
|------|---------------|-----------|---------|
| <!-- Phase 2 --> | | `<!-- dir/path -->` | [→ 详情](modules/<n>.md) |
```

**2.2** "功能列表"章节保持（P1-3 步骤 3 已添加）

**2.3** "模块间依赖"章节保持

**2.4** "模块边界约定"章节保持

**步骤 3：从 SKILL.md 删除三级分化逻辑**

修改 `skills/blyy-init-docs/SKILL.md`：

- 删除"模块复杂度评分与分级"整节（约第 266-318 行）
- 删除 Phase 2 Layer 2 中的 Core/Standard/Lightweight 分别处理逻辑（约第 478-507 行），改为"为每个模块使用 `templates/modules/_module.md.template` 生成一个 `modules/<m>.md`"
- 删除 `progress.md` YAML 中的 `module_tiers` 字段（约第 331-334 行）
- 删除任何提及"Core 模块"、"Standard 模块"、"Lightweight 模块"的描述（除非在 MIGRATION 或 CHANGELOG 的历史上下文中）

**步骤 4：从 doc-guide.md 删除三级分化**

修改 `skills/blyy-init-docs/resources/doc-guide.md`：

- 删除"模块复杂度评分规则"整段（约第 74-84 行）
- 删除"三级文档形态"表（约第 86-91 行）
- 删除"Core 模块文档清单"、"Standard 模块文档"、"Lightweight 模块"的说明（约第 93-110 行）
- 删除"级别升降规则"（约第 112-117 行）
- 全文搜索 `Core 模块`、`Standard 模块`、`Lightweight 模块`、`module_tier`、`modules-single`，除 CHANGELOG 外全部删除或改写

**步骤 5：从 doc-sync 删除升降级检测**

修改 `skills/blyy-doc-sync/SKILL.md`：
- 删除防线 1 的 Step 2.5 整段（约第 66-92 行）
- Step 3 涉及"按级别创建/归档"改为"创建/归档单文件 `modules/<m>.md`"
- 执行清单删除级别相关条目

修改 `skills/blyy-doc-sync/resources/defense-line-3-audit.md`：
- 删除 Step 2.5（模块分级全量复评）整段
- 趋势对比输出删除"模块分级"行

修改 `skills/blyy-doc-sync/resources/sync-matrix.md`：P1-3 步骤 7 已重写，确认无"级别升级/降级"行

**步骤 6：清理基线快照 schema**

修改 `skills/blyy-init-docs/templates/docs/doc-maintenance.md.template`：
- 基线快照 YAML 删除 `module_tiers` 字段
- 历史趋势表删除分级分布列（C/S/L）

修改 `skills/blyy-init-docs/resources/phase3-verification.md`：
- 基线快照 YAML schema 删除 `module_tiers`
- 历史趋势表删除分级分布列

**验证**：
- `grep -rn "module_tier\|Core 模块\|Standard 模块\|Lightweight 模块\|modules-single" skills/ --include="*.md"` 只剩 CHANGELOG 历史记录
- `ls skills/blyy-init-docs/templates/modules/` 只含 `_module.md.template`
- `ls skills/blyy-init-docs/templates/modules-single.md.template` 报错不存在
- SKILL.md 不再有"评分"、"升级"、"降级"流程

---

## P2 — 毕业仪式与 1.0.0 稳定契约（2-3 小时）

### P2-1 添加 STATUS.md

**新增文件**：仓库根目录 `STATUS.md`

```markdown
# 项目状态

**当前版本**：v1.0.0
**维护状态**：🌿 维护模式（Maintenance Mode）
**稳定契约**：已锁定

---

## 一句话定位

本项目是一套为 AI 编码工具设计的**业务知识文档 Skill**，核心思路是：**只外化 AI 读代码读不出来的业务知识**（业务术语、架构决策、跨模块流程、模块边界），其他信息让 AI 直接读代码。

## 为什么是 v1.0.0 和维护模式

v1.0.0 意味着：

- **公共契约已稳定**：模板结构、YAML 字段、标记格式、资源文件组织等对外接口在 1.x 生命周期内不会破坏性变更
- **核心设计已收敛**：经过 0.1 - 0.3 的演进和 1.0.0 的精简，定位已清晰，不再追求功能扩张
- **进入维护期**：不再积极迭代，原因是随着大模型能力快速提升（上下文、代码理解、Agent 能力），预构造复杂文档脚手架的边际价值在下降

## 设计哲学

**只做 AI 读代码读不出的那层**。具体：

- ✅ 业务术语 ↔ 代码符号映射（glossary）
- ✅ 数据库字段的业务语义（glossary 的字段语义章节）
- ✅ 架构决策的动机（DECISIONS/ADR）
- ✅ 跨模块业务流程（core-flow）
- ✅ 模块业务职责与边界（modules）
- ✅ 用户可见功能清单（modules.md 的功能列表）
- ✅ 配置项的业务语义（config.md）

**不做**的：

- ❌ 代码文件职责映射（AI grep 即可）
- ❌ API 接口详情（AI 读 Controller 即可）
- ❌ 数据库表结构细节（AI 读实体/migration 即可；字段业务语义放 glossary）
- ❌ 部署/监控/运维文档（属于 Ops 职责，不是 AI 辅助编码所需）
- ❌ 测试策略文档（AI 读测试目录即可）

## 版本策略

- **1.0.x**：仅 bug 修复，不引入新功能或破坏性变更
- **不会有 1.1 / 1.2**：若需新增 minor 功能，可能开启独立 fork 或 v2 新项目
- **2.0 假设性触发条件**：若未来出现根本性方向变化（如转为 MCP server 形态），作为新项目发布，不强制升级 1.x 用户

## 仍然做什么

- 修关键 bug
- 接受质量达标的 PR
- 在作者自己的项目上持续使用和验证

## 不再做什么

- 新增大功能
- 为超大型项目做专门优化
- 商业化路径
- 恢复已砍掉的文档类型

## 谁适合用

**适合**：
- 中小型项目（< 50 模块）
- 认同"AI 应读代码，文档只沉淀业务知识"的理念
- 希望文档维护成本可控
- 有业务语义复杂度（术语多、字段含义复杂、决策需要记录）的项目

**不适合**：
- 期望"零维护，全自动生成完整文档集"
- 需要完整 data-model / api-reference 生成的场景（建议用 Swagger/OpenAPI）
- 超大型单体项目
- 纯工具型/算法型项目（业务知识少，收益有限）

## 核心设计沉淀

即使项目不再积极开发，以下原则独立于本 Skill，在其他知识库工具中同样适用：

1. **三级事实分类（T1/T2/T3）**——区分确定性事实、高置信推断、推测性内容
2. **确定性清单优先于 AI 阅读**——shell 命令建立基线，避免 AI 自由发挥遗漏
3. **渐进式加载**——SKILL.md 只含入口，详细流程按需加载
4. **code_anchors + last_synced_commit**——文档与代码同步的增量契约
5. **结构化 TODO[priority,type,owner]**——让文档缺口可程序化处理
6. **业务知识 vs 代码推断的边界**——外化只做 AI 推不出的那部分

## 反馈

- 报告 bug：GitHub Issues
- 安全问题：见 [SECURITY.md](./SECURITY.md)

---

_最后更新：v1.0.0 发布_
```

**同步修改** `README.md`：

1. 顶部在 English/中文切换链接上方增加徽章：

```markdown
[![Status](https://img.shields.io/badge/status-maintenance_mode-yellow.svg)](./STATUS.md)
[![Version](https://img.shields.io/badge/version-v1.0.0-blue.svg)](./docs/CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
```

2. "How It Works / 工作原理"小节改写为（中英文都改）：

```markdown
### How It Works

**blyy-doc-skills** generates and maintains **business knowledge documentation** — the information that AI cannot infer from source code alone. Code-level details (file maps, API specs, table schemas) are deliberately NOT generated; AI reads those directly from source.

- **blyy-init-docs**: Scans your codebase and generates the business knowledge docs (architecture overview, module business responsibilities, glossary of business terms and field semantics, architecture decisions, cross-module flows)
- **blyy-doc-sync**: Keeps these docs in sync with code changes via a three-line-of-defense strategy
```

**验证**：
- `STATUS.md` 存在且内容完整
- README 顶部有三个徽章
- README "工作原理"体现新定位
- `grep -c "业务知识" STATUS.md` ≥ 5（术语一致性）

---

### P2-2 添加 SECURITY.md

**新增文件**：仓库根目录 `SECURITY.md`（注意：不是 `templates/root/SECURITY.md.template`，那个是给用户项目用的）

```markdown
# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅ Security fixes |
| < 1.0   | ❌ Not supported |

## Reporting a Vulnerability

If you discover a security issue in this skill (e.g., a flaw that would cause the skill to leak secrets, execute arbitrary code on behalf of a user, or corrupt user documents), please:

1. **Do NOT open a public issue**
2. Report via GitHub Security Advisory (preferred) or email the maintainer
3. Include: affected files, reproduction steps, potential impact

## Scope

**In scope**:
- Skill instructions that could cause AI to leak user secrets into generated docs
- Shell command injection in install scripts or skill-generated scripts
- Path traversal in file operations

**Out of scope**:
- Issues in user-side AI tools (Claude Code, Gemini, etc.)
- Issues in user projects that happen to use this skill
- Feature requests or general bugs (use regular Issues)

## Maintenance Mode Notice

This project is in maintenance mode. Security fixes will be prioritized, but non-critical issues may take longer to address.
```

---

### P2-3 添加迁移指南（v0.3.x → v1.0）

**新增文件**：`docs/MIGRATION-v1.md`

```markdown
# 从 v0.3.x 升级到 v1.0 指南

> v1.0.0 是从"全量文档生成器"到"业务知识文档 Skill"的重大定位调整。升级涉及**破坏性变更**。
>
> **是否应该升级？** 见本文最后一节的决策矩阵。

---

## 主要变更概览

### 文档类型

| 类型 | v0.3.x | v1.0 |
|------|--------|------|
| `ARCHITECTURE.md` | ✅ | ✅ |
| `modules.md` | ✅ | ✅（合并了 features） |
| `glossary.md` | ✅ | ✅（新增字段语义章节） |
| `core-flow.md` | ✅ | ✅ |
| `config.md` | ✅ | ✅（仅业务语义，不记值） |
| `DECISIONS.md` | ✅ | ✅ |
| `doc-maintenance.md` | ✅ | ✅ |
| `features.md` | ✅ | ❌（合并进 modules.md） |
| `code-map.md` | ✅ | ❌ |
| `api-reference.md` | ✅ | ❌ |
| `data-model.md` | ✅ | ❌（字段业务语义迁入 glossary） |
| `database/` | ✅ | ❌ |
| `deployment.md` | ✅ | ❌ |
| `runbook.md` | ✅ | ❌ |
| `monitoring.md` | ✅ | ❌ |
| `testing.md` | ✅ | ❌ |
| `modules/<m>/` 目录形态（Core） | ✅ | ❌（统一为单文件） |
| `modules/<m>.md` 单文件（Standard） | ✅ | ✅（所有模块） |

### 模块级变化

v0.3.x 的三级分化（Core/Standard/Lightweight）**全部移除**。所有模块统一为 `modules/<m>.md` 单文件，5 个章节：概述 / 职责与边界 / 依赖关系 / 核心业务流程 / 代码锚点。

### Skill 指令

- `SKILL.md` 的 `description` 字段重写
- `sync-matrix.md` / `phase3-verification.md` / `defense-line-3-audit.md` 同步收缩
- 基线快照 YAML 删除 `module_tiers` 字段

## 升级步骤

### 方案 A：保留旧文档，只升级 Skill（推荐给"已有稳定项目文档"的用户）

1. `git pull` 新版 skill 到 `.claude/skills/` 或 `.agents/skills/`
2. 旧项目中已生成的 `code-map.md`、`api-reference.md`、`data-model.md`、`deployment.md` 等**保留原地**——新 skill 不会主动删除它们
3. 新 skill 的 `blyy-doc-sync` 将**不再自动维护**这些文档——用户需自行决定是维持人工维护还是逐步淘汰
4. 对项目中的 `modules/<m>/` 完整目录形态（Core 模块），可**选择保留**，新 skill 不强制合并；`blyy-doc-sync` 会把它们视为单个模块的"目录形式"处理（但不会新生成此形态）

### 方案 B：完全对齐 v1.0 结构（推荐给"想彻底简化"的用户）

1. 在项目中运行：
   ```bash
   mkdir -p docs-legacy-v0
   mv docs/code-map.md docs-legacy-v0/ 2>/dev/null
   mv docs/api-reference.md docs-legacy-v0/ 2>/dev/null
   mv docs/data-model.md docs-legacy-v0/ 2>/dev/null
   mv docs/database docs-legacy-v0/ 2>/dev/null
   mv docs/deployment.md docs-legacy-v0/ 2>/dev/null
   mv docs/runbook.md docs-legacy-v0/ 2>/dev/null
   mv docs/monitoring.md docs-legacy-v0/ 2>/dev/null
   mv docs/testing.md docs-legacy-v0/ 2>/dev/null
   # features 的内容手工合并进 modules.md 的功能列表后
   mv docs/features.md docs-legacy-v0/ 2>/dev/null
   ```

2. 对 `modules/<m>/` 目录形态的模块，手工合并为单文件：
   - 创建 `modules/<m>.md`
   - 把目录内的 README.md / flow.md 的有价值内容合并进去（按新的 5 章节结构）
   - `code-map.md` / `data-model.md` / `api-reference.md` 中的**业务含义**迁移到 `glossary.md` 的字段语义章节或各处合适位置；纯代码结构信息丢弃
   - 移动整个目录到 `docs-legacy-v0/modules-old/<m>/` 备份
   
3. 在一次 AI 会话中让 blyy-doc-sync 防线 3 做一次全量审计，更新 `doc-maintenance.md` 基线

### 方案 C：完全重建（适合"旧文档已经很乱"的场景）

```bash
# 1. 备份整个 docs/
mv docs docs-legacy-full

# 2. 重新运行 blyy-init-docs
# 新 skill 会把 docs-legacy-full 作为 docs-old 处理，执行 Phase 1.5 结构化提取
```

## 应该升级吗？

| 当前状态 | 建议 |
|---------|------|
| 还在 v0.1 / v0.2 | ✅ 升级，收益明显 |
| v0.3.x，文档已稳定且低维护成本 | 🟡 评估后决定，不紧急 |
| v0.3.x，代码级文档（data-model 等）经常漂移或被忽视 | ✅ 升级，v1.0 的精简能缓解这些问题 |
| v0.3.x，团队已深度依赖 api-reference / data-model 等被砍文档 | ❌ 不要升级（或切换到专门工具如 Swagger） |
| 新项目 | ✅ 直接用 v1.0 |

## 遇到问题？

升级过程中遇到未列出的问题，请开 Issue。项目已进入维护模式，响应可能较慢。
```

---

### P2-4 编写 v1.0.0 CHANGELOG 条目

**修改文件**：`docs/CHANGELOG.md`

在顶部 `## [0.3.2]` 之前插入：

```markdown
## [1.0.0] — {当前日期}

> 🎓 **毕业版本 — 进入维护模式**。
>
> - 定位声明：[STATUS.md](../STATUS.md)
> - 升级指南：[MIGRATION-v1.md](./MIGRATION-v1.md)
> - 安全策略：[SECURITY.md](../SECURITY.md)
>
> 这是 1.x 的起点，也是最后一个主动迭代的版本。1.0.x 仅接受 bug 修复。

### 重大定位调整

从"全量文档生成器"收敛为"**业务知识文档 Skill**"。只生成 AI 读代码读不出来的业务知识层（业务术语、架构决策、跨模块流程、模块业务职责），其他让 AI 直接读代码。

### 移除（破坏性变更）

**全局级文档移除**：
- `code-map.md` —— AI grep 代码即可
- `api-reference.md` —— AI 读 Controller 即可
- `data-model.md` —— AI 读实体/migration 即可；字段业务语义合并到 `glossary.md` 字段语义章节
- `database/` —— schema 原文无需重复
- `deployment.md` / `runbook.md` / `monitoring.md` —— 运维职责，不是 AI 辅助编码所需
- `testing.md` —— AI 读测试目录即可
- `features.md` —— 合并为 `modules.md` 的"功能列表"章节

**模块级文档移除**：
- 模块三级分化（Core / Standard / Lightweight）**全部删除**
- 所有模块统一用 `modules/<m>.md` 单文件，5 章节结构
- 模块级 `code-map.md` / `api-reference.md` / `data-model.md` / `database/` / `flow.md` / `README.md` 等子文件模板删除
- 复杂度评分、升降级检测、`module_tiers` 字段全部移除

### 保留（v1.0 文档清单）

**全局**：
- `ARCHITECTURE.md`（文档入口 + 任务路由表）
- `modules.md`（模块注册表 + 功能列表 + 依赖关系）
- `glossary.md`（业务术语 ↔ 代码符号 + 字段业务语义）
- `core-flow.md`（跨模块业务流程）
- `config.md`（配置项业务语义，不记值/默认）
- `DECISIONS.md`（ADR）
- `doc-maintenance.md`（AI 运行时依赖）

**模块**：`modules/<m>.md` 单文件

### 新增

- `STATUS.md` —— 项目状态、设计哲学、版本策略声明
- `SECURITY.md` —— 安全问题报告流程
- `docs/MIGRATION-v1.md` —— v0.3.x 升级指南
- `skills/*/VERSION` —— 独立版本号文件
- README 顶部维护模式 / 版本 / License 徽章
- `glossary.md` 模板新增"字段业务语义"章节
- `modules.md` 模板新增"功能列表"章节

### 修复

- TODO `type` 枚举在两处定义冲突（#P0-1）
- `skill_version` 硬编码版本号脱节（#P0-2）
- CHANGELOG 仓库 URL 用户名不一致（#P0-3）

### 改进

- 两个 SKILL.md 的 `description` 显式化触发条件和负面边界（#P1-1）
- 明确声明 `blyy-doc-sync` 对 `blyy-init-docs` 的安装依赖；install 脚本补充单独安装时的警告（#P1-2）
- 全项目术语统一为"业务知识文档"

### 版本策略（从本版开始生效）

- 1.0.x：仅 bug 修复
- 不会有 1.1 / 1.2 minor 版本
- 若出现根本性方向变化（如转为 MCP），作为独立项目 v2 发布

---

```

**验证**：CHANGELOG 顶部有 v1.0.0 条目；交叉引用的三个文档（STATUS / MIGRATION / SECURITY）都已创建。

---

### P2-5 补充 .github 基础设施（最小化）

**目的**：1.0.0 作为公开项目应有的最低限度 GitHub 配置，但配合维护模式做极简处理。

**新增文件**：`.github/ISSUE_TEMPLATE/config.yml`

```yaml
blank_issues_enabled: true
contact_links:
  - name: 📖 Read STATUS.md first
    url: https://github.com/<OWNER>/blyy-doc-skills/blob/main/STATUS.md
    about: This project is in maintenance mode. Please read STATUS.md to understand what's in scope before opening an issue.
  - name: 🔒 Report a security issue
    url: https://github.com/<OWNER>/blyy-doc-skills/security/advisories/new
    about: Do not open public issues for security vulnerabilities.
```

（执行时把 `<OWNER>` 替换为实际 GitHub 用户名，通过 `git config --get remote.origin.url` 确认）

**验证**：`.github/ISSUE_TEMPLATE/config.yml` 存在。

---

## P3 — 可选沉淀（1 小时，可跳过）

### P3-1 编写设计原则独立文档

**目的**：把你在做这个 skill 过程中想明白的原则沉淀为独立资产。即使 skill 废了这份文档还在，对未来写博客、做其他工具、甚至求职都有用。

**新增文件**：`docs/DESIGN-PRINCIPLES.md`

内容见上版计划的 P2-3，此处略。**完全可选**，不做不影响发版。

如果不做这一任务，STATUS.md 最后的"核心设计沉淀"章节就是唯一的设计原则记录，这也够用。

---

## 执行完成后的完整验证清单

```bash
cd /your/repo

# 1. 无枚举冲突
! grep -rn "type.*fact.*decision" skills/

# 2. 版本号统一到 1.0.0
cat skills/blyy-init-docs/VERSION              # 1.0.0
cat skills/blyy-doc-sync/VERSION                # 1.0.0
grep -A1 "## \[1.0.0\]" docs/CHANGELOG.md | head -3

# 3. 仓库 URL 统一
USERNAME=$(git config --get remote.origin.url | grep -oP '(?<=/)[^/]+(?=/blyy-doc-skills)')
! grep "github.com" docs/CHANGELOG.md | grep -v "$USERNAME"

# 4. 毕业文档齐全
ls STATUS.md SECURITY.md docs/MIGRATION-v1.md
grep -c "v1.0.0" STATUS.md           # ≥ 2
grep -c "业务知识文档" STATUS.md     # ≥ 3（术语一致性）

# 5. 被砍模板已移除
for f in \
  skills/blyy-init-docs/templates/docs/code-map.md.template \
  skills/blyy-init-docs/templates/docs/api-reference.md.template \
  skills/blyy-init-docs/templates/docs/data-model.md.template \
  skills/blyy-init-docs/templates/docs/testing.md.template \
  skills/blyy-init-docs/templates/docs/deployment.md.template \
  skills/blyy-init-docs/templates/docs/runbook.md.template \
  skills/blyy-init-docs/templates/docs/monitoring.md.template \
  skills/blyy-init-docs/templates/docs/features.md.template \
  skills/blyy-init-docs/templates/modules/README.md.template \
  skills/blyy-init-docs/templates/modules/flow.md.template \
  skills/blyy-init-docs/templates/modules/code-map.md.template \
  skills/blyy-init-docs/templates/modules/api-reference.md.template \
  skills/blyy-init-docs/templates/modules/data-model.md.template \
  skills/blyy-init-docs/templates/modules-single.md.template; do
  [ ! -e "$f" ] || echo "❌ 未删除: $f"
done
[ ! -d skills/blyy-init-docs/templates/docs/database ] || echo "❌ 未删除: docs/database 目录"
[ ! -d skills/blyy-init-docs/templates/modules/database ] || echo "❌ 未删除: modules/database 目录"

# 6. 保留文档齐全
for f in \
  skills/blyy-init-docs/templates/docs/ARCHITECTURE.md.template \
  skills/blyy-init-docs/templates/docs/DECISIONS.md.template \
  skills/blyy-init-docs/templates/docs/config.md.template \
  skills/blyy-init-docs/templates/docs/core-flow.md.template \
  skills/blyy-init-docs/templates/docs/doc-maintenance.md.template \
  skills/blyy-init-docs/templates/docs/glossary.md.template \
  skills/blyy-init-docs/templates/docs/modules.md.template \
  skills/blyy-init-docs/templates/modules/_module.md.template; do
  [ -e "$f" ] || echo "❌ 缺失: $f"
done

# 7. 被砍文档不再被引用为"要生成/更新"
# 输出应只有 CHANGELOG / STATUS / MIGRATION / 任务注释等说明性引用
grep -rn "code-map\.md\|api-reference\.md\|data-model\.md\|testing\.md\|monitoring\.md\|runbook\.md\|deployment\.md\|features\.md" \
  skills/ --include="*.md" | \
  grep -v "CHANGELOG\|STATUS\|MIGRATION\|## " | \
  head -20
# 手动审视这个输出，确认都是无害的描述性引用

# 8. 三级分化彻底清除
! grep -rn "module_tier\|Core 模块\|Standard 模块\|Lightweight 模块\|modules-single" \
  skills/ --include="*.md" | grep -v CHANGELOG | grep -v MIGRATION

# 9. glossary 字段语义章节存在
grep -q "字段业务语义" skills/blyy-init-docs/templates/docs/glossary.md.template

# 10. modules.md 功能列表章节存在
grep -q "功能列表" skills/blyy-init-docs/templates/docs/modules.md.template

# 11. 模块单文件模板只有 5 章节
grep -c "^## " skills/blyy-init-docs/templates/modules/_module.md.template  # 应为 5

# 12. description 更新
grep -A1 "^description:" skills/blyy-init-docs/SKILL.md | head -3    # 含"业务知识文档"
grep -A1 "^description:" skills/blyy-doc-sync/SKILL.md | head -3      # 含"业务知识文档"

# 13. install 脚本语法正确
bash -n install.sh

# 14. README 徽章
grep -c "img.shields.io" README.md      # ≥ 3（Status / Version / License）

# 15. .github 基础设施
ls .github/ISSUE_TEMPLATE/config.yml

# 16. LICENSE 仍然存在
ls LICENSE
```

全部通过后：

1. 合并 `refactor/v1.0.0-graduation` 到主分支
2. 打 tag `v1.0.0`
3. 发布 GitHub Release（标题：`v1.0.0 - Graduation Release`），正文复制 CHANGELOG 的 v1.0.0 条目
4. （可选）把 v1.0.0 置顶为 latest release

---

## 明确不做的事

本次整改**明确不做**：

- ❌ 拆分 `doc-guide.md`（精简后自然瘦身）
- ❌ 单独瘦身 SKILL.md
- ❌ 沉淀 shell 到 `scripts/` 目录
- ❌ CLAUDE.md / Copilot 专用模板
- ❌ Cursor 特殊适配
- ❌ install 脚本加 `--dry-run` / `--force`
- ❌ 敏感信息脱敏规则（延后到 1.0.1 若有需求）
- ❌ 防线 3 的增量优化
- ❌ MCP 集成
- ❌ examples / 集成测试 / CI
- ❌ i18n
- ❌ 更多技术栈矩阵扩展

---

## PR 描述模板

```markdown
## v1.0.0 — Graduation Release

> 🎓 项目毕业并进入维护模式。详见 [STATUS.md](./STATUS.md)。

### 重大定位调整

从"全量文档生成器"收敛为"**业务知识文档 Skill**"。只外化 AI 读代码读不出的业务知识层，代码结构让 AI 直接读源码。

### 破坏性变更

- 移除代码级文档模板：code-map / api-reference / data-model / database
- 移除运营文档模板：deployment / runbook / monitoring / testing
- 移除独立 features.md（合并进 modules.md）
- 移除模块三级分化（Core/Standard/Lightweight）：所有模块统一单文件

### 修复
- TODO type 枚举冲突（#P0-1）
- skill_version 硬编码（#P0-2）
- CHANGELOG URL 错误（#P0-3）

### 改进
- SKILL.md description 显式化触发条件（#P1-1）
- 明确 doc-sync 对 init-docs 依赖（#P1-2）
- 用户项目文档精简（#P1-3）
- 砍掉模块三级分化（#P1-4）

### 新增
- STATUS.md（定位 + 维护模式声明）
- SECURITY.md（安全策略）
- docs/MIGRATION-v1.md（升级指南）
- skills/*/VERSION 文件
- README 徽章（Status / Version / License）
- glossary 字段业务语义章节
- modules.md 功能列表章节

### 升级指南

详见 [MIGRATION-v1.md](./docs/MIGRATION-v1.md) 的决策矩阵。

### 版本策略

1.0.x 仅接受 bug 修复。无 1.1。
```

---

## 执行完后需要做的事

1. **打 tag 发 Release** —— 完成仪式感，心理画上句号
2. **删掉 IDE 里这个项目的 TODO 便签** —— 从主要工作台移走
3. **（可选）发一篇公开声明** —— "这个工具做到 1.0 发布了，去干别的了"
4. **把设计哲学写成一篇博客** —— 这是你积累的真正长期资产
5. **归档到次要 workspace** —— 在心理上把这个项目从"在做"移到"已完成"

然后去做更值得的事。
