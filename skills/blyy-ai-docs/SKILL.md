---
name: blyy-ai-docs
description: 为 AI 工具生成/维护一份纯 AI 用、不重复代码事实、自失效的项目索引文档（ai-docs/），让 AI 不必全项目扫描即可快速理解业务并避免幻觉
---

# blyy-ai-docs — AI-Only 项目索引技能

## 概述

本 Skill 为项目生成并维护 `ai-docs/` 目录——一份**纯 AI 用**的轻量索引层。

**v2 架构：Hub-and-Spoke（轴辐式）**
- `INDEX.md` 是唯一的路由中心（Hub），始终读取，包含模块注册表 + 流程目录 + 全局决策
- `modules/{slug}.md` 是每个 Core/Standard 模块的独立详情文件（Spoke）
- 大模块自动溢出为 `modules/{slug}/_index.md` + 主题子文件（terms/flows/decisions）
- AI 每次任务只需读 INDEX + 1-2 个模块文件，而非全部内容

核心原则：

1. **快速索引**：帮 AI 快速定位代码入口，不做全项目扫描
2. **记录不可见事实**：业务逻辑、流程、设计意图——代码里直接呈现不了的
3. **禁止重复代码事实**：实体清单 / 端点表 / 文件清单 → 一律改为 `code-queries.md` 中的查询配方，由 AI 按需执行
4. **长期不腐烂**：基于 `code_anchors` + `last_synced_commit` 的 4-tier 自失效探针，自动定位过期内容
5. **不幻觉**：每条非 boilerplate 内容必须带 `[file#Symbol]` 锚点；无法锚定 → 强制 `<!-- UNVERIFIED -->`
6. **渐进式披露**：三级结构（项目级 → 模块级 → 主题级），AI 只读当前任务需要的最小上下文

> **多工具兼容**：本 Skill 采用 SKILL.md 标准格式，兼容 Gemini、Codex、Cursor、Claude Code 等。

## 前置条件

- git 仓库（依赖 `git diff` / `git hash-object`）
- `fd` 与 `rg` 可用（缺失时 `query-recipes.md` 提供 `find` / `grep` fallback）
- 有写入项目根目录的权限

---

## Phase 0 — 断点续跑检测

每次调用的第一步：检查是否有未完成的上次执行。

```
若 ai-docs/.init-temp/master-task.yaml 存在：
  → 读取进度 → 向用户展示：
    "📋 发现未完成的 Mode A 进度（{current_phase}，模块 {done}/{total}），继续？(继续 | 重新开始)"
  → 用户选"继续" → 从断点恢复（参见 resources/large-project-mode.md）
  → 用户选"重新开始" → 删除 .init-temp/ → 进入正常模式判定

若不存在 → 进入正常模式判定
```

---

## 执行模式判定

```
1. ai-docs/ 不存在
   → 进入 Mode A (Init)

2. ai-docs/MANIFEST.yaml 存在 AND 用户显式调用 "audit"
   → 进入 Mode C (Audit)

3. ai-docs/MANIFEST.yaml 存在 AND 距上次 audit > 90 天
   → 提示用户："建议跑 Mode C 全量审计，是否继续？(Y/跳过)"
   → 用户同意 → Mode C；否则继续判断

4. ai-docs/MANIFEST.yaml 存在 AND last_synced_commit ≠ 当前 HEAD
   → 进入 Mode B (Sync)

5. 都不满足
   → 报告 "ai-docs/ 已是最新（last_synced_commit = HEAD）"，无操作
```

读 `MANIFEST.yaml.last_synced_commit` 时，若值不在当前 git 历史中（force push / rebase 等导致）：

```bash
git merge-base --is-ancestor <last_synced_commit> HEAD
```

返回非 0 → 自动降级到 Mode C，并告知用户 "上次同步点已不可达，执行全量审计"。

---

## Mode A — Init（首次生成 ai-docs/）

> **目标**：从零生成完整的 `ai-docs/` 目录与 `MANIFEST.yaml`。

### Phase A0 — 环境探测

1. 检测 `fd` / `rg` / `git hash-object` 可用性，缺失时记录到 INIT-AI-REPORT
2. **必须 Read `resources/tech-stack-matrix.md`**，按依赖文件检测项目语言/框架
3. 输出：`detected_stack`（如 `csharp+aspnetcore`、`python+fastapi`）与 `project_root`
4. **文件数检测**：`fd --type f --exclude .git --exclude node_modules --exclude bin --exclude obj | wc -l`
   - **> 500 源文件**或 **> 5 子项目** → **必须 Read `resources/large-project-mode.md`**，切换到大型项目分阶段流程
   - ≤ 500 → 继续标准流程

