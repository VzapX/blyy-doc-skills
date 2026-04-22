# blyy-doc-skills v0.3.2 → v0.3.3 整改计划

> 交付给 Claude CLI 的一次性整改任务书。
> 每个任务独立可执行，含背景、文件位置、具体变更和验证方式。
> 优先级从高到低按 P0 → P3 排序，建议按序执行（P0 是必修 bug）。

---

## 工作前检查

Claude 开始前请：

1. 确认当前工作在仓库根目录（包含 `skills/`、`docs/`、`README.md`）
2. 确认 git 工作区干净，为整个整改创建新分支 `refactor/v0.3.3`
3. 每完成一个 P0/P1 任务提交一次 commit，commit message 用 `task: <任务ID> - <一句话>` 的格式
4. 执行过程中发现本文未预料到的问题，先停下来在 commit message 或 PR 描述里记录，不要自作主张扩大改动范围

---

## P0 — 必修 bug（预计 30 分钟）

### P0-1 修复 TODO type 枚举值双处定义冲突

**问题**：`skills/blyy-doc-sync/resources/sync-matrix.md:73-75` 定义的 TODO type 枚举和 `skills/blyy-init-docs/resources/doc-guide.md:776-786` 完全不一致。前者写的是 `{fact, decision, owner, review}`，后者是 `{business-context, design-rationale, ops-info, security-info, external-link, metric-baseline}`。而 `blyy-doc-sync/SKILL.md` 防线 1 Step 4 的路由逻辑依赖后一种枚举，如果 AI 读了 sync-matrix 的错误定义，路由会失效。

**修改文件**：`skills/blyy-doc-sync/resources/sync-matrix.md`

**变更**：删除第 64-77 行"结构化 TODO/UNVERIFIED 标记格式"章节中关于 `type` 和 `priority` 的错误枚举定义，改为统一指向 doc-guide.md：

将第 64-77 行替换为：

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
- `grep -rn "business-context\|design-rationale" skills/blyy-doc-sync/` 只出现在引用性描述中，不再定义枚举
- 通读 doc-sync/SKILL.md Step 4，确认其路由逻辑（business-context/ops-info/security-info 等）没有矛盾来源

---

### P0-2 修复 skill_version 版本号脱节

**问题**：`skills/blyy-init-docs/resources/phase3-verification.md:34` 硬编码了 `skill_version: blyy-init-docs v0.3.0`，但当前版本是 v0.3.2。每次发版如果忘改这里，用户基线快照里记录的版本就是错的。

**修改文件**：`skills/blyy-init-docs/resources/phase3-verification.md`

**变更**：将第 34 行改为占位符形式：

```yaml
skill_version: blyy-init-docs v{{SKILL_VERSION}}
```

然后在 `skills/blyy-init-docs/SKILL.md` 的 Phase 3 入口处新增一条指令：写入基线快照前，从 `skills/blyy-init-docs/VERSION` 文件读取当前版本号替换 `{{SKILL_VERSION}}`。

**新增文件**：`skills/blyy-init-docs/VERSION`

内容：

```
0.3.3
```

（doc-sync 同理，新增 `skills/blyy-doc-sync/VERSION`，写 `0.3.3`）

**同步修改** `docs/architecture.md:177-180` 的"每次发版必须"章节：

```markdown
每次发版必须：
1. 更新 `docs/CHANGELOG.md`
2. 更新 `skills/blyy-init-docs/VERSION` 和 `skills/blyy-doc-sync/VERSION`
3. （可选）更新 README 顶部的版本徽章
```

**验证**：
- `cat skills/blyy-init-docs/VERSION` 返回 `0.3.3`
- `grep "skill_version" skills/blyy-init-docs/resources/phase3-verification.md` 输出为占位符格式，不再硬编码版本号

---

### P0-3 修复仓库 URL 用户名不一致

**问题**：`docs/CHANGELOG.md` 底部引用链接为 `https://github.com/wugl/blyy-doc-skills/...`，但当前仓库实际在 `VzapX/blyy-doc-skills` 下。这会让 CHANGELOG 里的链接全部失效。

**修改文件**：`docs/CHANGELOG.md`

**变更**：将第 126-131 行的所有 `wugl/blyy-doc-skills` 替换为 `VzapX/blyy-doc-skills`：

