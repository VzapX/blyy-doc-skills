# Large Project Mode — 大型项目分阶段执行

> **何时读取**：Phase A0 检测到源代码文件 > 500 或子项目 > 5 时。
>
> **目的**：通过分层聚焦 + 任务持久化 + 子代理隔离，在跨会话场景下完成大型项目的 ai-docs 生成。
>
> 小型项目（≤500 文件）请勿读取本文件，直接使用 SKILL.md 的标准流程。

---

## 一、大型项目 Mode A 分阶段流程

大型项目将标准 Mode A 的 Phase A1–A3 展开为更细的四阶段：

### Phase A1-L — 项目轮廓扫描

> 由主 agent 串行完成，**不读业务代码**。

1. **读项目清单文件**：`.sln`、`.csproj`、`package.json`、`go.mod`、`pom.xml`、`Cargo.toml` 等，提取项目名称、技术栈、子项目列表
2. **生成目录树**（限深度 2–3 层）：`fd --type d --max-depth 3 --exclude .git --exclude node_modules --exclude bin --exclude obj`
3. **文件统计**：`fd --type f --exclude .git | xargs -I{} basename {} | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20`
4. **输出轮廓报告**→ 持久化到 `ai-docs/.init-temp/project-profile.md`

> **检查点 ①**：向用户展示项目轮廓，确认技术栈和项目范围。

### Phase A1-M — 模块识别与分级

1. 用 `tech-stack-matrix.md` 识别模块（含架构布局检测和跨层提取）
2. 用 `module-tiering.md` 评分分级
3. 持久化到 `ai-docs/.init-temp/modules.yaml`

> **检查点 ②**：向用户确认模块清单与分级。

### Phase A3-L — 模块级聚焦分析（高度并行）

**主 agent 编排**：
1. 为每个 Core/Standard 模块准备子代理任务（含目录范围 + 分级要求 + 强制规则摘要）
2. 按模块规模决定分组：< 20 文件合并、20–100 一对一、> 100 拆分子模块
3. 并行分发给子代理（建议并行度 3–5）
4. Lightweight 模块由主 agent 直接处理

**子代理执行**（每个模块独立上下文）：
1. 仅在分配的模块目录范围内工作
2. 按分级要求提取对应类别的分析条目（Core=5 类，Standard=3 类）
3. 每条断言标注 T1/T2/T3 + 锚点
4. **立即落盘**到 `ai-docs/.init-temp/analysis-{{module}}.md`
5. 输入文件超 800 行时分批 Read → 提取 → 追加写入

**主 agent 整合**：
1. 从落盘文件中读取每份报告
2. 补充跨模块关联
3. 收集所有 T3 → 进入 Phase A4 审查关卡

> **检查点 ③**：Pre-Fill Review Gate（同标准模式）。

### Phase A5-L — 渐进式文档生成

按以下顺序写入，每个文件完成后立即落盘：

1. `code-queries.md`（Phase A2 已完成）
2. `modules.md`（含分级标注）
3. `glossary.md`
4. `flows.md`
5. `decisions.md`
6. `INDEX.md`
7. `MANIFEST.yaml`

每个文件写完后更新 `master-task.yaml` 进度。用户可在任意步骤后暂停（进度已持久化）。

---

## 二、跨会话持久化机制

大型项目生成可能跨越多个会话。通过 `.init-temp/` 目录持久化进度：

```
ai-docs/.init-temp/
├── master-task.yaml          ← 主任务进度（当前阶段 + checklist）
├── project-profile.md        ← Phase A1-L 项目轮廓
├── modules.yaml              ← Phase A1-M 模块清单（用户已确认 + 分级）
├── clarifications.yaml       ← Phase A4 用户澄清记录
└── analysis-{{module}}.md    ← 各模块分析报告（子代理产出）
```

**`master-task.yaml` 格式**：