### Phase A1 — 模块识别与分级

1. 用 `tech-stack-matrix.md` 中的"模块识别启发"规则识别业务模块
2. **架构布局检测**（`tech-stack-matrix.md` Section 六）：判断领域组织 vs 分层架构
   - 分层架构 → **必须**执行跨层业务领域提取（Section 七），用业务概念聚合模块
   - 领域组织 → 按目录级识别
3. **子模块拆分检测**：对每个候选模块检查内部子领域边界：
   - 条件：目录内 ≥ 3 个子目录 AND 每个子目录 ≥ 15 个源文件 AND 子目录间有独立入口文件
   - 满足 → 向用户建议拆分：

     ```
     📊 识别到 Trading 模块规模过大（280 文件，3+ 子领域），建议拆分：
       Trading.Execution   — 订单执行引擎
       Trading.Risk        — 风控校验
       Trading.MarketData  — 行情数据接入
       Trading.Settlement  — 清算结算
     接受拆分？(Y | 保持为单一模块 | 自定义拆分)
     ```

   - 用户选"保持为单一模块" → 保留原模块（后续 Phase A5 可能溢出为目录模式）
   - 不满足条件 → 跳过
4. 向用户确认模块清单
5. **模块复杂度分级**：**必须 Read `resources/module-tiering.md`**，对每个模块执行确定性评分
6. 向用户展示分级结果：

   ```
   📊 识别到 {N} 个业务模块（含分级）：
   - Orders   [Core]     (score: 5) — 订单生命周期
   - Users    [Core]     (score: 3) — 用户管理
   - Notify   [Standard] (score: 2) — 通知派发
   - Seeders  [Lightweight] (score: 0) — 数据初始化
   确认？(Y | 调整)
   ```

7. 若识别 ≤ 1 模块 OR 全部 Lightweight，降级为"精简模式"：仅生成 `INDEX.md` + `code-queries.md` + `MANIFEST.yaml`（无模块详情文件）
8. 用户确认后写入临时文件 `ai-docs/.init-temp/modules.yaml`（含 tier 和 score）

### Phase A2 — 生成 code-queries.md

1. **必须 Read `resources/query-recipes.md`**
2. 按 `detected_stack` 挑选匹配的 recipe（例如 csharp 选 `R-ENT-01-cs`、`R-EP-01-cs` 等）
3. 对每个 recipe，按需替换 `<module_root>` 占位符为实际模块路径
4. 写入 `ai-docs/code-queries.md`，每条 recipe 包含：id、用途、命令、预期输出形式、失效信号
5. **关键**：本阶段**只写命令，不执行命令**——结果按需用，不持久化

### Phase A3 — 业务内容子代理并行提取

> **目标**：用子代理分别提取每个模块的"代码里 grep 不出来的事实"——业务定位、术语映射、流程顺序、设计决策、不变式。

1. **必须 Read `resources/anti-hallucination.md`**，确立 T1/T2/T3 与锚点强制规则后才能分发子代理
2. **按模块分级分发子代理**（分级由 Phase A1 确定）：
   - **Core 模块**：子代理全量提取 5 类（business_summary + terms + flows + decisions/invariants + dependencies）
   - **Standard 模块**：子代理适度提取 3 类（business_summary + terms + dependencies）
   - **Lightweight 模块**：**跳过子代理**，主 agent 直接读入口文件写 1 行 business_summary
3. 子代理产出（落盘到 `ai-docs/.init-temp/analysis-<module>.md`）：
   - **业务定位**：1-2 句"这个模块对外承诺什么"，必须有 entry 文件锚点
   - **术语候选**：业务名词 ↔ 代码符号映射，每条带 `[file#Symbol]`
   - **流程候选**（仅 Core）：跨模块流程步骤，每步带锚点
   - **决策/不变式候选**（仅 Core）：从注释、ADR 文件、commit 信息中收集
   - **跨模块依赖**：本模块调用了哪些其他模块（带 import / using 锚点）
4. 主 agent 汇总各子代理产出
5. T1/T2 → 准备入文档；T3 → 进入 Phase A4 审查