```bash
sed -i 's|github.com/wugl/blyy-doc-skills|github.com/VzapX/blyy-doc-skills|g' docs/CHANGELOG.md
```

（如果仓库确实是 `wugl` 那就反过来改——以 `git config --get remote.origin.url` 的输出为准。请先跑这条命令确认实际远端。）

**验证**：`grep "github.com" docs/CHANGELOG.md` 输出的 URL 和 `git config --get remote.origin.url` 中的用户名一致。

---

## P1 — 影响 skill 触发准确度和结构的问题（预计 3-4 小时）

### P1-1 重写两个 SKILL.md 的 description 字段

**问题**：当前 description 只有一句话定位，没写"何时用 / 何时不用 / 触发短语"，AI 路由决策容易偏差。参考 Anthropic 官方 skill 的 description 风格（见 docx/pptx 等）。

**修改文件**：
- `skills/blyy-init-docs/SKILL.md` 第 3 行
- `skills/blyy-doc-sync/SKILL.md` 第 3 行

**变更 1**：`skills/blyy-init-docs/SKILL.md`

```yaml
description: 为项目一次性初始化完整的文档体系。当用户要求"初始化文档 / 建立文档骨架 / doc init / 生成文档结构"，或项目从零开始建立文档、从遗留项目接手梳理文档时触发。扫描代码生成架构/模块/数据模型/部署等全套文档，已有 docs/ 自动迁移到 docs-old/ 再做结构化提取。每个项目只运行一次；日常维护用 blyy-doc-sync，不要重复执行本 skill。
```

**变更 2**：`skills/blyy-doc-sync/SKILL.md`

```yaml
description: 代码变更后保持文档与代码同步。任何新增/删除/修改源文件、配置、数据库 schema、API 后触发，以及用户说"同步文档 / 更新文档 / doc sync / 文档审计"时触发。执行三道防线：实时同步、提交前验证、定期审计（月/季度）。依赖项目已有 docs/doc-maintenance.md 基线（通常由 blyy-init-docs 生成），否则使用内置 fallback 矩阵。不要在没有任何文档体系的项目上强行执行。
```

**验证**：
- 两处 description 都包含"何时触发 / 何时不触发"
- 用几个测试 prompt 跑一下（如"帮我加个用户表"、"初始化项目文档"、"修了个 bug 要不要更新文档"），观察 AI 是否正确选择 skill 或不触发

---

### P1-2 处理 doc-sync 跨 skill 引用 init-docs 资源的问题

**问题**：`blyy-doc-sync/SKILL.md:50,76,216` 和 `resources/*.md` 多处引用 `blyy-init-docs/resources/doc-guide.md`。这假设两个 skill 同时安装且路径相邻，但 README 允许用户只装 doc-sync。路径一旦断裂，sync 无法工作。

**修改方案**（二选一，推荐 A）：

**方案 A — 在 doc-sync 的 SKILL.md 中显式声明依赖**（改动小）：

在 `skills/blyy-doc-sync/SKILL.md` 的"前置条件"章节（第 18-21 行）后新增：

```markdown
## 依赖的 Skill

本 Skill 的确定性清点命令矩阵、技术栈锚点矩阵、模块评分规则、TODO 枚举定义等均**引用** `blyy-init-docs/resources/doc-guide.md`。因此：

- **必须同时安装** `blyy-init-docs` 到同一个技能目录（`.claude/skills/` 或 `.agents/skills/`）。仅安装本 Skill 会导致路径失效。
- 安装脚本（`install.sh` / `install.ps1`）默认同时安装两者，不要单独跳过。
- 若你确实只需要 doc-sync，请先阅读 `blyy-init-docs/resources/doc-guide.md` 并手动将本 Skill 需要的章节内联到 `resources/sync-matrix.md`。
```

同时修改 `install.sh` / `install.ps1`：如果用户指定 `--skills blyy-doc-sync` 单独安装，打印 warning 并建议一起装。

**方案 B — 提取共享资源目录**（改动大但更干净）：

新增 `shared/` 目录放共享矩阵，两个 skill 的 resources 都相对引用 `../../shared/`。需要调整安装脚本让它在复制 skill 时一同复制 shared。

**建议先做 A**，B 留给 v0.4 做大重构。