```yaml
project_name: {{PROJECT_NAME}}
detected_stack: {{STACK}}
current_phase: A3-L          # 当前阶段标识
started_at: 2026-04-13
modules_confirmed: true
modules_total: 12
modules_analyzed: 8          # 已完成分析的模块数
files_written:               # 已写入的正式文档
  - code-queries.md
  - modules.md
checklist:
  - [x] Phase A0 环境探测
  - [x] Phase A1-L 项目轮廓
  - [x] Phase A1-M 模块识别与分级
  - [x] Phase A2 生成 code-queries.md
  - [/] Phase A3-L 模块聚焦分析 (8/12)
  - [ ] Phase A4 Pre-Fill Review
  - [ ] Phase A5-L 写正式文档
  - [ ] Phase A6 自检
```

**断点续做**：新会话 Phase 0 检测到 `master-task.yaml` 存在 → 读取进度 → 向用户展示并询问"继续/重新开始" → 从中断点继续。

**关键原则**：每完成一个步骤立即更新 `master-task.yaml`；子代理完成后立即写入分析报告。

---

## 三、上下文保护规则

1. **子代理隔离上下文**：每个子代理拥有独立上下文窗口，仅加载自己负责的模块文件
2. **即时落盘**：子代理完成分析后，**必须立即写入文件**，而非返回到主 agent 上下文
3. **主 agent 只读摘要**：整合阶段对每个子代理的落盘产物只读取摘要和条目列表，不重读原始源文件
4. **分批处理**：单个子代理的输入文件总量超 800 行时，分批处理：读一批 → 提取 → 追加写入 → 释放上下文 → 读下一批

---

## 四、异常处理

| 场景 | 处理 |
|------|------|
| 子代理长时间无响应 | 标记失败，继续其他子代理；最终报告中标注 |
| 子代理输出格式异常 | 尝试提取可用信息；完全不可用则重新分发一次 |
| 上下文窗口频繁压缩 | 建议进一步拆分模块子代理任务 |

---

## 五、模式自动升级

若标准模式执行过程中出现以下情况，建议切换到大型项目模式：

- Phase A3 子代理数量超过 8 个
- 单个子代理分析的文件超过 200 个
- 上下文窗口频繁触发压缩

切换方式：暂停当前 Phase A3，将已完成的子代理产出保留在 `.init-temp/`，创建 `master-task.yaml`，从对应步骤恢复。

---

## 六、文件过滤规则

所有扫描阶段默认排除以下文件/目录：

```
# 依赖与构建产物
node_modules/, bin/, obj/, dist/, build/, out/, target/, packages/

# 版本控制
.git/, .svn/, .hg/

# IDE 配置
.vs/, .vscode/, .idea/, *.user, *.suo

# 生成代码
*.Designer.cs, *.g.cs, *.generated.*
auto-generated/, __pycache__/, *.pyc
.next/, .nuxt/, .output/

# 二进制与媒体
*.dll, *.exe, *.pdb, *.jar, *.class
*.jpg, *.png, *.gif, *.ico, *.svg, *.woff, *.ttf

# 测试数据
**/testdata/, **/fixtures/, **/snapshots/, **/mocks/

# 锁文件
package-lock.json, yarn.lock, pnpm-lock.yaml, Gemfile.lock, poetry.lock
```

---

## 七、进度通报规范

| 时机 | 输出格式 |
|------|----------|
| 进入每个 Phase | `📋 Phase {id} — {阶段名} 开始...` |
| Phase A1-L 完成 | `📊 项目轮廓: {N} 个源文件, {M} 个子项目, 技术栈: {stack}` |
| Phase A1-M 完成 | `📊 模块分级: Core {N} / Standard {M} / Lightweight {K}` |
| 每个子代理启动 | `🔄 分析模块: {name} [{tier}]（{N} 个文件）...` |
| 每个子代理完成 | `✅ {name} 分析完成（terms {N}, flows {M}, T3 待审查 {K}）` |
| Phase A4 开始 | `📋 Pre-Fill Review: 发现 {N} 个 T3 推测项需确认` |
| 每个文档写入 | `📝 已写入 ({当前}/{总数}): {文件名}` |
| Phase A6 完成 | 输出 INIT-AI-REPORT |

子代理内部每处理 5 个文件输出一行进度：`  ├─ [{模块名}] 已分析 5/{总数} 个文件`
