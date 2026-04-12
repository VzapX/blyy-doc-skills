---
name: blyy-ai-docs
description: 为 AI 工具生成/维护一份纯 AI 用、不重复代码事实、自失效的项目索引文档（ai-docs/），让 AI 不必全项目扫描即可快速理解业务并避免幻觉
---

# blyy-ai-docs — AI-Only 项目索引技能

## 概述

本 Skill 为项目生成并维护 `ai-docs/` 目录——一份**纯 AI 用**的轻量索引层，区别于面向人类的 `docs/`。

设计目标：

1. **不重复代码事实**：实体清单 / 端点表 / 文件清单 → 一律改为 `code-queries.md` 中的查询配方，由 AI 按需执行
2. **多年不腐烂**：基于 `code_anchors` + `last_synced_commit` 的 4-tier 自失效探针，能在长周期迭代后自动定位过期内容
3. **不幻觉**：每条非 boilerplate 内容必须带 `[file#Symbol]` 锚点；无法锚定 → 强制 `<!-- UNVERIFIED -->`

> **多工具兼容**：本 Skill 采用 SKILL.md 标准格式，兼容 Gemini、Codex、Cursor、Claude Code 等。
>
> **与现有 skill 的关系**：
> - `blyy-init-docs` / `blyy-doc-sync` 生成 `docs/`，同时服务人类与 AI——内容更全但需要人工维护
> - `blyy-ai-docs` 生成 `ai-docs/`，仅服务 AI——内容更精但维护近乎自动
> - 两者**完全独立**，可单独安装；同时安装时也互不依赖

## 前置条件

- git 仓库（依赖 `git diff` / `git hash-object`）
- `fd` 与 `rg` 可用（缺失时 `query-recipes.md` 提供 `find` / `grep` fallback）
- 有写入项目根目录的权限

---

## 执行模式判定（每次调用都从这里开始）

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

### Phase A1 — 模块识别

1. 用 `tech-stack-matrix.md` 中的"模块识别启发"规则识别业务模块
2. 跨层架构（Controller / Service / Repository 分层）→ 用业务概念聚合（订单 / 用户 / 库存等），而非按层切
3. 向用户确认识别结果：

   ```
   📊 识别到 {N} 个业务模块：
   - Orders   (src/Modules/Orders/)   — 推断业务: 订单生命周期
   - Users    (src/Modules/Users/)    — 推断业务: 用户管理
   - Payments (src/Modules/Payments/) — 推断业务: 支付与对账
   ...
   确认？(Y | 调整)
   ```

4. 若识别 ≤ 1 模块（小项目 / CLI / 库），降级为"精简模式"：仅生成 `INDEX.md` + `glossary.md` + `code-queries.md` + `MANIFEST.yaml`，跳过 modules/flows/decisions
5. 用户确认后写入临时文件 `ai-docs/.init-temp/modules.yaml`

### Phase A2 — 生成 code-queries.md

1. **必须 Read `resources/query-recipes.md`**
2. 按 `detected_stack` 挑选匹配的 recipe（例如 csharp 选 `R-ENT-01-cs`、`R-EP-01-cs` 等）
3. 对每个 recipe，按需替换 `<module_root>` 占位符为实际模块路径
4. 写入 `ai-docs/code-queries.md`，每条 recipe 包含：id、用途、命令、预期输出形式、失效信号
5. **关键**：本阶段**只写命令，不执行命令**——结果按需用，不持久化

### Phase A3 — 业务内容子代理并行提取

> **目标**：用子代理分别提取每个模块的"代码里 grep 不出来的事实"——业务定位、术语映射、流程顺序、设计决策、不变式。

1. **必须 Read `resources/anti-hallucination.md`**，确立 T1/T2/T3 与锚点强制规则后才能分发子代理
2. 对每个模块启动一个子代理，输入：模块路径 + 强制规则摘要 + 模板要求
3. 子代理产出（落盘到 `ai-docs/.init-temp/analysis-<module>.md`）：
   - **业务定位**：1-2 句"这个模块对外承诺什么"，必须有 entry 文件锚点
   - **术语候选**：业务名词 ↔ 代码符号映射，每条带 `[file#Symbol]`
   - **流程候选**：跨模块流程步骤，每步带锚点
   - **决策/不变式候选**：从注释、ADR 文件、commit 信息中收集
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