> **子代理通用指令**（附加到每个子代理任务描述中）：
>
> - 你产出的**每一行**业务断言都必须带 `[file#Symbol]` 锚点；找不到锚点的断言改为 `<!-- UNVERIFIED: 简述 -->`
> - **禁止**列出 "本模块的所有实体" / "所有控制器" / "所有服务"——这些是 code-queries.md 的活儿，你的产物里写这种清单会被主 agent 拒收
> - 输入文件超 800 行时分批 Read → 提取 → 追加写入临时文件
> - 完成后输出结构化摘要（业务定位 N 条、术语 N 条、流程 N 步、决策 N 项、UNVERIFIED N 项）

### Phase A4 — 填充前审查关卡（Pre-Fill Review Gate）

> 在写正式文档前，所有 T3 推测项**必须**经用户确认。**此步骤完成前禁止开始写正式文档**。

1. 收集所有 T3 候选，按类型分组（业务定位类 / 术语类 / 流程类 / 决策类 / 不变式类）
2. 一次性向用户呈现：

   ```
   📋 发现 {N} 个 T3 推测项需确认

   【业务定位类】(3 项)
   1. [T3] Notifications 模块功能?
      最佳猜测: 邮件/短信通知派发 (置信度: 中)
      代码依据: NotificationService.cs#Send 调用 SmtpClient
      → 确认 / 纠正: ___

   【流程类】(2 项)
   2. [T3] 订单创建后是否触发库存锁定?
      最佳猜测: 是 (OrderService.CreateAsync 末尾调用 InventoryClient.Lock)
      代码依据: OrderService.cs#CreateAsync:78
      → 确认 / 纠正: ___

   ...
   ```

3. 用户响应处理：
   - **确认** → 升级为 T2，写入正式文档
   - **纠正** → 用用户文本写入，标 T1
   - **跳过** → 用 `<!-- UNVERIFIED: 简述 -->` 包裹后写入
4. 写入 `ai-docs/.init-temp/clarifications.yaml` 持久化结果，避免跨会话重复提问

### Phase A5 — 写正式文档 + MANIFEST 初始化

按以下顺序整合填充（每个文档完成后立即落盘）：

1. **`code-queries.md`** — Phase A2 已写，此处仅校验
2. **`modules/` 目录**：`mkdir -p ai-docs/modules`
3. **每个 Core/Standard 模块的详情文件**——按以下逻辑逐个写入：

   ```
   对每个 Core/Standard 模块：
     a. 从子代理产出中整合该模块的全部内容（summary + terms + flows + decisions + deps）
     b. 计算总行数
     c. 若 ≤ 200 行 → 写为 modules/{slug}.md（单文件模式，layout=file）
     d. 若 > 200 行 → 溢出为目录模式（layout=directory）：
        i.   mkdir modules/{slug}/
        ii.  写 modules/{slug}/_index.md — 摘要 + 路由表（summary/anchors/deps + 各主题 Top N 摘要）
        iii. 按主题行数决定溢出：
             - terms > 60 行 → 溢出到 modules/{slug}/terms.md
             - flows > 80 行 → 溢出到 modules/{slug}/flows.md
             - decisions > 60 行 → 溢出到 modules/{slug}/decisions.md
             - 未超阈值的主题内联留在 _index.md
     e. 记录 detail_file 和 layout 到临时变量，供后续写 MANIFEST
   ```

4. **`INDEX.md`**（Hub 文件）——从全部模块中聚合：
   - Module Quick Index 表（每模块一行：name + tier + code_root + summary + detail_file）
   - Cross-Module Dependency Graph（从各模块的 deps 中提取双向边）
   - Flow Catalog 路由表（从各模块的 flows 中提取：flow_name + trigger_module + involved + detail_in）
   - Global Decisions & Invariants（影响 ≥2 模块且无明确归属的决策/不变式，≤10 条）
   - Freshness 表
   - Lightweight 模块仅在 Module Quick Index 中登记（Detail 列为 `—`）