**验证**：
- 方案 A 下，SKILL.md 前置条件章节明确提到依赖
- `./install.sh ./test-project --skills blyy-doc-sync` 能打印提示信息

---

### P1-3 拆分 doc-guide.md（793 行 → 多个资源文件）

**问题**：`doc-guide.md` 目前 793 行，是 skill 中最重的单文件，AI 按需加载它的成本很高。

**修改方案**：拆分成 4 个文件：

1. `resources/doc-guide.md`（保留，约 200 行）— 仅保留「一、文档架构总览」「二、各文档职责定义」「三、全局与模块文档分工」「五、项目类型适配指南」这几个"轻量定位"章节
2. 新建 `resources/tech-stack-matrix.md`（约 300 行）— 搬过去这些章节：
   - 「四、Phase 2 填充规则」中的"确定性清点命令矩阵"
   - "字段说明提取优先级"和"各技术栈注释提取来源矩阵"
   - "字段名推断规则"表
   - "技术栈识别"
   - "锚点文件矩阵"（后端+前端，包括补充矩阵）
   - "配置识别策略"
   - 「四」中的 "模块识别策略"（Step 1/2/2.5/2.6/3/4）
3. 新建 `resources/fact-classification.md`（约 100 行）— 搬过去「四」中的：
   - "填充原则"（5 条规则）
   - "三级事实分类 T1/T2/T3 表和示例"
   - "子代理输出格式要求"
4. 新建 `resources/front-matter-spec.md`（约 150 行）— 搬过去「六、文档模板占位符说明」和「七、YAML Front Matter 字段标准」全部内容，以及结构化 TODO 格式（作为枚举定义的**唯一权威来源**，解决 P0-1 问题）

**同步更新**：
- `skills/blyy-init-docs/SKILL.md` 末尾"资源文件"表格补充新文件，更新各 Phase 的"必须 Read"指引
- `skills/blyy-doc-sync/SKILL.md` 及其 resources 中对 doc-guide.md 的引用，按需改为更具体的子文件
- `docs/architecture.md` "加载时机映射"图同步更新

**验证**：
- `wc -l skills/blyy-init-docs/resources/*.md` 每个文件 ≤ 350 行
- `grep -rn "doc-guide.md" skills/` 所有引用都还能找到被引用的章节（不一定在同一文件了）

---

### P1-4 瘦身 blyy-init-docs/SKILL.md（630 行 → 目标 ≤ 450 行）

**问题**：SKILL.md 每次调用必加载。630 行偏大，尤其 0.3.1、0.3.2 新增的内容应该下沉。

**修改**：将以下段落从 `SKILL.md` 迁移到 resources：

1. **Phase 0.1 工具 /init 检测表**（第 66-85 行约 20 行）→ 新建 `resources/tool-init-detection.md`，SKILL.md 保留一句入口 "若识别到 Claude Code/Gemini/Codex 等工具，Read resources/tool-init-detection.md 执行相应的 /init 指令"
2. **模块复杂度评分详细步骤**（第 266-318 行约 52 行）→ 新建 `resources/module-tiering.md`，SKILL.md 保留评分公式和铁律
3. **填充前审查关卡 Step 1-5 详细步骤**（第 394-456 行约 60 行）→ 新建 `resources/pre-fill-review.md`，SKILL.md 保留"此步骤完成前禁止文档填充"的铁律

保留在 SKILL.md 的原则：
- 阶段入口判断逻辑
- 触发条件（何时进入哪个 Phase）
- 核心铁律（3-5 条，即使 AI 不展开 resource 也能大致执行）
- 资源文件索引表（三列：文件 / 何时读取 / 用途）

**验证**：
- `wc -l skills/blyy-init-docs/SKILL.md` ≤ 450
- 保留的铁律覆盖所有下沉到 resources 的必要约束
- 全局搜索确认新 resource 文件有被 SKILL.md 或其他 resource 明确触发

---

### P1-5 合并重复内容：模式自动升级

**问题**：「标准模式自动升级到大型模式」的同一段内容出现在两处：
- `resources/operational-conventions.md:93-100`
- `resources/large-project-mode.md:122-129`