1. **`INDEX.md`** — 任务路由表 + 新鲜度概览
2. **`modules.md`** — 模块注册表（每个模块 1-2 句业务定位 + 入口锚点 + 跨模块依赖）
3. **`glossary.md`** — 业务术语 ↔ 代码符号映射
4. **`flows.md`** — 跨模块业务流程
5. **`decisions.md`** — ADR + 不变式合并
6. **`code-queries.md`** — Phase A2 已写，此处仅校验
7. **`MANIFEST.yaml`**：
   - `last_synced_commit = git rev-parse HEAD`
   - 对每个 anchor 文件：`git hash-object <file>` → `sha256`
   - 对每个 `#Symbol` 锚点：用 `resources/anchor-extraction.md` 的语言定位规则找到符号体范围 → `git hash-object <body>` → `body_sha256`
   - 写入 `anchors` 列表 + `history` 第一行 `event: init`

8. **`.gitignore` 更新**：
   - 若项目根 `.gitignore` 不存在 → 创建
   - 若已存在 → 追加：

     ```
     # blyy-ai-docs: 本地 AI 索引缓存（由技能按需重生成）
     ai-docs/
     ```

9. 清理 `ai-docs/.init-temp/` 临时目录

### Phase A6 — 自检与一次性报告

**强制检查**（任一不通过 → 回到 A5 修正）：

1. 所有 doc 中的非 boilerplate 段落都有 `[file#Symbol]` 锚点 OR `<!-- UNVERIFIED -->` 包裹？
2. 没有任何超过 20 行的列表型表（违反禁枚举铁律）？
3. `MANIFEST.anchors` 数量 ≥ 所有文档锚点的并集数量？
4. 所有 `code_anchors` front matter 字段都已填充？

**通过后**：输出一次性 `ai-docs/INIT-AI-REPORT.md`：

- 模块数 / 术语数 / 流程数 / 决策数 / 不变式数
- T1/T2/T3 分布
- UNVERIFIED 清单（含位置链接）
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

### Phase B1 — 4-tier 失效检测

1. **必须 Read `resources/self-invalidation.md`** 获取完整算法
2. 执行 Tier 1-4，输出每个 doc 的状态：`{CLEAN, REVIEW, STALE}`
3. 向用户汇报扫描结果：

   ```
   📊 ai-docs/ 同步检查（M_prev={prev_short}..M_curr={curr_short}）：
   - 检查 anchor 数: 87
   - CLEAN:  5 docs
   - REVIEW: 1 doc — flows.md（OrderService.CreateAsync body 改动）
   - STALE:  1 doc — modules.md（Modules/Old/ 已删除）
   ```

4. **保护机制**：若 `STALE > 50%` 总 anchor 数 → 拒绝静默运行，提示：

   ```
   ⚠️ STALE 比例 {pct}% 异常高，项目可能处于半重构状态。
   建议改跑 Mode A 全量重生成，是否继续？(继续 Mode B | 改为 Mode A | 取消)
   ```

### Phase B2 — 处理 STALE / REVIEW

**对每个 STALE doc**：

1. 通过反向锚点索引定位受影响段落
2. 重新读对应代码（含被改动的符号体）
3. **整段重写**该段落，禁止局部 patch
4. 子代理隔离上下文执行，产出落盘到 `ai-docs/.sync-temp/`

**对每个 REVIEW doc**：

1. 读取新代码体 vs 旧 claim
2. **仅修正矛盾点**，不动未受影响内容
3. 若新代码与旧 claim 完全一致（仅 cosmetic 改动） → 仅 bump `last_synced_commit`

向用户汇报每个 doc 的具体修改差异。

### Phase B3 — 新模块/失效模块检测

1. 列出 `modules.md` 注册的模块根 vs 当前文件系统的业务目录（用 `tech-stack-matrix.md` 的启发规则）
2. **新出现的目录**满足模块识别启发 → 提示："发现新模块 X，是否补登记？(Y/N)"
3. **已消失的目录** → 自动从 modules.md 移除 + 清理所有引用（含 glossary / flows / decisions）

### Phase B4 — 更新 MANIFEST

1. 对所有被改写的 doc，重算 anchors `sha256` 和 symbols `body_sha256`
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
   ```

4. 清理 `.sync-temp/`

---

## Mode C — Audit（兜底审计）

> **触发**：用户显式调用 `audit`，或距上次 audit > 90 天。**目标**：全量验证所有锚点 + 全量重生成 STALE。

### Phase C0 — 全量锚点验证

1. **必须 Read `resources/self-invalidation.md`**
2. 对 `MANIFEST.anchors` 中的每条 path：`test -f` 存在性
3. 对每个 `#Symbol`：用 `resources/anchor-extraction.md` 的定位规则验证仍在
4. 死锚点 → 收集到 STALE 列表

### Phase C1 — 抽样查询比对