5. **`MANIFEST.yaml`**：
   - `ai_docs_version = 2`
   - `last_synced_commit = git rev-parse HEAD`
   - 对每个 anchor 文件：`git hash-object <file>` → `sha256`
   - 对每个 `#Symbol` 锚点：用 `resources/anchor-extraction.md` 的语言定位规则找到符号体范围 → `git hash-object <body>` → `body_sha256`
   - 写入 `anchors` 列表——`docs` 反向索引**精确到模块文件**（如 `modules/orders.md` 或 `modules/orders/flows.md`），而非笼统文件名
   - 写入 `modules` 列表（含 `tier`、`complexity_score`、`detail_file`、`layout`、`overflow_files`）
   - 写入 `history` 第一行 `event: init`
   - 写入 `trend` 第一行（初始快照：模块数、锚点数、UNVERIFIED 数、TODO 数）

6. **`.gitignore` 更新**：
   - 若项目根 `.gitignore` 不存在 → 创建
   - 若已存在 → 追加：

     ```
     # blyy-ai-docs: 本地 AI 索引缓存（由技能按需重生成）
     ai-docs/
     ```

7. **AI 入口文件注入**（让所有 AI 工具知道 `ai-docs/` 的存在）：
   - 检测项目根已有的 AI 入口文件：`CLAUDE.md`、`AGENTS.md`、`.cursorrules`
   - 若**都不存在** → 在用户确认后创建最可能的入口文件（优先级：`CLAUDE.md` > `AGENTS.md`）
   - 对每个存在的入口文件，检查是否已包含 `ai-docs/INDEX.md` 引用（幂等标记：`<!-- blyy-ai-docs-anchor -->`）
   - 若未包含 → **在文件末尾追加**以下内容（不修改用户已有的内容）：

     ```markdown
     <!-- blyy-ai-docs-anchor -->
     ## AI Docs Index

     本项目使用 `ai-docs/` 作为 AI 专用索引层（Hub-and-Spoke 结构）。**每次任务开始时**，先读 `ai-docs/INDEX.md`：
     - 它包含模块注册表、流程目录、依赖图——帮你定位要读哪个模块详情文件
     - 每个模块有独立详情文件 `modules/{slug}.md`，包含术语/流程/决策
     - 大模块会拆分为目录 `modules/{slug}/`，先读 `_index.md` 再按需深入

     > `ai-docs/` 是 gitignored 的本地缓存。若不存在或已过期，调用 `blyy-ai-docs` 技能重新生成。
     ```

   - 向用户汇报："已在 {文件名} 中注入 ai-docs/ 索引指引"

8. 清理 `ai-docs/.init-temp/` 临时目录

### Phase A6 — 自检与一次性报告

**强制检查**（任一不通过 → 回到 A5 修正；完整清单见 `resources/anti-hallucination.md` 六、AI 自查清单）：

1. 所有模块详情文件和 INDEX.md 中的非 boilerplate 段落都有 `[file#Symbol]` 锚点 OR `<!-- UNVERIFIED -->` 包裹？
2. 没有任何超过 20 行的列表型表（违反禁枚举铁律）？
3. `MANIFEST.anchors` 数量 ≥ 所有文档锚点的并集数量？
4. 所有模块详情文件的 `code_anchors` front matter 字段都已填充？
5. 每个模块详情文件的 tier 标签与 MANIFEST.modules 的 tier 字段一致？
6. MANIFEST.modules 的 `detail_file` 指向的文件全部存在？
7. MANIFEST.modules 中 `layout=directory` 的模块，其 `overflow_files` 列出的文件全部存在？
8. INDEX.md 的 Module Quick Index 行数 = MANIFEST.modules 条目数？
9. INDEX.md 的 Flow Catalog 覆盖所有模块详情文件中的流程？
10. 所有 TODO 标记使用结构化格式 `<!-- TODO[pN, type]: desc -->`？
11. `.init-temp/` 已清理（或大型项目模式下保留 `master-task.yaml`）？

**通过后**：输出一次性 `ai-docs/INIT-AI-REPORT.md`：

- 模块数（Core / Standard / Lightweight 分布）
- 模块布局统计（file 模式 N 个 / directory 模式 N 个）
- 术语数 / 流程数 / 决策数 / 不变式数
- T1/T2/T3 分布
- UNVERIFIED + TODO 清单（含位置链接）
- 探测到的技术栈与 query-recipes 启用列表
- 下一步建议（"代码改动后调用本 skill 自动进入 Mode B"）

---

## Mode B — Sync（增量同步）

> **触发**：`last_synced_commit ≠ HEAD`。**目标**：让 ai-docs/ 跟上代码增量变化，**仅重写过期段落**。

