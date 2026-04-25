---
name: blyy-doc-sync
description: 代码变更后保持文档与代码同步。任何新增/删除/修改源文件、配置、数据库 schema、API 后触发，以及用户说"同步文档 / 更新文档 / doc sync / 文档审计"时触发。执行三道防线：实时同步、提交前验证、定期审计（月/季度）。依赖项目已有 docs/doc-maintenance.md 基线（通常由 blyy-init-docs 生成），否则使用内置 fallback 矩阵。不要在没有任何文档体系的项目上强行执行。
---

# blyy-doc-sync — 代码-文档持续同步 Skill

## 概述

本 Skill 用于在**每次代码变更后**检查并同步更新项目文档，确保文档不落后于代码。它通过三道防线策略实现持续维护。

> **与 `blyy-init-docs` 的关系：**
> - `blyy-init-docs` = Day 0，一次性初始化完整文档集
> - `blyy-doc-sync` = Day 1+，持续维护文档与代码的一致性
> - 两者共享 `blyy-init-docs/resources/tech-stack-matrix.md` 中的确定性清点命令矩阵和技术栈锚点矩阵，以及 `front-matter-spec.md` 中的结构化 TODO 枚举定义

## 前置条件

- 项目已通过 `blyy-init-docs` 或手动方式建立文档体系
- 项目内存在 `docs/doc-maintenance.md`（项目定制版），或由本 skill 的 `resources/sync-matrix.md` 提供通用 fallback

> **多工具兼容**：本 Skill 采用 SKILL.md 标准格式，兼容 Gemini、Codex、Cursor、Claude Code 等主流 AI 编程工具。

## 依赖的 Skill

本 Skill 的确定性清点命令矩阵、技术栈锚点矩阵、模块评分规则、TODO 枚举定义等均**引用** `blyy-init-docs/resources/doc-guide.md`（以及 v0.3.3 之后拆分出的子资源文件）。因此：

- **必须同时安装** `blyy-init-docs` 到同一个技能目录（`.claude/skills/` 或 `.agents/skills/`）。仅安装本 Skill 会导致路径失效。
- 安装脚本（`install.sh` / `install.ps1`）默认同时安装两者，不要单独跳过。
- 若你确实只需要 doc-sync，请先阅读 `blyy-init-docs/resources/doc-guide.md` 并手动将本 Skill 需要的章节内联到 `resources/sync-matrix.md`。

## 执行时机

AI 工具在执行**任何代码修改任务**后，应自动触发 blyy-doc-sync 检查。

---

## 三道防线

### 防线 1: 触发式同步 + 确定性验证（实时）

**每次代码变更后立即执行。**

#### Step 1 — 变更识别

1. 确认本次代码变更的类型（新增/修改/删除了哪些文件）
2. **基于 `last_synced_commit` 增量识别**（若文档 front matter 中存在该字段）：
   - 读取受影响文档的 `last_synced_commit`
   - 执行 `git diff --name-only <last_synced_commit>..HEAD` 获取自上次同步以来的所有变更
   - 若文档的 `code_anchors` 字段列出了关注路径，仅过滤这些路径下的变更
3. 查阅同步矩阵（优先读 `docs/doc-maintenance.md`，fallback 到 `resources/sync-matrix.md`）
4. 根据矩阵确定需更新的文档列表

#### Step 2 — 影响区域确定性扫描

> **核心理念**：不仅依赖 AI 判断"应该更新什么"，还用 shell 命令做确定性验证，确认文档与代码的实际差异。

对变更涉及的文档类别执行**针对性确定性扫描**（命令参考 `blyy-init-docs/resources/tech-stack-matrix.md` 一、确定性清点命令矩阵）：