**修改**：
- 保留 `operational-conventions.md` 版本（它本就是"约定性规范"的合集）
- 删除 `large-project-mode.md` 第 122-129 行
- 在 `large-project-mode.md` 对应位置加一条链接：`> 关于标准模式何时自动升级到大型模式，详见 operational-conventions.md 三、异常处理与容错策略。`

**验证**：
- `grep -rn "Phase 2 子代理数量超过 8 个" skills/` 只出现一次

---

## P2 — 合理优化（预计 1-2 天）

### P2-1 `install.sh` / `install.ps1` 加 `--dry-run` 和 `--force`

**问题**：
- 没有 dry-run，用户不知道安装脚本会动什么
- 目标目录存在时默认跳过（`[SKIP] 已存在`），用户升级 skill 时永远是旧版本

**修改文件**：`install.sh` 和 `install.ps1`

**变更 1**：新增 `--dry-run` 参数。dry-run 下只打印"将复制 X → Y"，不实际写文件。

**变更 2**：新增 `--force` 参数。当目标目录存在时：
- 无 `--force` → 打印 `[SKIP] <skill> 已存在（使用 --force 覆盖，或 --dry-run 预览）`
- 有 `--force` → 先备份到 `<dest>.bak-YYYYMMDD-HHMMSS`，再覆盖

**变更 3**：安装完成后检查两个 skill 版本是否一致（读 VERSION 文件），不一致给告警。

**验证**：
- `./install.sh --help` 输出包含 `--dry-run` 和 `--force`
- `./install.sh ./test-project --dry-run` 不实际写文件
- 目标已存在时不带 `--force` 不覆盖

---

### P2-2 把散落在 md 中的 shell 命令沉淀成脚本

**问题**：shell 命令现在散落在 SKILL.md、doc-guide.md、sync-matrix.md、defense-line-3-audit.md 里。AI 每次需要"理解 + 重新组装"，有出错可能。

**修改**：新建 `skills/blyy-doc-sync/scripts/` 目录，沉淀以下确定性脚本：

1. `scripts/check-deadlinks.sh` — 扫描 docs/ 下所有 md 的内部链接是否存在（来自 SKILL.md 防线 2 第 1 段）
2. `scripts/check-inventory-drift.sh <technology>` — 输入技术栈参数，返回各类文件清单和数量（来自 doc-guide.md 确定性清点命令矩阵）
3. `scripts/check-stale-docs.sh [--days N]` — 找 last_updated 超过 N 天的文档（默认 90）
4. `scripts/check-modules-registry.sh` — 对比 `modules.md` 中的条目 vs `docs/modules/` 实际目录
5. `scripts/full-audit.sh` — 防线 3 完整审计的主入口，依次调用上述脚本

对应修改 `blyy-doc-sync/SKILL.md`：把防线 1/2/3 中原本内联的 shell 命令替换为"运行 `scripts/check-xxx.sh`"，并在资源文件表格里新增 `scripts/` 一节。

**注意事项**：
- 所有脚本开头 `set -euo pipefail`
- 脚本支持两种退出码：0 = 正常；非 0 = 发现问题
- 所有 echo 使用简单可解析的格式（`LEVEL: message`），方便 AI 读取输出

**验证**：
- `bash scripts/check-deadlinks.sh` 在本仓库 docs/ 上能跑通
- `blyy-doc-sync/SKILL.md` 中不再有内联的 fd/rg 命令超过 5 行的块

---

### P2-3 补 CLAUDE.md 等 AI 上下文模板

**问题**：`templates/root/` 只有 `AGENTS.md.template`，但 SKILL.md Phase 0.2 允许用户选择生成 `CLAUDE.md` / `CURSOR.md` / `.cursorrules` / `.windsurfrules`。如果用户选 Claude Code，skill 没有对应模板。

**修改**：在 `templates/root/` 新增：

1. `CLAUDE.md.template` — 和 AGENTS.md 内容基本一致（Claude Code 本来也主要认这个文件），但 H1 换成 `# Claude Code Guidelines`，并在 Task Entry Protocol 里提到 `/init` 自动生成的 fallback 行为
2. `copilot-instructions.md.template` — 放 `.github/copilot-instructions.md`（结构简化版，Copilot 的 instructions 格式）

**同步修改** `skills/blyy-init-docs/SKILL.md` Phase 0.2：当用户选择工具为 Claude Code 时使用 CLAUDE.md.template；Gemini/Codex 用 AGENTS.md.template；Copilot 用 copilot-instructions.md.template；Cursor/Windsurf 保持规则文件生成。