### Phase B0 — 读取 MANIFEST 并校验可达性

```bash
M_prev=$(yq '.last_synced_commit' ai-docs/MANIFEST.yaml)
M_curr=$(git rev-parse HEAD)
git merge-base --is-ancestor "$M_prev" HEAD || exit_to_mode_c
```

若 ancestor 校验失败 → 自动降级到 Mode C，告知用户原因。

**v1 兼容检测**：若 `MANIFEST.yaml` 中 `ai_docs_version` 为 1（或缺失）→ 提示用户：

```
⚠️ 检测到 v1 平面结构的 ai-docs/，当前技能已升级为 v2 Hub-and-Spoke 结构。
建议重新生成（Mode A）以获得渐进式披露能力。(重新生成 | 继续使用 v1)
```

用户选"重新生成" → 进入 Mode A。

### Phase B1 — 主动映射 + 被动失效检测

1. **必须 Read `resources/sync-matrix.md`**，根据 `git diff --name-status` 输出快速标记"确定需检查"的模块文件
2. **必须 Read `resources/self-invalidation.md`** 获取完整 4-tier 算法
3. 执行 Tier 1-4，输出每个模块文件的状态：`{CLEAN, REVIEW, STALE}`（矩阵与 4-tier 结果合并）
   - `MANIFEST.anchors[].docs` 反向索引精确指向模块文件（如 `modules/orders.md` 或 `modules/orders/flows.md`），只需检查受影响的文件
4. 向用户汇报扫描结果：

   ```
   📊 ai-docs/ 同步检查（M_prev={prev_short}..M_curr={curr_short}）：
   - 检查 anchor 数: 87
   - CLEAN:  modules/users.md, modules/notifications.md, ...
   - REVIEW: modules/orders.md（OrderService.CreateAsync body 改动）
   - STALE:  modules/legacy.md（src/Legacy/ 已删除）
   ```

5. **保护机制**：若 `STALE > 50%` 总 anchor 数 → 拒绝静默运行，提示：

   ```
   ⚠️ STALE 比例 {pct}% 异常高，项目可能处于半重构状态。
   建议改跑 Mode A 全量重生成，是否继续？(继续 Mode B | 改为 Mode A | 取消)
   ```

### Phase B2 — 处理 STALE / REVIEW

**对每个 STALE 模块文件**：

1. 通过 `MANIFEST.anchors[].docs` 反向索引精确定位受影响的模块文件（单文件模式直接定位；目录模式定位到具体 topic 文件）
2. 重新读对应代码（含被改动的符号体）
3. **整段重写**该段落，禁止局部 patch
4. 子代理隔离上下文执行，产出落盘到 `ai-docs/.sync-temp/`
5. 若 STALE 影响了 INDEX.md 中的内容（Global Decisions、Flow Catalog、Dependency Graph）→ 同步更新 INDEX.md

**对每个 REVIEW 模块文件**：

1. 读取新代码体 vs 旧 claim
2. **仅修正矛盾点**，不动未受影响内容
3. 若新代码与旧 claim 完全一致（仅 cosmetic 改动） → 仅 bump `last_synced_commit`

**渐进式 TODO 填充**（处理 STALE/REVIEW 后顺手执行）：

1. 在本次涉及的模块文件中搜索 `<!-- TODO[` 和 `<!-- UNVERIFIED:` 标记
2. 若当前代码变更提供了足够证据可以填充 → 替换标记，向用户汇报
3. 不确定 → 保留标记不动（详见 `sync-matrix.md` 三、渐进式 TODO 填充）

向用户汇报每个模块文件的具体修改差异。

### Phase B3 — 新模块/失效模块/分级演化检测

1. 列出 MANIFEST.modules 注册的模块根 vs 当前文件系统的业务目录（用 `tech-stack-matrix.md` 的启发规则）
2. **新出现的目录**满足模块识别启发 → 评分分级 → 提示："发现新模块 X [Standard]，是否补登记？(Y/N)"
   - 用户确认 → 子代理分析该模块 → 写入 `modules/{slug}.md`（或目录模式）→ 更新 INDEX.md + MANIFEST
