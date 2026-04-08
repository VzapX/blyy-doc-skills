# 变更日志

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 格式。

## [0.3.0] — 2026-04-08

### 重构 — SKILL.md 渐进式加载架构

为避免大型 SKILL.md 一次性加载撑爆 AI 上下文窗口，按「主入口 + 按需 resource」的模式拆分两个 Skill 的指令文件。

**blyy-init-docs：**
- `SKILL.md` 从 893 行精简至 472 行（约 ↓47%，~12.6K → ~6.7K tokens）
- 新增 `resources/legacy-extraction.md`（73 行）— Phase 1.5 旧文档结构化提取详细流程
- 新增 `resources/large-project-mode.md`（128 行）— Phase 2A-2D 完整流程 + 任务持久化机制
- 新增 `resources/phase3-verification.md`（157 行）— 14 项检查 + 基线快照 YAML schema + INIT-REPORT 模板
- 新增 `resources/operational-conventions.md`（143 行）— 进度通报、上下文保护「边读边落盘」、异常容错、文件过滤规则

**blyy-doc-sync：**
- `SKILL.md` 从 354 行精简至 251 行（约 ↓29%，~5K → ~3.5K tokens）
- 新增 `resources/defense-line-3-audit.md`（124 行）— 防线 3 Step 0-6 详细流程

**关键设计原则：**
- 每个新 resource 文件顶部明确标注「何时读取」触发条件
- SKILL.md 中保留触发条件 + 核心铁律摘要，确保即便 AI 不展开 resource 也能遵循关键规则
- 资源文件表升级为三列（文件 / 何时读取 / 用途）

### 文档

- 重写 `docs/usage-guide.md`：反映新 Phase 模型、三道防线细节、T1/T2/T3、结构化 TODO、基线快照、resource 文件
- 更新 `docs/customization.md`：补充资源文件清单、YAML front matter 字段、`applicable_project_types` 项目类型过滤
- 新增 `docs/CHANGELOG.md`（本文件）
- 新增 `docs/architecture.md`：解释仓库内部结构与渐进式加载机制

---

## [0.2.0]

### 新增

- **三级事实分类（T1/T2/T3）**：每个填充的事实必须标注可信度级别，禁止 AI 自由臆测
- **Phase 2.5 填充前审查关卡**：T3 推测项批量呈现给用户一次性确认，避免逐条打断
- **Phase 1.5 旧文档结构化提取**：对 `docs-old/` 执行穷举式提取，作为 Phase 2 的输入
- **结构化 TODO 标记** `<!-- TODO[priority,type,owner]: ... -->`：按 priority/type/owner 三轴分类
  - priority: `p0` / `p1` / `p2` / `p3`
  - type: `business-context` / `design-rationale` / `ops-info` / `security-info` / `external-link` / `metric-baseline`
  - owner: `user` / `dev-team` / `ops-team` / `security-team` / 具体负责人
- **基线快照 YAML 块**：Phase 3 自动写入 `docs/doc-maintenance.md`，含 `inventory` / `markers` / `layer_distribution` / `fact_levels` 四类数据，供 doc-sync 防线 3 程序化解析
- **历史快照趋势表**：doc-sync 防线 3 每次执行后追加一行，便于发现腐烂趋势
- **YAML front matter 扩展字段**：`audience` / `read_priority` / `max_lines` / `parent_doc` / `code_anchors` / `applicable_project_types` / `last_synced_commit`
- **`applicable_project_types` 项目类型过滤**：Phase 1 骨架按字段自动过滤模板，无需 AI 自由判断
- **代码位置列必填**：所有列表型字段必须包含「源文件」/「定义位置」列，使用 `file:line` 格式
- **`last_synced_commit` 增量识别**：doc-sync 防线 1 基于该字段执行 `git diff` 增量识别变更范围
- **大型项目模式 Phase 2A-2D**：项目轮廓 → 锚点识别 → 模块聚焦分析 → 渐进式生成
- **任务持久化机制**：大型项目模式将进度持久化到 `.init-docs/` 目录，可跨会话恢复
- **确定性清单预扫描**：Phase 2 启动前用 shell 命令建立完整文件清单，作为子代理的强制检查表

### 改进

- 子代理改为隔离上下文执行，结果立即落盘到 `.init-temp/` 或 `.init-docs/`
- 进度通报规范化：主 agent 用 Phase 级输出，子代理用 `├─` 缩进区分

---

## [0.1.1]

### 修复

- 文档优化与初始化流程稳定性改进

---

## [0.1.0]

### 新增

- 初始版本发布
- `blyy-init-docs` Skill — 项目文档初始化
- `blyy-doc-sync` Skill — 文档持续同步维护
- 基础三道防线模型
- 多 AI 工具兼容（Gemini / Codex / Cursor / Claude Code）
- Windows / Linux / macOS 安装脚本

[0.3.0]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.3.0
[0.2.0]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.2.0
[0.1.1]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.1.1
[0.1.0]: https://github.com/wugl/blyy-doc-skills/releases/tag/v0.1.0