| 变更涉及的区域 | 确定性扫描动作 | 比对目标 |
|---------------|--------------|---------|
| 实体/模型文件 | `fd -e {ext} -p "Entity\|Model" --type f` | `docs/glossary.md` 术语表 + 字段语义表条目覆盖度 |
| 控制器/路由/CLI 入口 | `fd -e {ext} -p "Controller\|Handler" --type f` | `docs/modules.md` 功能列表条目覆盖度 |
| 配置文件 | `fd "appsettings\|config\|.env" --type f` | `docs/config.md` 中列出的配置项数量 |
| 模块目录 | 检查 `docs/modules/` 下文件 vs 代码中模块 | `docs/modules.md` 注册表条目数 |

**扫描结果处理：**

- **数量一致** → 可能只需更新内容，按常规同步矩阵更新
- **代码数量 > 文档数量** → 发现遗漏，必须补充。列出具体差异：`"代码中有 OrderService 但 glossary.md 术语表中未登记"`
- **代码数量 < 文档数量** → 文档引用了已删除的代码，必须清理

#### Step 3 — 文档更新

1. 逐一更新受影响的文档
2. **确定性差异优先**：先处理 Step 2 发现的数量差异（补充遗漏 / 清理过时），再处理内容变更
3. **代码位置同步**：若变更涉及文件重命名/移动，必须更新文档列表型字段中的「源文件」/「定义位置」列（`file:line` 格式），以及 front matter 的 `code_anchors`
4. 更新文档的 YAML `last_updated` 为当天日期，**同时更新 `last_synced_commit` 为当前 commit hash**（`git rev-parse HEAD`）
5. 新增模块 → 在 `modules.md` 注册表登记 + 创建 `modules/<m>.md` 单文件（使用 init-docs 的 `_module.md.template` 5 章节结构）
6. 删除模块 → 从 `modules.md` 移除 + 归档/删除 `modules/<m>.md`

#### Step 4 — TODO/UNVERIFIED 递减检查

> `blyy-init-docs` 可能在文档中留下 `<!-- TODO[priority,type,owner]: xxx -->` 和 `<!-- UNVERIFIED: xxx -->` 标记。每次代码变更都是填充这些标记的机会。结构化 TODO 的 priority/type/owner 含义详见 `blyy-init-docs/resources/front-matter-spec.md` 七.4（唯一权威枚举来源）。

1. 在本次变更涉及的文档中搜索结构化标记：
   - `<!-- TODO\[(p[0-3]),([\w-]+),([\w-]+)\]:` (正则)
   - `<!-- UNVERIFIED:`
2. **按 priority 顺序处理**：p0 → p1 → p2 → p3
3. 按 `type` 字段路由处理策略：
   - `business-context` — 检查代码注释、命名、调用链是否提供了足够的业务事实，能则填充
   - `design-rationale` — 检查是否有新的 ADR 或代码注释支撑决策，有则填充
   - `ops-info` — 检查 IaC/CI/运维脚本是否新增了相关配置，有则填充
   - `security-info` — 不自动填充，仅向用户提示
   - `external-link` — 不自动填充，由用户提供 URL
   - `metric-baseline` — 不自动填充，等待实测或配置补充
4. **按 owner 分组提问**：当一次变更涉及多个同 owner 的 TODO 时，合并为一次提问，避免逐条打断用户
5. 判断当前变更是否提供了足够的代码事实来填充这些标记：
   - 例如：`<!-- TODO[p1,business-context,user]: 订单创建流程步骤 -->`，而用户刚好完成了 `OrderService.CreateOrder()` 的实现
   - 例如：`<!-- UNVERIFIED: 订单创建后是否通知仓库 -->`，而用户刚写了 `NotificationService.NotifyWarehouse()` 调用
6. 若能填充 → 从代码中提取事实，替换标记，向用户汇报：`"✅ 已填充 TODO[p1,business-context]（core-flow.md: 订单创建流程）"`
7. 若不确定 → 保留标记不动

#### 执行清单