3. **已消失的目录** → 删除对应的 `modules/{slug}.md`（或 `modules/{slug}/` 目录）+ 从 INDEX.md 移除 + 清理 MANIFEST
4. **分级升级检测**：若本次变更涉及模块内文件增删，对该模块重新评分（规则见 `module-tiering.md`）
   - 评分跨越级别阈值 → 提示用户升级建议
   - Standard → Core 升级确认后：子代理补充提取 flows + decisions → 写入模块文件 → **链式触发 Phase B3.5**
   - 降级信号仅记录，留给 Mode C
5. **AI 入口文件完整性检查**：检查项目 AI 入口文件（`CLAUDE.md` / `AGENTS.md` / `.cursorrules`）中的 `<!-- blyy-ai-docs-anchor -->` 标记是否仍存在。若被用户删除或文件被重建 → 重新注入（同 Mode A 步骤 7）

### Phase B3.5 — 布局演化检测

> 在 B2/B3 的内容变更全部落地后执行。目的：检测模块文件是否需要在单文件/目录模式间转换。

**对 B2/B3 中被修改过的每个模块**：

1. 计算当前总行数：
   - `layout=file` → `wc -l modules/{slug}.md`
   - `layout=directory` → `wc -l modules/{slug}/_index.md` + 各 topic 文件

2. 判断是否需要布局转换（含**滞回区间**防震荡）：

   ```
   ┌─ 当前 layout=file 且行数 > 200 → 升级为 directory
   │   a. mkdir modules/{slug}/
   │   b. 拆分：summary/anchors/deps → _index.md
   │          主题按行数溢出（terms > 60 行 / flows > 80 行 / decisions > 60 行）
   │          未超阈值的主题留在 _index.md 内联
   │   c. 更新 MANIFEST.anchors[].docs 反向索引（精确到新 topic 文件）
   │   d. 更新 MANIFEST.modules[] — layout=directory, detail_file, overflow_files
   │   e. 更新 INDEX.md detail_file 路径
   │   f. 删除旧 modules/{slug}.md
   │   → 汇报："📂 {module} 模块内容增长至 {N} 行，已自动拆分为目录结构"
   │   → 追加 MANIFEST.history：event: layout-upgrade
   │
   ├─ 当前 layout=directory 且总行数 ≤ 160 → 降级为 file
   │   （降级阈值 160 < 升级阈值 200，40 行滞回带防震荡）
   │   a. 合并所有 topic 文件 + _index.md → modules/{slug}.md
   │   b. 更新 MANIFEST 反向索引 + layout=file + 清空 overflow_files
   │   c. 更新 INDEX.md detail_file 路径
   │   d. 删除 modules/{slug}/ 目录
   │   → 汇报："📄 {module} 模块内容缩减至 {N} 行，已合并为单文件"
   │   → 追加 MANIFEST.history：event: layout-downgrade
   │
   └─ 当前 layout=directory 且某个 topic 文件行数 ≤ 30 → 局部回收
       （回收阈值 30 < 溢出阈值 60/80，滞回带防震荡）
       a. 将该 topic 内容内联回 _index.md
       b. 从 overflow_files 中移除该文件
       c. 删除该 topic 文件
       d. 更新 MANIFEST.anchors[].docs 反向索引
       → 汇报："📄 {module}/{topic}.md 仅剩 {N} 行，已回收至 _index.md"
   ```

3. 若未触发任何转换 → 跳过（大部分同步周期不会触发布局变化）

### Phase B4 — 更新 MANIFEST

1. 对所有被改写的模块文件，重算 anchors `sha256` 和 symbols `body_sha256`
2. 更新 `last_synced_commit = M_curr`
3. 追加一行 history：

   ```yaml
   - date: YYYY-MM-DD
     event: sync
     prev_commit: M_prev_short
     curr_commit: M_curr_short
     stale_count: 1
     review_count: 1
     fixed: true
     layout_changes: 0          # B3.5 触发的布局转换数
   ```

4. 清理 `.sync-temp/`

---

## Mode C — Audit（兜底审计）

> **触发**：用户显式调用 `audit`，或距上次 audit > 90 天。**目标**：全量验证所有锚点 + 全量重生成 STALE + 结构演化。

### Phase C0 — 全量锚点验证

1. **必须 Read `resources/self-invalidation.md`**
2. 对 `MANIFEST.anchors` 中的每条 path：`test -f` 存在性
3. 对每个 `#Symbol`：用 `resources/anchor-extraction.md` 的定位规则验证仍在
4. 死锚点 → 收集到 STALE 列表
5. 验证 MANIFEST.modules 中所有 `detail_file` 指向的文件仍存在；`overflow_files` 同理