**验证**：
- 三个模板都有 `Task Entry Protocol` 章节
- `ls templates/root/` 至少包含 `AGENTS.md.template` 和 `CLAUDE.md.template`

---

### P2-4 修正 Cursor 的真实支持路径

**问题**：`install.sh:107` 把 Cursor 的 skill 安装到 `.agents/skills/`。但 Cursor 实际使用 `.cursor/rules/` 放 rules 文件，Cursor 不支持 SKILL.md 格式的 skill。

**修改方案**：
1. 把 Cursor 从"支持"列表降级为"部分支持"，在 README 里明确说明
2. 要么为 Cursor 提供一个不同的产物（从 SKILL.md 生成 `.cursor/rules/blyy-init-docs.mdc`），要么在 README/install 里明确告知 Cursor 用户需要手动转换

**具体修改 install.sh**：
- 当 tool=cursor 时，打印警告：`[WARN] Cursor 原生不支持 SKILL.md 格式，将按 .agents/skills/ 方式安装。如需更好支持，请手动将 SKILL.md 内容复制到 .cursor/rules/blyy-doc-skills.mdc`

**README 变更**：把 Cursor 从"完全兼容"的描述里拿出来，单独列一行注明限制。

**验证**：
- `./install.sh ./proj --tool cursor` 输出包含 warning
- README 的 AI 工具兼容性表格中对 Cursor 有额外注释

---

### P2-5 加 `.gitignore`（当前 zip 里没看到）

**问题**：用户安装后在项目中会生成 `.init-docs/`、`docs/.init-temp/`、`docs-old/` 等临时/归档目录，应建议加入 .gitignore。

**修改**：
1. 仓库根新增 `.gitignore`（如果没有）：
   ```
   # editors
   .vscode/
   .idea/
   *.swp
   # OS
   .DS_Store
   Thumbs.db
   ```
2. 新建 `skills/blyy-init-docs/resources/gitignore-snippet.md`，内容是：
   ```markdown
   # Skill 执行产物（建议加入项目 .gitignore）

   # 大型项目模式的任务持久化目录（init 完成后可删除或保留）
   .init-docs/

   # 标准模式的临时目录（Phase 3 后自动清理，偶尔遗留）
   docs/.init-temp/

   # 旧文档归档（init 完成后可手动清理）
   # docs-old/    # 默认保留，用户确认后手动删除
   ```
3. 在 `SKILL.md` Phase 3 最后一步加一条：`Phase 3 完成后，向用户展示 resources/gitignore-snippet.md 的内容，建议追加到项目 .gitignore`

**验证**：
- 仓库根存在 `.gitignore`
- 新增 `gitignore-snippet.md` 存在
- Phase 3 流程中引用了该文件

---

### P2-6 "降级"操作增加 diff 确认

**问题**：`defense-line-3-audit.md` Step 2.5 的"降级"操作会直接删除 `modules/<m>/` 整个目录或单文件。如果用户手工修改过内容，会永久丢失。

**修改文件**：`skills/blyy-doc-sync/resources/defense-line-3-audit.md` Step 2.5.5

**变更**：把"执行变更 → 降级"的步骤改为：

```markdown
5. **执行变更**：
   - **升级**：按防线 1 Step 2.5 的升级执行步骤操作（无破坏性，直接拆分）
   - **降级**（Core/Standard → Standard/Lightweight）：
     - **先做 diff 检查**：对比模板生成的内容与当前文档内容，标记出可能是用户手工添加的段落
     - 若存在明显的手工内容（非 Phase 2 占位符、非模板段落），暂停降级，向用户展示 diff 并确认：
       ```
       ⚠️ 模块 [X] 降级时检测到可能的手工内容：
       - modules/X/flow.md 第 45-80 行包含非模板内容
       - 建议：手工备份相关段落，或维持当前级别
       继续降级 / 跳过 / 中止审计？
       ```
     - 用户确认后再执行目录合并或删除
     - 执行前自动创建备份 `docs/.archive/modules-X-YYYYMMDD/`
   - 确认后更新 `modules.md` 注册表和 `doc-maintenance.md` 基线
```