```
□ 识别代码变更类型
□ 对变更区域执行确定性扫描（shell 命令）
□ 比对扫描结果 vs 文档内容，列出数量差异
□ 补充遗漏 / 清理过时引用
□ 按同步矩阵更新受影响文档内容
□ 更新 last_updated 元数据
□ 若新增模块 → 注册 + 创建 modules/<m>.md 单文件
□ 若删除模块 → 移除 + 归档 modules/<m>.md
□ 检查涉及区域的 TODO/UNVERIFIED 标记，尝试填充
□ 向用户汇报同步结果（含差异修复和 TODO 填充情况）
```

---

### 防线 2: 提交前验证（门禁）

**在完成一轮代码+文档修改后执行。**

#### 自动化验证（使用 shell 命令）

不仅靠 AI 阅读检查，还执行确定性命令验证：

```bash
# 1. 检查文档间交叉引用是否存在
rg -o '\[.*?\]\(((?!http)[^)]+)\)' docs/ --no-filename | \
  grep -oP '\(([^)]+)\)' | tr -d '()' | \
  while read f; do [ ! -e "$f" ] && echo "死链: $f"; done

# 2. 检查 modules.md 注册表 vs 实际模块文件
diff <(rg -oP '\| \[(\w+)\]' docs/modules.md | sort) \
     <(ls docs/modules/ | sort)

# 3. 检查文档 last_updated 是否当天
rg "last_updated:" docs/ --type md -l | \
  xargs grep -L "$(date +%Y-%m-%d)"
```

#### 验证清单

```
□ modules.md 注册表 vs docs/modules/ 目录一致 — 用 shell 命令验证
□ glossary.md 业务术语条目覆盖代码中的核心实体/服务类
□ modules.md 功能列表覆盖代码中的对外接口/CLI 命令/Web 页面入口
□ config.md 中配置项数量 vs 代码中配置文件数量一致 — 确定性扫描
□ 修改过的文档 last_updated 已更新为当天
□ 无断链引用（文档间交叉引用有效）
□ ARCHITECTURE.md 文档索引覆盖所有文档
□ 无残留的 TODO 标记对应已实现的代码（可选检查）
```

---

### 防线 3: 定期审计 — 轻量级完整性重扫（兜底）

**建议每月/每季度执行一次。**

> **执行**：触发防线 3 时，**必须 Read `resources/defense-line-3-audit.md`** 获取完整的 Step 0→6 流程（基线加载 → 全量重扫 → 文档比对 → 详细检查 → TODO 健康度报告 → 趋势对比 → 写入新基线）。
>
> 防线 1/2 不需要读取该资源。

**核心闭环**（无需展开本文件即生效）：
1. 读取 `docs/doc-maintenance.md` 的基线快照 YAML 块和历史趋势表
2. 用 `blyy-init-docs/resources/tech-stack-matrix.md` 一、确定性清点命令矩阵执行全量重扫
3. 与基线对比 → 输出腐烂信号 + 维护优先级建议
4. **追加一行新基线**到历史快照趋势表（不删除旧行），覆盖更新基线 YAML 块
5. 若项目未通过 init-docs 初始化，本次扫描后**首次写入基线快照**

---

## 与 blyy-init-docs 的数据衔接

### 基线数据

若项目通过 `blyy-init-docs` 初始化，以下数据可供 doc-sync 使用：

| 数据源 | 位置 | 用途 |
|--------|------|------|
| 项目基线快照（YAML） | `docs/doc-maintenance.md` 基线快照章节 | 防线 3 趋势对比的历史对比基准 |
| 历史快照趋势表 | `docs/doc-maintenance.md` 历史快照趋势章节 | 防线 3 检测文档腐烂趋势 |
| `last_synced_commit` | 各文档 front matter | 防线 1 增量识别变更范围 |
| `code_anchors` | 各文档 front matter | 防线 1 过滤变更范围 |
| 确定性清点命令 | `blyy-init-docs/resources/tech-stack-matrix.md` 一、清点命令矩阵 | 防线 1/2/3 的扫描命令参考 |
| 技术栈锚点矩阵 | `blyy-init-docs/resources/tech-stack-matrix.md` 四、锚点文件矩阵 | 判断代码变更涉及的文件类别 |
| 结构化 TODO 枚举 | `blyy-init-docs/resources/front-matter-spec.md` 七.4 | 防线 1 Step 4 路由 + 防线 3 聚合统计 |
| 结构化 TODO/UNVERIFIED 标记 | 各文档中 | 按 priority/type/owner 持续递减 |