### Phase C1 — 抽样查询比对

1. 从 `code-queries.md` 中挑选 5-10 个高价值 recipe（如 `R-ENT-01` 列实体、`R-EP-01` 列端点）
2. 执行并比对结果数量与 MANIFEST.history 上一行 audit 的基线
3. 偏差 > 10% → 提示 "某类对象增减明显，可能有 doc 落后"，记入审计报告

### Phase C1.5 — 模块分级全量复评

1. **Read `resources/module-tiering.md`**
2. 对 MANIFEST.modules 中每个模块重新执行完整评分
3. 与当前 `tier` 对比，输出升降级报告（**双向**——Mode B 仅提示升级，Mode C 同时处理降级）
4. 用户确认 → 升级模块补充分析（子代理提取缺失类别），降级模块简化详情文件
5. 更新 MANIFEST.modules 的 `tier` 和 `complexity_score`

### Phase C1.7 — 布局演化 + 子模块拆分建议

> Mode C 是唯一执行子模块拆分建议的时机。布局演化（file↔directory）同 B3.5 逻辑。

**布局演化**（同 Phase B3.5 逻辑）：

1. 对每个 Core/Standard 模块，计算当前总行数
2. 按 B3.5 相同的升级/降级/局部回收规则（含滞回区间）执行转换
3. 汇报所有布局变更

**子模块拆分建议**：

1. 对每个模块检查子领域边界条件：
   - 目录内 ≥ 3 个子目录 AND 每个子目录 ≥ 15 个源文件 AND 子目录间有独立入口文件
2. 满足条件 → 向用户建议拆分（**非自动，需确认**）：

   ```
   📊 审计发现 Trading 模块可能需要拆分（280 文件，3+ 子领域）：
     Trading.Execution   — 订单执行引擎（85 文件）
     Trading.Risk        — 风控校验（45 文件）
     Trading.MarketData  — 行情数据接入（38 文件）
   接受拆分？(Y | 保持现状 | 自定义)
   ```

3. 用户确认拆分 → 删除旧模块文件 → 为每个子模块评分分级 → 子代理分析 → 写入新模块文件 → 更新 INDEX.md + MANIFEST
4. 不满足条件或用户拒绝 → 跳过

### Phase C2 — 触发 Mode B 流程处理 STALE

1. 把 C0 收集的 STALE 列表交给 Mode B Phase B2 处理（目标精确到模块文件）
2. 跑完后回到 Mode C

### Phase C3 — 输出审计报告并更新 MANIFEST

1. 写一次性 `ai-docs/AUDIT-REPORT.md`（用户可删）：
   - 验证的 anchor 总数 / 死锚点数 / 已修复数
   - 抽样 query 偏差
   - 分级复评结果（升降级明细）
   - 布局演化结果（file↔directory 转换明细）
   - 子模块拆分结果（若有）
   - history 表当前长度与最早一行的日期（说明腐烂周期）
   - **腐烂信号**：对比最近 3+ 条 trend 行，TODO 连续上升 → 标记
2. 更新 MANIFEST：
   - `last_audited = 今天日期`
   - 追加 history 行 `event: audit`
   - **追加 trend 行**（模块数、锚点数、stale 数、UNVERIFIED 数、TODO 数）

---

## 核心铁律（无需展开任何 resource 即生效）