**验证**：
- Step 2.5.5 明确包含"先做 diff 检查"和"备份目录"两个动作
- 降级不再是"一刀切"删除

---

### P2-7 添加敏感信息过滤规则

**问题**：Phase 2 扫描配置文件时，`appsettings.json` / `.env` / `database.yml` 可能包含数据库密码、API Key 等。现在没有明确规则禁止把这些原样写入 `config.md`。

**修改文件**：`skills/blyy-init-docs/resources/doc-guide.md`（或拆分后放 `tech-stack-matrix.md` / `fact-classification.md`）

**新增章节**"敏感信息脱敏规则"：

```markdown
### 敏感信息脱敏规则

扫描配置文件填充 `config.md` 时，**必须**对以下字段模式进行脱敏：

| 字段模式（不区分大小写） | 处理方式 |
|------------------------|---------|
| `password`, `pwd`, `secret`, `apikey`, `api_key`, `token`, `accessKey`, `privateKey` | 值替换为 `***REDACTED***`，保留 key 名和位置 |
| `connectionString` / `conn_str` / `db_url` 包含 `Password=`、`pwd=` 的部分 | 只保留 host/port/database 部分，密码段脱敏 |
| 证书内容（PEM 格式，`-----BEGIN ...`） | 不写入文档，仅记录文件路径 |
| 以 `.env`、`secrets.*`、`*.pem`、`*.key` 为名的文件 | 只记录文件存在，不写入具体值 |

文档中展示脱敏后内容的同时，注明：`<!-- 敏感值已脱敏。真实值请在 .env 或密钥管理系统中查看 -->`

Phase 3 完整性校验时，额外检查 `config.md` 中是否有未脱敏的值符合上述模式，若有则列入完成报告。
```

同步在 `blyy-doc-sync/SKILL.md` 防线 2 的检查清单里加一条：
```
□ config.md 无明文密钥/密码（用 rg 检查常见模式）
```

**验证**：
- doc-guide（或拆分后的新文件）包含脱敏规则章节
- 在一个含 `"Password":"hunter2"` 的测试 `appsettings.json` 上跑 skill，config.md 中对应行显示为 `***REDACTED***`

---

## P3 — 长期改进（v0.4 及以后）

以下为方向性建议，每项独立可规划，不列具体文件变更：

### P3-1 自己吃自己的狗粮

用 blyy-init-docs 为本仓库自己生成 `docs/`（现在 docs/ 是手写的）。好处：
- 发现 skill 在"非典型文档型项目"上的边界问题
- README 里可以贴一个"这个 docs/ 就是 skill 自己生成的"作为 showcase
- 任何 skill 改动都会影响自身文档，自然形成回归测试

### P3-2 加一个 `examples/` 目录放 demo 输出

在 repo 里放 2-3 个典型项目（一个小 .NET Web API、一个 FastAPI、一个 Next.js）的 `docs/` 产物样本。不跑 skill 的人能直接看到期望产物，降低心理门槛。

### P3-3 做一套最小可运行的 integration test

用 GitHub Actions：
- 准备若干 fixture 项目（在 `tests/fixtures/`）
- 让 Claude CLI 跑 blyy-init-docs，比对产出
- 至少断言：生成的文档数、模块数、front matter 字段齐全

这是 skill 能不能规模化升级的关键——没有测试，每次动 SKILL.md 都在赌 AI 行为。

### P3-4 MCP 集成

目前靠 AI 跑 shell 命令理解项目。考虑为常见任务做 MCP 工具：
- `mcp__db-schema-reader` 直接读数据库 schema（比让 AI 翻迁移文件准）
- `mcp__git-history-reader` 读近期 commit 生成 CHANGELOG
- `mcp__code-structure-reader` 用 AST 而不是正则识别模块

这能把"AI 瞎猜"替换成"确定性读取"，和现在"确定性清单预扫描"理念一致。

### P3-5 pre-commit hook / GitHub Action 样例

防线 2 提出"提交前验证"，但没提供 hook 样例。放两个样例：
- `examples/pre-commit-hook.sh` — 调用 scripts/full-audit.sh
- `examples/github-actions/doc-sync-check.yml` — PR 必跑

### P3-6 破坏性变更的升级路径文档