### TODO 递减闭环

```
blyy-init-docs 生成文档 → 留下结构化 TODO[priority,type,owner] / UNVERIFIED 标记
    ↓
用户持续开发，每次代码变更触发 blyy-doc-sync
    ↓
防线 1 Step 4 按 priority 顺序检查：当前变更能否填充附近的标记？
    ↓ 能
按 type 路由处理（business-context 检查代码事实 / design-rationale 检查 ADR /
              ops-info 检查 IaC / security-info 提示安全团队 / external-link 等待 URL /
              metric-baseline 等待实测）
    ↓
按 owner 分组合并提问 → 自动填充并汇报 → 标记数量持续递减
    ↓
防线 3 定期统计：按 priority/type/owner 聚合 + 趋势对比 + 写入新基线
    ↓
最终目标：p0/p1 归零，p2/p3 可控
```

---

## 资源文件

| 文件 | 何时读取 | 用途 |
|------|---------|------|
| `resources/sync-matrix.md` | 防线 1 Step 1（项目无 `doc-maintenance.md` 时） | 通用代码变更→文档更新映射矩阵（跨项目复用 fallback） |
| `resources/defense-line-3-audit.md` | 触发防线 3 时 | 定期审计的 Step 0-6 详细流程（基线加载/重扫/比对/趋势/写入） |

## 与 doc-maintenance.md 的优先级

```
读取优先级：
1. 项目内 docs/doc-maintenance.md     ← 项目定制版（优先）
2. 本 skill 的 resources/sync-matrix.md ← 通用 fallback
```

确定性扫描命令参考：
```
1. blyy-init-docs/resources/tech-stack-matrix.md  ← 确定性清点命令矩阵 + 技术栈锚点矩阵
   blyy-init-docs/resources/front-matter-spec.md  ← 结构化 TODO 枚举定义（七.4）
```

## 进度通报

| 时机 | 输出 |
|------|------|
| 防线 1 开始 | `🔄 检测到代码变更，启动文档同步检查...` |
| 防线 1 确定性扫描完成 | `📊 扫描结果: {变更区域} — 代码 {N} 个 vs 文档 {M} 个` |
| 防线 1 每个文档更新 | `📝 已更新: {文档名}` |
| 防线 1 TODO 填充 | `✅ 已填充 {N} 个 TODO/UNVERIFIED 标记` |
| 防线 1 完成 | `✅ 文档同步完成: 更新 {N} 个文档, 修复 {M} 个差异, 填充 {K} 个标记 (last_synced_commit → {short_hash})` |
| 防线 2 完成 | `✅ 提交前验证通过`（或 `⚠️ 发现 {N} 个问题: ...`） |
| 防线 3 加载基线 | `📂 已加载基线快照 ({snapshot_date}, commit {short_hash})` |
| 防线 3 完成 | 输出完整审计报告（含覆盖率 + 按优先级的健康度 + 趋势对比 + 维护优先级） + 写入新基线 |

## 注意事项

- 防线 1 是核心，每次代码变更必须执行
- 防线 2 用于自检，确保无遗漏
- 防线 3 是最后兜底，弥补日常遗漏
- 文档更新应与代码修改在**同一任务**中完成，不要拆分为独立任务
- 日常文档维护使用 `blyy-doc-sync`，项目初始化使用 `blyy-init-docs`
- 确定性扫描命令需根据项目技术栈调整（参考 `tech-stack-matrix.md` 一、清点命令矩阵）
- TODO/UNVERIFIED 填充应保守——仅当代码事实明确支持时才填充，不确定则保留标记