1. **每条非 boilerplate 内容必须带 `code_anchor`**；无法锚定 → `<!-- UNVERIFIED: ... -->` 包裹，禁止裸断言
2. **禁止枚举性列表**（实体表、端点表、文件清单等）—— 用 `code-queries.md` 里的 recipe 替代。模板里没有"列出所有 X"的表格章节
3. **T3 推测必须经 Pre-Fill Review**（Mode A Phase A4），用户确认后升级为 T2 才能进入正式文档
4. **STALE 模块文件整段重写**，禁止局部 patch（避免漂移）
5. **MANIFEST.yaml 是真相源**——`last_synced_commit` 与 HEAD 偏差必须报告给用户
6. **文件级 sha 用 `git hash-object`**（跨平台、零依赖），禁用 `sha256sum` / `Get-FileHash`
7. **`ai-docs/` 默认 gitignore**——视为本地索引缓存，由 INDEX.md 顶部明示
8. **子代理产出立即落盘**到 `.init-temp/` 或 `.sync-temp/`，主 agent 从文件读取，不依赖上下文传递
9. **任何 Mode 下，列表型段落 > 20 行 → 直接拒绝**，回到 Phase A2 加 query recipe
10. **锚点格式优先级**：`[file#Symbol]` > `[file#Symbol:42-58]` > `[file:42-58]` > `[file]`。优先选符号锚点以抗行号漂移
11. **结构化 TODO 格式**：`<!-- TODO[p0-p3, type]: desc -->`（type: business-context / design-rationale / invariant-gap）。Mode B 同步时顺手填充
12. **AI 入口文件注入**：Mode A 完成后必须在项目 AI 入口文件（`CLAUDE.md` / `AGENTS.md` / `.cursorrules`）中注入 `ai-docs/INDEX.md` 索引指引，确保所有 AI 会话从 `ai-docs/` 开始索引。Mode B 检查注入仍存在
13. **布局自动演化**：Mode B Phase B3.5 / Mode C Phase C1.7 自动检测模块文件是否需要在单文件/目录模式间转换（升级阈值 >200 行，降级阈值 ≤160 行，滞回带防震荡）
14. **MANIFEST.anchors[].docs 精确到模块文件**：反向索引指向 `modules/{slug}.md` 或 `modules/{slug}/flows.md`，而非笼统文件名。这是 Mode B 精确重写的基础

---

## 资源文件

| 文件 | 何时读取 | 用途 |
|------|---------|------|
| `resources/tech-stack-matrix.md` | Mode A Phase A0/A1 + Mode B Phase B3 | 技术栈检测 + 锚点矩阵 + 模块识别 + 架构布局检测 + 跨层提取 |
| `resources/query-recipes.md` | Mode A Phase A2 | 8 大栈 fd/rg 命令库，按栈拼装 code-queries.md |
| `resources/anti-hallucination.md` | Mode A Phase A3 + 全程参考 | T1/T2/T3 + 锚点强制 + 禁枚举 + 结构化 TODO + 自查清单 |
| `resources/anchor-extraction.md` | Mode A Phase A5 + Mode B Phase B1 + Mode C Phase C0 | 8 语言符号定位正则 + body 范围提取 |
| `resources/self-invalidation.md` | Mode B Phase B1 + Mode C Phase C0 | 4-tier 失效检测算法完整流程 |
| `resources/module-tiering.md` | Mode A Phase A1 + Mode B Phase B3 + Mode C Phase C1.5 | 6 分制评分 + Core/Standard/Lightweight 分析深度 + 子模块拆分 + 升降级检测 |
| `resources/large-project-mode.md` | Phase A0 检测 >500 文件时 | 分阶段执行 + 跨会话持久化 + 上下文保护 + 文件过滤 |
| `resources/sync-matrix.md` | Mode B Phase B1 | 代码变更类型→模块文件映射 + 渐进式 TODO 填充 |

---

## 模板文件

| 文件 | 用途 |
|------|------|
| `templates/MANIFEST.yaml.template` | 状态契约 v2（含 detail_file / layout / overflow_files） |
| `templates/INDEX.md.template` | Hub：任务路由 + 模块注册 + 流程目录 + 依赖图 + 全局决策 |
| `templates/module-detail.md.template` | 单文件模式的模块详情（≤200 行：summary + terms + flows + decisions + deps） |
| `templates/module-index.md.template` | 目录溢出模式的 _index.md（摘要 + 各主题路由表） |
| `templates/code-queries.md.template` | 查询配方文件结构 |

> 溢出模块的 topic 子文件（`terms.md`、`flows.md`、`decisions.md`）复用 `module-detail.md.template` 中对应章节的格式，不需要独立模板。

---

## 注意事项

- 首次使用建议：先在小项目跑 Mode A，确认产物形态，再扩展到大型仓库
- 大型仓库（>500 文件）会自动切换到大型项目模式（`resources/large-project-mode.md`），支持跨会话断点恢复
- 超大仓库（>5000 文件）建议在 Phase A1 限定模块识别范围（明确告诉技能 "只看 src/Modules/"）
- `ai-docs/` 默认 gitignored——是本地 AI 索引缓存，每个开发者按需重生成
- 检测到 v1 平面结构的 `ai-docs/` 时，Mode B 会提示用户升级到 v2 Hub-and-Spoke 结构