0.2 → 0.3 的变化（T1/T2/T3 分级、结构化 TODO、YAML front matter 扩展）都是破坏性的，但 CHANGELOG 没写"老用户怎么升级"。建议新建 `docs/UPGRADE.md`，每个 0.x.0 版本给一个迁移脚本或手工步骤清单。

### P3-7 多语言（i18n）支持

模板全是中文。如果要开源推广海外用户：
- 把模板中的中文抽成 `locales/zh-CN/*.md` 和 `locales/en-US/*.md`
- install 时加 `--lang zh-CN|en-US` 参数
- SKILL.md 本身也可以双语（现在 README 已经是双语的）

### P3-8 子代理冲突合并规则

多个子代理分析同一模块得出不同结论的情况（分层架构下尤其常见）。现在 SKILL.md 只说"取并集"，但：
- 同名实体两份描述不同怎么办？
- 模块边界两边子代理判断不同怎么办？

补充到 `operational-conventions.md` 的"异常处理"章节，给明确规则：冲突条目自动标注 `<!-- CONFLICT: 来源A说...; 来源B说... -->`，进入 T3 审查关卡。

### P3-9 性能 / token 消耗透明化

用户实际跑一次 blyy-init-docs 大概要消耗多少 token、多少钱？没有任何文档说明。建议：
- 在 README 加一个"成本参考"章节
- 在 Phase 0 结束时给用户一个粗略估算（按项目规模）

---

## 执行后验证清单

Claude 在全部任务完成后，执行以下"冒烟测试"确认没有新引入问题：

```bash
# 1. 无跨文件矛盾的枚举定义
! grep -rn "type.*fact.*decision" skills/
grep -rn "business-context" skills/ | wc -l   # 应 ≥ 1（在 front-matter-spec 中定义）

# 2. 每个 SKILL.md 行数受控
wc -l skills/blyy-init-docs/SKILL.md      # ≤ 450
wc -l skills/blyy-doc-sync/SKILL.md       # ≤ 280

# 3. resources 单文件不超过 400 行
find skills/*/resources -name "*.md" -exec wc -l {} \; | awk '$1 > 400 {print}'
# 理想输出：空

# 4. 版本号一致
cat skills/blyy-init-docs/VERSION
cat skills/blyy-doc-sync/VERSION
grep "0.3" docs/CHANGELOG.md | head -1

# 5. 所有模板 front matter 字段齐全
for f in skills/blyy-init-docs/templates/**/*.template; do
  grep -q "applicable_project_types" "$f" || echo "缺字段: $f"
done

# 6. install 脚本语法正确
bash -n install.sh
pwsh -Command "& { [scriptblock]::Create((Get-Content install.ps1 -Raw)) }" 2>&1 | grep -i error
```

全部通过后，更新 `CHANGELOG.md` 为 `[0.3.3]` 条目，列出本次整改项，打 tag 发版。

---

## 可选：编写 PR 描述模板

如果通过 PR 提交本次整改，建议的 PR 描述：

```markdown
## v0.3.3 — 一致性修复与渐进式加载深化

### Breaking changes
无（所有变更向后兼容）

### 修复
- TODO type 枚举在两处定义冲突（P0-1）
- skill_version 硬编码导致版本脱节（P0-2）
- CHANGELOG 中仓库 URL 用户名不一致（P0-3）

### 改进
- 两个 SKILL.md 的 description 显式化触发条件（P1-1）
- 明确 blyy-doc-sync 对 blyy-init-docs 的依赖关系（P1-2）
- doc-guide.md 拆分为 4 个渐进式加载的资源文件（P1-3）
- blyy-init-docs SKILL.md 从 630 行瘦身到 ≤ 450 行（P1-4）
- 合并重复的"模式自动升级"章节（P1-5）
- install.sh/ps1 新增 --dry-run 和 --force 参数（P2-1）
- 确定性扫描命令沉淀为 scripts/ 可执行脚本（P2-2）
- 补全 CLAUDE.md 等 AI 上下文模板（P2-3）
- Cursor 支持范围明确化（P2-4）
- 加 .gitignore 和 gitignore-snippet（P2-5）
- 防线 3 降级操作增加 diff 检查和备份（P2-6）
- 配置扫描新增敏感信息脱敏规则（P2-7）

### 关联
- review 文档：见内部整改计划 v0.3.3
```