1. 从 `code-queries.md` 中挑选 5-10 个高价值 recipe（如 `R-ENT-01` 列实体、`R-EP-01` 列端点）
2. 执行并比对结果数量与 MANIFEST.history 上一行 audit 的基线
3. 偏差 > 10% → 提示 "某类对象增减明显，可能有 doc 落后"，记入审计报告

### Phase C2 — 触发 Mode B 流程处理 STALE

1. 把 C0 收集的 STALE 列表交给 Mode B Phase B2 处理
2. 跑完后回到 Mode C

### Phase C3 — 输出审计报告并更新 MANIFEST

1. 写一次性 `ai-docs/AUDIT-REPORT.md`（用户可删）：
   - 验证的 anchor 总数 / 死锚点数 / 已修复数
   - 抽样 query 偏差
   - history 表当前长度与最早一行的日期（说明腐烂周期）
2. 更新 MANIFEST：
   - `last_audited = 今天日期`
   - 追加 history 行 `event: audit`

---

## 核心铁律（无需展开任何 resource 即生效）

1. **每条非 boilerplate 内容必须带 `code_anchor`**；无法锚定 → `<!-- UNVERIFIED: ... -->` 包裹，禁止裸断言
2. **禁止枚举性列表**（实体表、端点表、文件清单等）—— 用 `code-queries.md` 里的 recipe 替代。模板里没有"列出所有 X"的表格章节
3. **T3 推测必须经 Pre-Fill Review**（Mode A Phase A4），用户确认后升级为 T2 才能进入正式文档
4. **STALE doc 整段重写**，禁止局部 patch（避免漂移）
5. **MANIFEST.yaml 是真相源**——`last_synced_commit` 与 HEAD 偏差必须报告给用户
6. **文件级 sha 用 `git hash-object`**（跨平台、零依赖），禁用 `sha256sum` / `Get-FileHash`
7. **`ai-docs/` 默认 gitignore**——视为本地索引缓存，由 INDEX.md 顶部明示
8. **子代理产出立即落盘**到 `.init-temp/` 或 `.sync-temp/`，主 agent 从文件读取，不依赖上下文传递
9. **任何 Mode 下，列表型段落 > 20 行 → 直接拒绝**，回到 Phase A2 加 query recipe
10. **锚点格式优先级**：`[file#Symbol]` > `[file#Symbol:42-58]` > `[file:42-58]` > `[file]`。优先选符号锚点以抗行号漂移

---

## 资源文件

| 文件 | 何时读取 | 用途 |
|------|---------|------|
| `resources/tech-stack-matrix.md` | Mode A Phase A0/A1 + Mode B Phase B3 | 技术栈检测 + 锚点文件矩阵 + 模块识别启发 |
| `resources/query-recipes.md` | Mode A Phase A2 | 8 大栈 fd/rg 命令库，按栈拼装 code-queries.md |
| `resources/anti-hallucination.md` | Mode A Phase A3 + 全程参考 | T1/T2/T3 + 锚点强制 + 禁枚举规则 |
| `resources/anchor-extraction.md` | Mode A Phase A5 + Mode B Phase B1 + Mode C Phase C0 | 8 语言符号定位正则 + body 范围提取 |
| `resources/self-invalidation.md` | Mode B Phase B1 + Mode C Phase C0 | 4-tier 失效检测算法完整流程 |

---

## 模板文件

| 文件 | 用途 |
|------|------|
| `templates/MANIFEST.yaml.template` | 状态契约（Mode A 初始化，B/C 更新） |
| `templates/INDEX.md.template` | 任务路由表 + 新鲜度概览 |
| `templates/modules.md.template` | 模块注册表（仅 name → 路径 → 1-2 句业务定位） |
| `templates/glossary.md.template` | 业务术语 ↔ 代码符号映射 |
| `templates/flows.md.template` | 跨模块业务流程 |
| `templates/decisions.md.template` | ADR + 不变式 |
| `templates/code-queries.md.template` | 查询配方文件结构 |

---

## 注意事项

- 本 Skill 与 `blyy-init-docs` / `blyy-doc-sync` 完全独立，可单独安装
- 同时安装时不会互相影响，`ai-docs/` 与 `docs/` 内容互不复制
- 首次使用建议：先在小项目跑 Mode A，确认产物形态，再扩展到大型仓库
- 大型仓库（>5000 文件）建议在 Phase A1 限定模块识别范围（明确告诉技能 "只看 src/Modules/"）
- 本 skill 不取代 `blyy-doc-sync`——人类阅读的 `docs/` 仍由它维护
